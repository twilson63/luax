-- debug-verify.lua - Debug verification
local crypto = require('crypto')
local httpsig = require('httpsig')

print("🔍 Debugging HTTP Signatures Verification")
print("==========================================")

local jwk = crypto.generate_jwk("ES256")
local public_key = crypto.jwk_to_public(jwk)

print("✅ Generated keys")

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
print("✅ Request signed")

-- Create verification message
local verify_request = {
    type = "request",
    method = "POST",
    path = "/api/test",
    headers = {},
    body = '{"test": "data"}'
}

-- Copy all headers
for k, v in pairs(signed.headers) do
    verify_request.headers[k] = v
end

for k, v in pairs(request.headers) do
    verify_request.headers[k] = v
end

print("✅ Created verification request")

local verify_options = {
    jwk = public_key,
    key_id = "test-key-1",  -- Add the key_id for verification
    required_headers = {"host"}
}

print("📝 Testing verification...")
local result, error_msg = httpsig.verify(verify_request, verify_options)

if result then
    print("✅ Verification returned result")
    print("   Type:", type(result))
    if type(result) == "table" then
        for k, v in pairs(result) do
            print("   " .. k .. ":", v)
        end
    end
else
    print("❌ Verification failed")
    if error_msg then
        print("   Error:", error_msg)
    end
end