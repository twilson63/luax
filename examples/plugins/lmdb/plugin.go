package main

import (
	"fmt"
	"os"

	"github.com/bmatsuo/lmdb-go/lmdb"
	"github.com/yuin/gopher-lua"
)

// HypePlugin interface (required for plugin implementation)
type HypePlugin interface {
	Name() string
	Version() string
	Description() string
	Register(L *lua.LState) error
	Dependencies() []string
	Close() error
}

// LMDBPlugin implements the HypePlugin interface for LMDB database operations
type LMDBPlugin struct {
	name        string
	version     string
	description string
}

// NewPlugin creates a new LMDB plugin instance
func NewPlugin() interface{} {
	return &LMDBPlugin{
		name:        "lmdb",
		version:     "1.0.0",
		description: "LMDB database plugin for high-performance key-value storage",
	}
}

// Name returns the plugin name
func (p *LMDBPlugin) Name() string {
	return p.name
}

// Version returns the plugin version
func (p *LMDBPlugin) Version() string {
	return p.version
}

// Description returns the plugin description
func (p *LMDBPlugin) Description() string {
	return p.description
}

// Dependencies returns the Go dependencies needed for this plugin
func (p *LMDBPlugin) Dependencies() []string {
	return []string{
		"github.com/bmatsuo/lmdb-go/lmdb",
	}
}

// Close cleans up plugin resources
func (p *LMDBPlugin) Close() error {
	return nil
}

// Register registers the LMDB module with the Lua state
func (p *LMDBPlugin) Register(L *lua.LState) error {
	// Register metatables first
	registerLMDBMetatables(L)
	
	// Register the lmdb module
	L.PreloadModule("lmdb", lmdbModuleLoader)
	return nil
}

// lmdbModuleLoader is the module loader function for LMDB
func lmdbModuleLoader(L *lua.LState) int {
	// Create the lmdb module table
	lmdbModule := L.NewTable()

	// Register functions
	L.SetField(lmdbModule, "open", L.NewFunction(lmdbOpen))
	L.SetField(lmdbModule, "version", L.NewFunction(lmdbVersion))

	// Push the module table onto the stack
	L.Push(lmdbModule)
	return 1
}

// LMDBEnv represents an LMDB environment
type LMDBEnv struct {
	env *lmdb.Env
	path string
}

// LMDBTxn represents an LMDB transaction
type LMDBTxn struct {
	txn *lmdb.Txn
	env *LMDBEnv
}

// LMDBDatabase represents an LMDB database
type LMDBDatabase struct {
	dbi lmdb.DBI
	name string
}

// LMDBCursor represents an LMDB cursor
type LMDBCursor struct {
	cursor *lmdb.Cursor
	txn    *LMDBTxn
}

// lmdbOpen opens an LMDB environment
func lmdbOpen(L *lua.LState) int {
	path := L.CheckString(1)
	
	// Get optional parameters
	opt := L.ToTable(2)
	
	// Default options
	maxDBs := 10
	mapSize := int64(1024 * 1024 * 1024) // 1GB default
	
	if opt != nil {
		if v := L.GetField(opt, "maxdbs"); v != lua.LNil {
			if num, ok := v.(lua.LNumber); ok {
				maxDBs = int(num)
			}
		}
		if v := L.GetField(opt, "mapsize"); v != lua.LNil {
			if num, ok := v.(lua.LNumber); ok {
				mapSize = int64(num)
			}
		}
	}
	
	// Create directory if it doesn't exist
	if err := os.MkdirAll(path, 0755); err != nil {
		L.Push(lua.LNil)
		L.Push(lua.LString(fmt.Sprintf("failed to create directory: %v", err)))
		return 2
	}
	
	// Open LMDB environment
	env, err := lmdb.NewEnv()
	if err != nil {
		L.Push(lua.LNil)
		L.Push(lua.LString(fmt.Sprintf("failed to create environment: %v", err)))
		return 2
	}
	
	// Set map size
	if err := env.SetMapSize(mapSize); err != nil {
		env.Close()
		L.Push(lua.LNil)
		L.Push(lua.LString(fmt.Sprintf("failed to set map size: %v", err)))
		return 2
	}
	
	// Set max DBs
	if err := env.SetMaxDBs(maxDBs); err != nil {
		env.Close()
		L.Push(lua.LNil)
		L.Push(lua.LString(fmt.Sprintf("failed to set max DBs: %v", err)))
		return 2
	}
	
	// Open the environment
	if err := env.Open(path, 0, 0644); err != nil {
		env.Close()
		L.Push(lua.LNil)
		L.Push(lua.LString(fmt.Sprintf("failed to open environment: %v", err)))
		return 2
	}
	
	// Create environment userdata
	lmdbEnv := &LMDBEnv{
		env:  env,
		path: path,
	}
	
	// Create Lua userdata
	ud := L.NewUserData()
	ud.Value = lmdbEnv
	
	// Set metatable for environment methods
	L.SetMetatable(ud, L.GetTypeMetatable("lmdb_env"))
	
	L.Push(ud)
	L.Push(lua.LNil)
	return 2
}

// lmdbVersion returns the LMDB version
func lmdbVersion(L *lua.LState) int {
	major, minor, patch, _ := lmdb.Version()
	versionStr := fmt.Sprintf("%d.%d.%d", major, minor, patch)
	L.Push(lua.LString(versionStr))
	return 1
}

// Register LMDB userdata metatables
func init() {
	// This will be called when the plugin is loaded
	// We need to register our metatables somewhere accessible
}

// registerLMDBMetatables registers the LMDB userdata metatables
func registerLMDBMetatables(L *lua.LState) {
	// Environment metatable
	envMT := L.NewTypeMetatable("lmdb_env")
	L.SetField(envMT, "__index", L.NewFunction(lmdbEnvIndex))
	L.SetField(envMT, "__gc", L.NewFunction(lmdbEnvGC))
	
	// Transaction metatable
	txnMT := L.NewTypeMetatable("lmdb_txn")
	L.SetField(txnMT, "__index", L.NewFunction(lmdbTxnIndex))
	L.SetField(txnMT, "__gc", L.NewFunction(lmdbTxnGC))
	
	// Database metatable
	dbMT := L.NewTypeMetatable("lmdb_db")
	L.SetField(dbMT, "__index", L.NewFunction(lmdbDbIndex))
	
	// Cursor metatable
	cursorMT := L.NewTypeMetatable("lmdb_cursor")
	L.SetField(cursorMT, "__index", L.NewFunction(lmdbCursorIndex))
	L.SetField(cursorMT, "__gc", L.NewFunction(lmdbCursorGC))
}

// lmdbEnvIndex handles environment method calls
func lmdbEnvIndex(L *lua.LState) int {
	env := checkLMDBEnv(L, 1)
	method := L.CheckString(2)
	
	switch method {
	case "begin":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			return lmdbBegin(L, env)
		}))
	case "open_db":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			return lmdbOpenDB(L, env)
		}))
	case "close":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			return lmdbEnvClose(L, env)
		}))
	case "sync":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			return lmdbSync(L, env)
		}))
	case "stat":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			return lmdbStat(L, env)
		}))
	case "path":
		L.Push(lua.LString(env.path))
	default:
		L.Push(lua.LNil)
	}
	
	return 1
}

// lmdbEnvGC handles environment garbage collection
func lmdbEnvGC(L *lua.LState) int {
	env := checkLMDBEnv(L, 1)
	if env.env != nil {
		env.env.Close()
		env.env = nil
	}
	return 0
}

// lmdbBegin starts a new transaction
func lmdbBegin(L *lua.LState, env *LMDBEnv) int {
	readonly := L.OptBool(2, false)
	
	var flags uint = 0
	if readonly {
		flags = lmdb.Readonly
	}
	
	txn, err := env.env.BeginTxn(nil, flags)
	if err != nil {
		L.Push(lua.LNil)
		L.Push(lua.LString(fmt.Sprintf("failed to begin transaction: %v", err)))
		return 2
	}
	
	// Create transaction userdata
	lmdbTxn := &LMDBTxn{
		txn: txn,
		env: env,
	}
	
	ud := L.NewUserData()
	ud.Value = lmdbTxn
	L.SetMetatable(ud, L.GetTypeMetatable("lmdb_txn"))
	
	L.Push(ud)
	L.Push(lua.LNil)
	return 2
}

// lmdbOpenDB opens a database within the environment
func lmdbOpenDB(L *lua.LState, env *LMDBEnv) int {
	name := L.OptString(2, "")
	create := L.OptBool(3, true)
	
	// Start a transaction to open the database
	txn, err := env.env.BeginTxn(nil, 0)
	if err != nil {
		L.Push(lua.LNil)
		L.Push(lua.LString(fmt.Sprintf("failed to begin transaction: %v", err)))
		return 2
	}
	defer txn.Abort()
	
	var flags uint = 0
	if create {
		flags = lmdb.Create
	}
	
	// Try different flag combinations to handle various database types
	flagCombinations := []uint{
		flags,                    // Default
		flags | lmdb.DupSort,     // Duplicate keys allowed
		flags | lmdb.ReverseKey,  // Reverse key order  
		flags | lmdb.DupFixed,    // Fixed-size duplicate data
		flags | lmdb.ReverseDup,  // Reverse duplicate data order
	}
	
	var dbi lmdb.DBI
	var lastError error
	
	for _, flagCombo := range flagCombinations {
		dbi, err = txn.OpenDBI(name, flagCombo)
		if err == nil {
			break // Success
		}
		lastError = err
	}
	
	if err != nil {
		L.Push(lua.LNil)
		L.Push(lua.LString(fmt.Sprintf("failed to open database: %v", lastError)))
		return 2
	}
	
	if err := txn.Commit(); err != nil {
		L.Push(lua.LNil)
		L.Push(lua.LString(fmt.Sprintf("failed to commit transaction: %v", err)))
		return 2
	}
	
	// Create database userdata
	lmdbDB := &LMDBDatabase{
		dbi:  dbi,
		name: name,
	}
	
	ud := L.NewUserData()
	ud.Value = lmdbDB
	L.SetMetatable(ud, L.GetTypeMetatable("lmdb_db"))
	
	L.Push(ud)
	L.Push(lua.LNil)
	return 2
}

// lmdbEnvClose closes the environment
func lmdbEnvClose(L *lua.LState, env *LMDBEnv) int {
	if env.env != nil {
		env.env.Close()
		env.env = nil
	}
	L.Push(lua.LBool(true))
	return 1
}

// lmdbSync syncs the environment
func lmdbSync(L *lua.LState, env *LMDBEnv) int {
	force := L.OptBool(2, false)
	
	if err := env.env.Sync(force); err != nil {
		L.Push(lua.LBool(false))
		L.Push(lua.LString(fmt.Sprintf("sync failed: %v", err)))
		return 2
	}
	
	L.Push(lua.LBool(true))
	L.Push(lua.LNil)
	return 2
}

// lmdbStat returns environment statistics
func lmdbStat(L *lua.LState, env *LMDBEnv) int {
	stat, err := env.env.Stat()
	if err != nil {
		L.Push(lua.LNil)
		L.Push(lua.LString(fmt.Sprintf("stat failed: %v", err)))
		return 2
	}
	
	statTable := L.NewTable()
	L.SetField(statTable, "psize", lua.LNumber(stat.PSize))
	L.SetField(statTable, "depth", lua.LNumber(stat.Depth))
	L.SetField(statTable, "branch_pages", lua.LNumber(stat.BranchPages))
	L.SetField(statTable, "leaf_pages", lua.LNumber(stat.LeafPages))
	L.SetField(statTable, "overflow_pages", lua.LNumber(stat.OverflowPages))
	L.SetField(statTable, "entries", lua.LNumber(stat.Entries))
	
	L.Push(statTable)
	L.Push(lua.LNil)
	return 2
}

// lmdbTxnIndex handles transaction method calls
func lmdbTxnIndex(L *lua.LState) int {
	txn := checkLMDBTxn(L, 1)
	method := L.CheckString(2)
	
	switch method {
	case "get":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			return lmdbGet(L, txn)
		}))
	case "put":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			return lmdbPut(L, txn)
		}))
	case "del":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			return lmdbDel(L, txn)
		}))
	case "commit":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			return lmdbCommit(L, txn)
		}))
	case "abort":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			return lmdbAbort(L, txn)
		}))
	case "cursor":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			return lmdbCursor(L, txn)
		}))
	default:
		L.Push(lua.LNil)
	}
	
	return 1
}

// lmdbTxnGC handles transaction garbage collection
func lmdbTxnGC(L *lua.LState) int {
	txn := checkLMDBTxn(L, 1)
	if txn.txn != nil {
		txn.txn.Abort()
		txn.txn = nil
	}
	return 0
}

// lmdbDbIndex handles database method calls
func lmdbDbIndex(L *lua.LState) int {
	db := checkLMDBDB(L, 1)
	method := L.CheckString(2)
	
	switch method {
	case "name":
		L.Push(lua.LString(db.name))
	default:
		L.Push(lua.LNil)
	}
	
	return 1
}

// Transaction operations
func lmdbGet(L *lua.LState, txn *LMDBTxn) int {
	db := checkLMDBDB(L, 2)
	key := L.CheckString(3)
	
	val, err := txn.txn.Get(db.dbi, []byte(key))
	if lmdb.IsNotFound(err) {
		L.Push(lua.LNil)
		L.Push(lua.LNil)
		return 2
	}
	if err != nil {
		L.Push(lua.LNil)
		L.Push(lua.LString(fmt.Sprintf("get failed: %v", err)))
		return 2
	}
	
	L.Push(lua.LString(string(val)))
	L.Push(lua.LNil)
	return 2
}

func lmdbPut(L *lua.LState, txn *LMDBTxn) int {
	db := checkLMDBDB(L, 2)
	key := L.CheckString(3)
	value := L.CheckString(4)
	
	err := txn.txn.Put(db.dbi, []byte(key), []byte(value), 0)
	if err != nil {
		L.Push(lua.LBool(false))
		L.Push(lua.LString(fmt.Sprintf("put failed: %v", err)))
		return 2
	}
	
	L.Push(lua.LBool(true))
	L.Push(lua.LNil)
	return 2
}

func lmdbDel(L *lua.LState, txn *LMDBTxn) int {
	db := checkLMDBDB(L, 2)
	key := L.CheckString(3)
	
	err := txn.txn.Del(db.dbi, []byte(key), nil)
	if lmdb.IsNotFound(err) {
		L.Push(lua.LBool(false))
		L.Push(lua.LString("key not found"))
		return 2
	}
	if err != nil {
		L.Push(lua.LBool(false))
		L.Push(lua.LString(fmt.Sprintf("del failed: %v", err)))
		return 2
	}
	
	L.Push(lua.LBool(true))
	L.Push(lua.LNil)
	return 2
}

func lmdbCommit(L *lua.LState, txn *LMDBTxn) int {
	if txn.txn == nil {
		L.Push(lua.LBool(false))
		L.Push(lua.LString("transaction already closed"))
		return 2
	}
	
	err := txn.txn.Commit()
	txn.txn = nil // Mark as closed
	
	if err != nil {
		L.Push(lua.LBool(false))
		L.Push(lua.LString(fmt.Sprintf("commit failed: %v", err)))
		return 2
	}
	
	L.Push(lua.LBool(true))
	L.Push(lua.LNil)
	return 2
}

func lmdbAbort(L *lua.LState, txn *LMDBTxn) int {
	if txn.txn == nil {
		L.Push(lua.LBool(false))
		L.Push(lua.LString("transaction already closed"))
		return 2
	}
	
	txn.txn.Abort()
	txn.txn = nil // Mark as closed
	
	L.Push(lua.LBool(true))
	L.Push(lua.LNil)
	return 2
}

// Helper functions to check userdata types
func checkLMDBEnv(L *lua.LState, n int) *LMDBEnv {
	ud := L.CheckUserData(n)
	if env, ok := ud.Value.(*LMDBEnv); ok {
		return env
	}
	L.ArgError(n, "lmdb_env expected")
	return nil
}

func checkLMDBTxn(L *lua.LState, n int) *LMDBTxn {
	ud := L.CheckUserData(n)
	if txn, ok := ud.Value.(*LMDBTxn); ok {
		return txn
	}
	L.ArgError(n, "lmdb_txn expected")
	return nil
}

func checkLMDBDB(L *lua.LState, n int) *LMDBDatabase {
	ud := L.CheckUserData(n)
	if db, ok := ud.Value.(*LMDBDatabase); ok {
		return db
	}
	L.ArgError(n, "lmdb_db expected")
	return nil
}

// lmdbCursor creates a new cursor for the database
func lmdbCursor(L *lua.LState, txn *LMDBTxn) int {
	db := checkLMDBDB(L, 2)
	
	cursor, err := txn.txn.OpenCursor(db.dbi)
	if err != nil {
		L.Push(lua.LNil)
		L.Push(lua.LString(fmt.Sprintf("failed to open cursor: %v", err)))
		return 2
	}
	
	// Create cursor userdata
	lmdbCursor := &LMDBCursor{
		cursor: cursor,
		txn:    txn,
	}
	
	ud := L.NewUserData()
	ud.Value = lmdbCursor
	L.SetMetatable(ud, L.GetTypeMetatable("lmdb_cursor"))
	
	L.Push(ud)
	L.Push(lua.LNil)
	return 2
}

// lmdbCursorIndex handles cursor method calls
func lmdbCursorIndex(L *lua.LState) int {
	cursor := checkLMDBCursor(L, 1)
	method := L.CheckString(2)
	
	switch method {
	case "first":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			return lmdbCursorFirst(L, cursor)
		}))
	case "last":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			return lmdbCursorLast(L, cursor)
		}))
	case "next":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			return lmdbCursorNext(L, cursor)
		}))
	case "prev":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			return lmdbCursorPrev(L, cursor)
		}))
	case "get":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			return lmdbCursorGet(L, cursor)
		}))
	case "close":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			return lmdbCursorClose(L, cursor)
		}))
	default:
		L.Push(lua.LNil)
	}
	
	return 1
}

// lmdbCursorGC handles cursor garbage collection
func lmdbCursorGC(L *lua.LState) int {
	cursor := checkLMDBCursor(L, 1)
	if cursor.cursor != nil {
		cursor.cursor.Close()
		cursor.cursor = nil
	}
	return 0
}

// Cursor operations
func lmdbCursorFirst(L *lua.LState, cursor *LMDBCursor) int {
	if cursor.cursor == nil {
		L.Push(lua.LNil)
		L.Push(lua.LNil)
		L.Push(lua.LString("cursor is closed"))
		return 3
	}
	
	key, val, err := cursor.cursor.Get(nil, nil, lmdb.First)
	if lmdb.IsNotFound(err) {
		L.Push(lua.LNil)
		L.Push(lua.LNil)
		L.Push(lua.LNil)
		return 3
	}
	if err != nil {
		L.Push(lua.LNil)
		L.Push(lua.LNil)
		L.Push(lua.LString(fmt.Sprintf("cursor first failed: %v", err)))
		return 3
	}
	
	L.Push(lua.LString(string(key)))
	L.Push(lua.LString(string(val)))
	L.Push(lua.LNil)
	return 3
}

func lmdbCursorLast(L *lua.LState, cursor *LMDBCursor) int {
	if cursor.cursor == nil {
		L.Push(lua.LNil)
		L.Push(lua.LNil)
		L.Push(lua.LString("cursor is closed"))
		return 3
	}
	
	key, val, err := cursor.cursor.Get(nil, nil, lmdb.Last)
	if lmdb.IsNotFound(err) {
		L.Push(lua.LNil)
		L.Push(lua.LNil)
		L.Push(lua.LNil)
		return 3
	}
	if err != nil {
		L.Push(lua.LNil)
		L.Push(lua.LNil)
		L.Push(lua.LString(fmt.Sprintf("cursor last failed: %v", err)))
		return 3
	}
	
	L.Push(lua.LString(string(key)))
	L.Push(lua.LString(string(val)))
	L.Push(lua.LNil)
	return 3
}

func lmdbCursorNext(L *lua.LState, cursor *LMDBCursor) int {
	if cursor.cursor == nil {
		L.Push(lua.LNil)
		L.Push(lua.LNil)
		L.Push(lua.LString("cursor is closed"))
		return 3
	}
	
	key, val, err := cursor.cursor.Get(nil, nil, lmdb.Next)
	if lmdb.IsNotFound(err) {
		L.Push(lua.LNil)
		L.Push(lua.LNil)
		L.Push(lua.LNil)
		return 3
	}
	if err != nil {
		L.Push(lua.LNil)
		L.Push(lua.LNil)
		L.Push(lua.LString(fmt.Sprintf("cursor next failed: %v", err)))
		return 3
	}
	
	L.Push(lua.LString(string(key)))
	L.Push(lua.LString(string(val)))
	L.Push(lua.LNil)
	return 3
}

func lmdbCursorPrev(L *lua.LState, cursor *LMDBCursor) int {
	if cursor.cursor == nil {
		L.Push(lua.LNil)
		L.Push(lua.LNil)
		L.Push(lua.LString("cursor is closed"))
		return 3
	}
	
	key, val, err := cursor.cursor.Get(nil, nil, lmdb.Prev)
	if lmdb.IsNotFound(err) {
		L.Push(lua.LNil)
		L.Push(lua.LNil)
		L.Push(lua.LNil)
		return 3
	}
	if err != nil {
		L.Push(lua.LNil)
		L.Push(lua.LNil)
		L.Push(lua.LString(fmt.Sprintf("cursor prev failed: %v", err)))
		return 3
	}
	
	L.Push(lua.LString(string(key)))
	L.Push(lua.LString(string(val)))
	L.Push(lua.LNil)
	return 3
}

func lmdbCursorGet(L *lua.LState, cursor *LMDBCursor) int {
	if cursor.cursor == nil {
		L.Push(lua.LNil)
		L.Push(lua.LNil)
		L.Push(lua.LString("cursor is closed"))
		return 3
	}
	
	key, val, err := cursor.cursor.Get(nil, nil, lmdb.GetCurrent)
	if lmdb.IsNotFound(err) {
		L.Push(lua.LNil)
		L.Push(lua.LNil)
		L.Push(lua.LNil)
		return 3
	}
	if err != nil {
		L.Push(lua.LNil)
		L.Push(lua.LNil)
		L.Push(lua.LString(fmt.Sprintf("cursor get failed: %v", err)))
		return 3
	}
	
	L.Push(lua.LString(string(key)))
	L.Push(lua.LString(string(val)))
	L.Push(lua.LNil)
	return 3
}

func lmdbCursorClose(L *lua.LState, cursor *LMDBCursor) int {
	if cursor.cursor != nil {
		cursor.cursor.Close()
		cursor.cursor = nil
	}
	L.Push(lua.LBool(true))
	return 1
}

// Helper function to check cursor userdata
func checkLMDBCursor(L *lua.LState, n int) *LMDBCursor {
	ud := L.CheckUserData(n)
	if cursor, ok := ud.Value.(*LMDBCursor); ok {
		return cursor
	}
	L.ArgError(n, "lmdb_cursor expected")
	return nil
}

