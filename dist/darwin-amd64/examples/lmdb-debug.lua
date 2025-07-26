-- LMDB Debug Tool
-- Tries different approaches to open and read LMDB databases
-- Usage: ./lmdb-debug <lmdb-path>

local lmdb = require("lmdb")

local function try_open_env(path, options)
    local env, err = lmdb.open(path, options)
    if env then
        return env, nil
    else
        return nil, err
    end
end

local function try_open_db(env, db_name, create)
    local success, result, err = pcall(function()
        return env:open_db(db_name, create)
    end)
    
    if success and result then
        return result, nil
    else
        return nil, err or result
    end
end

local function main(args)
    if not args or #args == 0 then
        print("Usage: ./lmdb-debug <lmdb-path>")
        return
    end
    
    local lmdb_path = args[1]
    
    print("LMDB Debug Tool")
    print("Path: " .. lmdb_path)
    print(string.rep("=", 50))
    
    -- Check files exist
    local data_file = lmdb_path .. "/data.mdb"
    local lock_file = lmdb_path .. "/lock.mdb"
    
    local file = io.open(data_file, "r")
    if file then
        local size = file:seek("end")
        file:close()
        print("✓ data.mdb exists (" .. size .. " bytes)")
    else
        print("✗ data.mdb not found")
        return
    end
    
    file = io.open(lock_file, "r")
    if file then
        file:close()
        print("✓ lock.mdb exists")
    else
        print("✗ lock.mdb not found")
    end
    
    print("")
    
    -- Try different environment configurations
    local env_configs = {
        {
            name = "Default config",
            options = {
                maxdbs = 10,
                mapsize = 1024 * 1024 * 1024
            }
        },
        {
            name = "High maxdbs",
            options = {
                maxdbs = 100,
                mapsize = 1024 * 1024 * 1024
            }
        },
        {
            name = "Larger mapsize",
            options = {
                maxdbs = 10,
                mapsize = 2 * 1024 * 1024 * 1024
            }
        },
        {
            name = "Read-only attempt",
            options = {
                maxdbs = 10,
                mapsize = 1024 * 1024 * 1024,
                readonly = true
            }
        }
    }
    
    for i, config in ipairs(env_configs) do
        print("Trying " .. config.name .. "...")
        
        local env, err = try_open_env(lmdb_path, config.options)
        if env then
            print("✓ Environment opened successfully")
            
            -- Try to get environment stats
            local stats, err = env:stat()
            if stats then
                print("  Environment stats:")
                print("    Page size: " .. stats.psize)
                print("    Tree depth: " .. stats.depth)
                print("    Branch pages: " .. stats.branch_pages)
                print("    Leaf pages: " .. stats.leaf_pages)
                print("    Overflow pages: " .. stats.overflow_pages)
                print("    Entries: " .. stats.entries)
            else
                print("  Could not get environment stats: " .. (err or "unknown"))
            end
            
            -- Try different database names
            local db_names = {"", "main", "data", "cache", "default"}
            
            for _, db_name in ipairs(db_names) do
                local display_name = db_name == "" and "(default)" or db_name
                local db, err = try_open_db(env, db_name, false)
                
                if db then
                    print("  ✓ Database '" .. display_name .. "' opened")
                    
                    -- Try to begin transaction
                    local txn, err = env:begin(true)
                    if txn then
                        print("    ✓ Transaction started")
                        
                        -- Try to create cursor
                        local cursor, err = txn:cursor(db)
                        if cursor then
                            print("    ✓ Cursor created")
                            
                            -- Try to get first key
                            local key, value, err = cursor:first()
                            if key then
                                print("    ✓ First key found: '" .. tostring(key) .. "'")
                                print("    ✓ Value length: " .. string.len(tostring(value)) .. " bytes")
                                
                                -- Try to get a few more keys
                                local count = 1
                                while count < 5 do
                                    key, value, err = cursor:next()
                                    if key then
                                        count = count + 1
                                        print("    ✓ Key " .. count .. ": '" .. tostring(key) .. "'")
                                    else
                                        break
                                    end
                                end
                                
                                print("    → SUCCESS: Use './lmdb-tree-reader " .. lmdb_path .. 
                                      (db_name == "" and "" or " " .. db_name) .. "'")
                            else
                                print("    ✗ No keys found or cursor error")
                            end
                            
                            cursor:close()
                        else
                            print("    ✗ Could not create cursor: " .. (err or "unknown"))
                        end
                        
                        txn:commit()
                    else
                        print("    ✗ Could not start transaction: " .. (err or "unknown"))
                    end
                else
                    print("  ✗ Database '" .. display_name .. "' failed: " .. (err or "unknown"))
                end
            end
            
            env:close()
            print("")
            break  -- If we successfully opened the environment, we can stop trying configs
        else
            print("✗ Failed to open environment: " .. (err or "unknown"))
        end
        
        print("")
    end
end

-- Run the application
main(arg)