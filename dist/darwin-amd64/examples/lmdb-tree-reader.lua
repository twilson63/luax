-- LMDB Tree Reader
-- Reads an LMDB file and displays all keys in a tree structure
-- Usage: ./lmdb-tree-reader <lmdb-file> [database-name]

local lmdb = require("lmdb")

-- Tree visualization utilities
local TreeViz = {}

-- Create a tree structure from sorted keys
function TreeViz.build_tree(keys)
    if #keys == 0 then
        return nil
    end
    
    -- Find the middle element as root
    local mid = math.floor((#keys + 1) / 2)
    local root = {
        key = keys[mid],
        left = nil,
        right = nil
    }
    
    -- Recursively build left and right subtrees
    if mid > 1 then
        local left_keys = {}
        for i = 1, mid - 1 do
            table.insert(left_keys, keys[i])
        end
        root.left = TreeViz.build_tree(left_keys)
    end
    
    if mid < #keys then
        local right_keys = {}
        for i = mid + 1, #keys do
            table.insert(right_keys, keys[i])
        end
        root.right = TreeViz.build_tree(right_keys)
    end
    
    return root
end

-- Print tree structure with nice formatting
function TreeViz.print_tree(node, prefix, is_last)
    if not node then
        return
    end
    
    prefix = prefix or ""
    is_last = is_last or true
    
    -- Print current node
    local connector = is_last and "└── " or "├── "
    print(prefix .. connector .. tostring(node.key))
    
    -- Calculate prefix for children
    local child_prefix = prefix .. (is_last and "    " or "│   ")
    
    -- Print children (left first, then right)
    if node.left or node.right then
        if node.left then
            TreeViz.print_tree(node.left, child_prefix, not node.right)
        end
        if node.right then
            TreeViz.print_tree(node.right, child_prefix, true)
        end
    end
end

-- Print a horizontal tree structure
function TreeViz.print_horizontal_tree(node, depth, max_depth)
    if not node then
        return
    end
    
    depth = depth or 0
    max_depth = max_depth or TreeViz.get_max_depth(node)
    
    -- Print right subtree first (top of display)
    if node.right then
        TreeViz.print_horizontal_tree(node.right, depth + 1, max_depth)
    end
    
    -- Print current node with proper indentation
    local indent = string.rep("    ", depth)
    print(indent .. tostring(node.key))
    
    -- Print left subtree (bottom of display)
    if node.left then
        TreeViz.print_horizontal_tree(node.left, depth + 1, max_depth)
    end
end

-- Get maximum depth of tree
function TreeViz.get_max_depth(node)
    if not node then
        return 0
    end
    
    local left_depth = TreeViz.get_max_depth(node.left)
    local right_depth = TreeViz.get_max_depth(node.right)
    
    return 1 + math.max(left_depth, right_depth)
end

-- LMDB reader functions
local LMDBReader = {}

function LMDBReader.read_all_keys(lmdb_path, database_name)
    -- Open LMDB environment
    local env, err = lmdb.open(lmdb_path, {
        maxdbs = 10,
        mapsize = 1024 * 1024 * 1024  -- 1GB
    })
    
    if not env then
        error("Failed to open LMDB environment: " .. (err or "unknown error"))
    end
    
    -- Open database
    database_name = database_name or ""  -- Default database
    local db, err = env:open_db(database_name, false)  -- Don't create if doesn't exist
    if not db then
        env:close()
        error("Failed to open database '" .. database_name .. "': " .. (err or "unknown error"))
    end
    
    -- Begin read-only transaction
    local txn, err = env:begin(true)  -- true = read-only
    if not txn then
        env:close()
        error("Failed to begin transaction: " .. (err or "unknown error"))
    end
    
    -- Create cursor to iterate through all keys
    local cursor, err = txn:cursor(db)
    if not cursor then
        txn:commit()
        env:close()
        error("Failed to create cursor: " .. (err or "unknown error"))
    end
    
    -- Read all keys using cursor
    local keys = {}
    
    -- Start from first key
    local key, value, err = cursor:first()
    while key do
        table.insert(keys, key)
        
        -- Move to next key
        key, value, err = cursor:next()
        
        -- Break if no more keys or error
        if not key then
            break
        end
    end
    
    -- Clean up
    cursor:close()
    txn:commit()
    env:close()
    
    return keys
end

-- Main application
local function show_help()
    print("LMDB Tree Reader - Visualize LMDB database keys as a tree")
    print("")
    print("Usage: ./lmdb-tree-reader <lmdb-path> [database-name] [options]")
    print("")
    print("Arguments:")
    print("  lmdb-path        Path to LMDB database directory")
    print("  database-name    Name of database within LMDB (default: main database)")
    print("")
    print("Options:")
    print("  --style=vertical     Display tree vertically (default)")
    print("  --style=horizontal   Display tree horizontally")
    print("  --help              Show this help message")
    print("")
    print("Examples:")
    print("  ./lmdb-tree-reader ./lmdb-tree-data")
    print("  ./lmdb-tree-reader ./lmdb-tree-data tree")
    print("  ./lmdb-tree-reader ./lmdb-tree-data --style=horizontal")
    print("")
end

local function parse_args(args)
    local config = {
        lmdb_path = nil,
        database_name = "",
        style = "vertical",
        help = false
    }
    
    for i, arg in ipairs(args) do
        if arg == "--help" or arg == "-h" then
            config.help = true
        elseif arg:match("^--style=(.+)$") then
            config.style = arg:match("^--style=(.+)$")
        elseif not config.lmdb_path then
            config.lmdb_path = arg
        elseif config.database_name == "" then
            config.database_name = arg
        end
    end
    
    return config
end

local function main(args)
    local config = parse_args(args or {})
    
    if config.help or not config.lmdb_path then
        show_help()
        return
    end
    
    -- Check if LMDB path exists
    local file = io.open(config.lmdb_path .. "/data.mdb", "r")
    if not file then
        file = io.open(config.lmdb_path .. "/lock.mdb", "r")
        if not file then
            print("Error: LMDB database not found at: " .. config.lmdb_path)
            print("Make sure the path contains data.mdb or lock.mdb files")
            return
        end
    end
    if file then file:close() end
    
    print("Reading LMDB database: " .. config.lmdb_path)
    if config.database_name ~= "" then
        print("Database: " .. config.database_name)
    else
        print("Database: (default)")
    end
    print("")
    
    -- Read all keys from LMDB
    local success, keys = pcall(LMDBReader.read_all_keys, config.lmdb_path, config.database_name)
    if not success then
        print("Error reading LMDB database: " .. keys)
        return
    end
    
    if #keys == 0 then
        print("No keys found in database.")
        print("Note: This tool currently has limited key discovery capabilities.")
        print("It works best with databases created by the lmdb-tree example.")
        return
    end
    
    -- Sort keys for better tree visualization
    table.sort(keys, function(a, b)
        -- Try to sort numerically if possible, otherwise lexicographically
        local num_a = tonumber(a)
        local num_b = tonumber(b)
        if num_a and num_b then
            return num_a < num_b
        else
            return tostring(a) < tostring(b)
        end
    end)
    
    print("Found " .. #keys .. " keys:")
    for i, key in ipairs(keys) do
        print("  " .. i .. ". " .. key)
    end
    print("")
    
    -- Build and display tree
    local tree = TreeViz.build_tree(keys)
    if tree then
        print("Tree visualization (" .. config.style .. "):")
        print(string.rep("=", 40))
        
        if config.style == "horizontal" then
            TreeViz.print_horizontal_tree(tree)
        else
            TreeViz.print_tree(tree)
        end
        
        print("")
        print("Tree statistics:")
        print("  Total keys: " .. #keys)
        print("  Max depth: " .. TreeViz.get_max_depth(tree))
        print("  Style: " .. config.style)
    else
        print("No tree to display.")
    end
end

-- Run the application
main(arg)