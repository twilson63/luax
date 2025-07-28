-- Textarea component for Bubble Tea
-- Multi-line text editor with cursor navigation

local textarea = {}

-- Create a new textarea
function textarea.new()
    local self = {
        lines = {""},
        cursor = {row = 1, col = 0},
        viewport = {
            width = 80,
            height = 10,
            offsetX = 0,
            offsetY = 0
        },
        focused = false,
        lineNumbers = false,
        lineNumberWidth = 4,
        wrapLines = true,
        tabSize = 4,
        maxLines = 0, -- 0 = unlimited
        onChange = nil
    }
    
    -- Set content
    function self:setValue(value)
        if type(value) == "string" then
            self.lines = {}
            for line in (value .. "\n"):gmatch("([^\n]*)\n") do
                table.insert(self.lines, line)
            end
            if #self.lines == 0 then
                self.lines = {""}
            end
        elseif type(value) == "table" then
            self.lines = value
        end
        self:clampCursor()
        self:updateViewport()
        return self
    end
    
    -- Get content
    function self:getValue()
        return table.concat(self.lines, "\n")
    end
    
    -- Set viewport size
    function self:setSize(width, height)
        self.viewport.width = width
        self.viewport.height = height
        self:updateViewport()
        return self
    end
    
    -- Focus/blur
    function self:focus()
        self.focused = true
        return self
    end
    
    function self:blur()
        self.focused = false
        return self
    end
    
    -- Cursor movement
    function self:cursorUp()
        if self.cursor.row > 1 then
            self.cursor.row = self.cursor.row - 1
            self:clampCursor()
            self:updateViewport()
        end
    end
    
    function self:cursorDown()
        if self.cursor.row < #self.lines then
            self.cursor.row = self.cursor.row + 1
            self:clampCursor()
            self:updateViewport()
        end
    end
    
    function self:cursorLeft()
        if self.cursor.col > 0 then
            self.cursor.col = self.cursor.col - 1
        elseif self.cursor.row > 1 then
            self.cursor.row = self.cursor.row - 1
            self.cursor.col = #self.lines[self.cursor.row]
        end
        self:updateViewport()
    end
    
    function self:cursorRight()
        local line = self.lines[self.cursor.row]
        if self.cursor.col < #line then
            self.cursor.col = self.cursor.col + 1
        elseif self.cursor.row < #self.lines then
            self.cursor.row = self.cursor.row + 1
            self.cursor.col = 0
        end
        self:updateViewport()
    end
    
    function self:cursorLineStart()
        self.cursor.col = 0
        self:updateViewport()
    end
    
    function self:cursorLineEnd()
        self.cursor.col = #self.lines[self.cursor.row]
        self:updateViewport()
    end
    
    function self:cursorDocStart()
        self.cursor.row = 1
        self.cursor.col = 0
        self:updateViewport()
    end
    
    function self:cursorDocEnd()
        self.cursor.row = #self.lines
        self.cursor.col = #self.lines[self.cursor.row]
        self:updateViewport()
    end
    
    -- Text manipulation
    function self:insertChar(char)
        local line = self.lines[self.cursor.row]
        local before = line:sub(1, self.cursor.col)
        local after = line:sub(self.cursor.col + 1)
        self.lines[self.cursor.row] = before .. char .. after
        self.cursor.col = self.cursor.col + 1
        self:updateViewport()
        if self.onChange then self.onChange(self:getValue()) end
    end
    
    function self:insertNewline()
        if self.maxLines > 0 and #self.lines >= self.maxLines then
            return
        end
        
        local line = self.lines[self.cursor.row]
        local before = line:sub(1, self.cursor.col)
        local after = line:sub(self.cursor.col + 1)
        
        self.lines[self.cursor.row] = before
        table.insert(self.lines, self.cursor.row + 1, after)
        
        self.cursor.row = self.cursor.row + 1
        self.cursor.col = 0
        self:updateViewport()
        if self.onChange then self.onChange(self:getValue()) end
    end
    
    function self:insertTab()
        local spaces = string.rep(" ", self.tabSize)
        for i = 1, self.tabSize do
            self:insertChar(" ")
        end
    end
    
    function self:deleteBeforeCursor()
        if self.cursor.col > 0 then
            local line = self.lines[self.cursor.row]
            local before = line:sub(1, self.cursor.col - 1)
            local after = line:sub(self.cursor.col + 1)
            self.lines[self.cursor.row] = before .. after
            self.cursor.col = self.cursor.col - 1
        elseif self.cursor.row > 1 then
            -- Join with previous line
            local prevLine = self.lines[self.cursor.row - 1]
            local currLine = self.lines[self.cursor.row]
            self.cursor.col = #prevLine
            self.lines[self.cursor.row - 1] = prevLine .. currLine
            table.remove(self.lines, self.cursor.row)
            self.cursor.row = self.cursor.row - 1
        end
        self:updateViewport()
        if self.onChange then self.onChange(self:getValue()) end
    end
    
    function self:deleteAfterCursor()
        local line = self.lines[self.cursor.row]
        if self.cursor.col < #line then
            local before = line:sub(1, self.cursor.col)
            local after = line:sub(self.cursor.col + 2)
            self.lines[self.cursor.row] = before .. after
        elseif self.cursor.row < #self.lines then
            -- Join with next line
            local nextLine = self.lines[self.cursor.row + 1]
            self.lines[self.cursor.row] = line .. nextLine
            table.remove(self.lines, self.cursor.row + 1)
        end
        if self.onChange then self.onChange(self:getValue()) end
    end
    
    function self:deleteCurrentLine()
        if #self.lines > 1 then
            table.remove(self.lines, self.cursor.row)
            if self.cursor.row > #self.lines then
                self.cursor.row = #self.lines
            end
        else
            self.lines[1] = ""
        end
        self.cursor.col = 0
        self:updateViewport()
        if self.onChange then self.onChange(self:getValue()) end
    end
    
    -- Helper methods
    function self:clampCursor()
        if self.cursor.row < 1 then
            self.cursor.row = 1
        elseif self.cursor.row > #self.lines then
            self.cursor.row = #self.lines
        end
        
        local lineLen = #self.lines[self.cursor.row]
        if self.cursor.col < 0 then
            self.cursor.col = 0
        elseif self.cursor.col > lineLen then
            self.cursor.col = lineLen
        end
    end
    
    function self:updateViewport()
        -- Vertical scrolling
        if self.cursor.row < self.viewport.offsetY + 1 then
            self.viewport.offsetY = self.cursor.row - 1
        elseif self.cursor.row > self.viewport.offsetY + self.viewport.height then
            self.viewport.offsetY = self.cursor.row - self.viewport.height
        end
        
        -- Horizontal scrolling
        local effectiveWidth = self.viewport.width
        if self.lineNumbers then
            effectiveWidth = effectiveWidth - self.lineNumberWidth - 1
        end
        
        if self.cursor.col < self.viewport.offsetX then
            self.viewport.offsetX = self.cursor.col
        elseif self.cursor.col >= self.viewport.offsetX + effectiveWidth then
            self.viewport.offsetX = self.cursor.col - effectiveWidth + 1
        end
    end
    
    -- Update method for Bubble Tea
    function self:update(msg)
        if not self.focused then
            return self
        end
        
        if msg.type == "key" then
            if msg.key == "up" then
                self:cursorUp()
            elseif msg.key == "down" then
                self:cursorDown()
            elseif msg.key == "left" then
                self:cursorLeft()
            elseif msg.key == "right" then
                self:cursorRight()
            elseif msg.key == "home" then
                self:cursorLineStart()
            elseif msg.key == "end" then
                self:cursorLineEnd()
            elseif msg.key == "ctrl+home" then
                self:cursorDocStart()
            elseif msg.key == "ctrl+end" then
                self:cursorDocEnd()
            elseif msg.key == "enter" then
                self:insertNewline()
            elseif msg.key == "tab" then
                self:insertTab()
            elseif msg.key == "backspace" then
                self:deleteBeforeCursor()
            elseif msg.key == "delete" then
                self:deleteAfterCursor()
            elseif msg.key == "ctrl+k" then
                self:deleteCurrentLine()
            elseif #msg.key == 1 and msg.key:match("[%g ]") then
                self:insertChar(msg.key)
            end
        elseif msg.type == "window_size" then
            self:setSize(msg.width, msg.height)
        end
        
        return self
    end
    
    -- View method for Bubble Tea
    function self:view()
        local output = {}
        local endRow = math.min(self.viewport.offsetY + self.viewport.height, #self.lines)
        
        for i = self.viewport.offsetY + 1, endRow do
            local line = self.lines[i]
            local displayLine = ""
            
            -- Add line numbers if enabled
            if self.lineNumbers then
                local lineNum = string.format("%" .. (self.lineNumberWidth - 1) .. "d ", i)
                displayLine = lineNum .. "│"
            end
            
            -- Get visible portion of line
            local effectiveWidth = self.viewport.width
            if self.lineNumbers then
                effectiveWidth = effectiveWidth - self.lineNumberWidth - 1
            end
            
            local visibleLine = line
            if self.viewport.offsetX > 0 then
                visibleLine = line:sub(self.viewport.offsetX + 1)
            end
            
            -- Add cursor if on this line and focused
            if self.focused and i == self.cursor.row then
                local cursorCol = self.cursor.col - self.viewport.offsetX
                if cursorCol >= 0 and cursorCol <= effectiveWidth then
                    local before = visibleLine:sub(1, cursorCol)
                    local after = visibleLine:sub(cursorCol + 1)
                    local atCursor = visibleLine:sub(cursorCol + 1, cursorCol + 1)
                    if atCursor == "" then atCursor = " " end
                    visibleLine = before .. "█" .. after:sub(2)
                end
            end
            
            -- Truncate to width
            if #visibleLine > effectiveWidth then
                visibleLine = visibleLine:sub(1, effectiveWidth)
            end
            
            displayLine = displayLine .. visibleLine
            table.insert(output, displayLine)
        end
        
        -- Pad with empty lines if needed
        while #output < self.viewport.height do
            local emptyLine = ""
            if self.lineNumbers then
                emptyLine = string.rep(" ", self.lineNumberWidth) .. "│"
            end
            table.insert(output, emptyLine)
        end
        
        return table.concat(output, "\n")
    end
    
    return self
end

-- Model for simple textarea
function textarea.model()
    return textarea.new()
end

-- Update function for simple textarea
function textarea.update(model, msg)
    return model:update(msg), nil
end

-- View function for simple textarea
function textarea.view(model)
    return model:view()
end

return textarea