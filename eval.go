package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/gdamore/tcell/v2"
	"github.com/gorilla/websocket"
	"github.com/rivo/tview"
	"github.com/yuin/gopher-lua"
	"go.etcd.io/bbolt"
)

func runScript(scriptPath string, scriptArgs []string) error {
	return runScriptWithPlugins(scriptPath, scriptArgs, []PluginSpec{})
}

func runScriptWithPlugins(scriptPath string, scriptArgs []string, pluginSpecs []PluginSpec) error {
	scriptContent, err := os.ReadFile(scriptPath)
	if err != nil {
		return fmt.Errorf("failed to read script file: %w", err)
	}

	// Load plugins
	registry := NewPluginRegistry()
	if len(pluginSpecs) > 0 {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
		defer cancel()
		
		if err := registry.LoadPlugins(ctx, pluginSpecs); err != nil {
			return fmt.Errorf("failed to load plugins: %w", err)
		}
		defer registry.Close()
	}

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
	setupCommandLineArgs(L, scriptPath, scriptArgs)
	
	// Register built-in modules
	registerHTTPModule(L)
	registerKVModule(L)
	registerTUIFunctions(L)
	registerCryptoModule(L)
	registerHTTPSigModule(L)
	registerWebSocketModule(L)

	// Register plugin modules
	if err := registry.RegisterAll(L); err != nil {
		return fmt.Errorf("failed to register plugins: %w", err)
	}

	if err := L.DoString(string(scriptContent)); err != nil {
		return fmt.Errorf("lua runtime error: %w", err)
	}

	return nil
}

func setupCommandLineArgs(L *lua.LState, scriptPath string, scriptArgs []string) {
	// Create arg table (following Lua convention)
	argTable := L.NewTable()
	
	// arg[0] is the script name (standard Lua convention)
	argTable.RawSetInt(0, lua.LString(scriptPath))
	
	// arg[1], arg[2], etc. are the script arguments
	for i, arg := range scriptArgs {
		argTable.RawSetInt(i+1, lua.LString(arg))
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
	
	// Event metatable
	eventMT := L.NewTypeMetatable("Event")
	L.SetField(eventMT, "__index", L.NewFunction(eventIndex))
}

// TUI Constructor Functions
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
	textView := tview.NewTextView().SetText(text)
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
	label := L.OptString(1, "")
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

// TUI Method Handlers
func appIndex(L *lua.LState) int {
	ud := L.CheckUserData(1)
	app := ud.Value.(*tview.Application)
	method := L.CheckString(2)
	
	switch method {
	case "SetRoot":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			rootUD := L.CheckUserData(2)
			fullscreen := L.OptBool(3, false)
			
			var root tview.Primitive
			switch v := rootUD.Value.(type) {
			case *tview.TextView:
				root = v
			case *tview.InputField:
				root = v
			case *tview.Button:
				root = v
			case *tview.Flex:
				root = v
			default:
				L.ArgError(2, "expected tview primitive")
				return 0
			}
			
			app.SetRoot(root, fullscreen)
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
	case "Draw":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			app.QueueUpdateDraw(func() {})
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
				L.Push(fn)
				ud := L.NewUserData()
				ud.Value = event
				L.SetMetatable(ud, L.GetTypeMetatable("Event"))
				L.Push(ud)
				L.Call(1, 1)
				result := L.Get(-1)
				L.Pop(1)
				if result == lua.LNil {
					return nil
				}
				return event
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
			return 0
		}))
	case "GetText":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			text := textView.GetText(false)
			L.Push(lua.LString(text))
			return 1
		}))
	case "SetWrap":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			wrap := L.CheckBool(2)
			textView.SetWrap(wrap)
			return 0
		}))
	case "SetWordWrap":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			wordWrap := L.CheckBool(2)
			textView.SetWordWrap(wordWrap)
			return 0
		}))
	case "SetTitle":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			title := L.CheckString(2)
			textView.SetTitle(title)
			return 0
		}))
	case "SetTextColor":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			color := L.CheckInt(2)
			textView.SetTextColor(tcell.Color(color))
			return 0
		}))
	case "SetDynamicColors":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			enable := L.CheckBool(2)
			textView.SetDynamicColors(enable)
			return 0
		}))
	case "SetBorder":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			enable := L.CheckBool(2)
			textView.SetBorder(enable)
			return 0
		}))
	case "SetBorderColor":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			color := L.CheckInt(2)
			textView.SetBorderColor(tcell.Color(color))
			return 0
		}))
	case "SetBackgroundColor":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			color := L.CheckInt(2)
			textView.SetBackgroundColor(tcell.Color(color))
			return 0
		}))
	case "SetRegions":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			enable := L.CheckBool(2)
			textView.SetRegions(enable)
			return 0
		}))
	case "SetScrollable":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			enable := L.CheckBool(2)
			textView.SetScrollable(enable)
			return 0
		}))
	}
	
	return 1
}

func inputFieldIndex(L *lua.LState) int {
	ud := L.CheckUserData(1)
	inputField := ud.Value.(*tview.InputField)
	method := L.CheckString(2)
	
	switch method {
	case "SetLabel":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			label := L.CheckString(2)
			inputField.SetLabel(label)
			return 0
		}))
	case "SetPlaceholder":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			placeholder := L.CheckString(2)
			inputField.SetPlaceholder(placeholder)
			return 0
		}))
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
			return 0
		}))
	case "SetDoneFunc":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			fn := L.CheckFunction(2)
			inputField.SetDoneFunc(func(key tcell.Key) {
				L.Push(fn)
				L.Push(lua.LNumber(int(key)))
				L.Call(1, 0)
			})
			return 0
		}))
	case "SetBorder":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			enable := L.CheckBool(2)
			inputField.SetBorder(enable)
			return 0
		}))
	case "SetBorderColor":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			color := L.CheckInt(2)
			inputField.SetBorderColor(tcell.Color(color))
			return 0
		}))
	case "SetFieldBackgroundColor":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			color := L.CheckInt(2)
			inputField.SetFieldBackgroundColor(tcell.Color(color))
			return 0
		}))
	case "SetFieldTextColor":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			color := L.CheckInt(2)
			inputField.SetFieldTextColor(tcell.Color(color))
			return 0
		}))
	case "SetTitle":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			title := L.CheckString(2)
			inputField.SetTitle(title)
			return 0
		}))
	}
	
	return 1
}

func buttonIndex(L *lua.LState) int {
	ud := L.CheckUserData(1)
	button := ud.Value.(*tview.Button)
	method := L.CheckString(2)
	
	switch method {
	case "SetLabel":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			label := L.CheckString(2)
			button.SetLabel(label)
			return 0
		}))
	case "SetSelectedFunc":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			fn := L.CheckFunction(2)
			button.SetSelectedFunc(func() {
				L.Push(fn)
				L.Call(0, 0)
			})
			return 0
		}))
	case "SetBorder":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			enable := L.CheckBool(2)
			button.SetBorder(enable)
			return 0
		}))
	case "SetBorderColor":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			color := L.CheckInt(2)
			button.SetBorderColor(tcell.Color(color))
			return 0
		}))
	case "SetBackgroundColor":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			color := L.CheckInt(2)
			button.SetBackgroundColor(tcell.Color(color))
			return 0
		}))
	case "SetLabelColor":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			color := L.CheckInt(2)
			button.SetLabelColor(tcell.Color(color))
			return 0
		}))
	case "SetTitle":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			title := L.CheckString(2)
			button.SetTitle(title)
			return 0
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
			return 0
		}))
	case "AddItem":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			itemUD := L.CheckUserData(2)
			fixedSize := L.CheckInt(3)
			proportion := L.CheckInt(4)
			focus := L.CheckBool(5)
			
			var item tview.Primitive
			switch v := itemUD.Value.(type) {
			case *tview.TextView:
				item = v
			case *tview.InputField:
				item = v
			case *tview.Button:
				item = v
			case *tview.Flex:
				item = v
			default:
				L.ArgError(2, "expected tview primitive")
				return 0
			}
			
			flex.AddItem(item, fixedSize, proportion, focus)
			return 0
		}))
	case "SetBorder":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			enable := L.CheckBool(2)
			flex.SetBorder(enable)
			return 0
		}))
	case "SetBorderColor":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			color := L.CheckInt(2)
			flex.SetBorderColor(tcell.Color(color))
			return 0
		}))
	case "SetTitle":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			title := L.CheckString(2)
			flex.SetTitle(title)
			return 0
		}))
	case "SetBackgroundColor":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			color := L.CheckInt(2)
			flex.SetBackgroundColor(tcell.Color(color))
			return 0
		}))
	}
	
	return 1
}

func eventIndex(L *lua.LState) int {
	ud := L.CheckUserData(1)
	event := ud.Value.(*tcell.EventKey)
	method := L.CheckString(2)
	
	switch method {
	case "Key":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			key := event.Key()
			L.Push(lua.LNumber(key))
			return 1
		}))
	case "Rune":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			r := event.Rune()
			L.Push(lua.LNumber(r))
			return 1
		}))
	}
	
	return 1
}

// HTTP Module
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

type HTTPServer struct {
	server *http.Server
	mux    *http.ServeMux
}

func httpGet(L *lua.LState) int {
	url := L.CheckString(1)
	
	// Create HTTP client with timeout
	client := &http.Client{
		Timeout: 30 * time.Second,
	}
	
	resp, err := client.Get(url)
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
	
	// Create response table
	responseTable := L.NewTable()
	L.SetField(responseTable, "status", lua.LNumber(resp.StatusCode))
	L.SetField(responseTable, "body", lua.LString(string(body)))
	
	// Add headers
	headersTable := L.NewTable()
	for key, values := range resp.Header {
		if len(values) > 0 {
			L.SetField(headersTable, key, lua.LString(values[0]))
		}
	}
	L.SetField(responseTable, "headers", headersTable)
	
	L.Push(responseTable)
	L.Push(lua.LNil)
	return 2
}

func httpNewServer(L *lua.LState) int {
	server := &HTTPServer{
		mux: http.NewServeMux(),
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
			pattern := L.CheckString(2)
			handlerFunc := L.CheckFunction(3)
			
			server.mux.HandleFunc(pattern, func(w http.ResponseWriter, r *http.Request) {
				// Create request table
				reqTable := L.NewTable()
				L.SetField(reqTable, "method", lua.LString(r.Method))
				L.SetField(reqTable, "url", lua.LString(r.URL.String()))
				
				// Read body
				body, _ := io.ReadAll(r.Body)
				L.SetField(reqTable, "body", lua.LString(string(body)))
				
				// Create response object
				resUD := L.NewUserData()
				resUD.Value = w
				
				// Set response metatable
				resMT := L.NewTypeMetatable("HTTPResponse")
				L.SetField(resMT, "__index", L.NewFunction(responseIndex))
				L.SetMetatable(resUD, resMT)
				
				// Call handler
				L.Push(handlerFunc)
				L.Push(reqTable)
				L.Push(resUD)
				L.Call(2, 0)
			})
			return 0
		}))
	case "listen":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			port := L.CheckInt(2)
			
			server.server = &http.Server{
				Addr:    fmt.Sprintf(":%d", port),
				Handler: server.mux,
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

func responseIndex(L *lua.LState) int {
	ud := L.CheckUserData(1)
	w := ud.Value.(http.ResponseWriter)
	method := L.CheckString(2)
	
	switch method {
	case "write":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			content := L.CheckString(2)
			w.Write([]byte(content))
			return 0
		}))
	case "header":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			key := L.CheckString(2)
			value := L.CheckString(3)
			w.Header().Set(key, value)
			return 0
		}))
	case "json":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			data := L.CheckTable(2)
			
			// Convert Lua table to Go map
			goMap := make(map[string]interface{})
			data.ForEach(func(key, value lua.LValue) {
				keyStr := key.String()
				switch v := value.(type) {
				case lua.LString:
					goMap[keyStr] = string(v)
				case lua.LNumber:
					goMap[keyStr] = float64(v)
				case lua.LBool:
					goMap[keyStr] = bool(v)
				default:
					goMap[keyStr] = v.String()
				}
			})
			
			jsonData, err := json.Marshal(goMap)
			if err != nil {
				L.Push(lua.LString(err.Error()))
				return 1
			}
			
			w.Header().Set("Content-Type", "application/json")
			w.Write(jsonData)
			return 0
		}))
	}
	
	return 1
}

// KV Database Module
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
	
	// Set up transaction metatable
	txnMT := L.NewTypeMetatable("KVTxn")
	L.SetField(txnMT, "__index", L.NewFunction(kvTxnIndex))
	
	// Set up cursor metatable
	cursorMT := L.NewTypeMetatable("KVCursor")
	L.SetField(cursorMT, "__index", L.NewFunction(kvCursorIndex))
}

type KVDB struct {
	db *bbolt.DB
}

type KVTxn struct {
	txn *bbolt.Tx
}

type KVCursor struct {
	cursor *bbolt.Cursor
	bucket string
}

func kvOpen(L *lua.LState) int {
	path := L.CheckString(1)
	
	db, err := bbolt.Open(path, 0600, nil)
	if err != nil {
		L.Push(lua.LNil)
		L.Push(lua.LString(err.Error()))
		return 2
	}
	
	kvdb := &KVDB{db: db}
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
			bucketName := L.CheckString(2)
			
			err := db.db.Update(func(tx *bbolt.Tx) error {
				_, err := tx.CreateBucketIfNotExists([]byte(bucketName))
				return err
			})
			
			if err != nil {
				L.Push(lua.LString(err.Error()))
				return 1
			}
			return 0
		}))
	case "put":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			bucketName := L.CheckString(2)
			key := L.CheckString(3)
			value := L.CheckString(4)
			
			err := db.db.Update(func(tx *bbolt.Tx) error {
				bucket := tx.Bucket([]byte(bucketName))
				if bucket == nil {
					return fmt.Errorf("bucket %s does not exist", bucketName)
				}
				return bucket.Put([]byte(key), []byte(value))
			})
			
			if err != nil {
				L.Push(lua.LString(err.Error()))
				return 1
			}
			return 0
		}))
	case "get":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			bucketName := L.CheckString(2)
			key := L.CheckString(3)
			
			var value []byte
			err := db.db.View(func(tx *bbolt.Tx) error {
				bucket := tx.Bucket([]byte(bucketName))
				if bucket == nil {
					return fmt.Errorf("bucket %s does not exist", bucketName)
				}
				value = bucket.Get([]byte(key))
				return nil
			})
			
			if err != nil {
				L.Push(lua.LNil)
				L.Push(lua.LString(err.Error()))
				return 2
			}
			
			if value == nil {
				L.Push(lua.LNil)
				L.Push(lua.LNil)
			} else {
				L.Push(lua.LString(string(value)))
				L.Push(lua.LNil)
			}
			return 2
		}))
	case "delete":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			bucketName := L.CheckString(2)
			key := L.CheckString(3)
			
			err := db.db.Update(func(tx *bbolt.Tx) error {
				bucket := tx.Bucket([]byte(bucketName))
				if bucket == nil {
					return fmt.Errorf("bucket %s does not exist", bucketName)
				}
				return bucket.Delete([]byte(key))
			})
			
			if err != nil {
				L.Push(lua.LString(err.Error()))
				return 1
			}
			return 0
		}))
	case "begin_txn":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			writable := !L.OptBool(2, false)
			
			tx, err := db.db.Begin(writable)
			if err != nil {
				L.Push(lua.LNil)
				L.Push(lua.LString(err.Error()))
				return 2
			}
			
			kvtxn := &KVTxn{txn: tx}
			ud := L.NewUserData()
			ud.Value = kvtxn
			L.SetMetatable(ud, L.GetTypeMetatable("KVTxn"))
			L.Push(ud)
			L.Push(lua.LNil)
			return 2
		}))
	case "keys":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			bucketName := L.CheckString(2)
			prefix := L.OptString(3, "")
			
			var keys []string
			err := db.db.View(func(tx *bbolt.Tx) error {
				bucket := tx.Bucket([]byte(bucketName))
				if bucket == nil {
					return fmt.Errorf("bucket %s does not exist", bucketName)
				}
				
				cursor := bucket.Cursor()
				for k, _ := cursor.First(); k != nil; k, _ = cursor.Next() {
					keyStr := string(k)
					if prefix == "" || strings.HasPrefix(keyStr, prefix) {
						keys = append(keys, keyStr)
					}
				}
				return nil
			})
			
			if err != nil {
				L.Push(lua.LNil)
				L.Push(lua.LString(err.Error()))
				return 2
			}
			
			// Convert to Lua table
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
			bucketName := L.CheckString(2)
			callback := L.CheckFunction(3)
			
			err := db.db.View(func(tx *bbolt.Tx) error {
				bucket := tx.Bucket([]byte(bucketName))
				if bucket == nil {
					return fmt.Errorf("bucket %s does not exist", bucketName)
				}
				
				cursor := bucket.Cursor()
				for k, v := cursor.First(); k != nil; k, v = cursor.Next() {
					L.Push(callback)
					L.Push(lua.LString(string(k)))
					L.Push(lua.LString(string(v)))
					L.Call(2, 1)
					
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
			return 0
		}))
	case "close":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			if db.db != nil {
				db.db.Close()
				db.db = nil
			}
			return 0
		}))
	}
	
	return 1
}

func kvTxnIndex(L *lua.LState) int {
	ud := L.CheckUserData(1)
	txn := ud.Value.(*KVTxn)
	method := L.CheckString(2)
	
	switch method {
	case "put":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			bucketName := L.CheckString(2)
			key := L.CheckString(3)
			value := L.CheckString(4)
			
			bucket := txn.txn.Bucket([]byte(bucketName))
			if bucket == nil {
				L.Push(lua.LString(fmt.Sprintf("bucket %s does not exist", bucketName)))
				return 1
			}
			
			err := bucket.Put([]byte(key), []byte(value))
			if err != nil {
				L.Push(lua.LString(err.Error()))
				return 1
			}
			return 0
		}))
	case "get":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			bucketName := L.CheckString(2)
			key := L.CheckString(3)
			
			bucket := txn.txn.Bucket([]byte(bucketName))
			if bucket == nil {
				L.Push(lua.LNil)
				L.Push(lua.LString(fmt.Sprintf("bucket %s does not exist", bucketName)))
				return 2
			}
			
			value := bucket.Get([]byte(key))
			if value == nil {
				L.Push(lua.LNil)
				L.Push(lua.LNil)
			} else {
				L.Push(lua.LString(string(value)))
				L.Push(lua.LNil)
			}
			return 2
		}))
	case "delete":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			bucketName := L.CheckString(2)
			key := L.CheckString(3)
			
			bucket := txn.txn.Bucket([]byte(bucketName))
			if bucket == nil {
				L.Push(lua.LString(fmt.Sprintf("bucket %s does not exist", bucketName)))
				return 1
			}
			
			err := bucket.Delete([]byte(key))
			if err != nil {
				L.Push(lua.LString(err.Error()))
				return 1
			}
			return 0
		}))
	case "commit":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			err := txn.txn.Commit()
			if err != nil {
				L.Push(lua.LString(err.Error()))
				return 1
			}
			return 0
		}))
	case "abort":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			err := txn.txn.Rollback()
			if err != nil {
				L.Push(lua.LString(err.Error()))
				return 1
			}
			return 0
		}))
	}
	
	return 1
}

func kvCursorIndex(L *lua.LState) int {
	ud := L.CheckUserData(1)
	cursor := ud.Value.(*KVCursor)
	method := L.CheckString(2)
	
	switch method {
	case "first":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			k, v := cursor.cursor.First()
			if k == nil {
				L.Push(lua.LNil)
				L.Push(lua.LNil)
			} else {
				L.Push(lua.LString(string(k)))
				L.Push(lua.LString(string(v)))
			}
			return 2
		}))
	case "last":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			k, v := cursor.cursor.Last()
			if k == nil {
				L.Push(lua.LNil)
				L.Push(lua.LNil)
			} else {
				L.Push(lua.LString(string(k)))
				L.Push(lua.LString(string(v)))
			}
			return 2
		}))
	case "seek":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			seek := L.CheckString(2)
			k, v := cursor.cursor.Seek([]byte(seek))
			if k == nil {
				L.Push(lua.LNil)
				L.Push(lua.LNil)
			} else {
				L.Push(lua.LString(string(k)))
				L.Push(lua.LString(string(v)))
			}
			return 2
		}))
	}
	
	return 1
}

// WebSocket Module
func registerWebSocketModule(L *lua.LState) {
	L.PreloadModule("websocket", func(L *lua.LState) int {
		wsModule := L.NewTable()
		L.SetField(wsModule, "newServer", L.NewFunction(wsNewServer))
		L.SetField(wsModule, "connect", L.NewFunction(wsConnect))
		L.Push(wsModule)
		return 1
	})
	
	// Set up WebSocket server metatable
	serverMT := L.NewTypeMetatable("WSServer")
	L.SetField(serverMT, "__index", L.NewFunction(wsServerIndex))
	
	// Set up WebSocket connection metatable
	connMT := L.NewTypeMetatable("WSConnection")
	L.SetField(connMT, "__index", L.NewFunction(wsConnectionIndex))
}

type WSServer struct {
	server   *http.Server
	mux      *http.ServeMux
	upgrader websocket.Upgrader
}

type WSConnection struct {
	conn          *websocket.Conn
	messageHandler *lua.LFunction
	closeHandler   *lua.LFunction
	errorHandler   *lua.LFunction
	mutex         sync.RWMutex
	L             *lua.LState
}

func wsNewServer(L *lua.LState) int {
	server := &WSServer{
		mux: http.NewServeMux(),
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				return true // Allow connections from any origin
			},
		},
	}
	
	ud := L.NewUserData()
	ud.Value = server
	L.SetMetatable(ud, L.GetTypeMetatable("WSServer"))
	L.Push(ud)
	return 1
}

func wsConnect(L *lua.LState) int {
	urlStr := L.CheckString(1)
	
	// Parse URL
	u, err := url.Parse(urlStr)
	if err != nil {
		L.Push(lua.LNil)
		L.Push(lua.LString("Invalid URL: " + err.Error()))
		return 2
	}
	
	// Connect to WebSocket
	conn, _, err := websocket.DefaultDialer.Dial(u.String(), nil)
	if err != nil {
		L.Push(lua.LNil)
		L.Push(lua.LString("Connection failed: " + err.Error()))
		return 2
	}
	
	wsConn := &WSConnection{
		conn: conn,
		L:    L,
	}
	
	ud := L.NewUserData()
	ud.Value = wsConn
	L.SetMetatable(ud, L.GetTypeMetatable("WSConnection"))
	
	// Start reading messages
	go wsConn.readMessages()
	
	L.Push(ud)
	L.Push(lua.LNil)
	return 2
}

func wsServerIndex(L *lua.LState) int {
	ud := L.CheckUserData(1)
	server := ud.Value.(*WSServer)
	method := L.CheckString(2)
	
	switch method {
	case "handle":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			pattern := L.CheckString(2)
			handlerFunc := L.CheckFunction(3)
			
			server.mux.HandleFunc(pattern, func(w http.ResponseWriter, r *http.Request) {
				conn, err := server.upgrader.Upgrade(w, r, nil)
				if err != nil {
					log.Printf("WebSocket upgrade failed: %v", err)
					return
				}
				
				wsConn := &WSConnection{
					conn: conn,
					L:    L,
				}
				
				connUD := L.NewUserData()
				connUD.Value = wsConn
				L.SetMetatable(connUD, L.GetTypeMetatable("WSConnection"))
				
				// Start reading messages
				go wsConn.readMessages()
				
				// Call the handler with the connection
				if err := L.CallByParam(lua.P{
					Fn:      handlerFunc,
					NRet:    0,
					Protect: true,
				}, connUD); err != nil {
					log.Printf("WebSocket handler error: %v", err)
				}
			})
			
			return 0
		}))
	case "listen":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			port := L.CheckInt(2)
			
			server.server = &http.Server{
				Addr:    fmt.Sprintf(":%d", port),
				Handler: server.mux,
			}
			
			// Start server in goroutine
			go func() {
				if err := server.server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
					log.Printf("WebSocket server error: %v", err)
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

func wsConnectionIndex(L *lua.LState) int {
	ud := L.CheckUserData(1)
	conn := ud.Value.(*WSConnection)
	method := L.CheckString(2)
	
	switch method {
	case "send":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			message := L.CheckString(2)
			
			conn.mutex.Lock()
			err := conn.conn.WriteMessage(websocket.TextMessage, []byte(message))
			conn.mutex.Unlock()
			
			if err != nil {
				L.Push(lua.LFalse)
				L.Push(lua.LString("Send failed: " + err.Error()))
				return 2
			}
			
			L.Push(lua.LTrue)
			L.Push(lua.LNil)
			return 2
		}))
	case "sendBinary":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			message := L.CheckString(2)
			
			conn.mutex.Lock()
			err := conn.conn.WriteMessage(websocket.BinaryMessage, []byte(message))
			conn.mutex.Unlock()
			
			if err != nil {
				L.Push(lua.LFalse)
				L.Push(lua.LString("Send failed: " + err.Error()))
				return 2
			}
			
			L.Push(lua.LTrue)
			L.Push(lua.LNil)
			return 2
		}))
	case "onMessage":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			handler := L.CheckFunction(2)
			conn.mutex.Lock()
			conn.messageHandler = handler
			conn.mutex.Unlock()
			return 0
		}))
	case "onClose":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			handler := L.CheckFunction(2)
			conn.mutex.Lock()
			conn.closeHandler = handler
			conn.mutex.Unlock()
			return 0
		}))
	case "onError":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			handler := L.CheckFunction(2)
			conn.mutex.Lock()
			conn.errorHandler = handler
			conn.mutex.Unlock()
			return 0
		}))
	case "close":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			conn.mutex.Lock()
			err := conn.conn.Close()
			conn.mutex.Unlock()
			
			if err != nil {
				L.Push(lua.LFalse)
				L.Push(lua.LString("Close failed: " + err.Error()))
				return 2
			}
			
			L.Push(lua.LTrue)
			L.Push(lua.LNil)
			return 2
		}))
	case "ping":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			conn.mutex.Lock()
			err := conn.conn.WriteMessage(websocket.PingMessage, nil)
			conn.mutex.Unlock()
			
			if err != nil {
				L.Push(lua.LFalse)
				L.Push(lua.LString("Ping failed: " + err.Error()))
				return 2
			}
			
			L.Push(lua.LTrue)
			L.Push(lua.LNil)
			return 2
		}))
	}
	
	return 1
}

func (wsConn *WSConnection) readMessages() {
	defer func() {
		if wsConn.closeHandler != nil {
			wsConn.mutex.RLock()
			handler := wsConn.closeHandler
			wsConn.mutex.RUnlock()
			
			if handler != nil {
				if err := wsConn.L.CallByParam(lua.P{
					Fn:      handler,
					NRet:    0,
					Protect: true,
				}); err != nil {
					log.Printf("WebSocket close handler error: %v", err)
				}
			}
		}
		wsConn.conn.Close()
	}()
	
	for {
		messageType, message, err := wsConn.conn.ReadMessage()
		if err != nil {
			if wsConn.errorHandler != nil {
				wsConn.mutex.RLock()
				handler := wsConn.errorHandler
				wsConn.mutex.RUnlock()
				
				if handler != nil {
					if err := wsConn.L.CallByParam(lua.P{
						Fn:      handler,
						NRet:    0,
						Protect: true,
					}, lua.LString(err.Error())); err != nil {
						log.Printf("WebSocket error handler error: %v", err)
					}
				}
			}
			break
		}
		
		if messageType == websocket.TextMessage || messageType == websocket.BinaryMessage {
			if wsConn.messageHandler != nil {
				wsConn.mutex.RLock()
				handler := wsConn.messageHandler
				wsConn.mutex.RUnlock()
				
				if handler != nil {
					messageTable := wsConn.L.NewTable()
					wsConn.L.SetField(messageTable, "data", lua.LString(string(message)))
					wsConn.L.SetField(messageTable, "type", lua.LString(func() string {
						if messageType == websocket.TextMessage {
							return "text"
						}
						return "binary"
					}()))
					
					if err := wsConn.L.CallByParam(lua.P{
						Fn:      handler,
						NRet:    0,
						Protect: true,
					}, messageTable); err != nil {
						log.Printf("WebSocket message handler error: %v", err)
					}
				}
			}
		}
	}
}

