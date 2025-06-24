-- debug-signing.lua - Debug signing process step by step
local crypto = require('crypto')
local httpsig = require('httpsig')

print("🔍 Debugging HTTP Signatures Signing")
print("====================================")

-- Test step by step
local jwk = crypto.generate_jwk("RS256")
print("1. ✅ Generated JWK")

local request = {
    type = "request",
    method = "GET",
    path = "/test",
    headers = {
        host = "example.com"
    },
    body = ""
}
print("2. ✅ Created request object")

local options = {
    jwk = jwk,
    key_id = "test",
    headers = {"(request-target)", "host"}
}
print("3. ✅ Created options object")

-- Test each component
print("4. Testing JWK access...")
print("   JWK type:", jwk.kty)
print("   JWK algorithm:", jwk.alg)

print("5. Testing crypto sign function...")
local test_data = "test signing data"
local signature = crypto.sign(jwk, test_data)
if signature then
    print("   ✅ Basic crypto.sign works, signature length:", #signature)
else
    print("   ❌ Basic crypto.sign failed")
    return
end

print("6. Testing httpsig.sign with minimal data...")

-- Try the most minimal possible request
local minimal_request = {
    type = "request",
    method = "GET",
    path = "/",
    headers = {
        host = "test.com"
    },
    body = ""
}

local minimal_options = {
    jwk = jwk,
    key_id = "test-key"
    -- No headers specified - should use defaults
}

print("   Calling httpsig.sign...")
local result = httpsig.sign(minimal_request, minimal_options)

if result then
    print("   ✅ httpsig.sign returned a result")
    if type(result) == "table" then
        print("   Result is a table")
        for k, v in pairs(result) do
            print("     " .. k .. ":", type(v))
        end
    else
        print("   Result type:", type(result))
    end
else
    print("   ❌ httpsig.sign returned nil")
end