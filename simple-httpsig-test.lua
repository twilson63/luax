-- simple-httpsig-test.lua - Simplified HTTP signatures test
local crypto = require('crypto')
local httpsig = require('httpsig')

print("🔏 Simple HTTP Signatures Test")
print("==============================")

-- Generate key
local jwk = crypto.generate_jwk("ES256")
print("✅ Generated key:", jwk.alg)

-- Test 1: Basic request signing
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

print("\n📝 Signing request...")
local signed = httpsig.sign(request, options)

if signed and signed.headers and signed.headers.signature then
    print("✅ Request signed successfully")
    print("   Signature length:", #signed.headers.signature)
    
    -- Test verification
    print("\n🔍 Verifying signature...")
    
    local verify_request = {
        type = "request",
        method = "POST",
        path = "/api/test",
        headers = {},
        body = '{"test": "data"}'
    }
    
    -- Copy all headers from signed request
    for k, v in pairs(signed.headers) do
        verify_request.headers[k] = v
    end
    
    -- Also copy original headers
    for k, v in pairs(request.headers) do
        verify_request.headers[k] = v
    end
    
    local verify_options = {
        jwk = crypto.jwk_to_public(jwk),
        required_headers = {"host"}
    }
    
    local verification = httpsig.verify(verify_request, verify_options)
    
    if verification then
        print("✅ Verification completed")
        print("   Valid:", verification.valid and "YES" or "NO")
        print("   Key ID:", verification.key_id or "none")
        print("   Algorithm:", verification.algorithm or "none")
        if verification.reason then
            print("   Reason:", verification.reason)
        end
    else
        print("❌ Verification failed to return result")
    end
    
else
    print("❌ Request signing failed")
    if signed then
        print("   Signed object exists but missing signature")
    else
        print("   No signed object returned")
    end
end

-- Test 2: Digest functionality
print("\n🧮 Testing digest functions...")

local content = '{"amount": 1000}'
local digest = httpsig.create_digest(content, "sha256")
print("Created digest:", digest)

local valid = httpsig.verify_digest(content, digest)
print("Digest valid:", valid and "YES" or "NO")

print("\n🎉 Simple test completed!")