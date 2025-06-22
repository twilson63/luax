-- Simple HTTP test script
local http = require('http')

print("Testing HTTP module...")

local response, err = http.get("http://httpbin.org/get")

if response then
    print("Success! Status:", response.status)
    print("Body length:", #response.body)
    print("First 200 chars:", string.sub(response.body, 1, 200))
else
    print("Error:", err)
end