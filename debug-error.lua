-- debug-error.lua - Capture error from httpsig.sign
local crypto = require('crypto')
local httpsig = require('httpsig')

print("🔍 Debugging HTTP Signatures Errors")
print("===================================")

local jwk = crypto.generate_jwk("RS256")
print("✅ Generated JWK")

local request = {
    type = "request",
    method = "GET",
    path = "/test",
    headers = {
        host = "example.com"
    },
    body = ""
}

local options = {
    jwk = jwk,
    key_id = "test-key"
}

print("📝 Calling httpsig.sign with error capture...")

-- Capture both return values (result and error)
local result, error_msg = httpsig.sign(request, options)

if result then
    print("✅ Success! Result type:", type(result))
    if type(result) == "table" and result.headers then
        print("   Has headers:", result.headers.signature and "YES" or "NO")
    end
else
    print("❌ Failed!")
    if error_msg then
        print("   Error message:", error_msg)
    else
        print("   No error message returned")
    end
end