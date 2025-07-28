-- Style module for Bubble Tea (Lip Gloss inspired)
-- Terminal styling with a fluent API

local style = {}

-- ANSI color codes
local colors = {
    -- Basic colors
    black = 30,
    red = 31,
    green = 32,
    yellow = 33,
    blue = 34,
    magenta = 35,
    cyan = 36,
    white = 37,
    
    -- Bright colors
    brightBlack = 90,
    brightRed = 91,
    brightGreen = 92,
    brightYellow = 93,
    brightBlue = 94,
    brightMagenta = 95,
    brightCyan = 96,
    brightWhite = 97,
    
    -- Reset
    reset = 0
}

-- Create a new style
function style.new()
    local self = {
        fg = nil,
        bg = nil,
        bold = false,
        italic = false,
        underline = false,
        strikethrough = false,
        reverse = false,
        blink = false,
        faint = false,
        
        paddingTop = 0,
        paddingRight = 0,
        paddingBottom = 0,
        paddingLeft = 0,
        
        marginTop = 0,
        marginRight = 0,
        marginBottom = 0,
        marginLeft = 0,
        
        borderStyle = nil,
        borderTop = false,
        borderRight = false,
        borderBottom = false,
        borderLeft = false,
        borderFg = nil,
        borderBg = nil,
        
        width = 0,
        height = 0,
        maxWidth = 0,
        maxHeight = 0,
        
        align = nil, -- left, center, right
        valign = nil -- top, middle, bottom
    }
    
    -- Foreground color
    function self:foreground(color)
        self.fg = color
        return self
    end
    
    -- Background color
    function self:background(color)
        self.bg = color
        return self
    end
    
    -- Text decorations
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
    
    function self:setReverse(enabled)
        self.reverse = enabled ~= false
        return self
    end
    
    function self:setBlink(enabled)
        self.blink = enabled ~= false
        return self
    end
    
    function self:setFaint(enabled)
        self.faint = enabled ~= false
        return self
    end
    
    -- Padding
    function self:padding(top, right, bottom, left)
        if type(top) == "number" and right == nil then
            -- Single value for all sides
            self.paddingTop = top
            self.paddingRight = top
            self.paddingBottom = top
            self.paddingLeft = top
        elseif bottom == nil then
            -- Vertical, horizontal
            self.paddingTop = top
            self.paddingBottom = top
            self.paddingRight = right
            self.paddingLeft = right
        else
            -- All four sides
            self.paddingTop = top
            self.paddingRight = right
            self.paddingBottom = bottom
            self.paddingLeft = left
        end
        return self
    end
    
    function self:paddingX(value)
        self.paddingLeft = value
        self.paddingRight = value
        return self
    end
    
    function self:paddingY(value)
        self.paddingTop = value
        self.paddingBottom = value
        return self
    end
    
    -- Margin
    function self:margin(top, right, bottom, left)
        if type(top) == "number" and right == nil then
            self.marginTop = top
            self.marginRight = top
            self.marginBottom = top
            self.marginLeft = top
        elseif bottom == nil then
            self.marginTop = top
            self.marginBottom = top
            self.marginRight = right
            self.marginLeft = right
        else
            self.marginTop = top
            self.marginRight = right
            self.marginBottom = bottom
            self.marginLeft = left
        end
        return self
    end
    
    function self:marginX(value)
        self.marginLeft = value
        self.marginRight = value
        return self
    end
    
    function self:marginY(value)
        self.marginTop = value
        self.marginBottom = value
        return self
    end
    
    -- Border
    function self:border(style, top, right, bottom, left)
        self.borderStyle = style or "normal"
        if top == nil then
            self.borderTop = true
            self.borderRight = true
            self.borderBottom = true
            self.borderLeft = true
        else
            self.borderTop = top
            self.borderRight = right
            self.borderBottom = bottom
            self.borderLeft = left
        end
        return self
    end
    
    function self:borderForeground(color)
        self.borderFg = color
        return self
    end
    
    function self:borderBackground(color)
        self.borderBg = color
        return self
    end
    
    -- Dimensions
    function self:setWidth(width)
        self.width = width
        return self
    end
    
    function self:setHeight(height)
        self.height = height
        return self
    end
    
    function self:setMaxWidth(width)
        self.maxWidth = width
        return self
    end
    
    function self:setMaxHeight(height)
        self.maxHeight = height
        return self
    end
    
    -- Alignment
    function self:setAlign(align)
        self.align = align
        return self
    end
    
    function self:setVerticalAlign(align)
        self.valign = align
        return self
    end
    
    -- Copy style
    function self:copy()
        local new = style.new()
        for k, v in pairs(self) do
            if type(v) ~= "function" then
                new[k] = v
            end
        end
        return new
    end
    
    -- Inherit from another style
    function self:inherit(other)
        for k, v in pairs(other) do
            if type(v) ~= "function" and k ~= "inherit" and k ~= "copy" then
                self[k] = v
            end
        end
        return self
    end
    
    -- Render text with style
    function self:render(text)
        -- Apply ANSI escape codes
        local codes = {}
        
        -- Text attributes
        if self.bold then table.insert(codes, "1") end
        if self.faint then table.insert(codes, "2") end
        if self.italic then table.insert(codes, "3") end
        if self.underline then table.insert(codes, "4") end
        if self.blink then table.insert(codes, "5") end
        if self.reverse then table.insert(codes, "7") end
        if self.strikethrough then table.insert(codes, "9") end
        
        -- Colors
        if self.fg then
            if type(self.fg) == "string" and colors[self.fg] then
                table.insert(codes, tostring(colors[self.fg]))
            elseif type(self.fg) == "number" then
                table.insert(codes, string.format("38;5;%d", self.fg))
            end
        end
        
        if self.bg then
            if type(self.bg) == "string" and colors[self.bg] then
                table.insert(codes, tostring(colors[self.bg] + 10))
            elseif type(self.bg) == "number" then
                table.insert(codes, string.format("48;5;%d", self.bg))
            end
        end
        
        -- Apply text styling
        local styled = text
        if #codes > 0 then
            styled = string.format("\027[%sm%s\027[0m", table.concat(codes, ";"), text)
        end
        
        -- Apply padding
        styled = self:applyPadding(styled)
        
        -- Apply border
        styled = self:applyBorder(styled)
        
        -- Apply margin
        styled = self:applyMargin(styled)
        
        -- Apply dimensions
        styled = self:applyDimensions(styled)
        
        return styled
    end
    
    -- Apply padding
    function self:applyPadding(text)
        if self.paddingTop == 0 and self.paddingRight == 0 and 
           self.paddingBottom == 0 and self.paddingLeft == 0 then
            return text
        end
        
        local lines = {}
        for line in (text .. "\n"):gmatch("(.-)\n") do
            table.insert(lines, line)
        end
        
        -- Add padding
        local padded = {}
        
        -- Top padding
        for i = 1, self.paddingTop do
            table.insert(padded, "")
        end
        
        -- Content with left/right padding
        for _, line in ipairs(lines) do
            local paddedLine = string.rep(" ", self.paddingLeft) .. 
                              line .. 
                              string.rep(" ", self.paddingRight)
            table.insert(padded, paddedLine)
        end
        
        -- Bottom padding
        for i = 1, self.paddingBottom do
            table.insert(padded, "")
        end
        
        return table.concat(padded, "\n")
    end
    
    -- Apply border
    function self:applyBorder(text)
        if not self.borderStyle then
            return text
        end
        
        -- Border characters
        local borders = {
            normal = {
                top = "─", bottom = "─", left = "│", right = "│",
                topLeft = "┌", topRight = "┐", bottomLeft = "└", bottomRight = "┘"
            },
            rounded = {
                top = "─", bottom = "─", left = "│", right = "│",
                topLeft = "╭", topRight = "╮", bottomLeft = "╰", bottomRight = "╯"
            },
            double = {
                top = "═", bottom = "═", left = "║", right = "║",
                topLeft = "╔", topRight = "╗", bottomLeft = "╚", bottomRight = "╝"
            },
            thick = {
                top = "━", bottom = "━", left = "┃", right = "┃",
                topLeft = "┏", topRight = "┓", bottomLeft = "┗", bottomRight = "┛"
            }
        }
        
        local border = borders[self.borderStyle] or borders.normal
        
        local lines = {}
        for line in (text .. "\n"):gmatch("(.-)\n") do
            table.insert(lines, line)
        end
        
        -- Calculate max width
        local maxWidth = 0
        for _, line in ipairs(lines) do
            maxWidth = math.max(maxWidth, #line)
        end
        
        local bordered = {}
        
        -- Top border
        if self.borderTop then
            local top = ""
            if self.borderLeft then top = top .. border.topLeft end
            top = top .. string.rep(border.top, maxWidth)
            if self.borderRight then top = top .. border.topRight end
            table.insert(bordered, top)
        end
        
        -- Content with side borders
        for _, line in ipairs(lines) do
            local borderedLine = ""
            if self.borderLeft then borderedLine = borderedLine .. border.left end
            borderedLine = borderedLine .. line .. string.rep(" ", maxWidth - #line)
            if self.borderRight then borderedLine = borderedLine .. border.right end
            table.insert(bordered, borderedLine)
        end
        
        -- Bottom border
        if self.borderBottom then
            local bottom = ""
            if self.borderLeft then bottom = bottom .. border.bottomLeft end
            bottom = bottom .. string.rep(border.bottom, maxWidth)
            if self.borderRight then bottom = bottom .. border.bottomRight end
            table.insert(bordered, bottom)
        end
        
        return table.concat(bordered, "\n")
    end
    
    -- Apply margin
    function self:applyMargin(text)
        if self.marginTop == 0 and self.marginBottom == 0 and
           self.marginLeft == 0 and self.marginRight == 0 then
            return text
        end
        
        local lines = {}
        for line in (text .. "\n"):gmatch("(.-)\n") do
            table.insert(lines, line)
        end
        
        local margined = {}
        
        -- Top margin
        for i = 1, self.marginTop do
            table.insert(margined, "")
        end
        
        -- Content with left margin
        for _, line in ipairs(lines) do
            table.insert(margined, string.rep(" ", self.marginLeft) .. line)
        end
        
        -- Bottom margin
        for i = 1, self.marginBottom do
            table.insert(margined, "")
        end
        
        return table.concat(margined, "\n")
    end
    
    -- Apply dimensions and alignment
    function self:applyDimensions(text)
        if self.width == 0 and self.height == 0 and 
           self.maxWidth == 0 and self.maxHeight == 0 then
            return text
        end
        
        local lines = {}
        for line in (text .. "\n"):gmatch("(.-)\n") do
            table.insert(lines, line)
        end
        
        -- Apply width constraints
        if self.width > 0 or self.maxWidth > 0 then
            local targetWidth = self.width
            if self.maxWidth > 0 then
                local maxLen = 0
                for _, line in ipairs(lines) do
                    maxLen = math.max(maxLen, #line)
                end
                if targetWidth == 0 or targetWidth > self.maxWidth then
                    targetWidth = math.min(maxLen, self.maxWidth)
                end
            end
            
            if targetWidth > 0 then
                for i, line in ipairs(lines) do
                    if #line > targetWidth then
                        -- Truncate
                        lines[i] = line:sub(1, targetWidth)
                    elseif #line < targetWidth then
                        -- Pad based on alignment
                        local padding = targetWidth - #line
                        if self.align == "center" then
                            local leftPad = math.floor(padding / 2)
                            local rightPad = padding - leftPad
                            lines[i] = string.rep(" ", leftPad) .. line .. string.rep(" ", rightPad)
                        elseif self.align == "right" then
                            lines[i] = string.rep(" ", padding) .. line
                        else -- left align
                            lines[i] = line .. string.rep(" ", padding)
                        end
                    end
                end
            end
        end
        
        -- Apply height constraints
        if self.height > 0 then
            if #lines < self.height then
                -- Add empty lines
                local emptyLines = self.height - #lines
                if self.valign == "middle" then
                    local topLines = math.floor(emptyLines / 2)
                    local bottomLines = emptyLines - topLines
                    for i = 1, topLines do
                        table.insert(lines, 1, "")
                    end
                    for i = 1, bottomLines do
                        table.insert(lines, "")
                    end
                elseif self.valign == "bottom" then
                    for i = 1, emptyLines do
                        table.insert(lines, 1, "")
                    end
                else -- top align
                    for i = 1, emptyLines do
                        table.insert(lines, "")
                    end
                end
            elseif #lines > self.height then
                -- Truncate
                local newLines = {}
                for i = 1, self.height do
                    newLines[i] = lines[i]
                end
                lines = newLines
            end
        end
        
        return table.concat(lines, "\n")
    end
    
    return self
end

-- Preset styles
style.presets = {
    error = function()
        return style.new()
            :foreground("red")
            :setBold(true)
    end,
    
    success = function()
        return style.new()
            :foreground("green")
    end,
    
    warning = function()
        return style.new()
            :foreground("yellow")
    end,
    
    info = function()
        return style.new()
            :foreground("blue")
    end,
    
    muted = function()
        return style.new()
            :foreground("brightBlack")
    end,
    
    highlight = function()
        return style.new()
            :background("yellow")
            :foreground("black")
    end,
    
    code = function()
        return style.new()
            :background("brightBlack")
            :padding(0, 1, 0, 1)
    end,
    
    bordered = function()
        return style.new()
            :border("normal")
            :padding(1)
    end,
    
    rounded = function()
        return style.new()
            :border("rounded")
            :padding(1)
    end
}

-- Helper functions
function style.red(text)
    return style.new():foreground("red"):render(text)
end

function style.green(text)
    return style.new():foreground("green"):render(text)
end

function style.yellow(text)
    return style.new():foreground("yellow"):render(text)
end

function style.blue(text)
    return style.new():foreground("blue"):render(text)
end

function style.bold(text)
    return style.new():setBold(true):render(text)
end

function style.italic(text)
    return style.new():setItalic(true):render(text)
end

function style.underline(text)
    return style.new():setUnderline(true):render(text)
end

return style