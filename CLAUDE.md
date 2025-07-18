# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Hype is a Go-based tool that packages Lua scripts into standalone executables with TUI (Terminal User Interface), HTTP server, and embedded database support. It embeds a Lua runtime with custom modules to create cross-platform applications with zero external dependencies.

## Development Commands

### Building and Testing
```bash
# Build the main hype executable
make build

# Build development version with race detection
make dev

# Run tests
make test

# Clean build artifacts
rm -f hype

# Build releases for all platforms
make releases
```

### Running Examples and Development
```bash
# Run Lua scripts directly in development mode (recommended for testing)
./hype run script.lua
./hype run script.lua -- --arg1 value1 --arg2 value2

# Build standalone executables
./hype build script.lua -o output_name
./hype build script.lua -t windows -o myapp-windows
./hype build script.lua -t linux -o myapp-linux
./hype build script.lua -t darwin -o myapp-darwin

# Cross-compilation with GOOS/GOARCH (v1.7.1+)
GOOS=linux GOARCH=amd64 ./hype build script.lua -o myapp-linux-amd64
GOOS=linux GOARCH=arm64 ./hype build script.lua -o myapp-linux-arm64
GOOS=darwin GOARCH=amd64 ./hype build script.lua -o myapp-macos-intel
GOOS=darwin GOARCH=arm64 ./hype build script.lua -o myapp-macos-arm64
GOOS=windows GOARCH=amd64 ./hype build script.lua -o myapp-windows.exe

# Test with provided examples
./hype run examples/hello.lua
./hype run examples/webserver.lua
./hype run examples/kv-test.lua
./hype run examples/browser.lua
```

Note: The README incorrectly mentions `eval` command - the actual command is `run`.

## Architecture

### Core Components

**main.go**: CLI entry point using Cobra framework
- `build` command: Packages Lua scripts into executables
- `run` command: Executes Lua scripts directly for development
- `version` command: Shows version information

**builder.go**: Executable generation system
- Creates temporary Go runtime embedding the Lua script
- Generates complete Go application with all dependencies
- Cross-compiles for different platforms
- Uses Go's template system to inject Lua scripts into runtime

**eval.go**: Direct script execution for development
- Provides immediate script execution without building
- Sets up Lua state with all modules (TUI, HTTP, KV)
- Handles command line argument passing to Lua scripts

### Lua Module System

The tool provides three main Lua modules:

**TUI Module** (`tui`):
- Built on rivo/tview and gdamore/tcell
- Components: App, TextView, InputField, Button, Flex
- Method chaining pattern with Go userdata and metatables

**HTTP Module** (`http`):
- Client: GET requests with timeout and header support
- Server: Pattern-based routing with JSON response helpers
- Goroutine-based server execution for non-blocking operation

**KV Module** (`kv`):
- BoltDB-based embedded key-value store
- ACID transactions with commit/rollback
- Bucket-based organization with prefix search
- Cursor iteration support

### Cross-Platform Building

The build system:
1. Creates temporary directory with generated Go runtime
2. Embeds Lua script as string constant in Go template
3. Generates go.mod with required dependencies
4. Cross-compiles using GOOS/GOARCH environment variables
5. Handles platform-specific executable extensions (.exe for Windows)

## Code Patterns

### Lua-Go Bridge Pattern
All Lua modules use consistent userdata/metatable patterns:
- Go structs wrapped in Lua userdata
- Method dispatch through `__index` metamethods  
- Consistent error handling (nil + error string returns)
- Memory management via garbage collection finalizers

### HTTP Request Handling
HTTP handlers receive request/response Lua tables with methods:
- Request: `.method`, `.url`, `.body`, `.headers`
- Response: `:write()`, `:json()`, `:header()`, `:status()`

### Database Operations
KV operations follow bucket-based pattern:
- `db:open_db("bucket_name")` - Create/access bucket
- `db:get("bucket", "key")` - Get value
- `db:put("bucket", "key", "value")` - Set value
- Transaction support with explicit commit/rollback

## Testing Strategy

Test Lua scripts in development using `./hype run script.lua` before building executables. This provides immediate feedback and easier debugging compared to the build process.

Example scripts in `examples/` directory demonstrate all major features and serve as integration tests.

## Build Dependencies

- Go 1.23+ (uses toolchain go1.24.3)
- Key Go modules:
  - `github.com/spf13/cobra` - CLI framework
  - `github.com/yuin/gopher-lua` - Lua runtime
  - `github.com/rivo/tview` - TUI components
  - `github.com/gdamore/tcell/v2` - Terminal handling
  - `go.etcd.io/bbolt` - Embedded database

## Platform Support

Cross-compilation targets:
- Linux (amd64, arm64)
- macOS/Darwin (amd64, arm64) 
- Windows (amd64)

Platform-specific considerations:
- macOS requires Gatekeeper bypass: `xattr -d com.apple.quarantine /path/to/hype`
- Windows executables get `.exe` extension automatically
- All platforms produce single-binary deployments with no external dependencies