-- Test the formatTable function
local function formatTable(t, indent)
    indent = indent or ""
    local parts = {}
    local keys = {}
    
    -- Collect all keys
    for k in pairs(t) do
        table.insert(keys, k)
    end
    
    -- Sort keys for consistent output
    table.sort(keys, function(a, b)
        if type(a) == type(b) then
            return tostring(a) < tostring(b)
        else
            return type(a) < type(b)
        end
    end)
    
    -- Format the table
    table.insert(parts, "{")
    for i, k in ipairs(keys) do
        local v = t[k]
        local key_str
        if type(k) == "string" then
            key_str = '"' .. k .. '"'
        else
            key_str = tostring(k)
        end
        local val_str
        
        if type(v) == "table" then
            if indent:len() < 20 then  -- Limit nesting depth
                val_str = formatTable(v, indent .. "  ")
            else
                val_str = "<nested table>"
            end
        elseif type(v) == "string" then
            val_str = '"' .. v .. '"'
        elseif type(v) == "function" then
            val_str = "<function>"
        elseif type(v) == "userdata" then
            val_str = "<userdata>"
        elseif type(v) == "thread" then
            val_str = "<thread>"
        else
            val_str = tostring(v)
        end
        
        table.insert(parts, indent .. "  [" .. key_str .. "] = " .. val_str .. (i < #keys and "," or ""))
    end
    table.insert(parts, indent .. "}")
    
    return table.concat(parts, "\n")
end

-- Test it
local t = {name="John", age=30, hobbies={"coding", "gaming"}}
print(formatTable(t))