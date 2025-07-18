-- crypto-demo.lua - Demonstrates Hype's JWK-based cryptography
-- Shows key generation, signing, verification, and key management

local crypto = require('crypto')
local kv = require('kv')

print("🔐 Hype Crypto Demo")
print("==================")

-- Initialize database for key storage
local db = kv.open("crypto_demo.db")
db:open_db("keys")

-- Generate different types of keys
print("\n📝 Generating cryptographic keys...")

-- RSA key for traditional applications
local rsa_key = crypto.generate_jwk("RS256")
print("✅ RSA key generated (RS256)")

-- ECDSA key for efficiency
local ecdsa_key = crypto.generate_jwk("ES256")  
print("✅ ECDSA key generated (ES256)")

-- Ed25519 key for modern applications
local ed25519_key = crypto.generate_jwk("EdDSA")
print("✅ Ed25519 key generated (EdDSA)")

-- Store keys securely in database
print("\n💾 Storing keys in database...")
db:put("keys", "rsa_private", crypto.jwk_to_json(rsa_key))
db:put("keys", "rsa_public", crypto.jwk_to_json(crypto.jwk_to_public(rsa_key)))
db:put("keys", "ecdsa_private", crypto.jwk_to_json(ecdsa_key))
db:put("keys", "ed25519_private", crypto.jwk_to_json(ed25519_key))

-- Generate key thumbprints for identification
local rsa_thumbprint = crypto.jwk_thumbprint(rsa_key)
local ecdsa_thumbprint = crypto.jwk_thumbprint(ecdsa_key)
local ed25519_thumbprint = crypto.jwk_thumbprint(ed25519_key)

print("RSA key thumbprint:", rsa_thumbprint)
print("ECDSA key thumbprint:", ecdsa_thumbprint)
print("Ed25519 key thumbprint:", ed25519_thumbprint)

-- Demo signing and verification
print("\n🔏 Digital Signature Demo...")

local sensitive_data = "Transfer $1000 from Account A to Account B - Authorization Code: " .. os.time()
print("Data to sign:", sensitive_data)

-- Sign with different algorithms
local rsa_signature = crypto.sign(rsa_key, sensitive_data)
local ecdsa_signature = crypto.sign(ecdsa_key, sensitive_data)
local ed25519_signature = crypto.sign(ed25519_key, sensitive_data)

print("\n📋 Signature Results:")
print("RSA signature length:", #rsa_signature, "bytes")
print("ECDSA signature length:", #ecdsa_signature, "bytes") 
print("Ed25519 signature length:", #ed25519_signature, "bytes")

-- Verify signatures
print("\n✅ Verification Results:")

local rsa_public = crypto.jwk_to_public(rsa_key)
local ecdsa_public = crypto.jwk_to_public(ecdsa_key)
local ed25519_public = crypto.jwk_to_public(ed25519_key)

local rsa_valid = crypto.verify(rsa_public, sensitive_data, rsa_signature)
local ecdsa_valid = crypto.verify(ecdsa_public, sensitive_data, ecdsa_signature)
local ed25519_valid = crypto.verify(ed25519_public, sensitive_data, ed25519_signature)

print("RSA verification:", rsa_valid and "✅ VALID" or "❌ INVALID")
print("ECDSA verification:", ecdsa_valid and "✅ VALID" or "❌ INVALID")
print("Ed25519 verification:", ed25519_valid and "✅ VALID" or "❌ INVALID")

-- Demo key loading from database
print("\n🔄 Key Persistence Demo...")
local stored_rsa_json = db:get("keys", "rsa_private")
local loaded_rsa_key = crypto.jwk_from_json(stored_rsa_json)

-- Sign with loaded key
local loaded_signature = crypto.sign(loaded_rsa_key, "Test with loaded key")
local loaded_verification = crypto.verify(rsa_public, "Test with loaded key", loaded_signature)

print("Loaded key signature verification:", loaded_verification and "✅ SUCCESS" or "❌ FAILED")

-- Security demo - tampered data detection
print("\n🚨 Security Demo - Tampered Data Detection...")
local tampered_data = "Transfer $9999 from Account A to Account B - Authorization Code: " .. os.time()
local tampered_result = crypto.verify(rsa_public, tampered_data, rsa_signature)
print("Tampered data verification:", tampered_result and "❌ SECURITY BREACH!" or "✅ TAMPER DETECTED")

-- Performance comparison
print("\n⚡ Performance Comparison...")
local start_time = os.clock()

-- RSA performance
for i = 1, 10 do
    crypto.sign(rsa_key, "performance test " .. i)
end
local rsa_time = os.clock() - start_time

start_time = os.clock()
-- ECDSA performance  
for i = 1, 10 do
    crypto.sign(ecdsa_key, "performance test " .. i)
end
local ecdsa_time = os.clock() - start_time

start_time = os.clock()
-- Ed25519 performance
for i = 1, 10 do
    crypto.sign(ed25519_key, "performance test " .. i)
end
local ed25519_time = os.clock() - start_time

print(string.format("RSA (10 signatures): %.3f seconds", rsa_time))
print(string.format("ECDSA (10 signatures): %.3f seconds", ecdsa_time))  
print(string.format("Ed25519 (10 signatures): %.3f seconds", ed25519_time))

-- Clean up
db:close()

print("\n🎉 Crypto demo completed!")
print("\n💡 Key Takeaways:")
print("• JWK format simplifies key management")
print("• Auto-algorithm detection from JWK metadata")
print("• All major signature algorithms supported")
print("• Perfect integration with Hype's KV database")
print("• Enterprise-grade security with simple API")
print("\n🔗 Next: Try HTTP signatures for secure API communication!")