-- debug-headers.lua - Debug header copying
local crypto = require('crypto')
local httpsig = require('httpsig')

print("🔍 Debugging Headers in Verification")
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

-- Sign the request
local signed = httpsig.sign(request, options)

print("📋 Headers after signing:")
for k, v in pairs(signed.headers) do
    print("   " .. k .. ": " .. tostring(v))
end

-- Create verification message exactly as signed
local verify_request = {
    type = "request",
    method = "POST",
    path = "/api/test",
    headers = {},
    body = '{"test": "data"}'
}

-- Copy headers more carefully
print("\n📋 Copying headers...")

-- First copy original headers
for k, v in pairs(request.headers) do
    verify_request.headers[k] = v
    print("   Original header " .. k .. ": " .. v)
end

-- Then copy signed headers
for k, v in pairs(signed.headers) do
    verify_request.headers[k] = v
    print("   Signed header " .. k .. ": " .. v)
end

print("\n📋 Final verification headers:")
for k, v in pairs(verify_request.headers) do
    print("   " .. k .. ": " .. v)
end

local verify_options = {
    jwk = crypto.jwk_to_public(jwk),
    key_id = "test-key-1",
    required_headers = {"host"}
}

print("\n📝 Testing verification...")
local result = httpsig.verify(verify_request, verify_options)

if result then
    print("✅ Verification result:")
    print("   Valid:", result.valid and "YES" or "NO")
    print("   Key ID:", result.key_id or "none")
    print("   Algorithm:", result.algorithm or "none")
    if result.reason then
        print("   Reason:", result.reason)
    end
else
    print("❌ No verification result")
end