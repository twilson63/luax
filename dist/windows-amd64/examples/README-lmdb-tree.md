# LMDB Tree Example

This example demonstrates using the LMDB plugin in a Hype Lua application to create a persistent binary tree.

## Overview

The `lmdb-tree.lua` application implements a binary search tree that stores its data persistently using LMDB (Lightning Memory-Mapped Database). This showcases:

- **Go Plugin Integration**: Uses the custom LMDB Go plugin for high-performance database operations
- **Persistent Data Structures**: Tree data survives between program runs
- **ACID Transactions**: All operations are transactional and consistent
- **CLI Interface**: Complete command-line interface for tree operations

## Features

### Tree Operations
- **Insert**: Add values to the tree with automatic BST ordering
- **Search**: Find values efficiently using binary search
- **List**: In-order traversal showing sorted values
- **Print**: Visual tree structure display
- **Stats**: Tree and database statistics

### Database Features
- **LMDB Integration**: Uses LMDB for lightning-fast key-value storage
- **Dual Databases**: Separate databases for tree nodes and metadata
- **Transaction Safety**: All operations are ACID compliant
- **Persistent Storage**: Data survives program restarts

## Usage

```bash
# Run using hype with the LMDB plugin
./hype run examples/lmdb-tree.lua --plugins ./examples/plugins/lmdb -- <command>

# Show help
./hype run examples/lmdb-tree.lua --plugins ./examples/plugins/lmdb -- help

# Insert values
./hype run examples/lmdb-tree.lua --plugins ./examples/plugins/lmdb -- insert apple
./hype run examples/lmdb-tree.lua --plugins ./examples/plugins/lmdb -- insert banana
./hype run examples/lmdb-tree.lua --plugins ./examples/plugins/lmdb -- insert cherry

# Search for values
./hype run examples/lmdb-tree.lua --plugins ./examples/plugins/lmdb -- search apple

# List all values (sorted)
./hype run examples/lmdb-tree.lua --plugins ./examples/plugins/lmdb -- list

# Print tree structure
./hype run examples/lmdb-tree.lua --plugins ./examples/plugins/lmdb -- print

# Show statistics
./hype run examples/lmdb-tree.lua --plugins ./examples/plugins/lmdb -- stats
```

## Example Session

```bash
# Insert some fruits
$ ./hype run examples/lmdb-tree.lua --plugins ./examples/plugins/lmdb -- insert apple
✓ LMDB databases initialized
✓ Inserted 'apple' as root (key: 1)
✓ LMDB databases closed

$ ./hype run examples/lmdb-tree.lua --plugins ./examples/plugins/lmdb -- insert banana
✓ LMDB databases initialized
✓ Inserted 'banana' as right child of 'apple' (key: 2)
✓ LMDB databases closed

$ ./hype run examples/lmdb-tree.lua --plugins ./examples/plugins/lmdb -- insert apricot
✓ LMDB databases initialized
✓ Inserted 'apricot' as left child of 'banana' (key: 3)
✓ LMDB databases closed

# View the tree structure
$ ./hype run examples/lmdb-tree.lua --plugins ./examples/plugins/lmdb -- print
✓ LMDB databases initialized
Tree structure:
Root: apple (key: 1)
  L: <empty>
  R: banana (key: 2)
    L: apricot (key: 3)
    R: <empty>
✓ LMDB databases closed

# List values in sorted order
$ ./hype run examples/lmdb-tree.lua --plugins ./examples/plugins/lmdb -- list
✓ LMDB databases initialized
Tree values (in-order):
  1. apple
  2. apricot
  3. banana
✓ LMDB databases closed

# Search for a value
$ ./hype run examples/lmdb-tree.lua --plugins ./examples/plugins/lmdb -- search banana
✓ LMDB databases initialized
✓ Found 'banana' (key: 2)
✓ LMDB databases closed

# Show statistics
$ ./hype run examples/lmdb-tree.lua --plugins ./examples/plugins/lmdb -- stats
✓ LMDB databases initialized
Tree Statistics:
  Node count: 3
  Max depth: 2
  Is empty: no

LMDB Statistics:
  Page size: 16384 bytes
  Tree depth: 1
  Branch pages: 0
  Leaf pages: 1
  Total entries: 2
✓ LMDB databases closed
```

## Technical Details

### Data Structure
- **Nodes**: Each tree node has a unique numeric key, string value, and optional left/right child references
- **Serialization**: Nodes are serialized as JSON strings for storage in LMDB
- **Metadata**: Root node key and next available key stored in separate metadata database

### Database Schema
- **tree database**: Stores tree nodes (key -> serialized node data)
- **metadata database**: Stores tree metadata (root key, next available key)

### Performance
- **LMDB**: Memory-mapped database provides excellent read/write performance
- **Transactions**: All operations are transactional for data integrity
- **Efficiency**: O(log n) search/insert operations with persistent storage

## File Structure

```
examples/
├── lmdb-tree.lua           # Main application
├── plugins/
│   └── lmdb/
│       ├── plugin.go       # LMDB Go plugin implementation
│       ├── hype-plugin.yaml # Plugin manifest
│       └── go.mod          # Go module dependencies
└── README-lmdb-tree.md     # This file
```

## Database Files

The application creates a `lmdb-tree-data/` directory with LMDB database files:
- `data.mdb` - Main database file
- `lock.mdb` - Lock file for concurrent access

These files persist between runs, maintaining your tree data.

## Extensions

This example can be extended with:
- **Tree balancing**: Implement AVL or Red-Black tree balancing
- **Bulk operations**: Batch insert/delete operations
- **Export/Import**: Save/load tree to/from JSON files
- **Web interface**: Add HTTP server for web-based tree manipulation
- **Cursors**: Implement range queries and tree iteration
- **Compression**: Add value compression for large datasets

## Dependencies

- **Hype**: Main runtime environment
- **LMDB Plugin**: Custom Go plugin for LMDB database operations
- **LMDB Library**: Native LMDB library (installed via Go dependencies)

This example showcases the power of Hype's plugin system and demonstrates how to build sophisticated applications with persistent data storage.