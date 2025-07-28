-- Bubble Tea Plugin for Hype (Integrated with Hype's TUI)
-- This version uses Hype's built-in TUI for terminal handling

local tea = {}

-- Version
tea.VERSION = "1.0.0"

-- Message types
tea.MSG_KEY = "key"
tea.MSG_MOUSE = "mouse"
tea.MSG_WINDOW_SIZE = "window_size"
tea.MSG_TICK = "tick"
tea.MSG_CUSTOM = "custom"
tea.MSG_QUIT = "quit"

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

-- Create a new Bubble Tea program that integrates with Hype's TUI
function tea.newProgram(model, update, view, init)
    local program = {
        model = model,
        update = update,
        view = view,
        init = init,
        running = false
    }
    
    function program:withAltScreen()
        -- Compatibility method
        return self
    end
    
    function program:withMouseCellMotion()
        -- Compatibility method
        return self
    end
    
    function program:run()
        -- Use Hype's TUI module for proper terminal handling
        local tui = require('tui')
        if not tui then
            error("Bubble Tea requires Hype's TUI module")
        end
        
        self.running = true
        
        -- Create TUI app
        local app = tui.newApp()
        local textView = tui.newTextView()
        
        -- Set up the view
        textView:SetDynamicColors(true)
        textView:SetScrollable(false)
        
        -- Initial render
        if self.init then
            local initMsg = self.init()
            if initMsg then
                self.model, _ = self.update(self.model, initMsg)
            end
        end
        
        local function render()
            local output = self.view(self.model)
            textView:Clear()
            textView:SetText(output)
        end
        
        -- Initial render
        render()
        
        -- Set up input handler
        textView:SetInputCapture(function(event)
            local msg = nil
            
            -- Convert TUI event to Bubble Tea message
            if event.Key() == tui.KeyEsc then
                msg = {type = tea.MSG_KEY, key = tea.KEY_ESC}
            elseif event.Key() == tui.KeyEnter then
                msg = {type = tea.MSG_KEY, key = tea.KEY_ENTER}
            elseif event.Key() == tui.KeyTab then
                msg = {type = tea.MSG_KEY, key = tea.KEY_TAB}
            elseif event.Key() == tui.KeyBackspace or event.Key() == tui.KeyBackspace2 then
                msg = {type = tea.MSG_KEY, key = tea.KEY_BACKSPACE}
            elseif event.Key() == tui.KeyDelete then
                msg = {type = tea.MSG_KEY, key = tea.KEY_DELETE}
            elseif event.Key() == tui.KeyUp then
                msg = {type = tea.MSG_KEY, key = tea.KEY_UP}
            elseif event.Key() == tui.KeyDown then
                msg = {type = tea.MSG_KEY, key = tea.KEY_DOWN}
            elseif event.Key() == tui.KeyLeft then
                msg = {type = tea.MSG_KEY, key = tea.KEY_LEFT}
            elseif event.Key() == tui.KeyRight then
                msg = {type = tea.MSG_KEY, key = tea.KEY_RIGHT}
            elseif event.Key() == tui.KeyHome then
                msg = {type = tea.MSG_KEY, key = tea.KEY_HOME}
            elseif event.Key() == tui.KeyEnd then
                msg = {type = tea.MSG_KEY, key = tea.KEY_END}
            elseif event.Key() == tui.KeyPgUp then
                msg = {type = tea.MSG_KEY, key = tea.KEY_PGUP}
            elseif event.Key() == tui.KeyPgDn then
                msg = {type = tea.MSG_KEY, key = tea.KEY_PGDOWN}
            elseif event.Key() == tui.KeyCtrlC then
                msg = {type = tea.MSG_KEY, key = tea.KEY_CTRL_C}
            elseif event.Rune() ~= 0 then
                msg = {type = tea.MSG_KEY, key = string.char(event.Rune())}
            end
            
            if msg then
                -- Update model
                local newModel, cmd = self.update(self.model, msg)
                self.model = newModel
                
                -- Handle commands
                if cmd then
                    if type(cmd) == "function" then
                        local result = cmd()
                        if result and result.type == "quit" then
                            app:Stop()
                            return event
                        end
                    end
                end
                
                -- Re-render
                app:QueueUpdateDraw(render)
            end
            
            return event
        end)
        
        -- Set root and run
        app:SetRoot(textView, true)
        app:Run()
        
        self.running = false
        return self.model
    end
    
    return program
end

-- Commands
function tea.quit()
    return function()
        return {type = tea.MSG_QUIT}
    end
end

function tea.cmd(fn)
    return fn
end

function tea.batch(...)
    return {...}
end

function tea.tick(duration, fn)
    return function()
        go(function()
            sleep(duration / 1000)
            return fn()
        end)
    end
end

-- Style module
local style = {}

function style.new()
    local self = {
        fg = nil,
        bg = nil,
        bold = false,
        italic = false,
        underline = false,
        strikethrough = false
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
    
    function self:setStrikethrough(enabled)
        self.strikethrough = enabled ~= false
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
        -- Use tview color tags for compatibility
        local result = text
        
        -- Apply attributes
        local tags = {}
        
        if self.fg then
            table.insert(tags, self.fg)
        end
        
        if self.bg then
            table.insert(tags, self.bg .. ":")
        end
        
        if self.bold then
            table.insert(tags, "b")
        end
        
        if self.italic then
            table.insert(tags, "i")
        end
        
        if self.underline then
            table.insert(tags, "u")
        end
        
        if self.strikethrough then
            table.insert(tags, "s")
        end
        
        if #tags > 0 then
            result = "[" .. table.concat(tags, ":") .. "]" .. text .. "[-]"
        end
        
        return result
    end
    
    return self
end

tea.style = style

-- Components

-- Text Input
local textinput = {}

function textinput.new()
    local self = {
        value = "",
        placeholder = "",
        cursor = 0,
        width = 0,
        focused = false,
        charLimit = 0
    }
    
    function self:setValue(value)
        self.value = value or ""
        if self.charLimit > 0 and #self.value > self.charLimit then
            self.value = self.value:sub(1, self.charLimit)
        end
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
    
    function self:setWidth(width)
        self.width = width
        return self
    end
    
    function self:setCharLimit(limit)
        self.charLimit = limit or 0
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
        
        if msg.type == tea.MSG_KEY then
            if msg.key == tea.KEY_LEFT then
                self.cursor = math.max(0, self.cursor - 1)
            elseif msg.key == tea.KEY_RIGHT then
                self.cursor = math.min(#self.value, self.cursor + 1)
            elseif msg.key == tea.KEY_HOME then
                self.cursor = 0
            elseif msg.key == tea.KEY_END then
                self.cursor = #self.value
            elseif msg.key == tea.KEY_BACKSPACE then
                if self.cursor > 0 then
                    local before = self.value:sub(1, self.cursor - 1)
                    local after = self.value:sub(self.cursor + 1)
                    self.value = before .. after
                    self.cursor = self.cursor - 1
                end
            elseif msg.key == tea.KEY_DELETE then
                if self.cursor < #self.value then
                    local before = self.value:sub(1, self.cursor)
                    local after = self.value:sub(self.cursor + 2)
                    self.value = before .. after
                end
            elseif #msg.key == 1 and msg.key:match("[%g ]") then
                if self.charLimit == 0 or #self.value < self.charLimit then
                    local before = self.value:sub(1, self.cursor)
                    local after = self.value:sub(self.cursor + 1)
                    self.value = before .. msg.key .. after
                    self.cursor = self.cursor + 1
                end
            end
        end
        
        return self
    end
    
    function self:view()
        local display = self.value
        
        if #self.value == 0 and not self.focused then
            display = "[gray]" .. self.placeholder .. "[-]"
        elseif self.focused then
            -- Show cursor
            local before = display:sub(1, self.cursor)
            local after = display:sub(self.cursor + 1)
            display = before .. "[white:black]█[-]" .. after
        end
        
        return display
    end
    
    return self
end

tea.textinput = textinput

-- List Component
local list = {}

function list.new(items)
    local self = {
        items = items or {},
        cursor = 1,
        selected = 0,
        height = 10
    }
    
    function self:setItems(items)
        self.items = items or {}
        self.cursor = math.min(self.cursor, #self.items)
        if self.cursor == 0 and #self.items > 0 then
            self.cursor = 1
        end
        return self
    end
    
    function self:setHeight(height)
        self.height = height
        return self
    end
    
    function self:update(msg)
        if msg.type == tea.MSG_KEY then
            if msg.key == tea.KEY_UP or msg.key == "k" then
                if self.cursor > 1 then
                    self.cursor = self.cursor - 1
                end
            elseif msg.key == tea.KEY_DOWN or msg.key == "j" then
                if self.cursor < #self.items then
                    self.cursor = self.cursor + 1
                end
            elseif msg.key == tea.KEY_HOME or msg.key == "g" then
                self.cursor = 1
            elseif msg.key == tea.KEY_END or msg.key == "G" then
                self.cursor = #self.items
            elseif msg.key == tea.KEY_ENTER then
                self.selected = self.cursor
                return self, {type = "select", item = self.items[self.cursor], index = self.cursor}
            end
        end
        
        return self, nil
    end
    
    function self:view()
        local lines = {}
        
        -- Calculate visible range
        local start = math.max(1, self.cursor - math.floor(self.height / 2))
        local finish = math.min(#self.items, start + self.height - 1)
        
        -- Adjust start if we're near the end
        if finish - start + 1 < self.height and start > 1 then
            start = math.max(1, finish - self.height + 1)
        end
        
        for i = start, finish do
            local item = self.items[i]
            local line = tostring(item)
            
            if i == self.cursor then
                line = "[yellow:black] > " .. line .. " [-]"
            else
                line = "   " .. line
            end
            
            table.insert(lines, line)
        end
        
        return table.concat(lines, "\n")
    end
    
    return self
end

tea.list = list

-- Spinner Component
local spinner = {}

spinner.styles = {
    dots = {frames = {"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}, fps = 12},
    line = {frames = {"-", "\\", "|", "/"}, fps = 10}
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
        if msg.type == tea.MSG_TICK then
            self.frame = self.frame + 1
            if self.frame > #self.frames then
                self.frame = 1
            end
        end
        return self
    end
    
    function self:view()
        return "[cyan]" .. self.frames[self.frame] .. "[-] " .. self.text
    end
    
    return self
end

tea.spinner = spinner

-- Progress Component
local progress = {}

function progress.new(total)
    local self = {
        current = 0,
        total = total or 100,
        width = 40,
        showPercentage = true
    }
    
    function self:setCurrent(value)
        self.current = math.max(0, math.min(value, self.total))
        return self
    end
    
    function self:increment(amount)
        amount = amount or 1
        self:setCurrent(self.current + amount)
        return self
    end
    
    function self:setWidth(width)
        self.width = width
        return self
    end
    
    function self:isComplete()
        return self.current >= self.total
    end
    
    function self:view()
        local ratio = self.current / self.total
        local filled = math.floor(self.width * ratio)
        local empty = self.width - filled
        
        local bar = "[green]" .. string.rep("█", filled) .. "[-]" ..
                   "[gray]" .. string.rep("░", empty) .. "[-]"
        
        local output = "[" .. bar .. "]"
        
        if self.showPercentage then
            output = output .. string.format(" %3d%%", math.floor(ratio * 100))
        end
        
        return output
    end
    
    return self
end

tea.progress = progress

-- Viewport Component
local viewport = {}

function viewport.new(width, height)
    local self = {
        width = width or 80,
        height = height or 24,
        content = "",
        lines = {},
        yOffset = 0
    }
    
    function self:setContent(content)
        self.content = content
        self.lines = {}
        for line in (content .. "\n"):gmatch("([^\n]*)\n") do
            table.insert(self.lines, line)
        end
        return self
    end
    
    function self:resize(width, height)
        self.width = width
        self.height = height
        return self
    end
    
    function self:update(msg)
        if msg.type == tea.MSG_KEY then
            if msg.key == tea.KEY_UP or msg.key == "k" then
                self.yOffset = math.max(0, self.yOffset - 1)
            elseif msg.key == tea.KEY_DOWN or msg.key == "j" then
                local maxOffset = math.max(0, #self.lines - self.height)
                self.yOffset = math.min(maxOffset, self.yOffset + 1)
            elseif msg.key == tea.KEY_PGUP then
                self.yOffset = math.max(0, self.yOffset - self.height)
            elseif msg.key == tea.KEY_PGDOWN then
                local maxOffset = math.max(0, #self.lines - self.height)
                self.yOffset = math.min(maxOffset, self.yOffset + self.height)
            elseif msg.key == tea.KEY_HOME or msg.key == "g" then
                self.yOffset = 0
            elseif msg.key == tea.KEY_END or msg.key == "G" then
                self.yOffset = math.max(0, #self.lines - self.height)
            end
        end
        return self
    end
    
    function self:view()
        local visible = {}
        local endLine = math.min(self.yOffset + self.height, #self.lines)
        
        for i = self.yOffset + 1, endLine do
            table.insert(visible, self.lines[i] or "")
        end
        
        -- Pad with empty lines
        while #visible < self.height do
            table.insert(visible, "")
        end
        
        return table.concat(visible, "\n")
    end
    
    return self
end

tea.viewport = viewport

-- Textarea Component
local textarea = {}

function textarea.new()
    local self = {
        lines = {""},
        cursor = {row = 1, col = 0},
        width = 80,
        height = 10,
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
    
    function self:setSize(width, height)
        self.width = width
        self.height = height
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
    
    function self:view()
        local visible = {}
        
        for i = 1, math.min(self.height, #self.lines) do
            local line = self.lines[i] or ""
            if self.focused and i == self.cursor.row then
                -- Show cursor on this line
                local before = line:sub(1, self.cursor.col)
                local after = line:sub(self.cursor.col + 1)
                line = before .. "[white:black]█[-]" .. after
            end
            table.insert(visible, line)
        end
        
        return table.concat(visible, "\n")
    end
    
    return self
end

tea.textarea = textarea

return tea