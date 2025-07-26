# Hype REPL (Read-Eval-Print Loop)

The Hype REPL is an interactive environment for testing Lua code, exploring the Hype API, and rapid prototyping. Available in v1.9.0+.

## Overview

The REPL provides two modes:
- **TUI Mode** (default): A beautiful terminal UI with separate output and input panels
- **Simple Mode**: A basic command-line interface

## Starting the REPL

```bash
# Start TUI REPL (default)
./hype repl

# Start simple REPL
./hype repl --simple
```

## TUI REPL Features

### Interface Layout

The TUI REPL displays with two panels:
- **Output Panel** (top): Shows command history, results, and messages
- **Input Panel** (bottom): Where you type your Lua expressions

### Table Formatting

Lua tables are automatically formatted for easy reading:

```lua
hype> {name="Alice", age=25, skills={"Lua", "Go", "Python"}}
{
  ["age"] = 25,
  ["name"] = "Alice",
  ["skills"] = {
    [1] = "Lua",
    [2] = "Go",
    [3] = "Python"
  }
}
```

### Special Commands

The REPL supports special commands that start with `:`:

| Command | Description |
|---------|-------------|
| `:help` | Show available commands and tips |
| `:history` or `:h` | Display command history with numbered entries |
| `:h=N` | Recall command N from history into the input field |
| `:clear` | Clear the output panel |

### History Management

Every command you execute is saved in the session history:

```lua
hype> :history
Command History:
  1: 2 + 2
  2: math.sqrt(16)
  3: crypto.sha256("test")

hype> :h=2
Recalled: math.sqrt(16)
```

The recalled command appears in the input field, ready to edit or execute.

## Available Modules

All Hype modules are pre-loaded and available:

- **`tui`** - Terminal UI components
- **`http`** - HTTP client and server
- **`kv`** - Key-value database
- **`crypto`** - Cryptographic functions
- **`ws`** - WebSocket support

## Usage Examples

### Basic Expressions

```lua
-- Arithmetic
hype> 2 + 2
4

-- String manipulation
hype> string.upper("hello")
HELLO

-- Tables
hype> t = {1, 2, 3}
hype> #t
3
```

### Using Hype Modules

```lua
-- Crypto operations
hype> crypto.sha256("hello world")
b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9

-- Generate a key
hype> key = crypto.generate_jwk("ES256")
hype> key
{
  ["alg"] = "ES256",
  ["crv"] = "P-256",
  ["d"] = "...",
  ["kty"] = "EC",
  ["use"] = "sig",
  ["x"] = "...",
  ["y"] = "..."
}

-- HTTP request (if network available)
hype> resp = http.get("https://api.example.com/data")
```

### Multiline Code

The simple REPL supports multiline input:

```lua
hype> function factorial(n)
....>     if n <= 1 then return 1 end
....>     return n * factorial(n-1)
....> end
hype> factorial(5)
120
```

## Tips and Tricks

1. **Explore Tables**: Use the REPL to explore module contents:
   ```lua
   hype> math
   -- Shows all math functions in a formatted table
   ```

2. **Test Functions**: Quickly test your functions before building:
   ```lua
   hype> function greet(name) return "Hello, " .. name end
   hype> greet("World")
   Hello, World
   ```

3. **Inspect Values**: The table formatter makes it easy to inspect complex data:
   ```lua
   hype> _G  -- Shows all global variables
   ```

4. **Quick Calculations**: Use as a powerful calculator:
   ```lua
   hype> 2^10
   1024
   hype> math.pi * 10^2
   314.15926535898
   ```

## Controls

- **Enter**: Execute the current expression
- **Ctrl+C**: Exit the REPL
- **Escape**: Clear current input (TUI mode)

## Simple Mode

The simple mode (`--simple` flag) provides a basic REPL without the TUI:
- Supports all the same Lua functionality
- Better for piping/scripting
- Multiline support with `\` continuation
- No special commands (`:history`, etc.)

## Troubleshooting

### Input Not Working
If typing doesn't work in TUI mode, try the simple mode with `--simple`.

### Colors/Display Issues
The TUI mode works best with terminals that support 256 colors. If you experience display issues, use simple mode.

### Large Output
Very large outputs may be truncated in TUI mode for performance. Use simple mode for unlimited output.

## Integration with Scripts

You can test functions from your scripts:

```lua
-- In REPL
hype> dofile("mylib.lua")
hype> myfunction(123)  -- Test your function
```

This makes the REPL perfect for iterative development and debugging.