-- Test string formatting
local key = "name"
local val = "John"

print("Test 1:", string.format("%s  [%s] = %s", "", key, val))
print("Test 2:", string.format("%s  [%q] = %q", "", key, val))
print("Test 3:", "" .. "  [" .. key .. "] = " .. val)

-- Test with table
local t = {name = "John", age = 30}
for k, v in pairs(t) do
    local key_str = type(k) == "string" and string.format("%q", k) or tostring(k)
    print("Key:", k, "Key_str:", key_str)
    print("Format 1:", string.format("  [%s] = %s", key_str, tostring(v)))
    print("Format 2:", "  [" .. key_str .. "] = " .. tostring(v))
end