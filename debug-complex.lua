-- debug-complex.lua - Debug the complex signing case
local crypto = require('crypto')
local httpsig = require('httpsig')

print("🔍 Debugging Complex HTTP Signatures")
print("====================================")

local jwk = crypto.generate_jwk("ES256")

local request = {
    type = "request",
    method = "POST",
    path = "/api/test",
    headers = {
        host = "api.example.com",
        ["content-type"] = "application/json"
    },
    body = '{"test": "data"}'
}

local options = {
    jwk = jwk,
    key_id = "test-key-1",
    headers = {"(request-target)", "host", "content-type", "digest"}
}

print("📝 Testing complex signing...")
local result, error_msg = httpsig.sign(request, options)

if result then
    print("✅ Success!")
else
    print("❌ Failed!")
    if error_msg then
        print("   Error:", error_msg)
    end
end