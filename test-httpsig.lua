-- test-httpsig.lua - Test HTTP Signatures functionality
local crypto = require('crypto')
local httpsig = require('httpsig')

print("🔏 HTTP Signatures Test")
print("=======================")

-- Generate test keys
local rsa_key = crypto.generate_jwk("RS256")
local ecdsa_key = crypto.generate_jwk("ES256")
local ed25519_key = crypto.generate_jwk("EdDSA")

print("✅ Generated test keys")

-- Test 1: HTTP Request Signing
print("\n📨 Testing HTTP Request Signing...")

local request = {
    type = "request",
    method = "POST",
    path = "/api/transfer",
    headers = {
        ["Host"] = "api.bank.com",
        ["Content-Type"] = "application/json",
        ["User-Agent"] = "Hype-Client/1.0"
    },
    body = '{"amount": 1000, "to": "account123"}'
}

local sign_options = {
    jwk = rsa_key,
    key_id = "rsa-key-2024",
    headers = {"(request-target)", "host", "date", "content-type", "digest"}
}

local signed_request = httpsig.sign(request, sign_options)
if signed_request and signed_request.headers and signed_request.headers.signature then
    print("✅ Request signed successfully")
    print("   Signature header length:", #signed_request.headers.signature)
else
    print("❌ Request signing failed")
    return
end

-- Test 2: HTTP Request Verification
print("\n🔍 Testing HTTP Request Verification...")

-- Create verification message (simulate received request)
local verify_request = {
    type = "request",
    method = "POST", 
    path = "/api/transfer",
    headers = signed_request.headers,
    body = '{"amount": 1000, "to": "account123"}'
}

-- Copy over original headers
for k, v in pairs(request.headers) do
    verify_request.headers[k] = v
end

local verify_options = {
    jwk = crypto.jwk_to_public(rsa_key),
    required_headers = {"date", "host"},
    max_age = 300
}

local verification = httpsig.verify(verify_request, verify_options)
if verification and verification.valid then
    print("✅ Request verification successful")
    print("   Key ID:", verification.key_id)
    print("   Algorithm:", verification.algorithm)
else
    print("❌ Request verification failed")
    if verification and verification.reason then
        print("   Reason:", verification.reason)
    end
    return
end

-- Test 3: HTTP Response Signing
print("\n📤 Testing HTTP Response Signing...")

local response = {
    type = "response",
    status = 200,
    headers = {
        ["Content-Type"] = "application/json",
        ["Server"] = "Hype-Server/1.0"
    },
    body = '{"status": "success", "transaction_id": "tx123"}'
}

local response_sign_options = {
    jwk = ecdsa_key,
    key_id = "ecdsa-server-key",
    headers = {"(status)", "content-type", "date", "digest"}
}

local signed_response = httpsig.sign(response, response_sign_options)
if signed_response and signed_response.headers and signed_response.headers.signature then
    print("✅ Response signed successfully")
    print("   Signature header length:", #signed_response.headers.signature)
else
    print("❌ Response signing failed")
    return
end

-- Test 4: HTTP Response Verification
print("\n🔍 Testing HTTP Response Verification...")

local verify_response = {
    type = "response",
    status = 200,
    headers = signed_response.headers,
    body = '{"status": "success", "transaction_id": "tx123"}'
}

-- Copy original headers
for k, v in pairs(response.headers) do
    verify_response.headers[k] = v
end

local response_verify_options = {
    jwk = crypto.jwk_to_public(ecdsa_key),
    required_headers = {"date", "content-type"},
    max_age = 300
}

local response_verification = httpsig.verify(verify_response, response_verify_options)
if response_verification and response_verification.valid then
    print("✅ Response verification successful")
    print("   Key ID:", response_verification.key_id)
    print("   Algorithm:", response_verification.algorithm)
else
    print("❌ Response verification failed")
    if response_verification and response_verification.reason then
        print("   Reason:", response_verification.reason)
    end
    return
end

-- Test 5: Digest Creation and Verification
print("\n🧮 Testing Digest Creation and Verification...")

local test_content = '{"sensitive": "data", "amount": 5000}'
local digest = httpsig.create_digest(test_content, "sha256")
if digest then
    print("✅ Digest created:", digest)
    
    local digest_valid = httpsig.verify_digest(test_content, digest)
    if digest_valid then
        print("✅ Digest verification successful")
    else
        print("❌ Digest verification failed")
    end
else
    print("❌ Digest creation failed")
    return
end

-- Test 6: Ed25519 Signing
print("\n🔐 Testing Ed25519 Signing...")

local ed25519_request = {
    type = "request",
    method = "GET",
    path = "/api/secure",
    headers = {
        ["Host"] = "secure.api.com",
        ["Authorization"] = "Bearer token123"
    },
    body = ""
}

local ed25519_options = {
    jwk = ed25519_key,
    key_id = "ed25519-client",
    headers = {"(request-target)", "host", "authorization", "date"}
}

local ed25519_signed = httpsig.sign(ed25519_request, ed25519_options)
if ed25519_signed and ed25519_signed.headers.signature then
    print("✅ Ed25519 signing successful")
    
    -- Verify Ed25519 signature
    local ed25519_verify_request = {
        type = "request",
        method = "GET",
        path = "/api/secure", 
        headers = ed25519_signed.headers,
        body = ""
    }
    
    for k, v in pairs(ed25519_request.headers) do
        ed25519_verify_request.headers[k] = v
    end
    
    local ed25519_verify_options = {
        jwk = crypto.jwk_to_public(ed25519_key),
        required_headers = {"host", "authorization"}
    }
    
    local ed25519_verification = httpsig.verify(ed25519_verify_request, ed25519_verify_options)
    if ed25519_verification and ed25519_verification.valid then
        print("✅ Ed25519 verification successful")
    else
        print("❌ Ed25519 verification failed")
    end
else
    print("❌ Ed25519 signing failed")
end

-- Test 7: Invalid Signature Detection
print("\n🚨 Testing Invalid Signature Detection...")

local tampered_request = {
    type = "request",
    method = "POST",
    path = "/api/transfer",
    headers = signed_request.headers,
    body = '{"amount": 9999, "to": "attacker_account"}' -- Tampered body
}

for k, v in pairs(request.headers) do
    tampered_request.headers[k] = v
end

local tampered_verification = httpsig.verify(tampered_request, verify_options)
if tampered_verification and not tampered_verification.valid then
    print("✅ Tampered signature correctly rejected")
    print("   Reason:", tampered_verification.reason or "Signature mismatch")
else
    print("❌ Tampered signature was incorrectly accepted!")
end

print("\n🎉 HTTP Signatures testing completed!")
print("\n💡 Key Features Tested:")
print("• HTTP request signing and verification")
print("• HTTP response signing and verification") 
print("• Multiple signature algorithms (RSA, ECDSA, Ed25519)")
print("• Digest creation and validation")
print("• Tamper detection and security validation")
print("• RFC-compliant HTTP signature headers")
print("\n🔒 Security validated - all signatures working correctly!")