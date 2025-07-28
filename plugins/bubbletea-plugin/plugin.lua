-- Bubble Tea Plugin for Hype
-- Modern TUI framework based on The Elm Architecture

local tea = {}

-- Version
tea.VERSION = "1.0.0"

-- Core concepts:
-- Model: Your application state
-- Update: Function that handles messages and updates the model
-- View: Function that renders the UI based on the model
-- Cmd: Commands that trigger I/O operations

-- Message types
tea.MSG_KEY = "key"
tea.MSG_MOUSE = "mouse"
tea.MSG_WINDOW_SIZE = "window_size"
tea.MSG_TICK = "tick"
tea.MSG_CUSTOM = "custom"

-- Key constants
tea.KEY_CTRL_C = "ctrl+c"
tea.KEY_CTRL_D = "ctrl+d"
tea.KEY_ENTER = "enter"
tea.KEY_ESC = "esc"
tea.KEY_TAB = "tab"
tea.KEY_BACKSPACE = "backspace"
tea.KEY_DELETE = "delete"
tea.KEY_SPACE = " "
tea.KEY_UP = "up"
tea.KEY_DOWN = "down"
tea.KEY_LEFT = "left"
tea.KEY_RIGHT = "right"
tea.KEY_HOME = "home"
tea.KEY_END = "end"
tea.KEY_PGUP = "pgup"
tea.KEY_PGDOWN = "pgdown"

-- Mouse event types
tea.MOUSE_LEFT = "left"
tea.MOUSE_RIGHT = "right"
tea.MOUSE_MIDDLE = "middle"
tea.MOUSE_RELEASE = "release"
tea.MOUSE_WHEEL_UP = "wheel_up"
tea.MOUSE_WHEEL_DOWN = "wheel_down"
tea.MOUSE_MOTION = "motion"

-- Create a new Bubble Tea program
function tea.newProgram(model, update, view, init)
    local program = {
        model = model,
        update = update,
        view = view,
        init = init,
        commands = {},
        subscriptions = {},
        running = false,
        altScreen = false,
        mouseEnabled = false
    }
    
    -- Enable alternate screen buffer
    function program:withAltScreen()
        self.altScreen = true
        return self
    end
    
    -- Enable mouse support
    function program:withMouseCellMotion()
        self.mouseEnabled = true
        return self
    end
    
    -- Run the program
    function program:run()
        self.running = true
        
        -- Initialize
        if self.altScreen then
            io.write("\027[?1049h") -- Enter alternate screen
        end
        
        if self.mouseEnabled then
            io.write("\027[?1003h") -- Enable mouse tracking
        end
        
        -- Hide cursor
        io.write("\027[?25l")
        
        -- Clear screen
        io.write("\027[2J\027[H")
        
        -- Run init command if provided
        local initCmd = nil
        if self.init then
            initCmd = self.init()
        end
        
        -- Initial render
        local output = self.view(self.model)
        io.write(output)
        io.flush()
        
        -- Process init command
        if initCmd then
            self:processCmd(initCmd)
        end
        
        -- Main event loop
        while self.running do
            -- Handle input (simplified - in real implementation would use proper terminal input handling)
            local input = self:waitForInput()
            if input then
                local msg = self:parseInput(input)
                if msg then
                    -- Update model
                    local newModel, cmd = self.update(self.model, msg)
                    self.model = newModel
                    
                    -- Process command
                    if cmd then
                        self:processCmd(cmd)
                    end
                    
                    -- Re-render
                    io.write("\027[2J\027[H") -- Clear screen and reset cursor
                    output = self.view(self.model)
                    io.write(output)
                    io.flush()
                end
            end
            
            -- Process subscriptions
            self:processSubscriptions()
        end
        
        -- Cleanup
        io.write("\027[?25h") -- Show cursor
        
        if self.mouseEnabled then
            io.write("\027[?1003l") -- Disable mouse tracking
        end
        
        if self.altScreen then
            io.write("\027[?1049l") -- Exit alternate screen
        end
        
        return self.model
    end
    
    -- Quit the program
    function program:quit()
        self.running = false
    end
    
    -- Send a message to the program
    function program:send(msg)
        if self.running then
            local newModel, cmd = self.update(self.model, msg)
            self.model = newModel
            
            if cmd then
                self:processCmd(cmd)
            end
            
            -- Re-render
            io.write("\027[2J\027[H")
            local output = self.view(self.model)
            io.write(output)
            io.flush()
        end
    end
    
    -- Wait for input (simplified)
    function program:waitForInput()
        -- In real implementation, this would use proper terminal input handling
        -- For now, using simple io.read
        local char = io.read(1)
        return char
    end
    
    -- Parse input into message
    function program:parseInput(input)
        -- Simplified input parsing
        if input == "\027" then
            -- Escape sequence
            local seq = io.read(2)
            if seq == "[A" then
                return {type = tea.MSG_KEY, key = tea.KEY_UP}
            elseif seq == "[B" then
                return {type = tea.MSG_KEY, key = tea.KEY_DOWN}
            elseif seq == "[C" then
                return {type = tea.MSG_KEY, key = tea.KEY_RIGHT}
            elseif seq == "[D" then
                return {type = tea.MSG_KEY, key = tea.KEY_LEFT}
            end
        elseif input == "\003" then
            return {type = tea.MSG_KEY, key = tea.KEY_CTRL_C}
        elseif input == "\004" then
            return {type = tea.MSG_KEY, key = tea.KEY_CTRL_D}
        elseif input == "\r" or input == "\n" then
            return {type = tea.MSG_KEY, key = tea.KEY_ENTER}
        elseif input == "\t" then
            return {type = tea.MSG_KEY, key = tea.KEY_TAB}
        elseif input == "\127" then
            return {type = tea.MSG_KEY, key = tea.KEY_BACKSPACE}
        elseif input == " " then
            return {type = tea.MSG_KEY, key = tea.KEY_SPACE}
        else
            return {type = tea.MSG_KEY, key = input}
        end
    end
    
    -- Process command
    function program:processCmd(cmd)
        if type(cmd) == "function" then
            -- Execute command and get message
            local msg = cmd()
            if msg then
                self:send(msg)
            end
        elseif type(cmd) == "table" then
            -- Batch commands
            for _, c in ipairs(cmd) do
                self:processCmd(c)
            end
        end
    end
    
    -- Process subscriptions
    function program:processSubscriptions()
        -- Handle time-based subscriptions, etc.
        for _, sub in ipairs(self.subscriptions) do
            sub()
        end
    end
    
    return program
end

-- Commands

-- Quit command
function tea.quit()
    return function()
        return {type = "quit"}
    end
end

-- Custom command
function tea.cmd(fn)
    return fn
end

-- Batch commands
function tea.batch(...)
    local cmds = {...}
    return cmds
end

-- Tick command for animations
function tea.tick(duration, fn)
    return function()
        -- In real implementation, would use proper timer
        go(function()
            sleep(duration)
            return fn()
        end)
    end
end

-- Every command for repeated ticks
function tea.every(duration, fn)
    return function()
        go(function()
            while true do
                sleep(duration)
                local msg = fn()
                if msg then
                    -- Send message to program
                    return msg
                end
            end
        end)
    end
end

-- Sequence commands
function tea.sequence(...)
    local cmds = {...}
    return function()
        for _, cmd in ipairs(cmds) do
            if cmd then
                local result = cmd()
                if result then
                    return result
                end
            end
        end
    end
end

-- Helper function to create a simple program
function tea.simpleProgram(options)
    local model = options.model or {}
    local update = options.update or function(m, msg) return m, nil end
    local view = options.view or function(m) return "" end
    local init = options.init
    
    return tea.newProgram(model, update, view, init)
end

-- Key matching helper
function tea.keyMatches(msg, keys)
    if msg.type ~= tea.MSG_KEY then
        return false
    end
    
    if type(keys) == "string" then
        return msg.key == keys
    elseif type(keys) == "table" then
        for _, key in ipairs(keys) do
            if msg.key == key then
                return true
            end
        end
    end
    
    return false
end

-- Window size message creator
function tea.windowSize(width, height)
    return {
        type = tea.MSG_WINDOW_SIZE,
        width = width,
        height = height
    }
end

-- Function to load component modules with proper path resolution
local function loadComponent(name)
    -- Try different path combinations
    local paths = {
        "plugins/bubbletea-plugin/lib/" .. name,
        "./plugins/bubbletea-plugin/lib/" .. name,
        "bubbletea-plugin/lib/" .. name,
        "./lib/" .. name,
        "lib/" .. name
    }
    
    for _, path in ipairs(paths) do
        local ok, module = pcall(require, path)
        if ok then
            return module
        end
        -- Also try with .lua extension
        ok, module = pcall(dofile, path .. ".lua")
        if ok then
            return module
        end
    end
    
    -- If all fails, try to load from the same directory as this plugin
    local pluginPath = debug.getinfo(1, "S").source:match("@(.*/)")
    if pluginPath then
        local fullPath = pluginPath .. "lib/" .. name .. ".lua"
        local ok, module = pcall(dofile, fullPath)
        if ok then
            return module
        end
    end
    
    error("Failed to load component: " .. name)
end

-- Export components modules
tea.viewport = loadComponent('viewport')
tea.textinput = loadComponent('textinput')
tea.textarea = loadComponent('textarea')
tea.list = loadComponent('list')
tea.spinner = loadComponent('spinner')
tea.progress = loadComponent('progress')

-- Styling module (Lip Gloss)
tea.style = loadComponent('style')

return tea