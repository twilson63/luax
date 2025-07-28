-- Spinner component for Bubble Tea
-- Animated loading spinner

local spinner = {}

-- Predefined spinner styles
spinner.styles = {
    line = {frames = {"-", "\\", "|", "/"}, fps = 10},
    dots = {frames = {"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}, fps = 12},
    dots2 = {frames = {"⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷"}, fps = 10},
    dots3 = {frames = {"⠋", "⠙", "⠚", "⠞", "⠖", "⠦", "⠴", "⠲", "⠳", "⠓"}, fps = 10},
    dots4 = {frames = {"⠄", "⠆", "⠇", "⠋", "⠙", "⠸", "⠰", "⠠", "⠰", "⠸", "⠙", "⠋", "⠇", "⠆"}, fps = 10},
    dots5 = {frames = {"⠋", "⠙", "⠚", "⠒", "⠂", "⠂", "⠒", "⠲", "⠴", "⠦", "⠖", "⠒", "⠐", "⠐", "⠒", "⠓", "⠋"}, fps = 10},
    arrow = {frames = {"←", "↖", "↑", "↗", "→", "↘", "↓", "↙"}, fps = 10},
    bouncing = {frames = {"⠁", "⠂", "⠄", "⡀", "⢀", "⠠", "⠐", "⠈"}, fps = 10},
    bouncingBar = {frames = {"[    ]", "[=   ]", "[==  ]", "[=== ]", "[ ===]", "[  ==]", "[   =]", "[    ]"}, fps = 10},
    circle = {frames = {"◐", "◓", "◑", "◒"}, fps = 8},
    square = {frames = {"◰", "◳", "◲", "◱"}, fps = 8},
    triangle = {frames = {"◢", "◣", "◤", "◥"}, fps = 8},
    halfCircle = {frames = {"◐", "◓", "◑", "◒"}, fps = 8},
    corners = {frames = {"◜", "◠", "◝", "◞", "◡", "◟"}, fps = 8},
    pipe = {frames = {"┤", "┘", "┴", "└", "├", "┌", "┬", "┐"}, fps = 10},
    simpleDots = {frames = {".", "..", "...", "   "}, fps = 5},
    simpleDotsScrolling = {frames = {".  ", ".. ", "...", " ..", "  .", "   "}, fps = 5},
    star = {frames = {"✶", "✸", "✹", "✺", "✹", "✷"}, fps = 8},
    flip = {frames = {"_", "_", "_", "-", "`", "`", "'", "´", "-", "_", "_", "_"}, fps = 12},
    hamburger = {frames = {"☱", "☲", "☴"}, fps = 8},
    grow = {frames = {"▁", "▃", "▄", "▅", "▆", "▇", "▆", "▅", "▄", "▃"}, fps = 10},
    balloon = {frames = {".", "o", "O", "@", "*", " "}, fps = 8},
    noise = {frames = {"▓", "▒", "░"}, fps = 15},
    bounce = {frames = {"⠁", "⠂", "⠄", "⠂"}, fps = 10},
    pong = {frames = {"▐⠂       ▌", "▐⠈       ▌", "▐ ⠂      ▌", "▐ ⠠      ▌", "▐  ⡀     ▌", "▐  ⠠     ▌", "▐   ⠂    ▌", "▐   ⠈    ▌", "▐    ⠂   ▌", "▐    ⠠   ▌", "▐     ⡀  ▌", "▐     ⠠  ▌", "▐      ⠂ ▌", "▐      ⠈ ▌", "▐       ⠂▌", "▐       ⠠▌", "▐       ⡀▌", "▐      ⠠ ▌", "▐      ⠂ ▌", "▐     ⠈  ▌", "▐     ⠂  ▌", "▐    ⠠   ▌", "▐    ⡀   ▌", "▐   ⠠    ▌", "▐   ⠂    ▌", "▐  ⠈     ▌", "▐  ⠂     ▌", "▐ ⠠      ▌", "▐ ⡀      ▌", "▐⠠       ▌"}, fps = 15}
}

-- Create a new spinner
function spinner.new(style)
    local styleData = style or spinner.styles.dots
    if type(style) == "string" and spinner.styles[style] then
        styleData = spinner.styles[style]
    end
    
    local self = {
        frames = styleData.frames,
        fps = styleData.fps or 10,
        frame = 1,
        lastUpdate = 0,
        tag = "",
        prefix = "",
        suffix = "",
        color = nil
    }
    
    -- Set spinner text/tag
    function self:setText(text)
        self.tag = text or ""
        return self
    end
    
    -- Set prefix
    function self:setPrefix(prefix)
        self.prefix = prefix or ""
        return self
    end
    
    -- Set suffix
    function self:setSuffix(suffix)
        self.suffix = suffix or ""
        return self
    end
    
    -- Get current frame
    function self:currentFrame()
        return self.frames[self.frame]
    end
    
    -- Advance to next frame
    function self:tick()
        self.frame = self.frame + 1
        if self.frame > #self.frames then
            self.frame = 1
        end
        self.lastUpdate = os.clock() * 1000
    end
    
    -- Update method for Bubble Tea
    function self:update(msg)
        if msg.type == "tick" then
            local now = os.clock() * 1000
            local interval = 1000 / self.fps
            
            if now - self.lastUpdate >= interval then
                self:tick()
            end
        end
        
        return self
    end
    
    -- View method for Bubble Tea
    function self:view()
        local parts = {}
        
        if self.prefix ~= "" then
            table.insert(parts, self.prefix)
        end
        
        table.insert(parts, self:currentFrame())
        
        if self.tag ~= "" then
            table.insert(parts, " " .. self.tag)
        end
        
        if self.suffix ~= "" then
            table.insert(parts, self.suffix)
        end
        
        return table.concat(parts)
    end
    
    -- Get tick command
    function self:tickCmd()
        local interval = 1000 / self.fps
        return function()
            -- This would normally use a timer
            -- In actual implementation, would return a tick message
            return {type = "tick"}
        end
    end
    
    return self
end

-- Model for simple spinner
function spinner.model(style)
    return spinner.new(style)
end

-- Update function
function spinner.update(model, msg)
    return model:update(msg), nil
end

-- View function
function spinner.view(model)
    return model:view()
end

-- Helper to create spinner with text
function spinner.withText(text, style)
    local s = spinner.new(style)
    s:setText(text)
    return s
end

return spinner