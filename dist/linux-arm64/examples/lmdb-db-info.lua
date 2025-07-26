-- LMDB Database Info Tool
-- Discovers available databases in an LMDB environment
-- Usage: ./lmdb-db-info <lmdb-path>

local lmdb = require("lmdb")

local function show_help()
    print("LMDB Database Info Tool")
    print("Usage: ./lmdb-db-info <lmdb-path>")
    print("")
    print("This tool attempts to discover available databases in an LMDB environment.")
    print("It will try common database names and show which ones exist.")
end

local function try_database(env, db_name)
    local success, db, err = pcall(function()
        return env:open_db(db_name, false)  -- Don't create
    end)
    
    if success and db then
        return true, db
    else
        return false, err
    end
end

local function get_db_stats(env, db_name)
    local db_ok, db = try_database(env, db_name)
    if not db_ok then
        return nil, "Database not accessible"
    end
    
    local txn, err = env:begin(true)  -- Read-only
    if not txn then
        return nil, "Failed to begin transaction: " .. (err or "unknown")
    end
    
    -- Try to create cursor and count keys
    local cursor, err = txn:cursor(db)
    if not cursor then
        txn:commit()
        return nil, "Failed to create cursor: " .. (err or "unknown")
    end
    
    local key_count = 0
    local sample_keys = {}
    
    -- Count keys and collect samples
    local key, value, err = cursor:first()
    while key and key_count < 1000 do  -- Limit to avoid hanging on huge DBs
        key_count = key_count + 1
        
        -- Collect first 5 keys as samples
        if #sample_keys < 5 then
            table.insert(sample_keys, key)
        end
        
        key, value, err = cursor:next()
        if not key then
            break
        end
    end
    
    cursor:close()
    txn:commit()
    
    return {
        key_count = key_count,
        sample_keys = sample_keys
    }
end

local function main(args)
    if not args or #args == 0 then
        show_help()
        return
    end
    
    local lmdb_path = args[1]
    
    -- Check if LMDB files exist
    local data_file = lmdb_path .. "/data.mdb"
    local lock_file = lmdb_path .. "/lock.mdb"
    
    local file = io.open(data_file, "r")
    if not file then
        file = io.open(lock_file, "r")
        if not file then
            print("Error: LMDB database not found at: " .. lmdb_path)
            print("Make sure the path contains data.mdb or lock.mdb files")
            return
        end
    end
    if file then file:close() end
    
    print("LMDB Database Info for: " .. lmdb_path)
    print(string.rep("=", 50))
    
    -- Open environment
    local env, err = lmdb.open(lmdb_path, {
        maxdbs = 50,  -- Allow more databases
        mapsize = 1024 * 1024 * 1024  -- 1GB
    })
    
    if not env then
        print("Error: Failed to open LMDB environment: " .. (err or "unknown"))
        return
    end
    
    -- Try common database names
    local common_names = {
        "",         -- Default database
        "main",
        "data",
        "cache",
        "sessions",
        "default",
        "store",
        "index",
        "metadata",
        "tree",
        "users",
        "config",
        "log",
        "events",
        "queue",
        "temp"
    }
    
    local found_databases = {}
    
    for _, db_name in ipairs(common_names) do
        local display_name = db_name == "" and "(default)" or db_name
        local db_ok, db = try_database(env, db_name)
        
        if db_ok then
            local stats, err = get_db_stats(env, db_name)
            if stats then
                table.insert(found_databases, {
                    name = display_name,
                    internal_name = db_name,
                    key_count = stats.key_count,
                    sample_keys = stats.sample_keys
                })
                print("✓ Found database: " .. display_name .. " (" .. stats.key_count .. " keys)")
            else
                print("✓ Found database: " .. display_name .. " (error reading: " .. (err or "unknown") .. ")")
            end
        end
    end
    
    env:close()
    
    print("")
    print("Summary:")
    print("--------")
    
    if #found_databases == 0 then
        print("No accessible databases found.")
        print("This could mean:")
        print("  - The LMDB uses custom database names")
        print("  - Database permissions or corruption issues")
        print("  - Different LMDB format/version")
    else
        print("Found " .. #found_databases .. " database(s):")
        print("")
        
        for i, db in ipairs(found_databases) do
            print(string.format("%d. %s", i, db.name))
            print(string.format("   Keys: %d", db.key_count))
            
            if #db.sample_keys > 0 then
                print("   Sample keys: " .. table.concat(db.sample_keys, ", "))
            end
            
            -- Show how to use with tree reader
            if db.internal_name == "" then
                print("   Use: ./lmdb-tree-reader " .. lmdb_path)
            else
                print("   Use: ./lmdb-tree-reader " .. lmdb_path .. " " .. db.internal_name)
            end
            print("")
        end
    end
end

-- Run the application
main(arg)