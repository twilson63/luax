-- Text input component for Bubble Tea
-- Single-line text input with cursor and editing capabilities

local textinput = {}

-- Create a new text input
function textinput.new()
    local self = {
        value = "",
        placeholder = "",
        cursor = 0,
        offset = 0,
        width = 0,
        echoMode = "normal", -- normal, password, none
        echoChar = "•",
        charLimit = 0, -- 0 = no limit
        validate = nil, -- validation function
        focused = false,
        cursorStyle = {
            blink = true,
            char = "█",
            blinkSpeed = 530 -- milliseconds
        },
        lastBlink = 0,
        cursorVisible = true
    }
    
    -- Set the value
    function self:setValue(value)
        self.value = value or ""
        if self.charLimit > 0 and #self.value > self.charLimit then
            self.value = self.value:sub(1, self.charLimit)
        end
        self.cursor = #self.value
        self:updateOffset()
        return self
    end
    
    -- Get the value
    function self:getValue()
        return self.value
    end
    
    -- Set placeholder
    function self:setPlaceholder(placeholder)
        self.placeholder = placeholder or ""
        return self
    end
    
    -- Set width
    function self:setWidth(width)
        self.width = width
        self:updateOffset()
        return self
    end
    
    -- Set echo mode
    function self:setEchoMode(mode)
        if mode == "normal" or mode == "password" or mode == "none" then
            self.echoMode = mode
        end
        return self
    end
    
    -- Set character limit
    function self:setCharLimit(limit)
        self.charLimit = limit or 0
        if self.charLimit > 0 and #self.value > self.charLimit then
            self.value = self.value:sub(1, self.charLimit)
            if self.cursor > #self.value then
                self.cursor = #self.value
            end
        end
        return self
    end
    
    -- Set validation function
    function self:setValidate(fn)
        self.validate = fn
        return self
    end
    
    -- Focus/blur
    function self:focus()
        self.focused = true
        self.cursorVisible = true
        self.lastBlink = os.clock() * 1000
        return self
    end
    
    function self:blur()
        self.focused = false
        return self
    end
    
    -- Cursor movement
    function self:cursorLeft()
        if self.cursor > 0 then
            self.cursor = self.cursor - 1
            self:updateOffset()
        end
    end
    
    function self:cursorRight()
        if self.cursor < #self.value then
            self.cursor = self.cursor + 1
            self:updateOffset()
        end
    end
    
    function self:cursorStart()
        self.cursor = 0
        self:updateOffset()
    end
    
    function self:cursorEnd()
        self.cursor = #self.value
        self:updateOffset()
    end
    
    -- Text manipulation
    function self:insertRune(char)
        if self.charLimit > 0 and #self.value >= self.charLimit then
            return
        end
        
        local before = self.value:sub(1, self.cursor)
        local after = self.value:sub(self.cursor + 1)
        local newValue = before .. char .. after
        
        -- Validate if validator is set
        if self.validate and not self.validate(newValue) then
            return
        end
        
        self.value = newValue
        self.cursor = self.cursor + 1
        self:updateOffset()
    end
    
    function self:deleteBeforeCursor()
        if self.cursor > 0 then
            local before = self.value:sub(1, self.cursor - 1)
            local after = self.value:sub(self.cursor + 1)
            self.value = before .. after
            self.cursor = self.cursor - 1
            self:updateOffset()
        end
    end
    
    function self:deleteAfterCursor()
        if self.cursor < #self.value then
            local before = self.value:sub(1, self.cursor)
            local after = self.value:sub(self.cursor + 2)
            self.value = before .. after
        end
    end
    
    function self:deleteWordBeforeCursor()
        if self.cursor == 0 then return end
        
        local before = self.value:sub(1, self.cursor)
        local after = self.value:sub(self.cursor + 1)
        
        -- Find word boundary
        local pos = self.cursor
        -- Skip spaces
        while pos > 0 and before:sub(pos, pos):match("%s") do
            pos = pos - 1
        end
        -- Skip word characters
        while pos > 0 and not before:sub(pos, pos):match("%s") do
            pos = pos - 1
        end
        
        self.value = before:sub(1, pos) .. after
        self.cursor = pos
        self:updateOffset()
    end
    
    function self:clear()
        self.value = ""
        self.cursor = 0
        self.offset = 0
    end
    
    -- Update visible offset
    function self:updateOffset()
        if self.width <= 0 then
            self.offset = 0
            return
        end
        
        -- Ensure cursor is visible
        if self.cursor < self.offset then
            self.offset = self.cursor
        elseif self.cursor >= self.offset + self.width then
            self.offset = self.cursor - self.width + 1
        end
    end
    
    -- Get display value
    function self:displayValue()
        if self.echoMode == "none" then
            return ""
        elseif self.echoMode == "password" then
            return string.rep(self.echoChar, #self.value)
        else
            return self.value
        end
    end
    
    -- Update method for Bubble Tea
    function self:update(msg)
        if not self.focused then
            return self
        end
        
        if msg.type == "key" then
            if msg.key == "left" then
                self:cursorLeft()
            elseif msg.key == "right" then
                self:cursorRight()
            elseif msg.key == "home" or msg.key == "ctrl+a" then
                self:cursorStart()
            elseif msg.key == "end" or msg.key == "ctrl+e" then
                self:cursorEnd()
            elseif msg.key == "backspace" then
                self:deleteBeforeCursor()
            elseif msg.key == "delete" then
                self:deleteAfterCursor()
            elseif msg.key == "ctrl+w" then
                self:deleteWordBeforeCursor()
            elseif msg.key == "ctrl+k" then
                -- Delete to end of line
                self.value = self.value:sub(1, self.cursor)
            elseif msg.key == "ctrl+u" then
                -- Delete to beginning of line
                self.value = self.value:sub(self.cursor + 1)
                self.cursor = 0
                self:updateOffset()
            elseif #msg.key == 1 and msg.key:match("[%g ]") then
                -- Printable character
                self:insertRune(msg.key)
            end
        elseif msg.type == "tick" and self.cursorStyle.blink then
            -- Handle cursor blinking
            local now = os.clock() * 1000
            if now - self.lastBlink >= self.cursorStyle.blinkSpeed then
                self.cursorVisible = not self.cursorVisible
                self.lastBlink = now
            end
        end
        
        return self
    end
    
    -- View method for Bubble Tea
    function self:view()
        local displayVal = self:displayValue()
        local output = ""
        
        if self.width > 0 then
            -- Apply offset and width limit
            local visibleVal = displayVal:sub(self.offset + 1, self.offset + self.width)
            
            if self.focused then
                -- Show cursor
                local cursorPos = self.cursor - self.offset
                if cursorPos >= 0 and cursorPos <= self.width then
                    local before = visibleVal:sub(1, cursorPos)
                    local after = visibleVal:sub(cursorPos + 1)
                    local cursorChar = self.cursorVisible and self.cursorStyle.char or " "
                    
                    -- Handle cursor at end
                    if cursorPos == #visibleVal then
                        output = before .. cursorChar
                    else
                        local atCursor = visibleVal:sub(cursorPos + 1, cursorPos + 1)
                        if atCursor == "" then atCursor = " " end
                        output = before .. cursorChar .. after
                    end
                else
                    output = visibleVal
                end
            else
                output = visibleVal
            end
            
            -- Pad to width
            if #output < self.width then
                output = output .. string.rep(" ", self.width - #output)
            end
        else
            -- No width limit
            if self.focused and self.cursorVisible then
                local before = displayVal:sub(1, self.cursor)
                local after = displayVal:sub(self.cursor + 1)
                output = before .. self.cursorStyle.char .. after
            else
                output = displayVal
            end
        end
        
        -- Show placeholder if empty and not focused
        if #self.value == 0 and not self.focused and #self.placeholder > 0 then
            output = self.placeholder
            if self.width > 0 and #output > self.width then
                output = output:sub(1, self.width)
            end
        end
        
        return output
    end
    
    return self
end

-- Model for simple text input
function textinput.model()
    return textinput.new()
end

-- Update function for simple text input
function textinput.update(model, msg)
    return model:update(msg), nil
end

-- View function for simple text input
function textinput.view(model)
    return model:view()
end

return textinput