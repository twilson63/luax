package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/yuin/gopher-lua"
)

// HTTPServer represents an HTTP server instance
type HTTPServer struct {
	server   *http.Server
	mux      *http.ServeMux
	handlers map[string]*lua.LFunction
	L        *lua.LState
	mu       sync.RWMutex
}

// ResponseWriter wraps http.ResponseWriter to track if headers were written
type ResponseWriter struct {
	w              http.ResponseWriter
	written        bool
	statusCode     int
	headersWritten bool
}

func (rw *ResponseWriter) Write(data []byte) (int, error) {
	if !rw.headersWritten {
		rw.w.WriteHeader(http.StatusOK)
		rw.headersWritten = true
	}
	rw.written = true
	return rw.w.Write(data)
}

func (rw *ResponseWriter) WriteHeader(code int) {
	if !rw.headersWritten {
		rw.statusCode = code
		rw.w.WriteHeader(code)
		rw.headersWritten = true
	}
}

// RegisterHTTPModule registers the HTTP module with all its functions
func RegisterHTTPModule(L *lua.LState) {
	L.PreloadModule("http", func(L *lua.LState) int {
		httpModule := L.NewTable()
		
		// Client methods
		L.SetField(httpModule, "get", L.NewFunction(httpGet))
		L.SetField(httpModule, "post", L.NewFunction(httpPost))
		L.SetField(httpModule, "put", L.NewFunction(httpPut))
		L.SetField(httpModule, "delete", L.NewFunction(httpDelete))
		L.SetField(httpModule, "head", L.NewFunction(httpHead))
		L.SetField(httpModule, "patch", L.NewFunction(httpPatch))
		L.SetField(httpModule, "request", L.NewFunction(httpRequest))
		
		// Server methods
		L.SetField(httpModule, "newServer", L.NewFunction(httpNewServer))
		
		L.Push(httpModule)
		return 1
	})
	
	// Set up server metatable
	serverMT := L.NewTypeMetatable("HTTPServer")
	L.SetField(serverMT, "__index", L.NewFunction(serverIndex))
}

// httpRequest is the generic HTTP request function
func httpRequest(L *lua.LState) int {
	method := L.CheckString(1)
	url := L.CheckString(2)
	
	var body io.Reader
	var contentType string
	headers := make(map[string]string)
	timeout := 30 * time.Second
	
	// Parse options (3rd parameter)
	if L.GetTop() >= 3 && L.Get(3) != lua.LNil {
		switch v := L.Get(3).(type) {
		case lua.LString:
			// If 3rd param is string, it's the body
			body = strings.NewReader(string(v))
		case *lua.LTable:
			// If 3rd param is table, it could be body (for JSON) or options
			if jsonBody := L.GetField(v, "_json"); jsonBody != lua.LNil {
				// Special case: table should be converted to JSON
				jsonBytes, err := tableToJSON(L, v)
				if err != nil {
					L.Push(lua.LNil)
					L.Push(lua.LString(fmt.Sprintf("failed to encode JSON: %v", err)))
					return 2
				}
				body = bytes.NewReader(jsonBytes)
				contentType = "application/json"
			}
		}
	}
	
	// Parse options (4th parameter or 3rd if body was string)
	optionsIndex := 4
	if body != nil && L.GetTop() >= 3 {
		optionsIndex = 4
	} else if body == nil && L.GetTop() >= 3 {
		optionsIndex = 3
	}
	
	if L.GetTop() >= optionsIndex {
		if options, ok := L.Get(optionsIndex).(*lua.LTable); ok {
			// Parse timeout
			if timeoutVal := L.GetField(options, "timeout"); timeoutVal != lua.LNil {
				if timeoutNum, ok := timeoutVal.(lua.LNumber); ok {
					timeout = time.Duration(float64(timeoutNum)) * time.Second
				}
			}
			
			// Parse headers
			if headersVal := L.GetField(options, "headers"); headersVal != lua.LNil {
				if headersTable, ok := headersVal.(*lua.LTable); ok {
					headersTable.ForEach(func(k, v lua.LValue) {
						if key, ok := k.(lua.LString); ok {
							if value, ok := v.(lua.LString); ok {
								headers[string(key)] = string(value)
							}
						}
					})
				}
			}
			
			// Parse body if not already set
			if body == nil {
				if bodyVal := L.GetField(options, "body"); bodyVal != lua.LNil {
					if bodyStr, ok := bodyVal.(lua.LString); ok {
						body = strings.NewReader(string(bodyStr))
					}
				}
			}
		}
	}
	
	// Create HTTP client
	client := &http.Client{
		Timeout: timeout,
	}
	
	// Create request
	req, err := http.NewRequest(method, url, body)
	if err != nil {
		L.Push(lua.LNil)
		L.Push(lua.LString(err.Error()))
		return 2
	}
	
	// Set headers
	for key, value := range headers {
		req.Header.Set(key, value)
	}
	
	// Set Content-Type if we have one
	if contentType != "" && req.Header.Get("Content-Type") == "" {
		req.Header.Set("Content-Type", contentType)
	}
	
	// Set default User-Agent if not provided
	if req.Header.Get("User-Agent") == "" {
		req.Header.Set("User-Agent", "Hype/1.0")
	}
	
	// Make request
	resp, err := client.Do(req)
	if err != nil {
		L.Push(lua.LNil)
		L.Push(lua.LString(err.Error()))
		return 2
	}
	defer resp.Body.Close()
	
	// Read response body
	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		L.Push(lua.LNil)
		L.Push(lua.LString(fmt.Sprintf("failed to read response: %v", err)))
		return 2
	}
	
	// Create response table
	responseTable := L.NewTable()
	L.SetField(responseTable, "status", lua.LNumber(resp.StatusCode))
	L.SetField(responseTable, "status_code", lua.LNumber(resp.StatusCode))
	L.SetField(responseTable, "body", lua.LString(string(respBody)))
	
	// Add headers
	headersTable := L.NewTable()
	for key, values := range resp.Header {
		if len(values) == 1 {
			L.SetField(headersTable, key, lua.LString(values[0]))
		} else if len(values) > 1 {
			// Multiple values - create array
			valuesTable := L.NewTable()
			for i, v := range values {
				valuesTable.RawSetInt(i+1, lua.LString(v))
			}
			L.SetField(headersTable, key, valuesTable)
		}
	}
	L.SetField(responseTable, "headers", headersTable)
	
	// Add JSON decode helper
	L.SetField(responseTable, "json", L.NewFunction(func(L *lua.LState) int {
		// Try to parse body as JSON
		var result interface{}
		if err := json.Unmarshal(respBody, &result); err != nil {
			L.Push(lua.LNil)
			L.Push(lua.LString(fmt.Sprintf("invalid JSON: %v", err)))
			return 2
		}
		
		// Convert to Lua value
		luaValue := goToLua(L, result)
		L.Push(luaValue)
		return 1
	}))
	
	L.Push(responseTable)
	L.Push(lua.LNil)
	return 2
}

// Convenience methods for common HTTP verbs
func httpGet(L *lua.LState) int {
	// Prepare arguments for httpRequest: method, url, options
	args := []lua.LValue{lua.LString("GET"), L.Get(1)}
	if L.GetTop() >= 2 {
		args = append(args, L.Get(2)) // options
	}
	// Clear stack and push new args
	L.SetTop(0)
	for _, arg := range args {
		L.Push(arg)
	}
	return httpRequest(L)
}

func httpPost(L *lua.LState) int {
	// Prepare arguments for httpRequest: method, url, body, options
	args := []lua.LValue{lua.LString("POST"), L.Get(1)}
	if L.GetTop() >= 2 {
		args = append(args, L.Get(2)) // body
	}
	if L.GetTop() >= 3 {
		args = append(args, L.Get(3)) // options
	}
	// Clear stack and push new args
	L.SetTop(0)
	for _, arg := range args {
		L.Push(arg)
	}
	return httpRequest(L)
}

func httpPut(L *lua.LState) int {
	// Prepare arguments for httpRequest: method, url, body, options
	args := []lua.LValue{lua.LString("PUT"), L.Get(1)}
	if L.GetTop() >= 2 {
		args = append(args, L.Get(2)) // body
	}
	if L.GetTop() >= 3 {
		args = append(args, L.Get(3)) // options
	}
	// Clear stack and push new args
	L.SetTop(0)
	for _, arg := range args {
		L.Push(arg)
	}
	return httpRequest(L)
}

func httpDelete(L *lua.LState) int {
	// Prepare arguments for httpRequest: method, url, options
	args := []lua.LValue{lua.LString("DELETE"), L.Get(1)}
	if L.GetTop() >= 2 {
		args = append(args, L.Get(2)) // options
	}
	// Clear stack and push new args
	L.SetTop(0)
	for _, arg := range args {
		L.Push(arg)
	}
	return httpRequest(L)
}

func httpHead(L *lua.LState) int {
	// Prepare arguments for httpRequest: method, url, options
	args := []lua.LValue{lua.LString("HEAD"), L.Get(1)}
	if L.GetTop() >= 2 {
		args = append(args, L.Get(2)) // options
	}
	// Clear stack and push new args
	L.SetTop(0)
	for _, arg := range args {
		L.Push(arg)
	}
	return httpRequest(L)
}

func httpPatch(L *lua.LState) int {
	// Prepare arguments for httpRequest: method, url, body, options
	args := []lua.LValue{lua.LString("PATCH"), L.Get(1)}
	if L.GetTop() >= 2 {
		args = append(args, L.Get(2)) // body
	}
	if L.GetTop() >= 3 {
		args = append(args, L.Get(3)) // options
	}
	// Clear stack and push new args
	L.SetTop(0)
	for _, arg := range args {
		L.Push(arg)
	}
	return httpRequest(L)
}

// HTTP Server implementation
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
			pattern := L.CheckString(2)
			handler := L.CheckFunction(3)
			
			server.mu.Lock()
			server.handlers[pattern] = handler
			server.mu.Unlock()
			
			// Support method-specific patterns like "GET /users"
			var httpMethod, path string
			parts := strings.SplitN(pattern, " ", 2)
			if len(parts) == 2 {
				httpMethod = parts[0]
				path = parts[1]
			} else {
				httpMethod = ""
				path = pattern
			}
			
			server.mux.HandleFunc(path, func(w http.ResponseWriter, r *http.Request) {
				// Check method if specified
				if httpMethod != "" && r.Method != httpMethod {
					w.WriteHeader(http.StatusMethodNotAllowed)
					return
				}
				server.handleRequest(w, r, pattern)
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

func (s *HTTPServer) handleRequest(w http.ResponseWriter, r *http.Request, pattern string) {
	s.mu.RLock()
	handler, exists := s.handlers[pattern]
	s.mu.RUnlock()
	
	if !exists {
		http.NotFound(w, r)
		return
	}
	
	// Create a new coroutine for this request to avoid state conflicts
	co, _ := s.L.NewThread()
	
	// Create request object
	reqTable := co.NewTable()
	co.SetField(reqTable, "method", lua.LString(r.Method))
	co.SetField(reqTable, "url", lua.LString(r.URL.String()))
	co.SetField(reqTable, "path", lua.LString(r.URL.Path))
	
	// Add headers
	headersTable := co.NewTable()
	for key, values := range r.Header {
		if len(values) == 1 {
			co.SetField(headersTable, key, lua.LString(values[0]))
		} else {
			valuesTable := co.NewTable()
			for i, v := range values {
				valuesTable.RawSetInt(i+1, lua.LString(v))
			}
			co.SetField(headersTable, key, valuesTable)
		}
	}
	co.SetField(reqTable, "headers", headersTable)
	
	// Add query parameters
	queryTable := co.NewTable()
	for key, values := range r.URL.Query() {
		if len(values) == 1 {
			co.SetField(queryTable, key, lua.LString(values[0]))
		} else {
			valuesTable := co.NewTable()
			for i, v := range values {
				valuesTable.RawSetInt(i+1, lua.LString(v))
			}
			co.SetField(queryTable, key, valuesTable)
		}
	}
	co.SetField(reqTable, "query", queryTable)
	
	// Add URL parameters (if any)
	paramsTable := co.NewTable()
	co.SetField(reqTable, "params", paramsTable)
	
	// Read body
	if r.Body != nil {
		bodyBytes, _ := io.ReadAll(r.Body)
		co.SetField(reqTable, "body", lua.LString(string(bodyBytes)))
		
		// Add JSON parse helper
		co.SetField(reqTable, "json", co.NewFunction(func(L *lua.LState) int {
			var result interface{}
			if err := json.Unmarshal(bodyBytes, &result); err != nil {
				L.Push(lua.LNil)
				L.Push(lua.LString(fmt.Sprintf("invalid JSON: %v", err)))
				return 2
			}
			luaValue := goToLua(L, result)
			L.Push(luaValue)
			return 1
		}))
	}
	
	// Create response wrapper
	rw := &ResponseWriter{
		w:          w,
		written:    false,
		statusCode: http.StatusOK,
	}
	
	// Create response object
	resTable := co.NewTable()
	
	// write method
	co.SetField(resTable, "write", co.NewFunction(func(L *lua.LState) int {
		content := L.CheckString(2)
		rw.Write([]byte(content))
		L.Push(L.Get(1)) // Return self for chaining
		return 1
	}))
	
	// json method
	co.SetField(resTable, "json", co.NewFunction(func(L *lua.LState) int {
		data := L.Get(2)
		
		jsonBytes, err := luaToJSON(L, data)
		if err != nil {
			http.Error(rw.w, fmt.Sprintf("JSON encoding error: %v", err), http.StatusInternalServerError)
			return 0
		}
		
		rw.w.Header().Set("Content-Type", "application/json")
		rw.Write(jsonBytes)
		L.Push(L.Get(1)) // Return self for chaining
		return 1
	}))
	
	// header method
	co.SetField(resTable, "header", co.NewFunction(func(L *lua.LState) int {
		key := L.CheckString(2)
		value := L.CheckString(3)
		rw.w.Header().Set(key, value)
		L.Push(L.Get(1)) // Return self for chaining
		return 1
	}))
	
	// status method
	co.SetField(resTable, "status", co.NewFunction(func(L *lua.LState) int {
		code := L.CheckInt(2)
		rw.WriteHeader(code)
		L.Push(L.Get(1)) // Return self for chaining
		return 1
	}))
	
	// redirect method
	co.SetField(resTable, "redirect", co.NewFunction(func(L *lua.LState) int {
		url := L.CheckString(2)
		code := L.OptInt(3, http.StatusFound)
		http.Redirect(rw.w, r, url, code)
		return 0
	}))
	
	// Call the handler
	co.Push(handler)
	co.Push(reqTable)
	co.Push(resTable)
	
	if err := co.PCall(2, 0, nil); err != nil {
		if !rw.written {
			http.Error(w, fmt.Sprintf("Handler error: %v", err), http.StatusInternalServerError)
		}
	}
}

// Helper functions for JSON conversion
func tableToJSON(L *lua.LState, table *lua.LTable) ([]byte, error) {
	result := luaTableToGo(L, table)
	return json.Marshal(result)
}

func luaTableToGo(L *lua.LState, table *lua.LTable) interface{} {
	// Check if it's an array
	maxn := table.MaxN()
	if maxn > 0 {
		// It's an array
		arr := make([]interface{}, maxn)
		for i := 1; i <= maxn; i++ {
			val := table.RawGetInt(i)
			arr[i-1] = luaValueToGo(L, val)
		}
		
		// Check if there are non-numeric keys
		hasNonNumeric := false
		table.ForEach(func(k, v lua.LValue) {
			if _, ok := k.(lua.LNumber); !ok {
				hasNonNumeric = true
			}
		})
		
		if !hasNonNumeric {
			return arr
		}
	}
	
	// It's a map
	m := make(map[string]interface{})
	table.ForEach(func(k, v lua.LValue) {
		key := k.String()
		m[key] = luaValueToGo(L, v)
	})
	return m
}

func luaValueToGo(L *lua.LState, value lua.LValue) interface{} {
	switch v := value.(type) {
	case lua.LString:
		return string(v)
	case lua.LNumber:
		return float64(v)
	case lua.LBool:
		return bool(v)
	case *lua.LTable:
		return luaTableToGo(L, v)
	case *lua.LNilType:
		return nil
	default:
		return v.String()
	}
}

func goToLua(L *lua.LState, value interface{}) lua.LValue {
	switch v := value.(type) {
	case nil:
		return lua.LNil
	case bool:
		return lua.LBool(v)
	case float64:
		return lua.LNumber(v)
	case string:
		return lua.LString(v)
	case []interface{}:
		table := L.NewTable()
		for i, item := range v {
			table.RawSetInt(i+1, goToLua(L, item))
		}
		return table
	case map[string]interface{}:
		table := L.NewTable()
		for key, val := range v {
			L.SetField(table, key, goToLua(L, val))
		}
		return table
	default:
		return lua.LString(fmt.Sprintf("%v", v))
	}
}

func luaToJSON(L *lua.LState, value lua.LValue) ([]byte, error) {
	goValue := luaValueToGo(L, value)
	return json.Marshal(goValue)
}