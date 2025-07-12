-- httpsig-basic.lua - Basic HTTP signatures examples
local crypto = require('crypto')
local httpsig = require('httpsig')

print("🔏 HTTP Signatures Examples")
print("============================")

-- Generate keys for examples
local server_key = crypto.generate_jwk("RS256")
local client_key = crypto.generate_jwk("ES256")

print("✅ Generated RSA server key and ECDSA client key")

-- Example 1: Sign an HTTP Request
print("\n1️⃣ HTTP Request Signing")
print("------------------------")

local request = {
    type = "request",
    method = "POST",
    path = "/api/users",
    headers = {
        ["Host"] = "api.example.com",
        ["Content-Type"] = "application/json",
        ["User-Agent"] = "MyApp/1.0"
    },
    body = '{"name": "Alice", "email": "alice@example.com"}'
}

local sign_options = {
    jwk = client_key,
    key_id = "client-key-2024",
    headers = {"(request-target)", "host", "content-type", "digest", "date"}
}

local signed_request = httpsig.sign(request, sign_options)
if signed_request then
    print("✅ Request signed successfully")
    print("   Added headers:")
    for key, value in pairs(signed_request.headers) do
        if key == "signature" then
            print("   " .. key .. ": " .. value:sub(1, 50) .. "...")
        elseif key == "digest" or key == "date" then
            print("   " .. key .. ": " .. value)
        end
    end
else
    print("❌ Request signing failed")
end

-- Example 2: Verify the HTTP Request
print("\n2️⃣ HTTP Request Verification")
print("-----------------------------")

-- Create verification message (simulate received request)
local verify_request = {
    type = "request",
    method = "POST",
    path = "/api/users",
    headers = signed_request.headers,
    body = '{"name": "Alice", "email": "alice@example.com"}'
}

-- Copy original headers
for k, v in pairs(request.headers) do
    verify_request.headers[k] = v
end

local verify_options = {
    jwk = crypto.jwk_to_public(client_key),
    required_headers = {"host", "content-type"},
    max_age = 300  -- 5 minutes
}

local verification = httpsig.verify(verify_request, verify_options)
if verification and verification.valid then
    print("✅ Request verification successful")
    print("   Key ID:", verification.key_id)
    print("   Algorithm:", verification.algorithm)
else
    print("❌ Request verification failed")
    if verification then
        print("   Reason:", verification.reason)
    end
end

-- Example 3: Sign an HTTP Response
print("\n3️⃣ HTTP Response Signing")
print("-------------------------")

local response = {
    type = "response",
    status = 201,
    headers = {
        ["Content-Type"] = "application/json",
        ["Server"] = "MyAPI/1.0",
        ["Location"] = "/api/users/123"
    },
    body = '{"id": 123, "name": "Alice", "created": "2024-01-15T10:30:00Z"}'
}

local response_sign_options = {
    jwk = server_key,
    key_id = "server-rsa-2024",
    headers = {"(status)", "content-type", "location", "digest", "date"}
}

local signed_response = httpsig.sign(response, response_sign_options)
if signed_response then
    print("✅ Response signed successfully")
    print("   Status:", response.status)
    print("   Signature length:", #signed_response.headers.signature)
else
    print("❌ Response signing failed")
end

-- Example 4: Verify HTTP Response
print("\n4️⃣ HTTP Response Verification")
print("------------------------------")

local verify_response = {
    type = "response",
    status = 201,
    headers = signed_response.headers,
    body = '{"id": 123, "name": "Alice", "created": "2024-01-15T10:30:00Z"}'
}

for k, v in pairs(response.headers) do
    verify_response.headers[k] = v
end

local response_verify_options = {
    jwk = crypto.jwk_to_public(server_key),
    required_headers = {"content-type", "location"}
}

local response_verification = httpsig.verify(verify_response, response_verify_options)
if response_verification and response_verification.valid then
    print("✅ Response verification successful")
    print("   Server key ID:", response_verification.key_id)
else
    print("❌ Response verification failed")
end

-- Example 5: Digest Operations
print("\n5️⃣ Digest Creation & Verification")
print("----------------------------------")

local data = '{"secret": "confidential-data", "timestamp": "2024-01-15T10:30:00Z"}'

-- Create digest
local digest = httpsig.create_digest(data, "sha256")
print("✅ Created SHA-256 digest:", digest)

-- Verify digest
local is_valid_digest = httpsig.verify_digest(data, digest)
print("✅ Digest verification:", is_valid_digest and "VALID" or "INVALID")

-- Test with tampered data
local tampered_data = '{"secret": "HACKED!", "timestamp": "2024-01-15T10:30:00Z"}'
local is_tampered_valid = httpsig.verify_digest(tampered_data, digest)
print("🔒 Tampered data verification:", is_tampered_valid and "VALID" or "INVALID (as expected)")

-- Example 6: Security Demonstration
print("\n6️⃣ Security Demonstration")
print("--------------------------")

-- Try to tamper with signed request
local tampered_request = {
    type = "request",
    method = "POST",
    path = "/api/users",
    headers = signed_request.headers,
    body = '{"name": "Hacker", "email": "hacker@evil.com"}'  -- Tampered!
}

for k, v in pairs(request.headers) do
    tampered_request.headers[k] = v
end

local tampered_verification = httpsig.verify(tampered_request, verify_options)
if tampered_verification and not tampered_verification.valid then
    print("✅ Tampered request correctly rejected")
    print("   Reason:", tampered_verification.reason)
else
    print("❌ Security failure - tampered request accepted!")
end

print("\n🎉 HTTP Signatures examples completed!")
print("\n💡 Use Cases:")
print("• API authentication and authorization")
print("• Webhook payload verification")
print("• Microservice communication security")
print("• Financial transaction signing")
print("• Document integrity protection")