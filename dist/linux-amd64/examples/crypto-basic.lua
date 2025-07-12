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

print("\n🎉 Cryptography examples completed!")
print("\n💡 Use Cases:")
print("• Digital signatures for API authentication")
print("• Document integrity verification") 
print("• Secure token generation")
print("• Certificate and key management")