-- LuaX Web Server Example
local http = require('http')

-- Create TUI for server monitoring
local app = tui.newApp()
local logView = tui.newTextView("LuaX Web Server Starting...\n")
local statusBar = tui.newTextView("Server: Starting...")

-- Set up TUI layout
local flex = tui.newFlex()
flex:SetDirection(0) -- Vertical
flex:AddItem(logView, 0, 1, false)    -- Main log area
flex:AddItem(statusBar, 1, 0, false)  -- Status bar

logView:SetWrap(true)
logView:SetWordWrap(true)
statusBar:SetTextColor(0x00ff00) -- Green

-- Logging function
local function log(message)
    local timestamp = os.date("%H:%M:%S")
    local logMessage = string.format("[%s] %s\n", timestamp, message)
    
    -- Get current text and append
    local currentText = ""
    if logView.GetText then
        currentText = logView:GetText()
    end
    logView:SetText(currentText .. logMessage)
end

-- Create HTTP server
local server = http.newServer()

-- Home page
server:handle("/", function(req, res)
    log("GET / from " .. (req.headers["User-Agent"] or "unknown"))
    
    local html = [[
<!DOCTYPE html>
<html>
<head>
    <title>LuaX Web Server</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .endpoint { background: #f5f5f5; padding: 10px; margin: 10px 0; border-radius: 5px; }
        pre { background: #e8e8e8; padding: 10px; border-radius: 3px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 LuaX Web Server</h1>
        <p>This web server is running inside a Lua script packaged with LuaX!</p>
        
        <h2>Available Endpoints:</h2>
        
        <div class="endpoint">
            <h3>GET /api/hello</h3>
            <p>Returns a simple JSON greeting</p>
        </div>
        
        <div class="endpoint">
            <h3>GET /api/time</h3>
            <p>Returns current server time</p>
        </div>
        
        <div class="endpoint">
            <h3>GET /api/info</h3>
            <p>Returns server information</p>
        </div>
        
        <div class="endpoint">
            <h3>GET /api/echo?message=hello</h3>
            <p>Echoes back query parameters</p>
        </div>
        
        <h2>Try it:</h2>
        <pre>curl http://localhost:8080/api/hello</pre>
        <pre>curl http://localhost:8080/api/echo?message=test</pre>
        
        <p><small>Server monitored via TUI - check your terminal!</small></p>
    </div>
</body>
</html>]]
    
    res:header("Content-Type", "text/html")
    res:write(html)
end)

-- API endpoints
server:handle("/api/hello", function(req, res)
    log("API: /api/hello")
    res:json({
        message = "Hello from LuaX!",
        server = "LuaX Web Server",
        timestamp = os.time()
    })
end)

server:handle("/api/time", function(req, res)
    log("API: /api/time")
    res:json({
        time = os.date("%Y-%m-%d %H:%M:%S"),
        timestamp = os.time(),
        timezone = os.date("%Z")
    })
end)

server:handle("/api/info", function(req, res)
    log("API: /api/info")
    res:json({
        server = "LuaX Web Server",
        version = "1.0.0",
        lua_version = _VERSION,
        uptime = os.clock(),
        endpoints = {"/", "/api/hello", "/api/time", "/api/info", "/api/echo"}
    })
end)

server:handle("/api/echo", function(req, res)
    log("API: /api/echo with query: " .. req.url)
    
    -- Convert query table to regular table for JSON
    local queryData = {}
    if req.query then
        for k, v in pairs(req.query) do
            queryData[k] = v
        end
    end
    
    res:json({
        method = req.method,
        path = req.path,
        query = queryData,
        headers = req.headers,
        echo = req.query.message or "No message provided"
    })
end)

-- Set up key bindings for TUI
app:SetInputCapture(function(event)
    if event:Key() == 3 then -- Ctrl+C
        log("Shutting down server...")
        server:stop()
        app:Stop()
        return nil
    end
    return event
end)

-- Start server
log("Starting HTTP server on port 8080...")
server:listen(8080)

statusBar:SetText("Server: Running on http://localhost:8080 | Press Ctrl+C to stop")
log("Server started successfully!")
log("Visit: http://localhost:8080")
log("Try: curl http://localhost:8080/api/hello")

-- Set up and run TUI
app:SetRoot(flex, true)
app:Run()