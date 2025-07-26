-- Debug what's happening with load
print("Type of load:", type(load))
print("Type of _G.load:", type(_G.load))

-- Check if load is the standard function
if type(load) == "function" then
    -- Test if it's the standard load by checking parameter count
    local ok, err = pcall(function()
        load("return 1")
    end)
    print("Standard load test:", ok, err)
end

-- List what load expects
print("\nChecking load function...")
local mt = getmetatable(load)
if mt then
    print("load has metatable")
end

-- Try using load correctly
if type(load) == "function" then
    local f, err = load("return 42")
    if f then
        print("load() worked, result:", f())
    else
        print("load() failed:", err)
    end
end