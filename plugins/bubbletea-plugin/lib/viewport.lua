-- Viewport component for Bubble Tea
-- Scrollable viewport for displaying content larger than the terminal

local viewport = {}

-- Create a new viewport
function viewport.new(width, height)
    local self = {
        width = width or 80,
        height = height or 24,
        content = "",
        lines = {},
        yOffset = 0,
        xOffset = 0,
        wrapText = true,
        mouseWheelEnabled = true,
        keyMap = {
            up = {"k", "up"},
            down = {"j", "down"},
            halfPageUp = {"ctrl+u"},
            halfPageDown = {"ctrl+d"},
            pageUp = {"b", "pgup"},
            pageDown = {"f", "pgdown"},
            top = {"g", "home"},
            bottom = {"G", "end"}
        }
    }
    
    -- Set content
    function self:setContent(content)
        self.content = content
        self:updateLines()
        return self
    end
    
    -- Update internal line representation
    function self:updateLines()
        self.lines = {}
        if self.wrapText then
            -- Word wrap implementation
            for line in self.content:gmatch("[^\n]+") do
                if #line <= self.width then
                    table.insert(self.lines, line)
                else
                    -- Simple word wrap
                    local currentLine = ""
                    for word in line:gmatch("%S+") do
                        if #currentLine + #word + 1 <= self.width then
                            currentLine = currentLine == "" and word or currentLine .. " " .. word
                        else
                            if currentLine ~= "" then
                                table.insert(self.lines, currentLine)
                            end
                            currentLine = word
                        end
                    end
                    if currentLine ~= "" then
                        table.insert(self.lines, currentLine)
                    end
                end
            end
        else
            -- No wrapping, just split by newlines
            for line in self.content:gmatch("[^\n]*") do
                table.insert(self.lines, line)
            end
        end
    end
    
    -- Get visible lines
    function self:visibleLines()
        local visible = {}
        local endLine = math.min(self.yOffset + self.height, #self.lines)
        
        for i = self.yOffset + 1, endLine do
            local line = self.lines[i] or ""
            -- Handle horizontal scrolling
            if self.xOffset > 0 and #line > self.xOffset then
                line = line:sub(self.xOffset + 1)
            elseif self.xOffset > 0 then
                line = ""
            end
            -- Truncate to width
            if #line > self.width then
                line = line:sub(1, self.width)
            end
            table.insert(visible, line)
        end
        
        return visible
    end
    
    -- Scroll methods
    function self:lineUp(n)
        n = n or 1
        self.yOffset = math.max(0, self.yOffset - n)
    end
    
    function self:lineDown(n)
        n = n or 1
        local maxOffset = math.max(0, #self.lines - self.height)
        self.yOffset = math.min(maxOffset, self.yOffset + n)
    end
    
    function self:halfPageUp()
        self:lineUp(math.floor(self.height / 2))
    end
    
    function self:halfPageDown()
        self:lineDown(math.floor(self.height / 2))
    end
    
    function self:pageUp()
        self:lineUp(self.height - 1)
    end
    
    function self:pageDown()
        self:lineDown(self.height - 1)
    end
    
    function self:gotoTop()
        self.yOffset = 0
    end
    
    function self:gotoBottom()
        self.yOffset = math.max(0, #self.lines - self.height)
    end
    
    -- Handle scrolling by percentage
    function self:setYOffset(offset)
        local maxOffset = math.max(0, #self.lines - self.height)
        self.yOffset = math.max(0, math.min(maxOffset, offset))
    end
    
    function self:setXOffset(offset)
        self.xOffset = math.max(0, offset)
    end
    
    -- Get scroll percentage
    function self:scrollPercent()
        if #self.lines <= self.height then
            return 100
        end
        local maxOffset = #self.lines - self.height
        return math.floor((self.yOffset / maxOffset) * 100)
    end
    
    -- Resize viewport
    function self:resize(width, height)
        self.width = width
        self.height = height
        self:updateLines()
        -- Adjust offset if needed
        local maxOffset = math.max(0, #self.lines - self.height)
        self.yOffset = math.min(self.yOffset, maxOffset)
    end
    
    -- Update method for Bubble Tea
    function self:update(msg)
        if msg.type == "key" then
            -- Handle key events
            for action, keys in pairs(self.keyMap) do
                for _, key in ipairs(keys) do
                    if msg.key == key then
                        if action == "up" then
                            self:lineUp()
                        elseif action == "down" then
                            self:lineDown()
                        elseif action == "halfPageUp" then
                            self:halfPageUp()
                        elseif action == "halfPageDown" then
                            self:halfPageDown()
                        elseif action == "pageUp" then
                            self:pageUp()
                        elseif action == "pageDown" then
                            self:pageDown()
                        elseif action == "top" then
                            self:gotoTop()
                        elseif action == "bottom" then
                            self:gotoBottom()
                        end
                        return self
                    end
                end
            end
        elseif msg.type == "mouse" and self.mouseWheelEnabled then
            -- Handle mouse wheel
            if msg.button == "wheel_up" then
                self:lineUp(3)
                return self
            elseif msg.button == "wheel_down" then
                self:lineDown(3)
                return self
            end
        elseif msg.type == "window_size" then
            -- Handle resize
            self:resize(msg.width, msg.height)
            return self
        end
        
        return self
    end
    
    -- View method for Bubble Tea
    function self:view()
        local lines = self:visibleLines()
        local output = table.concat(lines, "\n")
        
        -- Pad with empty lines if needed
        local lineCount = #lines
        if lineCount < self.height then
            for i = lineCount + 1, self.height do
                output = output .. "\n"
            end
        end
        
        return output
    end
    
    -- Get viewport info for status bars
    function self:info()
        return {
            scrollPercent = self:scrollPercent(),
            totalLines = #self.lines,
            visibleLines = math.min(self.height, #self.lines),
            yOffset = self.yOffset,
            xOffset = self.xOffset,
            atTop = self.yOffset == 0,
            atBottom = self.yOffset >= math.max(0, #self.lines - self.height)
        }
    end
    
    return self
end

-- Model for simple viewport usage
function viewport.model(content, width, height)
    local vp = viewport.new(width, height)
    vp:setContent(content)
    return vp
end

-- Update function for simple viewport
function viewport.update(model, msg)
    return model:update(msg), nil
end

-- View function for simple viewport
function viewport.view(model)
    return model:view()
end

return viewport