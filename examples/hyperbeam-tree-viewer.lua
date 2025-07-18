-- Hyperbeam Database Tree Viewer
-- Unified tool for visualizing LMDB database structure
-- Usage: mdb_dump /path/to/lmdb | ./hype run hyperbeam-tree-viewer.lua [--summary|--parser]
-- Default: --parser (full tree view)

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

local function get_main_groups(keys)
    local groups = {}
    local group_counts = {}
    
    for _, key in ipairs(keys) do
        -- Extract main group identifier
        local main_group = key:match("^([^/]+)")
        if main_group and main_group ~= "group" then
            if not groups[main_group] then
                groups[main_group] = {}
                group_counts[main_group] = 0
            end
            group_counts[main_group] = group_counts[main_group] + 1
            
            -- Extract subkey if it exists
            local subkey = key:match("^[^/]+/(.+)$")
            if subkey then
                groups[main_group][subkey] = true
            end
        end
    end
    
    return groups, group_counts
end

local function show_summary(keys)
    print("Hyperbeam Database Structure Summary")
    print("===================================")
    print()
    print("Total keys: " .. #keys)
    print()
    
    local groups, group_counts = get_main_groups(keys)
    
    -- Sort groups by count (most entries first)
    local sorted_groups = {}
    for group, _ in pairs(groups) do
        table.insert(sorted_groups, group)
    end
    table.sort(sorted_groups, function(a, b) 
        return group_counts[a] > group_counts[b] 
    end)
    
    print("Main Groups (top 10):")
    print("--------------------")
    
    for i = 1, math.min(10, #sorted_groups) do
        local group = sorted_groups[i]
        local count = group_counts[group]
        
        print(string.format("📁 %s (%d entries)", group, count))
        
        -- Show sample subkeys
        local subkeys = {}
        for subkey, _ in pairs(groups[group]) do
            table.insert(subkeys, subkey)
        end
        table.sort(subkeys)
        
        for j = 1, math.min(5, #subkeys) do
            local subkey = subkeys[j]
            local icon = subkey:find("link") and "🔗 " or "  "
            print(string.format("  %s%s", icon, subkey))
        end
        
        if #subkeys > 5 then
            print(string.format("  ... and %d more", #subkeys - 5))
        end
        print()
    end
    
    -- Show statistics
    print("Statistics:")
    print("-----------")
    print(string.format("Total groups: %d", #sorted_groups))
    print(string.format("Total entries: %d", #keys))
    
    local link_count = 0
    for _, key in ipairs(keys) do
        if key:find("link:") then
            link_count = link_count + 1
        end
    end
    print(string.format("Link references: %d", link_count))
    
    local common_fields = {
        "authority", "device", "scheduler", "type", "balance+link", 
        "module+link", "process+link", "results+link"
    }
    
    print("\nCommon field types:")
    for _, field in ipairs(common_fields) do
        local field_count = 0
        for _, key in ipairs(keys) do
            if key:find(field) then
                field_count = field_count + 1
            end
        end
        if field_count > 0 then
            print(string.format("  %s: %d", field, field_count))
        end
    end
end

local function show_parser(keys)
    print("Hyperbeam Database Tree Visualization")
    print("=====================================")
    print("Reading mdb_dump output from stdin...")
    print()
    
    print("Found " .. #keys .. " keys")
    print()
    
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

local function show_help()
    print("Hyperbeam Database Tree Viewer")
    print("=============================")
    print()
    print("Usage: mdb_dump /path/to/lmdb | ./hype run hyperbeam-tree-viewer.lua [OPTIONS]")
    print()
    print("OPTIONS:")
    print("  --summary    Show condensed structure summary")
    print("  --parser     Show full tree visualization (default)")
    print("  --help       Show this help message")
    print()
    print("Examples:")
    print("  mdb_dump /path/to/lmdb | ./hype run hyperbeam-tree-viewer.lua")
    print("  mdb_dump /path/to/lmdb | ./hype run hyperbeam-tree-viewer.lua --summary")
    print("  mdb_dump /path/to/lmdb | ./hype run hyperbeam-tree-viewer.lua --parser")
end

local function main(args)
    -- Parse command line arguments
    local mode = "parser" -- default
    
    if args and #args > 0 then
        local arg1 = args[1]
        if arg1 == "--help" or arg1 == "-h" then
            show_help()
            return
        elseif arg1 == "--summary" or arg1 == "-s" then
            mode = "summary"
        elseif arg1 == "--parser" or arg1 == "-p" then
            mode = "parser"
        else
            print("Unknown option: " .. arg1)
            print("Use --help for usage information")
            return
        end
    end
    
    -- Read keys from stdin
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
    
    if #keys == 0 then
        print("No keys found. Make sure to pipe mdb_dump output:")
        print("mdb_dump /path/to/lmdb | ./hype run hyperbeam-tree-viewer.lua")
        return
    end
    
    -- Show appropriate view
    if mode == "summary" then
        show_summary(keys)
    else
        show_parser(keys)
    end
end

-- Run the viewer
main(arg)