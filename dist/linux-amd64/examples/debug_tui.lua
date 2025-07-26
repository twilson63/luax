-- Debug TUI to see what methods are available

print("Debugging TUI...")

-- Check app methods
local app = tui.newApp()
print("app type:", type(app))

-- Try to get the metatable
local mt = getmetatable(app)
if mt then
    print("Metatable found")
    if mt.__index then
        print("__index type:", type(mt.__index))
        
        -- If __index is a table, print its contents
        if type(mt.__index) == "table" then
            print("Methods in __index table:")
            for k, v in pairs(mt.__index) do
                print("  ", k, type(v))
            end
        end
    end
else
    print("No metatable found")
end

-- Try calling methods directly
print("\nTrying to access methods:")
print("app.Run:", type(app.Run))
print("app.SetRoot:", type(app.SetRoot))
print("app.Stop:", type(app.Stop))

-- Check how the browser example does it
print("\nChecking if methods work with colon syntax:")
local success, err = pcall(function()
    print("Trying app:Stop()...")
    -- Don't actually call Run as it will block
end)
print("Success:", success, err or "OK")