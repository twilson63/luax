-- LMDB Tree Binary
-- A persistent binary tree implementation using LMDB for storage
-- Usage: ./lmdb-tree <command> [args...]

local lmdb = require("lmdb")

-- Configuration
local DB_PATH = "./lmdb-tree-data"
local TREE_DB = "tree"
local METADATA_DB = "metadata"

-- Global database handles
local env = nil
local tree_db = nil
local metadata_db = nil

-- Tree node structure (serialized to JSON)
local TreeNode = {}
TreeNode.__index = TreeNode

function TreeNode:new(key, value, left, right)
    local node = {
        key = key,
        value = value,
        left = left,    -- key of left child node
        right = right   -- key of right child node
    }
    setmetatable(node, self)
    return node
end

function TreeNode:serialize()
    return string.format('{"key":%s,"value":"%s","left":%s,"right":%s}',
        self.key,
        self.value or "",
        self.left and tostring(self.left) or "null",
        self.right and tostring(self.right) or "null"
    )
end

function TreeNode:deserialize(data)
    -- Simple JSON parsing for tree nodes
    local key = data:match('"key":(%d+)')
    local value = data:match('"value":"([^"]*)"')
    local left = data:match('"left":(%d+)')
    local right = data:match('"right":(%d+)')
    
    return TreeNode:new(
        tonumber(key),
        value,
        tonumber(left),
        tonumber(right)
    )
end

-- Database operations
local DB = {}

function DB.init()
    -- Open LMDB environment
    local err
    env, err = lmdb.open(DB_PATH, {
        maxdbs = 10,
        mapsize = 1024 * 1024 * 100  -- 100MB
    })
    
    if not env then
        error("Failed to open LMDB environment: " .. (err or "unknown error"))
    end
    
    -- Open databases
    tree_db, err = env:open_db(TREE_DB, true)
    if not tree_db then
        error("Failed to open tree database: " .. (err or "unknown error"))
    end
    
    metadata_db, err = env:open_db(METADATA_DB, true)
    if not metadata_db then
        error("Failed to open metadata database: " .. (err or "unknown error"))
    end
    
    print("✓ LMDB databases initialized")
end

function DB.close()
    if env then
        env:close()
        print("✓ LMDB databases closed")
    end
end

function DB.get_node(key)
    local txn, err = env:begin(true)  -- read-only transaction
    if not txn then
        error("Failed to begin transaction: " .. (err or "unknown error"))
    end
    
    local data, err = txn:get(tree_db, tostring(key))
    txn:commit()
    
    if not data then
        return nil
    end
    
    return TreeNode:deserialize(data)
end

function DB.put_node(node)
    local txn, err = env:begin(false)  -- read-write transaction
    if not txn then
        error("Failed to begin transaction: " .. (err or "unknown error"))
    end
    
    local success, err = txn:put(tree_db, tostring(node.key), node:serialize())
    if not success then
        txn:abort()
        error("Failed to store node: " .. (err or "unknown error"))
    end
    
    local success, err = txn:commit()
    if not success then
        error("Failed to commit transaction: " .. (err or "unknown error"))
    end
end

function DB.delete_node(key)
    local txn, err = env:begin(false)  -- read-write transaction
    if not txn then
        error("Failed to begin transaction: " .. (err or "unknown error"))
    end
    
    local success, err = txn:del(tree_db, tostring(key))
    if not success then
        txn:abort()
        return false, err
    end
    
    local success, err = txn:commit()
    if not success then
        error("Failed to commit transaction: " .. (err or "unknown error"))
    end
    
    return true
end

function DB.get_root()
    local txn, err = env:begin(true)  -- read-only transaction
    if not txn then
        error("Failed to begin transaction: " .. (err or "unknown error"))
    end
    
    local root_key, err = txn:get(metadata_db, "root")
    txn:commit()
    
    if not root_key then
        return nil
    end
    
    return tonumber(root_key)
end

function DB.set_root(key)
    local txn, err = env:begin(false)  -- read-write transaction
    if not txn then
        error("Failed to begin transaction: " .. (err or "unknown error"))
    end
    
    local success, err = txn:put(metadata_db, "root", tostring(key))
    if not success then
        txn:abort()
        error("Failed to set root: " .. (err or "unknown error"))
    end
    
    local success, err = txn:commit()
    if not success then
        error("Failed to commit transaction: " .. (err or "unknown error"))
    end
end

function DB.get_next_key()
    local txn, err = env:begin(true)  -- read-only transaction
    if not txn then
        error("Failed to begin transaction: " .. (err or "unknown error"))
    end
    
    local next_key, err = txn:get(metadata_db, "next_key")
    txn:commit()
    
    if not next_key then
        return 1
    end
    
    return tonumber(next_key)
end

function DB.increment_next_key()
    local current_key = DB.get_next_key()
    local new_key = current_key + 1
    
    local txn, err = env:begin(false)  -- read-write transaction
    if not txn then
        error("Failed to begin transaction: " .. (err or "unknown error"))
    end
    
    local success, err = txn:put(metadata_db, "next_key", tostring(new_key))
    if not success then
        txn:abort()
        error("Failed to increment next_key: " .. (err or "unknown error"))
    end
    
    local success, err = txn:commit()
    if not success then
        error("Failed to commit transaction: " .. (err or "unknown error"))
    end
    
    return current_key
end

-- Binary Tree operations
local Tree = {}

function Tree.insert(value)
    local root_key = DB.get_root()
    local new_key = DB.get_next_key()
    
    if not root_key then
        -- First node becomes root
        local root_node = TreeNode:new(new_key, value)
        DB.put_node(root_node)
        DB.set_root(new_key)
        DB.increment_next_key()
        print(string.format("✓ Inserted '%s' as root (key: %d)", value, new_key))
        return
    end
    
    -- Insert into existing tree
    local function insert_recursive(node_key, value)
        local node = DB.get_node(node_key)
        if not node then
            error("Node not found: " .. node_key)
        end
        
        if value < node.value then
            if node.left then
                insert_recursive(node.left, value)
            else
                local new_node = TreeNode:new(new_key, value)
                DB.put_node(new_node)
                node.left = new_key
                DB.put_node(node)
                print(string.format("✓ Inserted '%s' as left child of '%s' (key: %d)", value, node.value, new_key))
            end
        else
            if node.right then
                insert_recursive(node.right, value)
            else
                local new_node = TreeNode:new(new_key, value)
                DB.put_node(new_node)
                node.right = new_key
                DB.put_node(node)
                print(string.format("✓ Inserted '%s' as right child of '%s' (key: %d)", value, node.value, new_key))
            end
        end
    end
    
    insert_recursive(root_key, value)
    DB.increment_next_key()
end

function Tree.search(value)
    local root_key = DB.get_root()
    if not root_key then
        return false, "Tree is empty"
    end
    
    local function search_recursive(node_key, value)
        if not node_key then
            return false
        end
        
        local node = DB.get_node(node_key)
        if not node then
            return false
        end
        
        if node.value == value then
            return true, node
        elseif value < node.value then
            return search_recursive(node.left, value)
        else
            return search_recursive(node.right, value)
        end
    end
    
    return search_recursive(root_key, value)
end

function Tree.traverse_inorder(callback)
    local root_key = DB.get_root()
    if not root_key then
        return
    end
    
    local function traverse_recursive(node_key)
        if not node_key then
            return
        end
        
        local node = DB.get_node(node_key)
        if not node then
            return
        end
        
        traverse_recursive(node.left)
        callback(node)
        traverse_recursive(node.right)
    end
    
    traverse_recursive(root_key)
end

function Tree.print_tree()
    local root_key = DB.get_root()
    if not root_key then
        print("Tree is empty")
        return
    end
    
    local function print_recursive(node_key, depth, prefix)
        if not node_key then
            return
        end
        
        local node = DB.get_node(node_key)
        if not node then
            return
        end
        
        print(string.rep("  ", depth) .. prefix .. node.value .. " (key: " .. node.key .. ")")
        
        if node.left or node.right then
            if node.left then
                print_recursive(node.left, depth + 1, "L: ")
            else
                print(string.rep("  ", depth + 1) .. "L: <empty>")
            end
            
            if node.right then
                print_recursive(node.right, depth + 1, "R: ")
            else
                print(string.rep("  ", depth + 1) .. "R: <empty>")
            end
        end
    end
    
    print("Tree structure:")
    print_recursive(root_key, 0, "Root: ")
end

-- Statistics
function Tree.get_stats()
    local root_key = DB.get_root()
    if not root_key then
        return {
            node_count = 0,
            max_depth = 0,
            is_empty = true
        }
    end
    
    local node_count = 0
    local max_depth = 0
    
    local function count_nodes(node_key, depth)
        if not node_key then
            return
        end
        
        local node = DB.get_node(node_key)
        if not node then
            return
        end
        
        node_count = node_count + 1
        max_depth = math.max(max_depth, depth)
        
        count_nodes(node.left, depth + 1)
        count_nodes(node.right, depth + 1)
    end
    
    count_nodes(root_key, 1)
    
    return {
        node_count = node_count,
        max_depth = max_depth,
        is_empty = false
    }
end

-- CLI Interface
local function show_help()
    print("LMDB Tree Binary - Persistent Binary Tree using LMDB")
    print("")
    print("Usage: ./lmdb-tree <command> [args...]")
    print("")
    print("Commands:")
    print("  insert <value>    Insert a value into the tree")
    print("  search <value>    Search for a value in the tree")
    print("  list              List all values in the tree (in-order)")
    print("  print             Print the tree structure")
    print("  stats             Show tree statistics")
    print("  clear             Clear the entire tree")
    print("  help              Show this help message")
    print("")
    print("Examples:")
    print("  ./lmdb-tree insert apple")
    print("  ./lmdb-tree insert banana")
    print("  ./lmdb-tree search apple")
    print("  ./lmdb-tree list")
    print("  ./lmdb-tree print")
    print("")
end

local function main(args)
    -- Parse command line arguments
    args = args or {}
    local command = args[1]
    
    if not command or command == "help" then
        show_help()
        return
    end
    
    -- Initialize database
    DB.init()
    
    -- Handle commands
    if command == "insert" then
        local value = args[2]
        if not value then
            print("Error: Please provide a value to insert")
            print("Usage: ./lmdb-tree insert <value>")
            return
        end
        
        Tree.insert(value)
        
    elseif command == "search" then
        local value = args[2]
        if not value then
            print("Error: Please provide a value to search")
            print("Usage: ./lmdb-tree search <value>")
            return
        end
        
        local found, node = Tree.search(value)
        if found then
            print(string.format("✓ Found '%s' (key: %d)", value, node.key))
        else
            print(string.format("✗ Value '%s' not found", value))
        end
        
    elseif command == "list" then
        print("Tree values (in-order):")
        local values = {}
        Tree.traverse_inorder(function(node)
            table.insert(values, node.value)
        end)
        
        if #values == 0 then
            print("  (empty)")
        else
            for i, value in ipairs(values) do
                print(string.format("  %d. %s", i, value))
            end
        end
        
    elseif command == "print" then
        Tree.print_tree()
        
    elseif command == "stats" then
        local stats = Tree.get_stats()
        print("Tree Statistics:")
        print(string.format("  Node count: %d", stats.node_count))
        print(string.format("  Max depth: %d", stats.max_depth))
        print(string.format("  Is empty: %s", stats.is_empty and "yes" or "no"))
        
        -- Get LMDB statistics
        local lmdb_stats, err = env:stat()
        if lmdb_stats then
            print("")
            print("LMDB Statistics:")
            print(string.format("  Page size: %d bytes", lmdb_stats.psize))
            print(string.format("  Tree depth: %d", lmdb_stats.depth))
            print(string.format("  Branch pages: %d", lmdb_stats.branch_pages))
            print(string.format("  Leaf pages: %d", lmdb_stats.leaf_pages))
            print(string.format("  Total entries: %d", lmdb_stats.entries))
        end
        
    elseif command == "clear" then
        print("Clearing tree...")
        
        -- Note: For a complete implementation, we'd need to implement
        -- a proper tree deletion that removes all nodes
        -- For now, we'll just remove the root reference
        
        local root_key = DB.get_root()
        if root_key then
            -- Simple approach: just remove root reference
            -- In a production system, you'd want to traverse and delete all nodes
            local txn, err = env:begin(false)
            if txn then
                txn:del(metadata_db, "root")
                txn:commit()
                print("✓ Tree cleared (root reference removed)")
                print("Note: Node data still exists in database for recovery")
            else
                print("✗ Failed to clear tree")
            end
        else
            print("Tree is already empty")
        end
        
    else
        print("Unknown command: " .. command)
        show_help()
    end
    
    -- Clean up
    DB.close()
end

-- Run the application
main(arg)