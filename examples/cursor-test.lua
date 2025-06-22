-- Key-Value Database Cursor Test Script
local kv = require('kv')

print("Testing KV database cursor functionality...")

-- Open database 
local db, err = kv.open("./cursor-test.bolt")
if err then
    print("Error opening database:", err)
    os.exit(1)
end

print("Database opened successfully!")

-- Create a bucket
local err = db:open_db("users")
if err then
    print("Error creating users bucket:", err)
    db:close()
    os.exit(1)
end

print("Users bucket created/opened")

-- Add some test data
print("\n--- Adding test data ---")
local users = {
    {"admin:alice", "Alice Administrator"},
    {"admin:bob", "Bob Administrator"},
    {"user:charlie", "Charlie User"},
    {"user:diana", "Diana User"},
    {"user:eve", "Eve User"},
    {"guest:frank", "Frank Guest"}
}

for _, user in ipairs(users) do
    local err = db:put("users", user[1], user[2])
    if err then
        print("Error adding user:", err)
    else
        print("✓ Added:", user[1], "->", user[2])
    end
end

print("\n--- Testing db:keys() - List all keys ---")
local keys, err = db:keys("users")
if err then
    print("Error getting keys:", err)
else
    print("All keys:")
    for i = 1, #keys do
        print("  " .. i .. ":", keys[i])
    end
end

print("\n--- Testing db:keys() with prefix - List admin users ---")
local adminKeys, err = db:keys("users", "admin:")
if err then
    print("Error getting admin keys:", err)
else
    print("Admin keys:")
    for i = 1, #adminKeys do
        print("  " .. i .. ":", adminKeys[i])
    end
end

print("\n--- Testing db:foreach() - Iterate through all data ---")
local err = db:foreach("users", function(key, value)
    print("  " .. key .. " -> " .. value)
    return true -- continue iteration
end)
if err then
    print("Error in foreach:", err)
end

print("\n--- Testing db:foreach() with early termination ---")
print("Stopping after first 3 items:")
local count = 0
local err = db:foreach("users", function(key, value)
    count = count + 1
    print("  " .. count .. ". " .. key .. " -> " .. value)
    if count >= 3 then
        return false -- stop iteration
    end
    return true -- continue iteration
end)
if err then
    print("Error in foreach:", err)
end

-- Close database
db:close()
print("\n✓ Database closed successfully!")
print("Cursor test completed!")