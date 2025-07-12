-- Advanced TUI Dashboard Example
-- Showcases all enhanced TUI features with beautiful styling
-- Features: Professional design, interactive controls, real-time simulation

local app = tui.newApp()
local kv = require('kv')

-- Color constants for consistent theming
local COLORS = {
    PRIMARY = 39,      -- Bright blue
    SUCCESS = 46,      -- Bright green  
    WARNING = 226,     -- Bright yellow
    DANGER = 196,      -- Bright red
    SECONDARY = 245,   -- Light gray
    DARK = 235,        -- Dark gray
    DARKER = 232,      -- Very dark gray
    LIGHT = 255,       -- White
    ACCENT = 201,      -- Bright magenta
    INFO = 51          -- Bright cyan
}

-- Application state
local currentUser = "admin"
local serverStatus = "online"
local logCount = 0

-- Database setup
local db = kv.open("./dashboard.db")
db:open_db("settings")
db:put("settings", "theme", "dark")
db:put("settings", "user", currentUser)

-- Utility functions
local function createProgressBar(value, maxVal, width, showPercent)
    local percentage = math.floor((value / maxVal) * 100)
    local filled = math.floor((value / maxVal) * width)
    local bar = ""
    
    for i = 1, width do
        if i <= filled then
            bar = bar .. "█"
        else
            bar = bar .. "░"
        end
    end
    
    if showPercent then
        return string.format("%s %d%%", bar, percentage)
    else
        return bar
    end
end

local function getCurrentMetrics()
    -- Simulate dynamic metrics
    math.randomseed(os.time())
    return {
        cpu = math.random(20, 75),
        memory = math.random(35, 65),
        disk = math.random(15, 45),
        network = math.random(100, 1000),
        active_users = math.random(50, 200),
        requests_per_sec = math.random(10, 100)
    }
end

-- Create main layout
local mainFlex = tui.newFlex()
mainFlex:SetDirection(1) -- Vertical
mainFlex:SetBorder(true)
mainFlex:SetTitle("🎛️  Advanced TUI Dashboard - Enhanced Features Demo")
mainFlex:SetBorderColor(COLORS.PRIMARY)
mainFlex:SetBackgroundColor(COLORS.DARKER)

-- Header section with user info
local headerFlex = tui.newFlex()
headerFlex:SetDirection(0) -- Horizontal
headerFlex:SetBorder(true)
headerFlex:SetTitle("🏠 Dashboard Overview")
headerFlex:SetBorderColor(COLORS.ACCENT)
headerFlex:SetBackgroundColor(COLORS.DARK)

-- Welcome panel
local welcomePanel = tui.newTextView("")
welcomePanel:SetDynamicColors(true)
welcomePanel:SetBorder(true)
welcomePanel:SetTitle("👋 Welcome")
welcomePanel:SetBorderColor(COLORS.SUCCESS)
welcomePanel:SetBackgroundColor(COLORS.DARK)

-- System metrics panel
local metricsPanel = tui.newTextView("")
metricsPanel:SetDynamicColors(true)
metricsPanel:SetBorder(true)
metricsPanel:SetTitle("📊 Live Metrics")
metricsPanel:SetBorderColor(COLORS.INFO)
metricsPanel:SetBackgroundColor(COLORS.DARK)

-- Server status panel
local statusPanel = tui.newTextView("")
statusPanel:SetDynamicColors(true)
statusPanel:SetBorder(true)
statusPanel:SetTitle("🔧 Server Status")
statusPanel:SetBorderColor(COLORS.WARNING)
statusPanel:SetBackgroundColor(COLORS.DARK)

-- Control panel section
local controlFlex = tui.newFlex()
controlFlex:SetDirection(0) -- Horizontal
controlFlex:SetBorder(true)
controlFlex:SetTitle("⚙️  Control Panel")
controlFlex:SetBorderColor(COLORS.SECONDARY)
controlFlex:SetBackgroundColor(COLORS.DARK)

-- User input field
local userInput = tui.newInputField()
userInput:SetLabel("Username: ")
userInput:SetText(currentUser)
userInput:SetPlaceholder("Enter username...")
userInput:SetBorder(true)
userInput:SetTitle("👤 User Settings")
userInput:SetBorderColor(COLORS.SECONDARY)
userInput:SetFieldBackgroundColor(COLORS.DARKER)
userInput:SetFieldTextColor(COLORS.LIGHT)

-- Action buttons with enhanced styling
local refreshButton = tui.newButton("🔄 Refresh Data")
refreshButton:SetBorder(true)
refreshButton:SetBorderColor(COLORS.SUCCESS)
refreshButton:SetBackgroundColor(COLORS.SUCCESS)
refreshButton:SetLabelColor(COLORS.LIGHT)

local toggleButton = tui.newButton("🔀 Toggle Status")
toggleButton:SetBorder(true)
toggleButton:SetBorderColor(COLORS.WARNING)
toggleButton:SetBackgroundColor(COLORS.WARNING)
toggleButton:SetLabelColor(COLORS.DARKER)

local saveButton = tui.newButton("💾 Save Config")
saveButton:SetBorder(true)
saveButton:SetBorderColor(COLORS.INFO)
saveButton:SetBackgroundColor(COLORS.INFO)
saveButton:SetLabelColor(COLORS.LIGHT)

local exitButton = tui.newButton("❌ Exit App")
exitButton:SetBorder(true)
exitButton:SetBorderColor(COLORS.DANGER)
exitButton:SetBackgroundColor(COLORS.DANGER)
exitButton:SetLabelColor(COLORS.LIGHT)

-- Activity log panel
local logPanel = tui.newTextView("")
logPanel:SetDynamicColors(true)
logPanel:SetBorder(true)
logPanel:SetTitle("📝 Activity Log")
logPanel:SetBorderColor(COLORS.SECONDARY)
logPanel:SetBackgroundColor(COLORS.DARK)
logPanel:SetScrollable(true)
logPanel:SetWrap(true)

-- Functions to update content
local function updateWelcomePanel()
    local currentTime = os.date("%Y-%m-%d %H:%M:%S")
    local theme = db:get("settings", "theme") or "dark"
    
    local welcomeText = string.format([[
[%d]🎉 Welcome to Advanced Dashboard![%d]

[%d]Current User:[%d] %s
[%d]Login Time:[%d]  %s
[%d]Theme:[%d]       %s
[%d]Database:[%d]    Connected ✅

[%d]🚀 Enhanced TUI Features:[%d]
• Dynamic colors and markup
• Custom borders and themes  
• Interactive components
• Real-time data updates
• Database integration
]], 
        COLORS.PRIMARY, COLORS.LIGHT,
        COLORS.INFO, COLORS.LIGHT, currentUser,
        COLORS.INFO, COLORS.LIGHT, currentTime,
        COLORS.INFO, COLORS.LIGHT, theme,
        COLORS.INFO, COLORS.LIGHT,
        COLORS.ACCENT, COLORS.LIGHT
    )
    
    welcomePanel:SetText(welcomeText)
end

local function updateMetricsPanel()
    local metrics = getCurrentMetrics()
    
    local metricsText = string.format([[
[%d]📈 Performance Metrics[%d]

[%d]CPU Usage:[%d]
%s

[%d]Memory Usage:[%d]
%s

[%d]Disk Usage:[%d]
%s

[%d]📡 Network Traffic:[%d]
[%d]Current:[%d] %d KB/s
[%d]Active Users:[%d] %d
[%d]Requests/sec:[%d] %d
]], 
        COLORS.ACCENT, COLORS.LIGHT,
        COLORS.INFO, COLORS.LIGHT,
        createProgressBar(metrics.cpu, 100, 25, true),
        COLORS.INFO, COLORS.LIGHT,
        createProgressBar(metrics.memory, 100, 25, true),
        COLORS.INFO, COLORS.LIGHT,
        createProgressBar(metrics.disk, 100, 25, true),
        COLORS.ACCENT, COLORS.LIGHT,
        COLORS.SUCCESS, COLORS.LIGHT, metrics.network,
        COLORS.INFO, COLORS.LIGHT, metrics.active_users,
        COLORS.WARNING, COLORS.LIGHT, metrics.requests_per_sec
    )
    
    metricsPanel:SetText(metricsText)
end

local function updateStatusPanel()
    local uptime = "2d 14h 32m"
    local statusColor = serverStatus == "online" and COLORS.SUCCESS or COLORS.DANGER
    local statusIcon = serverStatus == "online" and "🟢" or "🔴"
    
    local statusText = string.format([[
[%d]🖥️  Server Information[%d]

[%d]Status:[%d] %s %s
[%d]Uptime:[%d] %s
[%d]Load Average:[%d] 0.45, 0.32, 0.28
[%d]Total Logs:[%d] %d

[%d]📋 Quick Stats:[%d]
[%d]• Disk Space:[%d] 250GB free
[%d]• Processes:[%d] 187 running
[%d]• Services:[%d] 12 active
[%d]• Connections:[%d] 45 open

[%d]🔗 Network Interfaces:[%d]
[%d]eth0:[%d] 192.168.1.100
[%d]lo:[%d]   127.0.0.1
]], 
        COLORS.ACCENT, COLORS.LIGHT,
        COLORS.INFO, COLORS.LIGHT, statusIcon, serverStatus,
        COLORS.INFO, COLORS.LIGHT, uptime,
        COLORS.INFO, COLORS.LIGHT,
        COLORS.INFO, COLORS.LIGHT, logCount,
        COLORS.ACCENT, COLORS.LIGHT,
        COLORS.INFO, COLORS.LIGHT,
        COLORS.INFO, COLORS.LIGHT,
        COLORS.INFO, COLORS.LIGHT,
        COLORS.INFO, COLORS.LIGHT,
        COLORS.ACCENT, COLORS.LIGHT,
        COLORS.SUCCESS, COLORS.LIGHT,
        COLORS.WARNING, COLORS.LIGHT
    )
    
    statusPanel:SetText(statusText)
end

local function addLogEntry(level, message)
    logCount = logCount + 1
    local timestamp = os.date("%H:%M:%S")
    local levelColor = COLORS.INFO
    
    if level == "SUCCESS" then levelColor = COLORS.SUCCESS
    elseif level == "WARNING" then levelColor = COLORS.WARNING
    elseif level == "ERROR" then levelColor = COLORS.DANGER
    end
    
    local logEntry = string.format("[%d][%s][%d] [%d]%s[%d] - %s", 
        COLORS.SECONDARY, timestamp, COLORS.LIGHT,
        levelColor, level, COLORS.LIGHT, message)
    
    local currentLog = logPanel:GetText()
    local newLog = currentLog .. logEntry .. "\n"
    
    -- Keep only last 15 lines
    local lines = {}
    for line in newLog:gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    
    local maxLines = 15
    if #lines > maxLines then
        local trimmedLines = {}
        for i = #lines - maxLines + 1, #lines do
            table.insert(trimmedLines, lines[i])
        end
        newLog = table.concat(trimmedLines, "\n") .. "\n"
    end
    
    logPanel:SetText(newLog)
end

local function updateAllPanels()
    updateWelcomePanel()
    updateMetricsPanel()
    updateStatusPanel()
end

-- Button event handlers
refreshButton:SetSelectedFunc(function()
    addLogEntry("INFO", "Dashboard refreshed manually")
    updateAllPanels()
end)

toggleButton:SetSelectedFunc(function()
    if serverStatus == "online" then
        serverStatus = "offline"
        addLogEntry("WARNING", "Server status changed to offline")
    else
        serverStatus = "online"
        addLogEntry("SUCCESS", "Server status changed to online")
    end
    updateStatusPanel()
end)

saveButton:SetSelectedFunc(function()
    local username = userInput:GetText()
    if username and username ~= "" then
        currentUser = username
        db:put("settings", "user", currentUser)
        addLogEntry("SUCCESS", "Configuration saved for user: " .. currentUser)
        updateWelcomePanel()
    else
        addLogEntry("ERROR", "Invalid username provided")
    end
end)

exitButton:SetSelectedFunc(function()
    addLogEntry("INFO", "Application shutdown initiated")
    db:close()
    app:Stop()
end)

userInput:SetDoneFunc(function(key)
    if key == 13 then -- Enter key
        local username = userInput:GetText()
        if username and username ~= "" then
            currentUser = username
            addLogEntry("INFO", "Username updated to: " .. currentUser)
            updateWelcomePanel()
        end
    end
end)

-- Layout assembly
headerFlex:AddItem(welcomePanel, 0, 1, false)
headerFlex:AddItem(metricsPanel, 0, 1, false)
headerFlex:AddItem(statusPanel, 0, 1, false)

controlFlex:AddItem(userInput, 0, 1, true)
controlFlex:AddItem(refreshButton, 18, 0, false)
controlFlex:AddItem(toggleButton, 18, 0, false)
controlFlex:AddItem(saveButton, 16, 0, false)
controlFlex:AddItem(exitButton, 14, 0, false)

mainFlex:AddItem(headerFlex, 0, 2, false)
mainFlex:AddItem(controlFlex, 5, 0, false)
mainFlex:AddItem(logPanel, 0, 1, false)

-- Set up the app
app:SetRoot(mainFlex, true)

-- Global key bindings
app:SetInputCapture(function(event)
    local key = event:Key()
    
    if key == 17 then -- Ctrl+Q
        addLogEntry("INFO", "Exit via Ctrl+Q")
        db:close()
        app:Stop()
        return nil
    elseif key == 18 then -- Ctrl+R
        addLogEntry("INFO", "Refresh via Ctrl+R")
        updateAllPanels()
        return nil
    elseif key == 20 then -- Ctrl+T
        if serverStatus == "online" then
            serverStatus = "offline"
            addLogEntry("WARNING", "Server toggled offline via Ctrl+T")
        else
            serverStatus = "online"
            addLogEntry("SUCCESS", "Server toggled online via Ctrl+T")
        end
        updateStatusPanel()
        return nil
    end
    
    return event
end)

-- Initialize application
print("🎛️  Advanced TUI Dashboard")
print("═══════════════════════════════════════════")
print("Enhanced TUI Features Demonstrated:")
print("• SetDynamicColors - Color markup in text")
print("• SetBorder - Borders around all components")
print("• SetBorderColor - Custom colored borders")
print("• SetBackgroundColor - Themed backgrounds")
print("• SetTitle - Titles on all panels")
print("• SetFieldBackgroundColor - Input styling")
print("• SetFieldTextColor - Input text colors")
print("• SetLabelColor - Button text colors")
print("• SetScrollable - Scrollable log panel")
print("• Interactive buttons and inputs")
print("• Real-time data simulation")
print("• Database integration")
print("")
print("Keyboard Controls:")
print("• Ctrl+Q: Exit application")
print("• Ctrl+R: Refresh all data")
print("• Ctrl+T: Toggle server status")
print("• Tab: Navigate between controls")
print("• Enter: Submit input changes")
print("")

-- Add initial log entries
addLogEntry("SUCCESS", "Advanced Dashboard initialized")
addLogEntry("INFO", "Enhanced TUI features loaded")
addLogEntry("INFO", "Database connection established")
addLogEntry("INFO", "All systems ready")

-- Initial display update
updateAllPanels()

-- Start the application
app:Run()

-- Cleanup
if db then
    db:close()
end