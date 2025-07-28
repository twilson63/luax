-- List component for Bubble Tea
-- Scrollable list with item selection

local list = {}

-- Create a new list
function list.new(items)
    local self = {
        items = items or {},
        selected = 1,
        cursor = 1,
        height = 10,
        width = 0,
        offset = 0,
        showHelp = true,
        showStatusBar = true,
        showPagination = true,
        filterEnabled = true,
        filterValue = "",
        filteredItems = {},
        itemRenderer = nil,
        styles = {
            selected = {prefix = "> ", suffix = ""},
            normal = {prefix = "  ", suffix = ""},
            help = "↑/k up • ↓/j down • enter select • / filter • q quit"
        }
    }
    
    -- Initialize filtered items
    self:updateFilter()
    
    -- Set items
    function self:setItems(items)
        self.items = items or {}
        self:updateFilter()
        self:clampCursor()
        return self
    end
    
    -- Add item
    function self:addItem(item)
        table.insert(self.items, item)
        self:updateFilter()
        return self
    end
    
    -- Remove item
    function self:removeItem(index)
        if index > 0 and index <= #self.items then
            table.remove(self.items, index)
            self:updateFilter()
            self:clampCursor()
        end
        return self
    end
    
    -- Set dimensions
    function self:setHeight(height)
        self.height = height
        self:updateOffset()
        return self
    end
    
    function self:setWidth(width)
        self.width = width
        return self
    end
    
    -- Set custom item renderer
    function self:setItemRenderer(fn)
        self.itemRenderer = fn
        return self
    end
    
    -- Cursor movement
    function self:cursorUp()
        if self.cursor > 1 then
            self.cursor = self.cursor - 1
            self:updateOffset()
        end
    end
    
    function self:cursorDown()
        if self.cursor < #self.filteredItems then
            self.cursor = self.cursor + 1
            self:updateOffset()
        end
    end
    
    function self:cursorTop()
        self.cursor = 1
        self:updateOffset()
    end
    
    function self:cursorBottom()
        self.cursor = #self.filteredItems
        self:updateOffset()
    end
    
    function self:pageUp()
        self.cursor = math.max(1, self.cursor - self.height)
        self:updateOffset()
    end
    
    function self:pageDown()
        self.cursor = math.min(#self.filteredItems, self.cursor + self.height)
        self:updateOffset()
    end
    
    -- Selection
    function self:select()
        if self.cursor > 0 and self.cursor <= #self.filteredItems then
            local item = self.filteredItems[self.cursor]
            -- Find actual index in original items
            for i, v in ipairs(self.items) do
                if v == item then
                    self.selected = i
                    break
                end
            end
        end
    end
    
    function self:getSelected()
        if self.selected > 0 and self.selected <= #self.items then
            return self.items[self.selected], self.selected
        end
        return nil, 0
    end
    
    -- Filtering
    function self:setFilter(value)
        self.filterValue = value or ""
        self:updateFilter()
    end
    
    function self:updateFilter()
        if self.filterValue == "" then
            self.filteredItems = {}
            for i, item in ipairs(self.items) do
                table.insert(self.filteredItems, item)
            end
        else
            self.filteredItems = {}
            local pattern = self.filterValue:lower()
            for _, item in ipairs(self.items) do
                local text = tostring(item):lower()
                if text:find(pattern, 1, true) then
                    table.insert(self.filteredItems, item)
                end
            end
        end
        
        -- Reset cursor if needed
        if self.cursor > #self.filteredItems then
            self.cursor = math.max(1, #self.filteredItems)
        end
        self:updateOffset()
    end
    
    -- Helper methods
    function self:clampCursor()
        if self.cursor < 1 then
            self.cursor = 1
        elseif self.cursor > #self.filteredItems then
            self.cursor = #self.filteredItems
        end
    end
    
    function self:updateOffset()
        -- Calculate visible area
        local visibleHeight = self.height
        if self.showHelp then visibleHeight = visibleHeight - 1 end
        if self.showStatusBar then visibleHeight = visibleHeight - 1 end
        
        -- Adjust offset to keep cursor visible
        if self.cursor < self.offset + 1 then
            self.offset = self.cursor - 1
        elseif self.cursor > self.offset + visibleHeight then
            self.offset = self.cursor - visibleHeight
        end
        
        -- Clamp offset
        self.offset = math.max(0, math.min(self.offset, #self.filteredItems - visibleHeight))
    end
    
    -- Default item renderer
    function self:defaultRenderer(item, index, selected)
        local style = selected and self.styles.selected or self.styles.normal
        local text = tostring(item)
        
        -- Truncate if width is set
        if self.width > 0 then
            local maxLen = self.width - #style.prefix - #style.suffix
            if #text > maxLen then
                text = text:sub(1, maxLen - 3) .. "..."
            end
        end
        
        return style.prefix .. text .. style.suffix
    end
    
    -- Update method for Bubble Tea
    function self:update(msg)
        if msg.type == "key" then
            if self.filterEnabled and msg.key == "/" then
                -- Start filtering mode
                return self, {type = "start_filter"}
            elseif msg.key == "up" or msg.key == "k" then
                self:cursorUp()
            elseif msg.key == "down" or msg.key == "j" then
                self:cursorDown()
            elseif msg.key == "home" or msg.key == "g" then
                self:cursorTop()
            elseif msg.key == "end" or msg.key == "G" then
                self:cursorBottom()
            elseif msg.key == "pgup" then
                self:pageUp()
            elseif msg.key == "pgdown" then
                self:pageDown()
            elseif msg.key == "enter" then
                self:select()
                return self, {type = "select", item = self:getSelected()}
            end
        elseif msg.type == "window_size" then
            self:setHeight(msg.height)
            self:setWidth(msg.width)
        elseif msg.type == "filter_update" then
            self:setFilter(msg.value)
        end
        
        return self, nil
    end
    
    -- View method for Bubble Tea
    function self:view()
        local lines = {}
        
        -- Calculate visible area
        local visibleHeight = self.height
        if self.showHelp then visibleHeight = visibleHeight - 1 end
        if self.showStatusBar then visibleHeight = visibleHeight - 1 end
        
        -- Render visible items
        local endIdx = math.min(self.offset + visibleHeight, #self.filteredItems)
        for i = self.offset + 1, endIdx do
            local item = self.filteredItems[i]
            local isSelected = (i == self.cursor)
            
            local line
            if self.itemRenderer then
                line = self.itemRenderer(item, i, isSelected)
            else
                line = self:defaultRenderer(item, i, isSelected)
            end
            
            table.insert(lines, line)
        end
        
        -- Pad with empty lines
        while #lines < visibleHeight do
            table.insert(lines, "")
        end
        
        -- Add status bar
        if self.showStatusBar then
            local status = ""
            if self.filterValue ~= "" then
                status = string.format("Filter: %s | %d/%d items", 
                    self.filterValue, #self.filteredItems, #self.items)
            else
                status = string.format("%d items", #self.items)
            end
            
            if self.showPagination and #self.filteredItems > visibleHeight then
                local page = math.floor(self.cursor / visibleHeight) + 1
                local totalPages = math.ceil(#self.filteredItems / visibleHeight)
                status = status .. string.format(" | Page %d/%d", page, totalPages)
            end
            
            table.insert(lines, status)
        end
        
        -- Add help
        if self.showHelp then
            table.insert(lines, self.styles.help)
        end
        
        return table.concat(lines, "\n")
    end
    
    return self
end

-- Simple list model
function list.model(items)
    return list.new(items)
end

-- Update function
function list.update(model, msg)
    return model:update(msg)
end

-- View function
function list.view(model)
    return model:view()
end

-- Helper to create a simple string list
function list.newStringList(strings)
    local l = list.new(strings)
    return l
end

-- Helper to create a list with custom items
function list.newItemList(items, renderer)
    local l = list.new(items)
    if renderer then
        l:setItemRenderer(renderer)
    end
    return l
end

return list