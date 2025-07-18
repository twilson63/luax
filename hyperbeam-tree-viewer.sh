#!/bin/bash

# Hyperbeam Tree Viewer - Shell Wrapper
# This is a wrapper around the Lua script for easier usage

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LUA_SCRIPT="$SCRIPT_DIR/hyperbeam-tree-viewer.lua"

# Check if the Lua script exists
if [ ! -f "$LUA_SCRIPT" ]; then
    echo "Error: hyperbeam-tree-viewer.lua not found at $LUA_SCRIPT"
    exit 1
fi

# Check if hype binary exists
if [ ! -f "$SCRIPT_DIR/hype" ]; then
    echo "Error: hype binary not found at $SCRIPT_DIR/hype"
    exit 1
fi

# Run the Lua script with hype, passing all arguments
"$SCRIPT_DIR/hype" run "$LUA_SCRIPT" -- "$@"