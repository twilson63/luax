# LMDB Tree Reader

A command-line tool that reads LMDB databases and visualizes all keys as a tree structure, similar to the [lmdb_tree](https://github.com/twilson63/lmdb_tree) tool.

## Overview

The `lmdb-tree-reader` tool opens an LMDB database file and displays all keys in a tree visualization. It uses LMDB cursors to iterate through all keys and then builds a balanced binary tree for visualization.

## Features

- **Complete Key Discovery**: Uses LMDB cursors to find all keys in the database
- **Tree Visualization**: Displays keys in a balanced binary tree structure
- **Multiple Styles**: Supports both vertical and horizontal tree layouts
- **Database Selection**: Can read specific named databases within an LMDB environment
- **Standalone Binary**: Self-contained executable with no external dependencies

## Usage

```bash
./lmdb-tree-reader <lmdb-path> [database-name] [options]
```

### Arguments

- `lmdb-path`: Path to LMDB database directory (required)
- `database-name`: Name of database within LMDB environment (optional, defaults to main database)

### Options

- `--style=vertical`: Display tree vertically (default)
- `--style=horizontal`: Display tree horizontally
- `--help`: Show help message

### Examples

```bash
# Read the main database
./lmdb-tree-reader ./my-lmdb-data

# Read a specific named database
./lmdb-tree-reader ./my-lmdb-data users

# Use horizontal layout
./lmdb-tree-reader ./my-lmdb-data --style=horizontal

# Read the tree database from our example
./lmdb-tree-reader ./lmdb-tree-data tree

# Read the metadata database
./lmdb-tree-reader ./lmdb-tree-data metadata
```

## Example Output

### Vertical Tree (Default)
```
Reading LMDB database: ./lmdb-tree-data
Database: tree

Found 8 keys:
  1. 1
  2. 2
  3. 3
  4. 4
  5. 5
  6. 6
  7. 7
  8. 8

Tree visualization (vertical):
========================================
└── 4
    └── 2
        └── 1
        └── 3
    └── 6
        └── 5
        └── 7
            └── 8

Tree statistics:
  Total keys: 8
  Max depth: 4
  Style: vertical
```

### Horizontal Tree
```
Tree visualization (horizontal):
========================================
            8
        7
    6
        5
4
        3
    2
        1

Tree statistics:
  Total keys: 8
  Max depth: 4
  Style: horizontal
```

## Building

### From Source (with Hype)
```bash
# Build standalone binary
./hype build examples/lmdb-tree-reader.lua -o lmdb-tree-reader --plugins ./examples/plugins/lmdb

# Or run directly
./hype run examples/lmdb-tree-reader.lua --plugins ./examples/plugins/lmdb -- <lmdb-path> [database-name]
```

### Prerequisites
- Hype runtime
- LMDB plugin (included in examples/plugins/lmdb)

## Technical Details

### LMDB Integration
- Uses LMDB cursors for efficient key iteration
- Supports multiple databases within one environment
- Read-only operations (safe for production databases)
- Proper resource cleanup and error handling

### Tree Algorithm
- Builds a balanced binary search tree from sorted keys
- Uses recursive tree construction for optimal balance
- Supports both vertical and horizontal visualization styles

### Performance
- Efficient cursor-based iteration
- Memory-efficient processing of large databases
- Fast tree construction and visualization

## File Structure

```
examples/
├── lmdb-tree-reader.lua        # Main application
├── plugins/
│   └── lmdb/
│       ├── plugin.go           # LMDB plugin with cursor support
│       ├── hype-plugin.yaml    # Plugin manifest
│       └── go.mod              # Dependencies
└── README-lmdb-tree-reader.md  # This file
```

## Error Handling

The tool handles various error conditions:
- **Missing LMDB files**: Checks for data.mdb/lock.mdb files
- **Database not found**: Reports if specified database doesn't exist
- **Cursor errors**: Handles cursor creation and iteration failures
- **Empty databases**: Gracefully handles databases with no keys

## Comparison with lmdb_tree

This tool is inspired by and similar to the [lmdb_tree](https://github.com/twilson63/lmdb_tree) tool but offers:

- **Cross-platform**: Works on macOS, Linux, and Windows
- **Self-contained**: Single binary with no external dependencies
- **Flexible visualization**: Multiple display styles
- **Database selection**: Can read specific named databases
- **Hype integration**: Built using Hype's plugin system

## Use Cases

- **Database inspection**: Visualize the structure of LMDB databases
- **Debugging**: Understand key distribution and tree balance
- **Documentation**: Generate tree diagrams for documentation
- **Learning**: Understand how keys are organized in LMDB
- **Monitoring**: Check database structure and key patterns

## Extensions

This tool can be extended with:
- **Value display**: Show key-value pairs instead of just keys
- **Filtering**: Filter keys by pattern or range
- **Export**: Export tree structure to JSON/XML
- **Statistics**: More detailed database statistics
- **Comparison**: Compare multiple databases
- **Interactive mode**: Browse databases interactively

## Dependencies

- **LMDB**: Lightning Memory-Mapped Database library
- **Hype**: Runtime environment with plugin support
- **Go**: For the native LMDB plugin implementation

The standalone binary includes all dependencies and requires no external libraries.