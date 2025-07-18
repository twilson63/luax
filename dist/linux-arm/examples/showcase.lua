-- Hype Feature Showcase
-- Demonstrates TUI, HTTP, and Database functionality in one app

local kv = require('kv')
local http = require('http')

-- Initialize database
local db, err = kv.open("./showcase.db")
if err then
    print("Database error:", err)
    os.exit(1)
end
db:open_db("logs")

-- TUI Setup
local app = tui.newApp()
local flex = tui.newFlex()
local logView = tui.newTextView("")
local statusBar = tui.newTextView("Hype Showcase - HTTP Server + Database + TUI")

-- Configure TUI components
logView:SetWrap(true)
logView:SetWordWrap(true)
logView:SetTitle("Server Logs")
statusBar:SetTextColor(0x00ff00) -- Green

-- Logging function that displays in TUI and stores in database
local function log(message)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local logEntry = timestamp .. " - " .. message
    
    -- Display in TUI
    local currentText = ""
    if logView.GetText then
        currentText = logView:GetText()
    end
    logView:SetText(currentText .. logEntry .. "\n")
    
    -- Store in database
    local logId = "log_" .. os.time() .. "_" .. math.random(1000)
    db:put("logs", logId, logEntry)
    
    -- Update status
    statusBar:SetText("Last: " .. message)
end

-- HTTP Server setup
local server = http.newServer()

-- API endpoint - Get all logs
server:handle("/logs", function(req, res)
    local logs = {}
    db:foreach("logs", function(key, value)
        table.insert(logs, value)
        return true
    end)
    res:json({ logs = logs, count = #logs })
    log("API: Retrieved " .. #logs .. " log entries")
end)

-- API endpoint - Add new log entry
server:handle("/log", function(req, res)
    if req.method == "POST" then
        local message = req.body or "Empty message"
        log("API: " .. message)
        res:json({ message = "Log added", timestamp = os.time() })
    else
        res:json({ error = "POST method required" })
    end
end)

-- Status endpoint
server:handle("/status", function(req, res)
    local logCount = 0
    db:foreach("logs", function(key, value)
        logCount = logCount + 1
        return true
    end)
    
    res:json({
        server = "Hype Showcase",
        status = "running",
        logs_stored = logCount,
        uptime = os.time()
    })
    log("Status check - " .. logCount .. " logs stored")
end)

-- Root endpoint with welcome message
server:handle("/", function(req, res)
    res:write([[
Hype Showcase Server

Available endpoints:
- GET  /status  - Server status and statistics
- GET  /logs    - Retrieve all stored logs  
- POST /log     - Add new log entry (send message in body)

This server demonstrates:
- HTTP API with multiple endpoints
- Embedded database storage with BoltDB
- Real-time TUI interface with server logs
- Cross-platform executable deployment

Built with Hype - Lua Script to Executable Packager
]])
    log("Root page served")
end)

-- Setup TUI layout
flex:SetDirection(1) -- Vertical layout
flex:AddItem(logView, 0, 1, false)     -- Main log area (expandable)
flex:AddItem(statusBar, 1, 0, false)   -- Status bar (fixed height)

app:SetRoot(flex, true)

-- Start HTTP server
server:listen(8080)
log("Server started on http://localhost:8080")
log("Database connected: showcase.db")
log("TUI interface ready")
log("Ready for requests!")

-- Set up graceful shutdown
app:SetInputCapture(function(event)
    if event:Key() == 17 then -- Ctrl+Q
        log("Shutting down server...")
        server:stop()
        db:close()
        app:Stop()
        return nil
    end
    return event
end)

-- Add some initial demo data
log("Adding demo data to database...")
db:put("logs", "demo1", "Demo: Application started")
db:put("logs", "demo2", "Demo: Database initialized")  
db:put("logs", "demo3", "Demo: HTTP routes configured")

-- Start the TUI application
app:Run()

-- Cleanup on exit
server:stop()
db:close()
print("Hype Showcase completed!")