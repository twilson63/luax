-- Hyperbeam Database Tree Parser
-- Parses mdb_dump output and creates a tree visualization
-- Usage: mdb_dump /path/to/lmdb | ./hype run hyperbeam-tree-parser.lua

local function hex_to_string(hex)
    -- Convert hex string to readable string
    local str = ""
    for i = 1, #hex, 2 do
        local byte = tonumber(hex:sub(i, i+1), 16)
        if byte and byte >= 32 and byte <= 126 then
            str = str .. string.char(byte)
        else
            return nil -- Not printable
        end
    end
    return str
end

local function parse_key(hex_key)
    -- Try to convert hex key to readable format
    local readable = hex_to_string(hex_key)
    if readable then
        return readable
    end
    return hex_key:sub(1, 20) .. "..." -- Show first 20 chars of hex
end

local function build_tree_structure(keys)
    local tree = {}
    
    for _, key in ipairs(keys) do
        local parts = {}
        
        -- Split by common separators
        if key:find("/") then
            -- Split by slash
            for part in key:gmatch("[^/]+") do
                table.insert(parts, part)
            end
        elseif key:find("%-%-") then
            -- Split by double dash (group separators)
            for part in key:gmatch("[^%-%-]+") do
                if part ~= "" then
                    table.insert(parts, part)
                end
            end
        else
            -- Single key
            table.insert(parts, key)
        end
        
        -- Build tree structure
        local current = tree
        for i, part in ipairs(parts) do
            if not current[part] then
                current[part] = {}
            end
            current = current[part]
        end
    end
    
    return tree
end

local function print_tree(node, prefix, is_last, level)
    prefix = prefix or ""
    level = level or 0
    
    if level > 6 then -- Limit depth to prevent overwhelming output
        return
    end
    
    local keys = {}
    for k, _ in pairs(node) do
        table.insert(keys, k)
    end
    table.sort(keys)
    
    for i, key in ipairs(keys) do
        local is_last_item = (i == #keys)
        local connector = is_last_item and "└── " or "├── "
        
        -- Show key with type indication
        local display_key = key
        if key:find("link:") then
            display_key = "🔗 " .. key:gsub("link:", "")
        elseif key == "group" then
            display_key = "📁 " .. key
        elseif key:find("%+link") then
            display_key = "🔗 " .. key
        end
        
        print(prefix .. connector .. display_key)
        
        -- Recursively print children
        local child_prefix = prefix .. (is_last_item and "    " or "│   ")
        if type(node[key]) == "table" and next(node[key]) then
            print_tree(node[key], child_prefix, is_last_item, level + 1)
        end
    end
end

local function main()
    print("Hyperbeam Database Tree Visualization")
    print("=====================================")
    print("Reading mdb_dump output from stdin...")
    print()
    
    local keys = {}
    local in_data = false
    
    -- Read from stdin (piped mdb_dump output)
    for line in io.lines() do
        if line == "HEADER=END" then
            in_data = true
        elseif in_data and line:match("^%s+[0-9a-f]") then
            -- This is a hex key line
            local hex_key = line:match("^%s+([0-9a-f]+)")
            if hex_key then
                local parsed_key = parse_key(hex_key)
                table.insert(keys, parsed_key)
            end
        end
    end
    
    print("Found " .. #keys .. " keys")
    print()
    
    if #keys == 0 then
        print("No keys found. Make sure to pipe mdb_dump output:")
        print("mdb_dump /path/to/lmdb | ./hype run hyperbeam-tree-parser.lua")
        return
    end
    
    -- Show sample of raw keys
    print("Sample keys:")
    for i = 1, math.min(10, #keys) do
        print("  " .. keys[i])
    end
    print()
    
    -- Build and display tree
    print("Tree Structure:")
    print("---------------")
    
    local tree = build_tree_structure(keys)
    print_tree(tree)
    
    print()
    print("Legend:")
    print("🔗 = Link/Reference")
    print("📁 = Group/Container")
    print("Tree depth limited to 6 levels for readability")
end

-- Run the parser
main()