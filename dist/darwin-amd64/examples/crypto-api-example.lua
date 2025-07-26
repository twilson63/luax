-- Example showing the crypto API usage pattern
local crypto = require("crypto")

-- Create a wrapper that provides the requested API pattern
local cryptoAPI = {
    sha384 = function(data) 
        return crypto.digest("sha384", data) 
    end,
    
    sign = function(data, jwk) 
        return crypto.sign("rsa-pss", data, jwk) 
    end,
    
    base64urlDecode = function(s) 
        return crypto.base64urlDecode(s) 
    end
}

print("Crypto API Example")
print("==================")

-- Example 1: Using sha384
local message = "Important data to hash"
local hash = cryptoAPI.sha384(message)
print("\n1. SHA384 Hash:")
print("   Input: " .. message)
print("   Hash: " .. hash)

-- Example 2: Using RSA-PSS signing
print("\n2. RSA-PSS Signing:")
local jwk = crypto.generate_jwk("PS256", 2048)
print("   Generated RSA key")

local dataToSign = "Sign this message"
local signature = cryptoAPI.sign(dataToSign, jwk)
print("   Data: " .. dataToSign)
print("   Signature: " .. string.sub(signature, 1, 50) .. "...")

-- Verify the signature
local isValid = crypto.verify(jwk, dataToSign, signature)
print("   Verification: " .. (isValid and "SUCCESS" or "FAILED"))

-- Example 3: Base64 URL decoding
print("\n3. Base64 URL Decoding:")
local encoded = "VGhpcyBpcyBhIHRlc3Q"  -- "This is a test"
local decoded = cryptoAPI.base64urlDecode(encoded)
print("   Encoded: " .. encoded)
print("   Decoded: " .. decoded)

-- Example 4: Combined usage
print("\n4. Combined Example - Sign and encode:")
local data = "My secret message"
local sig = cryptoAPI.sign(data, jwk)
local hashOfSig = cryptoAPI.sha384(sig)
print("   Original: " .. data)
print("   Signature hash: " .. string.sub(hashOfSig, 1, 50) .. "...")

print("\nAll examples completed successfully!")