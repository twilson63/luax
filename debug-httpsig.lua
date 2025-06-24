-- debug-httpsig.lua - Debug HTTP signatures
local crypto = require('crypto')
local httpsig = require('httpsig')

print("🔍 Debugging HTTP Signatures")
print("============================")

-- Test if modules load
print("crypto module:", crypto and "✅ loaded" or "❌ not loaded")
print("httpsig module:", httpsig and "✅ loaded" or "❌ not loaded")

if not httpsig then
    print("❌ httpsig module failed to load")
    return
end

-- Check available functions
print("\nhttpsig functions:")
for k, v in pairs(httpsig) do
    print("  " .. k .. ":", type(v))
end

-- Test key generation
local jwk = crypto.generate_jwk("RS256")
if not jwk then
    print("❌ Failed to generate JWK")
    return
end

print("\n✅ Generated JWK:", jwk.kty, jwk.alg)

-- Test simple digest creation
local digest = httpsig.create_digest("test content", "sha256")
if digest then
    print("✅ Created digest:", digest)
else
    print("❌ Failed to create digest")
end

-- Test simple request structure
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
    key_id = "test-key",
    headers = {"(request-target)", "host"}
}

print("\n🔏 Testing simple signing...")
local result = httpsig.sign(request, options)
if result then
    print("✅ Signing returned result")
    if result.headers then
        print("   Headers returned:", result.headers.signature and "✅ signature present" or "❌ no signature")
    else
        print("   ❌ No headers in result")
    end
else
    print("❌ Signing returned nil")
end