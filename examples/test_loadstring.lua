-- Test loadstring
print("loadstring exists?", loadstring ~= nil)

if loadstring then
    local f, err = loadstring("return 1 + 1")
    if f then
        print("Result:", f())
    else
        print("Error:", err)
    end
else
    print("loadstring not available, trying load with correct syntax")
    
    -- In Lua 5.2+, load can take a string but syntax is different
    -- Let's check what version we're using
    print("_VERSION:", _VERSION)
end