-- Bubble Tea Plugin for Hype (Embedded Version)
-- Modern TUI framework based on The Elm Architecture

local tea = {}

-- Version
tea.VERSION = "1.0.0"

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
        running = false,
        altScreen = false
    }
    
    -- Enable alternate screen buffer
    function program:withAltScreen()
        self.altScreen = true
        return self
    end
    
    -- Enable mouse support
    function program:withMouseCellMotion()
        -- Mouse support would be implemented here
        return self
    end
    
    -- Run the program (simplified for demo)
    function program:run()
        self.running = true
        
        -- Initialize
        if self.altScreen then
            io.write("\027[?1049h") -- Enter alternate screen
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
        
        -- Simplified main loop - in real implementation would handle proper input
        print("\n\n(Press Enter to exit)")
        io.read()
        
        -- Cleanup
        io.write("\027[?25h") -- Show cursor
        
        if self.altScreen then
            io.write("\027[?1049l") -- Exit alternate screen
        end
        
        return self.model
    end
    
    return program
end

-- Commands
function tea.quit()
    return function()
        return {type = "quit"}
    end
end

function tea.cmd(fn)
    return fn
end

function tea.batch(...)
    local cmds = {...}
    return cmds
end

function tea.tick(duration, fn)
    return function()
        -- In real implementation, would use timer
        return fn()
    end
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

-- Style module (simplified)
local style = {}

function style.new()
    local self = {
        fg = nil,
        bg = nil,
        bold = false,
        italic = false,
        underline = false
    }
    
    function self:foreground(color)
        self.fg = color
        return self
    end
    
    function self:background(color)
        self.bg = color
        return self
    end
    
    function self:setBold(enabled)
        self.bold = enabled ~= false
        return self
    end
    
    function self:setItalic(enabled)
        self.italic = enabled ~= false
        return self
    end
    
    function self:setUnderline(enabled)
        self.underline = enabled ~= false
        return self
    end
    
    function self:copy()
        local new = style.new()
        for k, v in pairs(self) do
            if type(v) ~= "function" then
                new[k] = v
            end
        end
        return new
    end
    
    function self:render(text)
        local codes = {}
        
        -- Text attributes
        if self.bold then table.insert(codes, "1") end
        if self.italic then table.insert(codes, "3") end
        if self.underline then table.insert(codes, "4") end
        
        -- Colors (simplified)
        local colors = {
            black = 30, red = 31, green = 32, yellow = 33,
            blue = 34, magenta = 35, cyan = 36, white = 37
        }
        
        if self.fg and colors[self.fg] then
            table.insert(codes, tostring(colors[self.fg]))
        end
        
        if self.bg and colors[self.bg] then
            table.insert(codes, tostring(colors[self.bg] + 10))
        end
        
        -- Apply styling
        if #codes > 0 then
            return string.format("\027[%sm%s\027[0m", table.concat(codes, ";"), text)
        else
            return text
        end
    end
    
    return self
end

tea.style = style

-- Text input component (simplified)
local textinput = {}

function textinput.new()
    local self = {
        value = "",
        placeholder = "",
        cursor = 0,
        focused = false
    }
    
    function self:setValue(value)
        self.value = value or ""
        self.cursor = #self.value
        return self
    end
    
    function self:getValue()
        return self.value
    end
    
    function self:setPlaceholder(placeholder)
        self.placeholder = placeholder or ""
        return self
    end
    
    function self:focus()
        self.focused = true
        return self
    end
    
    function self:blur()
        self.focused = false
        return self
    end
    
    function self:update(msg)
        if not self.focused then
            return self
        end
        
        if msg.type == "key" then
            if #msg.key == 1 and msg.key:match("[%g ]") then
                self.value = self.value .. msg.key
                self.cursor = self.cursor + 1
            elseif msg.key == "backspace" and #self.value > 0 then
                self.value = self.value:sub(1, -2)
                self.cursor = math.max(0, self.cursor - 1)
            end
        end
        
        return self
    end
    
    function self:view()
        if #self.value == 0 and not self.focused then
            return self.placeholder
        end
        
        if self.focused then
            return self.value .. "█"
        else
            return self.value
        end
    end
    
    return self
end

tea.textinput = textinput

-- List component (simplified)
local list = {}

function list.new(items)
    local self = {
        items = items or {},
        selected = 1,
        cursor = 1
    }
    
    function self:update(msg)
        if msg.type == "key" then
            if msg.key == "up" or msg.key == "k" then
                self.cursor = math.max(1, self.cursor - 1)
            elseif msg.key == "down" or msg.key == "j" then
                self.cursor = math.min(#self.items, self.cursor + 1)
            elseif msg.key == "enter" then
                self.selected = self.cursor
                return self, {type = "select", item = self.items[self.cursor]}
            end
        end
        
        return self, nil
    end
    
    function self:view()
        local lines = {}
        for i, item in ipairs(self.items) do
            local prefix = (i == self.cursor) and "> " or "  "
            table.insert(lines, prefix .. tostring(item))
        end
        return table.concat(lines, "\n")
    end
    
    return self
end

tea.list = list

-- Spinner component (simplified)
local spinner = {}

spinner.styles = {
    dots = {frames = {"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}, fps = 12}
}

function spinner.new(style)
    local styleData = style or "dots"
    if type(style) == "string" and spinner.styles[style] then
        styleData = spinner.styles[style]
    end
    
    local self = {
        frames = styleData.frames,
        frame = 1,
        text = ""
    }
    
    function self:setText(text)
        self.text = text or ""
        return self
    end
    
    function self:update(msg)
        if msg.type == "tick" then
            self.frame = self.frame + 1
            if self.frame > #self.frames then
                self.frame = 1
            end
        end
        return self
    end
    
    function self:view()
        return self.frames[self.frame] .. " " .. self.text
    end
    
    return self
end

tea.spinner = spinner

-- Progress component (simplified)
local progress = {}

function progress.new(total)
    local self = {
        current = 0,
        total = total or 100,
        width = 40
    }
    
    function self:setCurrent(value)
        self.current = math.max(0, math.min(value, self.total))
        return self
    end
    
    function self:setWidth(width)
        self.width = width
        return self
    end
    
    function self:view()
        local ratio = self.current / self.total
        local filled = math.floor(self.width * ratio)
        local empty = self.width - filled
        
        local bar = "[" .. string.rep("█", filled) .. string.rep("░", empty) .. "]"
        local percent = string.format(" %3d%%", math.floor(ratio * 100))
        
        return bar .. percent
    end
    
    return self
end

tea.progress = progress

-- Viewport component (simplified)
local viewport = {}

function viewport.new(width, height)
    local self = {
        width = width or 80,
        height = height or 24,
        content = "",
        offset = 0
    }
    
    function self:setContent(content)
        self.content = content
        return self
    end
    
    function self:update(msg)
        -- Handle scrolling
        if msg.type == "key" then
            if msg.key == "up" or msg.key == "k" then
                self.offset = math.max(0, self.offset - 1)
            elseif msg.key == "down" or msg.key == "j" then
                self.offset = self.offset + 1
            end
        end
        return self
    end
    
    function self:view()
        local lines = {}
        local lineNum = 0
        for line in self.content:gmatch("[^\n]*") do
            lineNum = lineNum + 1
            if lineNum > self.offset and lineNum <= self.offset + self.height then
                table.insert(lines, line)
            end
        end
        
        -- Pad with empty lines
        while #lines < self.height do
            table.insert(lines, "")
        end
        
        return table.concat(lines, "\n")
    end
    
    return self
end

tea.viewport = viewport

-- Textarea component (simplified)
local textarea = {}

function textarea.new()
    local self = {
        lines = {""},
        cursor = {row = 1, col = 0},
        focused = false
    }
    
    function self:setValue(value)
        self.lines = {}
        for line in (value .. "\n"):gmatch("([^\n]*)\n") do
            table.insert(self.lines, line)
        end
        if #self.lines == 0 then
            self.lines = {""}
        end
        return self
    end
    
    function self:getValue()
        return table.concat(self.lines, "\n")
    end
    
    function self:focus()
        self.focused = true
        return self
    end
    
    function self:view()
        return table.concat(self.lines, "\n")
    end
    
    return self
end

tea.textarea = textarea

return tea