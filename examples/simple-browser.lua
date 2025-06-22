-- Simplified browser for debugging
local http = require('http')

print("Starting simple browser...")

local app = tui.newApp()
local textView = tui.newTextView("Browser loaded! Press any key...")

print("Created app and textview...")

app:SetRoot(textView, true)
print("Set root...")

-- Test HTTP in background
local function testHTTP()
    print("Testing HTTP...")
    local response, err = http.get("http://httpbin.org/get")
    if response then
        print("HTTP Success! Status:", response.status)
        textView:SetText("HTTP works! Status: " .. response.status .. "\nBody: " .. string.sub(response.body, 1, 100))
        app:Draw()
    else
        print("HTTP Error:", err)
        textView:SetText("HTTP Error: " .. tostring(err))
        app:Draw()
    end
end

-- Test HTTP immediately
testHTTP()

print("Starting app...")
app:Run()