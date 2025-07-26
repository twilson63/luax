-- Test different ways of calling methods

local app = tui.newApp()

print("Testing method calls...")

-- Test 1: Direct method access
print("1. app.Run type:", type(app.Run))

-- Test 2: Using pcall to catch errors
print("2. Testing app.Stop()...")
local ok1, err1 = pcall(function() app:Stop() end)
print("   Result:", ok1, err1 or "OK")

-- Test 3: Trying Run in a protected way
print("3. Testing app.Run (will exit immediately since no root)...")
local ok2, err2 = pcall(function() 
    -- Set a simple root first
    local text = tui.newTextView("Test")
    app:SetRoot(text, true)
    -- Just try to run
    app:Run() 
end)
print("   Result:", ok2, err2 or "OK")

print("All tests complete!")