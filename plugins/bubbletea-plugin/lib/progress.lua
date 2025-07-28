-- Progress bar component for Bubble Tea
-- Customizable progress indicator

local progress = {}

-- Create a new progress bar
function progress.new(total)
    local self = {
        current = 0,
        total = total or 100,
        width = 40,
        showPercentage = true,
        showNumbers = false,
        fillChar = "█",
        emptyChar = "░",
        fillEmptyChar = "▒",
        leftBracket = "[",
        rightBracket = "]",
        fillColor = nil,
        emptyColor = nil,
        percentageColor = nil
    }
    
    -- Set current progress
    function self:setCurrent(value)
        self.current = math.max(0, math.min(value, self.total))
        return self
    end
    
    -- Set total
    function self:setTotal(value)
        self.total = math.max(1, value)
        self.current = math.min(self.current, self.total)
        return self
    end
    
    -- Increment progress
    function self:increment(amount)
        amount = amount or 1
        self:setCurrent(self.current + amount)
        return self
    end
    
    -- Set width
    function self:setWidth(width)
        self.width = math.max(3, width)
        return self
    end
    
    -- Set style
    function self:setStyle(options)
        if options.fillChar then self.fillChar = options.fillChar end
        if options.emptyChar then self.emptyChar = options.emptyChar end
        if options.fillEmptyChar then self.fillEmptyChar = options.fillEmptyChar end
        if options.leftBracket then self.leftBracket = options.leftBracket end
        if options.rightBracket then self.rightBracket = options.rightBracket end
        if options.showPercentage ~= nil then self.showPercentage = options.showPercentage end
        if options.showNumbers ~= nil then self.showNumbers = options.showNumbers end
        return self
    end
    
    -- Get percentage
    function self:percentage()
        if self.total == 0 then return 0 end
        return math.floor((self.current / self.total) * 100)
    end
    
    -- Get progress ratio
    function self:ratio()
        if self.total == 0 then return 0 end
        return self.current / self.total
    end
    
    -- Check if complete
    function self:isComplete()
        return self.current >= self.total
    end
    
    -- Update method for Bubble Tea
    function self:update(msg)
        if msg.type == "progress_set" then
            self:setCurrent(msg.value)
        elseif msg.type == "progress_increment" then
            self:increment(msg.amount)
        elseif msg.type == "window_size" then
            -- Adjust width based on window size if needed
            if msg.width < self.width + 10 then
                self.width = math.max(10, msg.width - 10)
            end
        end
        
        return self
    end
    
    -- View method for Bubble Tea
    function self:view()
        local parts = {}
        
        -- Calculate filled width
        local ratio = self:ratio()
        local filledWidth = math.floor(self.width * ratio)
        local emptyWidth = self.width - filledWidth
        
        -- Build progress bar
        table.insert(parts, self.leftBracket)
        
        -- Filled portion
        if filledWidth > 0 then
            table.insert(parts, string.rep(self.fillChar, filledWidth))
        end
        
        -- Transition character (partially filled)
        if emptyWidth > 0 and filledWidth < self.width and self.fillEmptyChar then
            -- Use a special character for the partially filled position
            if ratio > 0 and ratio < 1 then
                table.insert(parts, self.fillEmptyChar)
                emptyWidth = emptyWidth - 1
            end
        end
        
        -- Empty portion
        if emptyWidth > 0 then
            table.insert(parts, string.rep(self.emptyChar, emptyWidth))
        end
        
        table.insert(parts, self.rightBracket)
        
        -- Add percentage
        if self.showPercentage then
            table.insert(parts, string.format(" %3d%%", self:percentage()))
        end
        
        -- Add numbers
        if self.showNumbers then
            table.insert(parts, string.format(" (%d/%d)", self.current, self.total))
        end
        
        return table.concat(parts)
    end
    
    return self
end

-- Preset styles
progress.styles = {
    default = {
        fillChar = "█",
        emptyChar = "░",
        fillEmptyChar = "▒"
    },
    ascii = {
        fillChar = "#",
        emptyChar = "-",
        fillEmptyChar = nil,
        leftBracket = "[",
        rightBracket = "]"
    },
    dots = {
        fillChar = "●",
        emptyChar = "○",
        fillEmptyChar = "◐"
    },
    blocks = {
        fillChar = "■",
        emptyChar = "□",
        fillEmptyChar = "▣"
    },
    arrows = {
        fillChar = "▶",
        emptyChar = "▷",
        fillEmptyChar = nil
    },
    lines = {
        fillChar = "━",
        emptyChar = "─",
        fillEmptyChar = nil,
        leftBracket = "",
        rightBracket = ""
    }
}

-- Create progress with preset style
function progress.withStyle(total, styleName)
    local p = progress.new(total)
    local style = progress.styles[styleName] or progress.styles.default
    p:setStyle(style)
    return p
end

-- Model for simple progress
function progress.model(total)
    return progress.new(total)
end

-- Update function
function progress.update(model, msg)
    return model:update(msg), nil
end

-- View function
function progress.view(model)
    return model:view()
end

-- Helper for percentage-based progress
function progress.percentage(percent)
    local p = progress.new(100)
    p:setCurrent(percent)
    return p
end

-- Helper for file/download progress
function progress.download(currentBytes, totalBytes)
    local p = progress.new(totalBytes)
    p:setCurrent(currentBytes)
    p.showNumbers = true
    
    -- Override view to show byte sizes
    local originalView = p.view
    p.view = function(self)
        local bar = originalView(self)
        -- Format bytes
        local function formatBytes(bytes)
            if bytes < 1024 then
                return string.format("%d B", bytes)
            elseif bytes < 1024 * 1024 then
                return string.format("%.1f KB", bytes / 1024)
            elseif bytes < 1024 * 1024 * 1024 then
                return string.format("%.1f MB", bytes / (1024 * 1024))
            else
                return string.format("%.1f GB", bytes / (1024 * 1024 * 1024))
            end
        end
        
        -- Replace numbers with formatted bytes
        if self.showNumbers then
            bar = bar:gsub("%(%d+/%d+%)", 
                string.format("(%s/%s)", 
                    formatBytes(self.current), 
                    formatBytes(self.total)))
        end
        
        return bar
    end
    
    return p
end

return progress