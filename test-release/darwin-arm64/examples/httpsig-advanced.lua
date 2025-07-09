-- httpsig-advanced.lua - Advanced HTTP signatures examples
local crypto = require('crypto')
local httpsig = require('httpsig')

print("🚀 Advanced HTTP Signatures")
print("============================")

-- Example 1: Key Management System
print("\n1️⃣ Key Management System")
print("-------------------------")

local key_store = {}

-- Generate different keys for different purposes
key_store.signing_keys = {
    ["user-auth-2024"] = crypto.generate_jwk("RS256"),
    ["webhook-2024"] = crypto.generate_jwk("ES256"), 
    ["admin-2024"] = crypto.generate_jwk("EdDSA")
}

key_store.verification_keys = {}
for key_id, private_key in pairs(key_store.signing_keys) do
    key_store.verification_keys[key_id] = crypto.jwk_to_public(private_key)
    print("✅ Generated key pair:", key_id)
end

-- Example 2: Webhook Signing System
print("\n2️⃣ Webhook Signing System")
print("--------------------------")

function sign_webhook(payload, event_type, webhook_url)
    local webhook_request = {
        type = "request",
        method = "POST",
        path = "/webhook",
        headers = {
            ["Host"] = webhook_url:match("https?://([^/]+)") or "example.com",
            ["Content-Type"] = "application/json",
            ["X-Event-Type"] = event_type,
            ["X-Webhook-ID"] = "wh_" .. os.time()
        },
        body = payload
    }
    
    local sign_options = {
        jwk = key_store.signing_keys["webhook-2024"],
        key_id = "webhook-2024",
        headers = {"(request-target)", "host", "x-event-type", "x-webhook-id", "digest", "date"},
        created = os.time(),
        expires = os.time() + 300  -- 5 minutes
    }
    
    return httpsig.sign(webhook_request, sign_options)
end

function verify_webhook(request_data, sender_key_id)
    local verify_options = {
        jwk = key_store.verification_keys[sender_key_id],
        required_headers = {"host", "x-event-type", "digest"},
        max_age = 300
    }
    
    return httpsig.verify(request_data, verify_options)
end

-- Test webhook system
local webhook_payload = '{"event": "user.created", "user_id": 12345, "timestamp": "2024-01-15T10:30:00Z"}'
local signed_webhook = sign_webhook(webhook_payload, "user.created", "https://client.example.com/webhook")

if signed_webhook then
    print("✅ Webhook signed successfully")
    print("   Event type: user.created")
    print("   Expires in: 5 minutes")
    
    -- Simulate webhook reception and verification
    local webhook_verification = verify_webhook({
        type = "request",
        method = "POST",
        path = "/webhook",
        headers = signed_webhook.headers,
        body = webhook_payload
    }, "webhook-2024")
    
    if webhook_verification and webhook_verification.valid then
        print("✅ Webhook verification successful")
    else
        print("❌ Webhook verification failed")
    end
else
    print("❌ Webhook signing failed")
end

-- Example 3: API Gateway with Multiple Algorithms
print("\n3️⃣ API Gateway Authentication")
print("------------------------------")

function create_api_request(method, endpoint, payload, auth_level)
    local key_mapping = {
        ["user"] = "user-auth-2024",
        ["admin"] = "admin-2024",
        ["system"] = "webhook-2024"
    }
    
    local key_id = key_mapping[auth_level] or "user-auth-2024"
    
    local api_request = {
        type = "request",
        method = method,
        path = endpoint,
        headers = {
            ["Host"] = "api.example.com",
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bearer token123",
            ["X-Auth-Level"] = auth_level
        },
        body = payload or ""
    }
    
    local headers_to_sign = {"(request-target)", "host", "authorization", "x-auth-level", "date"}
    if payload and payload ~= "" then
        table.insert(headers_to_sign, "digest")
    end
    
    local sign_options = {
        jwk = key_store.signing_keys[key_id],
        key_id = key_id,
        headers = headers_to_sign,
        created = os.time()
    }
    
    return httpsig.sign(api_request, sign_options)
end

-- Test different auth levels
local auth_levels = {"user", "admin", "system"}
for _, level in ipairs(auth_levels) do
    local api_request = create_api_request("GET", "/api/profile", nil, level)
    if api_request then
        local key_id = api_request.headers.signature:match('keyId="([^"]+)"')
        print("✅ " .. level .. " request signed with " .. key_id)
    end
end

-- Example 4: Signature Validation Pipeline
print("\n4️⃣ Signature Validation Pipeline")
print("---------------------------------")

function validate_request_pipeline(request_data)
    local steps = {
        {name = "Parse Signature", func = function()
            return request_data.headers.signature ~= nil
        end},
        
        {name = "Extract Key ID", func = function()
            local key_id = request_data.headers.signature:match('keyId="([^"]+)"')
            request_data.extracted_key_id = key_id
            return key_id ~= nil
        end},
        
        {name = "Verify Key Exists", func = function()
            return key_store.verification_keys[request_data.extracted_key_id] ~= nil
        end},
        
        {name = "Verify Signature", func = function()
            local verify_options = {
                jwk = key_store.verification_keys[request_data.extracted_key_id],
                required_headers = {"host", "date"},
                max_age = 300
            }
            local result = httpsig.verify(request_data, verify_options)
            return result and result.valid
        end}
    }
    
    for _, step in ipairs(steps) do
        local success = step.func()
        if success then
            print("   ✅ " .. step.name)
        else
            print("   ❌ " .. step.name .. " failed")
            return false, step.name
        end
    end
    
    return true, "All validations passed"
end

-- Test validation pipeline
local test_request = create_api_request("POST", "/api/data", '{"value": 42}', "admin")
if test_request then
    print("🔍 Running validation pipeline...")
    local success, message = validate_request_pipeline({
        type = "request",
        method = "POST",
        path = "/api/data",
        headers = test_request.headers,
        body = '{"value": 42}'
    })
    print("   Result:", success and "PASSED" or "FAILED", "-", message)
end

-- Example 5: Performance Benchmarking
print("\n5️⃣ Performance Benchmarking")
print("----------------------------")

function benchmark_algorithm(algorithm, iterations)
    local key = crypto.generate_jwk(algorithm)
    local test_request = {
        type = "request",
        method = "GET",
        path = "/test",
        headers = {["Host"] = "test.com"},
        body = ""
    }
    
    local sign_options = {
        jwk = key,
        key_id = "benchmark-key",
        headers = {"(request-target)", "host", "date"}
    }
    
    local start_time = os.clock()
    
    for i = 1, iterations do
        httpsig.sign(test_request, sign_options)
    end
    
    local elapsed = os.clock() - start_time
    local ops_per_sec = iterations / elapsed
    
    return elapsed, ops_per_sec
end

local iterations = 100
local algorithms = {"RS256", "ES256", "EdDSA"}

print("Benchmarking " .. iterations .. " signatures per algorithm:")
for _, alg in ipairs(algorithms) do
    local elapsed, ops_per_sec = benchmark_algorithm(alg, iterations)
    print("   " .. alg .. ": " .. string.format("%.0f", ops_per_sec) .. " ops/sec")
end

-- Example 6: Signature Chaining
print("\n6️⃣ Signature Chaining")
print("----------------------")

function create_signature_chain(data, signers)
    local current_data = data
    local signatures = {}
    
    for i, signer in ipairs(signers) do
        local request = {
            type = "request",
            method = "POST",
            path = "/chain",
            headers = {
                ["Host"] = "chain.example.com",
                ["X-Chain-Step"] = tostring(i)
            },
            body = current_data
        }
        
        local sign_options = {
            jwk = key_store.signing_keys[signer.key_id],
            key_id = signer.key_id,
            headers = {"(request-target)", "host", "x-chain-step", "digest", "date"}
        }
        
        local signed = httpsig.sign(request, sign_options)
        if signed then
            signatures[i] = signed.headers.signature
            current_data = current_data .. "\nSignature-" .. i .. ": " .. signed.headers.signature
            print("   ✅ Step " .. i .. ": Signed by " .. signer.key_id)
        else
            print("   ❌ Step " .. i .. ": Signing failed")
            break
        end
    end
    
    return signatures, current_data
end

-- Create a signature chain
local signers = {
    {key_id = "user-auth-2024"},
    {key_id = "admin-2024"},
    {key_id = "webhook-2024"}
}

local chain_signatures, final_data = create_signature_chain("Original document content", signers)
print("✅ Created signature chain with " .. #chain_signatures .. " signatures")

print("\n🎉 Advanced HTTP Signatures examples completed!")
print("\n💡 Advanced Patterns:")
print("• Multi-party signature chains")
print("• Algorithm-specific key management")
print("• Webhook security systems")
print("• API gateway authentication")
print("• Performance optimization strategies")