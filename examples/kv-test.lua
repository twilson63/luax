-- Key-Value Database Test Script
local kv = require('kv')

print("Testing KV database functionality...")

-- Open database 
local db, err = kv.open("./test-db.bolt")

if err then
    print("Error opening database:", err)
    os.exit(1)
end

print("Database opened successfully!")

-- Create a bucket (similar to opening a database in LMDB)
local err = db:open_db("users")
if err then
    print("Error creating users bucket:", err)
    db:close()
    os.exit(1)
end

print("Users bucket created/opened")

-- Test basic operations
print("\n--- Testing basic operations ---")

-- Put some data
local err = db:put("users", "user1", "John Doe")
if err then
    print("Error putting data:", err)
else
    print("✓ Put: user1 -> John Doe")
end

local err = db:put("users", "user2", "Jane Smith")
if err then
    print("Error putting data:", err)
else
    print("✓ Put: user2 -> Jane Smith")
end

-- Get data
local value, err = db:get("users", "user1")
if err then
    print("Error getting data:", err)
elseif value then
    print("✓ Get: user1 ->", value)
else
    print("Key not found: user1")
end

local value, err = db:get("users", "user2")
if err then
    print("Error getting data:", err)
elseif value then
    print("✓ Get: user2 ->", value)
else
    print("Key not found: user2")
end

-- Test non-existent key
local value, err = db:get("users", "user3")
if err then
    print("Error getting data:", err)
elseif value then
    print("Get: user3 ->", value)
else
    print("✓ Key not found: user3 (expected)")
end

print("\n--- Testing transactions ---")

-- Test transactions
local txn, err = db:begin_txn(false)
if err then
    print("Error starting transaction:", err)
else
    print("✓ Transaction started")
    
    -- Put data in transaction
    local err = txn:put("users", "user3", "Bob Wilson")
    if err then
        print("Error in txn put:", err)
        txn:abort()
    else
        print("✓ Txn Put: user3 -> Bob Wilson")
        
        -- Commit transaction
        local err = txn:commit()
        if err then
            print("Error committing transaction:", err)
        else
            print("✓ Transaction committed")
        end
    end
end

-- Verify transaction worked
local value, err = db:get("users", "user3")
if err then
    print("Error getting txn data:", err)
elseif value then
    print("✓ Txn result: user3 ->", value)
else
    print("Txn key not found: user3")
end

print("\n--- Testing delete ---")

-- Delete a key
local err = db:delete("users", "user2")
if err then
    print("Error deleting key:", err)
else
    print("✓ Deleted: user2")
end

-- Verify deletion
local value, err = db:get("users", "user2")
if err then
    print("Error checking deleted key:", err)
elseif value then
    print("Delete failed: user2 still exists ->", value)
else
    print("✓ Confirmed: user2 deleted")
end

print("\n--- Final state ---")
print("Remaining keys:")

-- Check remaining data
local value, err = db:get("users", "user1")
if value then print("- user1:", value) end

local value, err = db:get("users", "user3")
if value then print("- user3:", value) end

print("\n--- Testing cursor functionality ---")

-- List all keys using keys() function
local keys, err = db:keys("users")
if err then
    print("Error getting keys:", err)
else
    print("Keys using db:keys():")
    for i = 1, #keys do
        print("  " .. i .. ":", keys[i])
    end
end

-- Iterate using foreach
print("\nAll data using db:foreach():")
local err = db:foreach("users", function(key, value)
    print("  " .. key .. " = " .. value)
    return true -- continue
end)
if err then
    print("Error in foreach:", err)
end

-- Close database
db:close()
print("\n✓ Database closed successfully!")
print("KV database test completed!")