-- Hyperbeam Database Tree Summary
-- Creates a condensed tree view showing just the main structure
-- Usage: mdb_dump /path/to/lmdb | ./hype run hyperbeam-tree-summary.lua

local function hex_to_string(hex)
    local str = ""
    for i = 1, #hex, 2 do
        local byte = tonumber(hex:sub(i, i+1), 16)
        if byte and byte >= 32 and byte <= 126 then
            str = str .. string.char(byte)
        else
            return nil
        end
    end
    return str
end

local function parse_key(hex_key)
    local readable = hex_to_string(hex_key)
    if readable then
        return readable
    end
    return hex_key:sub(1, 20) .. "..."
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

local function main()
    print("Hyperbeam Database Structure Summary")
    print("===================================")
    print()
    
    local keys = {}
    local in_data = false
    
    for line in io.lines() do
        if line == "HEADER=END" then
            in_data = true
        elseif in_data and line:match("^%s+[0-9a-f]") then
            local hex_key = line:match("^%s+([0-9a-f]+)")
            if hex_key then
                local parsed_key = parse_key(hex_key)
                table.insert(keys, parsed_key)
            end
        end
    end
    
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

main()