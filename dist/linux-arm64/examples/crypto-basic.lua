-- crypto-basic.lua - Basic cryptography examples with Hype
local crypto = require('crypto')

print("🔐 Hype Cryptography Examples")
print("=============================")

-- Example 1: Generate different types of keys
print("\n1️⃣ Key Generation")
print("-------------------")

-- RSA keys
local rsa_key = crypto.generate_jwk("RS256")
print("✅ Generated RSA-256 key")
print("   Key type:", rsa_key.kty)
print("   Algorithm:", rsa_key.alg)

-- ECDSA keys  
local ecdsa_key = crypto.generate_jwk("ES256")
print("✅ Generated ECDSA-256 key")
print("   Key type:", ecdsa_key.kty)
print("   Algorithm:", ecdsa_key.alg)

-- Ed25519 keys
local ed25519_key = crypto.generate_jwk("EdDSA")
print("✅ Generated Ed25519 key")
print("   Key type:", ed25519_key.kty)
print("   Algorithm:", ed25519_key.alg)

-- RSA-PSS keys (new in v1.7.2)
local pss_key = crypto.generate_jwk("PS512")
print("✅ Generated RSA-PSS-512 key")
print("   Key type:", pss_key.kty)
print("   Algorithm:", pss_key.alg)

-- Example 2: Basic signing and verification
print("\n2️⃣ Basic Signing & Verification")
print("--------------------------------")

local message = "Hello, secure world! 🌍"
local signature = crypto.sign(rsa_key, message)

if signature then
    print("✅ Message signed successfully")
    print("   Signature length:", #signature, "bytes")
    
    -- Extract public key for verification
    local public_key = crypto.jwk_to_public(rsa_key)
    local is_valid = crypto.verify(public_key, message, signature)
    
    if is_valid then
        print("✅ Signature verified successfully")
    else
        print("❌ Signature verification failed")
    end
else
    print("❌ Signing failed")
end

-- Example 3: JSON serialization
print("\n3️⃣ Key Serialization")
print("---------------------")

local key_json = crypto.jwk_to_json(ecdsa_key)
print("✅ Exported key to JSON")
print("   JSON length:", #key_json, "characters")

local imported_key = crypto.jwk_from_json(key_json)
print("✅ Imported key from JSON")
print("   Algorithm matches:", imported_key.alg == ecdsa_key.alg)

-- Example 4: Key thumbprints
print("\n4️⃣ Key Identification")
print("----------------------")

local thumbprint = crypto.jwk_thumbprint(ed25519_key)
print("✅ Generated key thumbprint")
print("   Thumbprint:", thumbprint)
print("   Can be used as unique key identifier")

-- Example 5: Different algorithms comparison
print("\n5️⃣ Algorithm Comparison")
print("-----------------------")

local test_data = "Performance test data 📊"

local algorithms = {"RS256", "ES256", "EdDSA"}
for _, alg in ipairs(algorithms) do
    local key = crypto.generate_jwk(alg)
    local start_time = os.clock()
    
    -- Sign 100 times
    for i = 1, 100 do
        crypto.sign(key, test_data .. i)
    end
    
    local elapsed = os.clock() - start_time
    print("✅", alg, "- 100 signatures in", string.format("%.3f", elapsed), "seconds")
end

print("\n5️⃣ 4096-bit RSA Keys")
print("--------------------")

-- Generate different RSA key sizes
local rsa_2048 = crypto.generate_jwk("RS256")        -- Default 2048-bit
local rsa_3072 = crypto.generate_jwk("RS256", 3072)  -- 3072-bit
local rsa_4096 = crypto.generate_jwk("RS256", 4096)  -- 4096-bit

print("Generated RSA keys:")
print("• 2048-bit (default)")
print("• 3072-bit")
print("• 4096-bit (maximum)")

-- Test 4096-bit signature
local message = "High security transaction"
local sig_4096 = crypto.sign(rsa_4096, message)
local pub_4096 = crypto.jwk_to_public(rsa_4096)
local valid = crypto.verify(pub_4096, message, sig_4096)

print("\n4096-bit RSA signature:")
print("• Message:", message)
print("• Signature length:", #sig_4096, "characters")
print("• Verification:", valid and "✅ Success" or "❌ Failed")

print("\n6️⃣ Hashing Functions")
print("--------------------")

-- Basic hashing
local data = "Important data to hash"
local hash256 = crypto.sha256(data)
local hash384 = crypto.sha384(data)
local hash512 = crypto.sha512(data)

print("SHA-256:", string.sub(hash256, 1, 32) .. "...")
print("SHA-384:", string.sub(hash384, 1, 32) .. "...")
print("SHA-512:", string.sub(hash512, 1, 32) .. "...")

-- Deep hashing for complex data
local complex_data = {
    user = "alice",
    permissions = {"read", "write"},
    metadata = {
        created = os.time(),
        version = "1.0"
    }
}

local deep_hash = crypto.deep_hash(complex_data)
print("\nDeep hash of complex object:")
print("   Hash:", string.sub(deep_hash, 1, 48) .. "...")
print("   Algorithm: SHA-384 (default)")

-- Deep hash with different algorithm
local deep_sha256 = crypto.deep_hash(complex_data, "sha256")
print("\nDeep hash with SHA-256:")
print("   Hash:", string.sub(deep_sha256, 1, 48) .. "...")

print("\n🎉 Cryptography examples completed!")
print("\n💡 Use Cases:")
print("• Digital signatures for API authentication")
print("• Document integrity verification") 
print("• Secure token generation")
print("• Certificate and key management")
print("• SHA-384 deep hashing for complex data structures")