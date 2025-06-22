package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"text/template"
)

// Removed embed for now - we'll generate everything at build time

type BuildConfig struct {
	ScriptPath   string
	OutputName   string
	Target       string
	ScriptContent string
}


func buildExecutable(scriptPath, outputName, target string) error {
	config := &BuildConfig{
		ScriptPath: scriptPath,
		OutputName: outputName,
		Target:     target,
	}

	if config.OutputName == "" {
		base := filepath.Base(scriptPath)
		config.OutputName = strings.TrimSuffix(base, filepath.Ext(base))
	}

	if config.Target == "current" {
		config.Target = runtime.GOOS
	}

	scriptContent, err := os.ReadFile(scriptPath)
	if err != nil {
		return fmt.Errorf("failed to read script file: %w", err)
	}
	config.ScriptContent = string(scriptContent)

	tempDir, err := os.MkdirTemp("", "luax-build-*")
	if err != nil {
		return fmt.Errorf("failed to create temp directory: %w", err)
	}
	defer os.RemoveAll(tempDir)

	if err := generateRuntimeCode(tempDir, config); err != nil {
		return fmt.Errorf("failed to generate runtime code: %w", err)
	}

	if err := buildExecutableFromRuntime(tempDir, config); err != nil {
		return fmt.Errorf("failed to build executable: %w", err)
	}

	return nil
}

func generateRuntimeCode(tempDir string, config *BuildConfig) error {
	runtimeTemplate := `package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"os"
	"sync"
	"github.com/yuin/gopher-lua"
	"github.com/gdamore/tcell/v2"
	"github.com/rivo/tview"
	"go.etcd.io/bbolt"
	"io"
	"net/http"
	"time"
)

const luaScript = ` + "`" + `{{.ScriptContent}}` + "`" + `

func main() {
	L := lua.NewState()
	defer L.Close()

	// Open standard libraries
	L.PreloadModule("_G", lua.OpenBase)
	L.PreloadModule("package", lua.OpenPackage)
	L.PreloadModule("coroutine", lua.OpenCoroutine)
	L.PreloadModule("table", lua.OpenTable)
	L.PreloadModule("io", lua.OpenIo)
	L.PreloadModule("os", lua.OpenOs)
	L.PreloadModule("string", lua.OpenString)
	L.PreloadModule("math", lua.OpenMath)
	L.PreloadModule("debug", lua.OpenDebug)
	
	// Set up command line arguments
	setupCommandLineArgs(L)
	
	// Register HTTP module
	registerHTTPModule(L)

	// Register KV module
	registerKVModule(L)

	// Register TUI functions
	registerTUIFunctions(L)

	if err := L.DoString(luaScript); err != nil {
		fmt.Fprintf(os.Stderr, "Error running Lua script: %v\n", err)
		os.Exit(1)
	}
}

func setupCommandLineArgs(L *lua.LState) {
	// Create arg table (following Lua convention)
	argTable := L.NewTable()
	
	// Get command line arguments from os.Args
	args := os.Args
	
	// arg[0] is the executable name (script name equivalent)
	if len(args) > 0 {
		argTable.RawSetInt(0, lua.LString(args[0]))
	}
	
	// arg[1], arg[2], etc. are the script arguments
	for i := 1; i < len(args); i++ {
		argTable.RawSetInt(i, lua.LString(args[i]))
	}
	
	// Set global arg table
	L.SetGlobal("arg", argTable)
}

func registerTUIFunctions(L *lua.LState) {
	// Create TUI module
	tuiModule := L.NewTable()
	
	// Basic TUI functions
	L.SetField(tuiModule, "newApp", L.NewFunction(luaNewApp))
	L.SetField(tuiModule, "newTextView", L.NewFunction(luaNewTextView))
	L.SetField(tuiModule, "newInputField", L.NewFunction(luaNewInputField))
	L.SetField(tuiModule, "newButton", L.NewFunction(luaNewButton))
	L.SetField(tuiModule, "newFlex", L.NewFunction(luaNewFlex))
	
	L.SetGlobal("tui", tuiModule)
	
	// Set up metatables for TUI objects
	setupTUIMetatables(L)
}

func setupTUIMetatables(L *lua.LState) {
	// App metatable
	appMT := L.NewTypeMetatable("App")
	L.SetField(appMT, "__index", L.NewFunction(appIndex))
	
	// TextView metatable  
	textViewMT := L.NewTypeMetatable("TextView")
	L.SetField(textViewMT, "__index", L.NewFunction(textViewIndex))
	
	// InputField metatable
	inputFieldMT := L.NewTypeMetatable("InputField")
	L.SetField(inputFieldMT, "__index", L.NewFunction(inputFieldIndex))
	
	// Button metatable
	buttonMT := L.NewTypeMetatable("Button")
	L.SetField(buttonMT, "__index", L.NewFunction(buttonIndex))
	
	// Flex metatable
	flexMT := L.NewTypeMetatable("Flex")
	L.SetField(flexMT, "__index", L.NewFunction(flexIndex))
}

func appIndex(L *lua.LState) int {
	ud := L.CheckUserData(1)
	app := ud.Value.(*tview.Application)
	method := L.CheckString(2)
	
	switch method {
	case "SetRoot":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			// Skip the first argument (self)
			rootUD := L.CheckUserData(2)
			fullscreen := L.OptBool(3, true)
			app.SetRoot(rootUD.Value.(tview.Primitive), fullscreen)
			return 0
		}))
	case "Run":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			if err := app.Run(); err != nil {
				L.Push(lua.LString(err.Error()))
				return 1
			}
			return 0
		}))
	case "Stop":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			app.Stop()
			return 0
		}))
	case "SetFocus":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			primitiveUD := L.CheckUserData(2)
			app.SetFocus(primitiveUD.Value.(tview.Primitive))
			return 0
		}))
	case "SetInputCapture":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			fn := L.CheckFunction(2)
			app.SetInputCapture(func(event *tcell.EventKey) *tcell.EventKey {
				// Create a simple event object for Lua
				eventObj := L.NewTable()
				L.SetField(eventObj, "Key", L.NewFunction(func(L *lua.LState) int {
					L.Push(lua.LNumber(int(event.Key())))
					return 1
				}))
				
				L.Push(fn)
				L.Push(eventObj)
				L.Call(1, 1)
				
				// Check return value - if nil, consume event
				ret := L.Get(-1)
				L.Pop(1)
				if ret == lua.LNil {
					return nil
				}
				return event
			})
			L.Push(ud)
			return 1
		}))
	case "Draw":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			app.QueueUpdateDraw(func() {
				// This safely queues a redraw
			})
			return 0
		}))
	}
	return 1
}

func textViewIndex(L *lua.LState) int {
	ud := L.CheckUserData(1)
	textView := ud.Value.(*tview.TextView)
	method := L.CheckString(2)
	
	switch method {
	case "SetText":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			text := L.CheckString(2)
			textView.SetText(text)
			L.Push(ud)
			return 1
		}))
	case "SetWrap":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			wrap := L.CheckBool(2)
			textView.SetWrap(wrap)
			L.Push(ud)
			return 1
		}))
	case "SetWordWrap":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			wordWrap := L.CheckBool(2)
			textView.SetWordWrap(wordWrap)
			L.Push(ud)
			return 1
		}))
	case "SetTitle":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			title := L.CheckString(2)
			textView.SetTitle(title)
			L.Push(ud)
			return 1
		}))
	case "SetTextColor":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			color := L.CheckInt(2)
			textView.SetTextColor(tcell.Color(color))
			L.Push(ud)
			return 1
		}))
	case "GetText":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			text := textView.GetText(false)
			L.Push(lua.LString(text))
			return 1
		}))
	}
	return 1
}

func inputFieldIndex(L *lua.LState) int {
	ud := L.CheckUserData(1)
	inputField := ud.Value.(*tview.InputField)
	method := L.CheckString(2)
	
	switch method {
	case "GetText":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			text := inputField.GetText()
			L.Push(lua.LString(text))
			return 1
		}))
	case "SetText":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			text := L.CheckString(2)
			inputField.SetText(text)
			L.Push(ud)
			return 1
		}))
	case "SetLabel":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			label := L.CheckString(2)
			inputField.SetLabel(label)
			L.Push(ud)
			return 1
		}))
	case "SetPlaceholder":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			placeholder := L.CheckString(2)
			inputField.SetPlaceholder(placeholder)
			L.Push(ud)
			return 1
		}))
	case "SetDoneFunc":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			fn := L.CheckFunction(2)
			inputField.SetDoneFunc(func(key tcell.Key) {
				L.Push(fn)
				L.Push(lua.LNumber(int(key)))
				L.Call(1, 0)
			})
			L.Push(ud)
			return 1
		}))
	}
	return 1
}

func buttonIndex(L *lua.LState) int {
	ud := L.CheckUserData(1)
	button := ud.Value.(*tview.Button)
	method := L.CheckString(2)
	
	switch method {
	case "SetSelectedFunc":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			fn := L.CheckFunction(2)
			button.SetSelectedFunc(func() {
				L.Push(fn)
				L.Call(0, 0)
			})
			L.Push(ud)
			return 1
		}))
	}
	return 1
}

func flexIndex(L *lua.LState) int {
	ud := L.CheckUserData(1)
	flex := ud.Value.(*tview.Flex)
	method := L.CheckString(2)
	
	switch method {
	case "SetDirection":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			direction := L.CheckInt(2)
			flex.SetDirection(direction)
			L.Push(ud)
			return 1
		}))
	case "AddItem":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			itemUD := L.CheckUserData(2)
			fixedSize := L.CheckInt(3)
			proportion := L.CheckInt(4)
			focus := L.CheckBool(5)
			flex.AddItem(itemUD.Value.(tview.Primitive), fixedSize, proportion, focus)
			L.Push(ud)
			return 1
		}))
	}
	return 1
}

func luaNewApp(L *lua.LState) int {
	app := tview.NewApplication()
	ud := L.NewUserData()
	ud.Value = app
	L.SetMetatable(ud, L.GetTypeMetatable("App"))
	L.Push(ud)
	return 1
}

func luaNewTextView(L *lua.LState) int {
	text := L.OptString(1, "")
	textView := tview.NewTextView().SetText(text).SetDynamicColors(true).SetWrap(true)
	ud := L.NewUserData()
	ud.Value = textView
	L.SetMetatable(ud, L.GetTypeMetatable("TextView"))
	L.Push(ud)
	return 1
}

func luaNewInputField(L *lua.LState) int {
	inputField := tview.NewInputField()
	ud := L.NewUserData()
	ud.Value = inputField
	L.SetMetatable(ud, L.GetTypeMetatable("InputField"))
	L.Push(ud)
	return 1
}

func luaNewButton(L *lua.LState) int {
	label := L.OptString(1, "Button")
	button := tview.NewButton(label)
	ud := L.NewUserData()
	ud.Value = button
	L.SetMetatable(ud, L.GetTypeMetatable("Button"))
	L.Push(ud)
	return 1
}

func luaNewFlex(L *lua.LState) int {
	flex := tview.NewFlex()
	ud := L.NewUserData()
	ud.Value = flex
	L.SetMetatable(ud, L.GetTypeMetatable("Flex"))
	L.Push(ud)
	return 1
}

func registerHTTPModule(L *lua.LState) {
	L.PreloadModule("http", func(L *lua.LState) int {
		httpModule := L.NewTable()
		L.SetField(httpModule, "get", L.NewFunction(httpGet))
		L.SetField(httpModule, "newServer", L.NewFunction(httpNewServer))
		L.Push(httpModule)
		return 1
	})
	
	// Set up server metatable
	serverMT := L.NewTypeMetatable("HTTPServer")
	L.SetField(serverMT, "__index", L.NewFunction(serverIndex))
}

func httpGet(L *lua.LState) int {
	url := L.CheckString(1)
	
	// Optional options table
	var timeout time.Duration = 30 * time.Second
	var userAgent string = "LuaX/1.0"
	
	if L.GetTop() >= 2 {
		options := L.CheckTable(2)
		if timeoutVal := L.GetField(options, "timeout"); timeoutVal != lua.LNil {
			if timeoutNum, ok := timeoutVal.(lua.LNumber); ok {
				timeout = time.Duration(float64(timeoutNum)) * time.Second
			}
		}
		if headers := L.GetField(options, "headers"); headers != lua.LNil {
			if headersTable, ok := headers.(*lua.LTable); ok {
				if ua := L.GetField(headersTable, "User-Agent"); ua != lua.LNil {
					if uaStr, ok := ua.(lua.LString); ok {
						userAgent = string(uaStr)
					}
				}
			}
		}
	}
	
	client := &http.Client{Timeout: timeout}
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		L.Push(lua.LNil)
		L.Push(lua.LString(err.Error()))
		return 2
	}
	
	req.Header.Set("User-Agent", userAgent)
	
	resp, err := client.Do(req)
	if err != nil {
		L.Push(lua.LNil)
		L.Push(lua.LString(err.Error()))
		return 2
	}
	defer resp.Body.Close()
	
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		L.Push(lua.LNil)
		L.Push(lua.LString(err.Error()))
		return 2
	}
	
	result := L.NewTable()
	L.SetField(result, "status", lua.LNumber(resp.StatusCode))
	L.SetField(result, "body", lua.LString(string(body)))
	
	L.Push(result)
	L.Push(lua.LNil)
	return 2
}

type HTTPServer struct {
	server   *http.Server
	mux      *http.ServeMux
	handlers map[string]*lua.LFunction
	L        *lua.LState  // Main Lua state for registration  
	mu       sync.RWMutex
}

func httpNewServer(L *lua.LState) int {
	server := &HTTPServer{
		mux:      http.NewServeMux(),
		handlers: make(map[string]*lua.LFunction),
		L:        L,
	}
	
	ud := L.NewUserData()
	ud.Value = server
	L.SetMetatable(ud, L.GetTypeMetatable("HTTPServer"))
	L.Push(ud)
	return 1
}

func serverIndex(L *lua.LState) int {
	ud := L.CheckUserData(1)
	server := ud.Value.(*HTTPServer)
	method := L.CheckString(2)
	
	switch method {
	case "handle":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			path := L.CheckString(2)
			handler := L.CheckFunction(3)
			
			server.mu.Lock()
			server.handlers[path] = handler
			server.mu.Unlock()
			
			// Register the handler with the mux
			server.mux.HandleFunc(path, func(w http.ResponseWriter, r *http.Request) {
				server.handleRequest(w, r, path)
			})
			
			L.Push(ud)
			return 1
		}))
	case "listen":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			port := L.CheckInt(2)
			addr := fmt.Sprintf(":%d", port)
			
			server.server = &http.Server{
				Addr:         addr,
				Handler:      server.mux,
				ReadTimeout:  30 * time.Second,
				WriteTimeout: 30 * time.Second,
				IdleTimeout:  120 * time.Second,
			}
			
			// Start server in goroutine
			go func() {
				if err := server.server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
					fmt.Printf("Server error: %v\n", err)
				}
			}()
			
			return 0
		}))
	case "stop":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			if server.server != nil {
				ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
				defer cancel()
				server.server.Shutdown(ctx)
			}
			return 0
		}))
	}
	return 1
}

func (s *HTTPServer) handleRequest(w http.ResponseWriter, r *http.Request, path string) {
	s.mu.RLock()
	handler, exists := s.handlers[path]
	s.mu.RUnlock()
	
	if !exists {
		http.NotFound(w, r)
		return
	}
	
	// Use a mutex to protect the Lua state from concurrent access
	// This ensures thread-safety for the shared Lua interpreter
	s.mu.Lock()
	defer s.mu.Unlock()
	
	// Create request object for Lua
	reqObj := s.L.NewTable()
	s.L.SetField(reqObj, "method", lua.LString(r.Method))
	s.L.SetField(reqObj, "url", lua.LString(r.URL.String()))
	s.L.SetField(reqObj, "path", lua.LString(r.URL.Path))
	
	// Add headers
	headers := s.L.NewTable()
	for key, values := range r.Header {
		s.L.SetField(headers, key, lua.LString(values[0]))
	}
	s.L.SetField(reqObj, "headers", headers)
	
	// Add query parameters
	query := s.L.NewTable()
	for key, values := range r.URL.Query() {
		s.L.SetField(query, key, lua.LString(values[0]))
	}
	s.L.SetField(reqObj, "query", query)
	
	// Read body
	if r.Body != nil {
		body, _ := io.ReadAll(r.Body)
		s.L.SetField(reqObj, "body", lua.LString(string(body)))
	}
	
	// Create response object for Lua
	resObj := s.L.NewTable()
	responseData := &ResponseWriter{w: w, written: false}
	
	s.L.SetField(resObj, "write", s.L.NewFunction(func(L *lua.LState) int {
		content := L.CheckString(2) // Skip self parameter
		responseData.w.Write([]byte(content))
		responseData.written = true
		return 0
	}))
	
	s.L.SetField(resObj, "json", s.L.NewFunction(func(L *lua.LState) int {
		data := L.CheckAny(2) // Skip self parameter
		
		// Convert Lua value to Go interface
		var goData interface{}
		goData = luaValueToGo(L, data)
		
		jsonBytes, err := json.Marshal(goData)
		if err != nil {
			http.Error(responseData.w, "JSON encoding error", http.StatusInternalServerError)
			return 0
		}
		
		responseData.w.Header().Set("Content-Type", "application/json")
		responseData.w.Write(jsonBytes)
		responseData.written = true
		return 0
	}))
	
	s.L.SetField(resObj, "status", s.L.NewFunction(func(L *lua.LState) int {
		code := L.CheckInt(2) // Skip self parameter
		responseData.w.WriteHeader(code)
		return 0
	}))
	
	s.L.SetField(resObj, "header", s.L.NewFunction(func(L *lua.LState) int {
		key := L.CheckString(2) // Skip self parameter
		value := L.CheckString(3)
		responseData.w.Header().Set(key, value)
		return 0
	}))
	
	// Call the Lua handler
	s.L.Push(handler)
	s.L.Push(reqObj)
	s.L.Push(resObj)
	
	if err := s.L.PCall(2, 0, nil); err != nil {
		if !responseData.written {
			http.Error(w, "Handler error: "+err.Error(), http.StatusInternalServerError)
		}
	}
	
	// If no response was written, send empty 200
	if !responseData.written {
		w.WriteHeader(http.StatusOK)
	}
}

type ResponseWriter struct {
	w       http.ResponseWriter
	written bool
}

func luaValueToGo(L *lua.LState, value lua.LValue) interface{} {
	if value == lua.LNil {
		return nil
	}
	
	switch v := value.(type) {
	case lua.LString:
		return string(v)
	case lua.LNumber:
		return float64(v)
	case lua.LBool:
		return bool(v)
	case *lua.LTable:
		// Check if it's an array or object
		result := make(map[string]interface{})
		v.ForEach(func(key, val lua.LValue) {
			if keyStr, ok := key.(lua.LString); ok {
				result[string(keyStr)] = luaValueToGo(L, val)
			}
		})
		return result
	default:
		return value.String()
	}
}

func registerKVModule(L *lua.LState) {
	L.PreloadModule("kv", func(L *lua.LState) int {
		kvModule := L.NewTable()
		L.SetField(kvModule, "open", L.NewFunction(kvOpen))
		L.Push(kvModule)
		return 1
	})
	
	// Set up database metatable
	dbMT := L.NewTypeMetatable("KVDB")
	L.SetField(dbMT, "__index", L.NewFunction(kvIndex))
	L.SetField(dbMT, "__gc", L.NewFunction(kvGC))
	
	// Set up transaction metatable
	txnMT := L.NewTypeMetatable("KVTxn")
	L.SetField(txnMT, "__index", L.NewFunction(kvTxnIndex))
	L.SetField(txnMT, "__gc", L.NewFunction(kvTxnGC))
	
	// Set up cursor metatable
	cursorMT := L.NewTypeMetatable("KVCursor")
	L.SetField(cursorMT, "__index", L.NewFunction(kvCursorIndex))
	L.SetField(cursorMT, "__gc", L.NewFunction(kvCursorGC))
}

type KVDB struct {
	db   *bbolt.DB
	path string
}

type KVTxn struct {
	tx     *bbolt.Tx
	db     *KVDB
	bucket *bbolt.Bucket
}

type KVCursor struct {
	cursor *bbolt.Cursor
	tx     *bbolt.Tx
	db     *KVDB
}

func kvOpen(L *lua.LState) int {
	path := L.CheckString(1)
	
	// Optional options table (for compatibility)
	var readonly bool = false
	
	if L.GetTop() >= 2 {
		options := L.CheckTable(2)
		if readonlyVal := L.GetField(options, "readonly"); readonlyVal != lua.LNil {
			if readonlyBool, ok := readonlyVal.(lua.LBool); ok {
				readonly = bool(readonlyBool)
			}
		}
	}
	
	options := &bbolt.Options{
		ReadOnly: readonly,
	}
	
	db, err := bbolt.Open(path, 0644, options)
	if err != nil {
		L.Push(lua.LNil)
		L.Push(lua.LString(err.Error()))
		return 2
	}
	
	kvdb := &KVDB{
		db:   db,
		path: path,
	}
	
	ud := L.NewUserData()
	ud.Value = kvdb
	L.SetMetatable(ud, L.GetTypeMetatable("KVDB"))
	L.Push(ud)
	L.Push(lua.LNil)
	return 2
}

func kvIndex(L *lua.LState) int {
	ud := L.CheckUserData(1)
	db := ud.Value.(*KVDB)
	method := L.CheckString(2)
	
	switch method {
	case "open_db":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			bucketName := L.OptString(2, "default")
			
			// Create bucket if it doesn't exist
			err := db.db.Update(func(tx *bbolt.Tx) error {
				_, err := tx.CreateBucketIfNotExists([]byte(bucketName))
				return err
			})
			
			if err != nil {
				L.Push(lua.LString(err.Error()))
				return 1
			}
			
			L.Push(lua.LNil) // No error
			return 1
		}))
	case "begin_txn":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			readonly := L.OptBool(2, false)
			
			var tx *bbolt.Tx
			var err error
			
			if readonly {
				tx, err = db.db.Begin(false)
			} else {
				tx, err = db.db.Begin(true)
			}
			
			if err != nil {
				L.Push(lua.LNil)
				L.Push(lua.LString(err.Error()))
				return 2
			}
			
			kvTxn := &KVTxn{tx: tx, db: db}
			
			ud := L.NewUserData()
			ud.Value = kvTxn
			L.SetMetatable(ud, L.GetTypeMetatable("KVTxn"))
			L.Push(ud)
			L.Push(lua.LNil)
			return 2
		}))
	case "get":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			bucketName := L.OptString(2, "default")
			key := L.CheckString(3)
			
			var val []byte
			err := db.db.View(func(tx *bbolt.Tx) error {
				bucket := tx.Bucket([]byte(bucketName))
				if bucket == nil {
					return fmt.Errorf("bucket not found: %s", bucketName)
				}
				val = bucket.Get([]byte(key))
				return nil
			})
			
			if err != nil {
				L.Push(lua.LNil)
				L.Push(lua.LString(err.Error()))
				return 2
			}
			
			if val == nil {
				L.Push(lua.LNil)
				L.Push(lua.LNil)
				return 2
			}
			
			L.Push(lua.LString(string(val)))
			L.Push(lua.LNil)
			return 2
		}))
	case "put":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			bucketName := L.OptString(2, "default")
			key := L.CheckString(3)
			value := L.CheckString(4)
			
			err := db.db.Update(func(tx *bbolt.Tx) error {
				bucket := tx.Bucket([]byte(bucketName))
				if bucket == nil {
					return fmt.Errorf("bucket not found: %s", bucketName)
				}
				return bucket.Put([]byte(key), []byte(value))
			})
			
			if err != nil {
				L.Push(lua.LString(err.Error()))
				return 1
			}
			
			L.Push(lua.LNil)
			return 1
		}))
	case "delete":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			bucketName := L.OptString(2, "default")
			key := L.CheckString(3)
			
			err := db.db.Update(func(tx *bbolt.Tx) error {
				bucket := tx.Bucket([]byte(bucketName))
				if bucket == nil {
					return fmt.Errorf("bucket not found: %s", bucketName)
				}
				return bucket.Delete([]byte(key))
			})
			
			if err != nil {
				L.Push(lua.LString(err.Error()))
				return 1
			}
			
			L.Push(lua.LNil)
			return 1
		}))
	case "keys":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			bucketName := L.OptString(2, "default")
			prefix := L.OptString(3, "")
			
			var keys []string
			err := db.db.View(func(tx *bbolt.Tx) error {
				bucket := tx.Bucket([]byte(bucketName))
				if bucket == nil {
					return fmt.Errorf("bucket not found: %s", bucketName)
				}
				
				c := bucket.Cursor()
				if prefix != "" {
					// Prefix search
					prefixBytes := []byte(prefix)
					for k, _ := c.Seek(prefixBytes); k != nil && bytes.HasPrefix(k, prefixBytes); k, _ = c.Next() {
						keys = append(keys, string(k))
					}
				} else {
					// All keys
					for k, _ := c.First(); k != nil; k, _ = c.Next() {
						keys = append(keys, string(k))
					}
				}
				return nil
			})
			
			if err != nil {
				L.Push(lua.LNil)
				L.Push(lua.LString(err.Error()))
				return 2
			}
			
			// Create Lua table with keys
			table := L.NewTable()
			for i, key := range keys {
				table.RawSetInt(i+1, lua.LString(key))
			}
			L.Push(table)
			L.Push(lua.LNil)
			return 2
		}))
	case "foreach":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			bucketName := L.OptString(2, "default")
			callback := L.CheckFunction(3)
			
			err := db.db.View(func(tx *bbolt.Tx) error {
				bucket := tx.Bucket([]byte(bucketName))
				if bucket == nil {
					return fmt.Errorf("bucket not found: %s", bucketName)
				}
				
				c := bucket.Cursor()
				for k, v := c.First(); k != nil; k, v = c.Next() {
					L.Push(callback)
					L.Push(lua.LString(string(k)))
					L.Push(lua.LString(string(v)))
					if err := L.PCall(2, 1, nil); err != nil {
						return fmt.Errorf("callback error: %v", err)
					}
					
					// Check if callback returned false to break
					result := L.Get(-1)
					L.Pop(1)
					if result == lua.LFalse {
						break
					}
				}
				return nil
			})
			
			if err != nil {
				L.Push(lua.LString(err.Error()))
				return 1
			}
			
			L.Push(lua.LNil)
			return 1
		}))
	case "close":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			db.db.Close()
			return 0
		}))
	}
	return 1
}

func kvGC(L *lua.LState) int {
	ud := L.CheckUserData(1)
	if db, ok := ud.Value.(*KVDB); ok {
		db.db.Close()
	}
	return 0
}

func kvTxnIndex(L *lua.LState) int {
	ud := L.CheckUserData(1)
	txn := ud.Value.(*KVTxn)
	method := L.CheckString(2)
	
	switch method {
	case "get":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			bucketName := L.OptString(2, "default")
			key := L.CheckString(3)
			
			bucket := txn.tx.Bucket([]byte(bucketName))
			if bucket == nil {
				L.Push(lua.LNil)
				L.Push(lua.LString("bucket not found"))
				return 2
			}
			
			val := bucket.Get([]byte(key))
			if val == nil {
				L.Push(lua.LNil)
				L.Push(lua.LNil)
				return 2
			}
			
			L.Push(lua.LString(string(val)))
			L.Push(lua.LNil)
			return 2
		}))
	case "put":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			bucketName := L.OptString(2, "default")
			key := L.CheckString(3)
			value := L.CheckString(4)
			
			bucket := txn.tx.Bucket([]byte(bucketName))
			if bucket == nil {
				L.Push(lua.LString("bucket not found"))
				return 1
			}
			
			err := bucket.Put([]byte(key), []byte(value))
			if err != nil {
				L.Push(lua.LString(err.Error()))
				return 1
			}
			
			L.Push(lua.LNil)
			return 1
		}))
	case "delete":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			bucketName := L.OptString(2, "default")
			key := L.CheckString(3)
			
			bucket := txn.tx.Bucket([]byte(bucketName))
			if bucket == nil {
				L.Push(lua.LString("bucket not found"))
				return 1
			}
			
			err := bucket.Delete([]byte(key))
			if err != nil {
				L.Push(lua.LString(err.Error()))
				return 1
			}
			
			L.Push(lua.LNil)
			return 1
		}))
	case "commit":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			err := txn.tx.Commit()
			if err != nil {
				L.Push(lua.LString(err.Error()))
				return 1
			}
			L.Push(lua.LNil)
			return 1
		}))
	case "abort":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			txn.tx.Rollback()
			return 0
		}))
	}
	return 1
}

func kvTxnGC(L *lua.LState) int {
	ud := L.CheckUserData(1)
	if txn, ok := ud.Value.(*KVTxn); ok {
		txn.tx.Rollback()
	}
	return 0
}

func kvCursorIndex(L *lua.LState) int {
	ud := L.CheckUserData(1)
	cursor := ud.Value.(*KVCursor)
	method := L.CheckString(2)
	
	switch method {
	case "first":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			var key, value []byte
			err := cursor.db.db.View(func(tx *bbolt.Tx) error {
				c := tx.Bucket([]byte("default")).Cursor() // TODO: make bucket configurable
				key, value = c.First()
				return nil
			})
			
			if err != nil {
				L.Push(lua.LNil)
				L.Push(lua.LNil)
				L.Push(lua.LString(err.Error()))
				return 3
			}
			
			if key == nil {
				L.Push(lua.LNil)
				L.Push(lua.LNil)
				L.Push(lua.LNil)
				return 3
			}
			
			L.Push(lua.LString(string(key)))
			L.Push(lua.LString(string(value)))
			L.Push(lua.LNil)
			return 3
		}))
	case "last":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			var key, value []byte
			err := cursor.db.db.View(func(tx *bbolt.Tx) error {
				c := tx.Bucket([]byte("default")).Cursor()
				key, value = c.Last()
				return nil
			})
			
			if err != nil {
				L.Push(lua.LNil)
				L.Push(lua.LNil)
				L.Push(lua.LString(err.Error()))
				return 3
			}
			
			if key == nil {
				L.Push(lua.LNil)
				L.Push(lua.LNil)
				L.Push(lua.LNil)
				return 3
			}
			
			L.Push(lua.LString(string(key)))
			L.Push(lua.LString(string(value)))
			L.Push(lua.LNil)
			return 3
		}))
	case "seek":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			seekKey := L.CheckString(2)
			
			var key, value []byte
			err := cursor.db.db.View(func(tx *bbolt.Tx) error {
				c := tx.Bucket([]byte("default")).Cursor()
				key, value = c.Seek([]byte(seekKey))
				return nil
			})
			
			if err != nil {
				L.Push(lua.LNil)
				L.Push(lua.LNil)
				L.Push(lua.LString(err.Error()))
				return 3
			}
			
			if key == nil {
				L.Push(lua.LNil)
				L.Push(lua.LNil)
				L.Push(lua.LNil)
				return 3
			}
			
			L.Push(lua.LString(string(key)))
			L.Push(lua.LString(string(value)))
			L.Push(lua.LNil)
			return 3
		}))
	}
	return 1
}

func kvCursorGC(L *lua.LState) int {
	// Cursors are automatically cleaned up when transaction ends
	return 0
}

`

	tmpl, err := template.New("runtime").Parse(runtimeTemplate)
	if err != nil {
		return err
	}

	mainFile := filepath.Join(tempDir, "main.go")
	f, err := os.Create(mainFile)
	if err != nil {
		return err
	}
	defer f.Close()

	return tmpl.Execute(f, config)
}

func buildExecutableFromRuntime(tempDir string, config *BuildConfig) error {
	goModContent := `module luax-runtime

go 1.21

require (
	github.com/yuin/gopher-lua v1.1.1
	github.com/gdamore/tcell/v2 v2.7.0
	github.com/rivo/tview v0.0.0-20240101144852-b3bd1aa5e9f2
	go.etcd.io/bbolt v1.4.1
)
`

	goModPath := filepath.Join(tempDir, "go.mod")
	if err := os.WriteFile(goModPath, []byte(goModContent), 0644); err != nil {
		return err
	}

	// Run go mod tidy to download dependencies
	tidyCmd := exec.Command("go", "mod", "tidy")
	tidyCmd.Dir = tempDir
	if output, err := tidyCmd.CombinedOutput(); err != nil {
		return fmt.Errorf("go mod tidy failed: %w\nOutput: %s", err, output)
	}

	outputPath := config.OutputName
	if config.Target == "windows" {
		outputPath += ".exe"
	}

	cmd := exec.Command("go", "build", "-o", outputPath, ".")
	cmd.Dir = tempDir
	cmd.Env = append(os.Environ(),
		"GOOS="+config.Target,
		"GOARCH=amd64",
	)

	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("go build failed: %w\nOutput: %s", err, output)
	}

	builtExecutable := filepath.Join(tempDir, filepath.Base(outputPath))
	if _, err := os.Stat(builtExecutable); err == nil {
		return os.Rename(builtExecutable, outputPath)
	}

	return nil
}