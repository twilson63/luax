# Hype REPL - Interactive Development Guide

> Master the interactive REPL for rapid Lua development and API exploration

## Table of Contents
1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [TUI REPL Features](#tui-repl-features)
4. [Simple REPL Mode](#simple-repl-mode)
5. [Special Commands](#special-commands)
6. [Working with Modules](#working-with-modules)
7. [Advanced Usage](#advanced-usage)
8. [Tips & Tricks](#tips--tricks)
9. [Common Workflows](#common-workflows)
10. [Troubleshooting](#troubleshooting)

## Introduction

The Hype REPL (Read-Eval-Print Loop) provides an interactive environment for:
- 🚀 **Rapid prototyping** - Test ideas instantly
- 🔍 **API exploration** - Discover module capabilities
- 🐛 **Debugging** - Inspect values and test functions
- 📚 **Learning** - Experiment with Hype features
- 🧪 **Testing** - Validate code before building

Available since v1.9.0, the REPL comes in two flavors:
- **TUI REPL** (default) - Rich terminal interface with panels
- **Simple REPL** - Basic command-line interface

## Getting Started

### Launching the REPL

```bash
# Start TUI REPL (default)
./hype repl

# Start simple REPL
./hype repl --simple

# With plugins
./hype repl --plugins fs@1.0.0,json
```

### First Steps

When you start the TUI REPL, you'll see:
```
┌─────────────────────────────────────────────────┐
│ Hype REPL v1.9.0                                │
│ Type :help for commands                         │
├─────────────────────────────────────────────────┤
│                                                 │
│ Output Panel                                    │
│                                                 │
├─────────────────────────────────────────────────┤
│ hype> _                                         │
└─────────────────────────────────────────────────┘
```

Try these commands:
```lua
-- Basic expression
hype> 2 + 2
4

-- Create a table
hype> user = {name = "Alice", age = 30}
{
  ["age"] = 30,
  ["name"] = "Alice"
}

-- Access Hype modules
hype> crypto.sha256("hello")
2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
```

## TUI REPL Features

### Interface Layout

The TUI REPL has two main panels:

1. **Output Panel** (Top)
   - Shows results and output
   - Scrollable with mouse or keyboard
   - Preserves history during session

2. **Input Panel** (Bottom)
   - Where you type commands
   - Multi-line support with Shift+Enter
   - Syntax highlighting (in supported terminals)

### Navigation

| Key | Action |
|-----|--------|
| `↑/↓` | Navigate command history |
| `Ctrl+A` | Move to start of line |
| `Ctrl+E` | Move to end of line |
| `Ctrl+U` | Clear current line |
| `Ctrl+L` | Clear output panel |
| `Ctrl+C` | Cancel current input |
| `Ctrl+D` | Exit REPL |
| `Tab` | Auto-completion (when available) |
| `PageUp/PageDown` | Scroll output panel |

### Beautiful Output Formatting

Tables are automatically formatted for readability:

```lua
hype> config = {
  server = {
    host = "localhost",
    port = 8080,
    ssl = false
  },
  database = {
    path = "./data.db",
    options = {
      timeout = 30,
      readonly = false
    }
  }
}

-- Output:
{
  ["database"] = {
    ["options"] = {
      ["readonly"] = false,
      ["timeout"] = 30
    },
    ["path"] = "./data.db"
  },
  ["server"] = {
    ["host"] = "localhost",
    ["port"] = 8080,
    ["ssl"] = false
  }
}
```

## Simple REPL Mode

For minimal environments or automation:

```bash
./hype repl --simple
```

Features:
- Basic prompt without TUI
- Same Lua environment
- Suitable for scripts and pipes
- Less memory overhead

Example session:
```
Hype REPL (simple mode)
Type 'exit' or Ctrl+D to quit
> print("Hello from simple REPL")
Hello from simple REPL
> os.exit()
```

## Special Commands

The REPL supports special commands prefixed with `:`:

### Basic Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `:help` | `:h` | Show available commands |
| `:clear` | `:c` | Clear output panel |
| `:exit` | `:quit`, `:q` | Exit REPL |
| `:history` | `:hist` | Show command history |
| `:h=N` | - | Recall command N from history |

### History Management

```lua
-- View history
hype> :history
Command History:
  1: 2 + 2
  2: user = {name = "Alice"}
  3: crypto.sha256("test")

-- Recall command 2
hype> :h=2
Recalled: user = {name = "Alice"}

-- Execute recalled command
hype> user = {name = "Alice", updated = true}
```

### Loading Files

```lua
-- Load and execute a Lua file
hype> :load utils.lua
Loaded: utils.lua

-- Or use dofile
hype> dofile("config.lua")
```

## Working with Modules

### Built-in Modules

All Hype modules are pre-loaded in the REPL:

```lua
-- TUI Module
hype> app = tui.newApp()
<TUI App>

-- HTTP Module  
hype> client = http.client()
<HTTP Client>

-- Database Module
hype> db = kv.open(":memory:")
<KV Database (memory)>

-- Crypto Module
hype> key = crypto.generate_jwk("ES256")
{
  ["alg"] = "ES256",
  ["crv"] = "P-256",
  ["kty"] = "EC",
  ...
}

-- WebSocket Module
hype> ws = websocket.newServer()
<WebSocket Server>
```

### Plugin Modules

Load plugins at startup:
```bash
./hype repl --plugins fs@1.0.0,json
```

Use in REPL:
```lua
hype> fs.readFile("test.txt")
"File contents here"

hype> json.encode({a = 1, b = 2})
'{"a":1,"b":2}'
```

### Module Exploration

Discover module methods:
```lua
-- Inspect module table
hype> for k,v in pairs(crypto) do print(k, type(v)) end
generate_jwk    function
sign            function
verify          function
sha256          function
sha512          function
jwk_to_public   function
jwk_to_json     function
...

-- Get function info (if debug info available)
hype> debug.getinfo(crypto.sha256)
{
  ["source"] = "=[Go function]",
  ["what"] = "Go",
  ...
}
```

## Advanced Usage

### Multi-line Input

For complex code, use multi-line mode:

```lua
hype> function calculate_stats(numbers)
    local sum = 0
    local count = #numbers
    for _, n in ipairs(numbers) do
        sum = sum + n
    end
    return {
        sum = sum,
        average = sum / count,
        count = count
    }
end

hype> calculate_stats({10, 20, 30, 40, 50})
{
  ["average"] = 30.0,
  ["count"] = 5,
  ["sum"] = 150
}
```

### Working with Coroutines

```lua
-- Create a coroutine
hype> co = coroutine.create(function()
    for i = 1, 3 do
        print("Step " .. i)
        coroutine.yield(i * 10)
    end
end)

-- Resume it
hype> coroutine.resume(co)
Step 1
true    10

hype> coroutine.resume(co)
Step 2
true    20
```

### Error Handling

The REPL shows detailed error information:

```lua
hype> error("Something went wrong")
Error: Something went wrong
Stack traceback:
    [string "repl"]:1: in main chunk

hype> 1 / 0
Error: division by zero

hype> nil.foo
Error: attempt to index a nil value
```

### Global Environment

The REPL maintains state between commands:

```lua
-- Define a function
hype> function greet(name)
    return "Hello, " .. (name or "World") .. "!"
end

-- Use it later
hype> message = greet("Hype")
"Hello, Hype!"

-- Access previous results
hype> print(message:upper())
HELLO, HYPE!
```

## Tips & Tricks

### 1. Quick Testing

Test functions before adding to your script:
```lua
-- Test HTTP endpoint
hype> resp = http.get("https://api.github.com/users/github")
hype> resp.status_code
200

-- Parse JSON response
hype> data = json.decode(resp.body)
hype> data.name
"GitHub"
```

### 2. Interactive Debugging

Add debugging functions to your scripts:
```lua
-- In your script
function debug_break(context)
    print("Debug break:", context)
    -- Pause execution
end

-- In REPL, redefine to inspect
hype> function debug_break(context)
    print("Context:", context)
    print("Enter 'cont' to continue")
    io.read()
end
```

### 3. Performance Testing

Quick benchmarks:
```lua
hype> function benchmark(fn, iterations)
    iterations = iterations or 1000
    local start = os.clock()
    for i = 1, iterations do
        fn()
    end
    local elapsed = os.clock() - start
    return string.format("%d iterations in %.3f seconds", iterations, elapsed)
end

hype> benchmark(function() crypto.sha256("test") end, 10000)
"10000 iterations in 0.125 seconds"
```

### 4. Data Inspection

Create helper functions:
```lua
hype> function inspect(t, indent)
    indent = indent or 0
    for k, v in pairs(t) do
        print(string.rep("  ", indent) .. k .. ":", type(v))
        if type(v) == "table" and indent < 3 then
            inspect(v, indent + 1)
        end
    end
end

hype> inspect(_G)  -- Inspect global environment
```

### 5. Save REPL Session

Capture your work:
```lua
-- Start logging
hype> logfile = io.open("repl-session.lua", "w")

-- Your work...
hype> function save_command(cmd)
    if logfile then
        logfile:write(cmd .. "\n")
        logfile:flush()
    end
end

-- Before exit
hype> logfile:close()
```

## Common Workflows

### 1. API Exploration Workflow

```lua
-- 1. Load a module
hype> server = http.newServer()

-- 2. Explore its methods
hype> getmetatable(server).__index
<table of methods>

-- 3. Test a method
hype> server:handle("/test", function(req, res)
    res:json({message = "Hello from REPL"})
end)

-- 4. Start server in background
hype> go(function() server:listen(8080) end)

-- 5. Test with client
hype> resp = http.get("http://localhost:8080/test")
hype> resp.body
'{"message":"Hello from REPL"}'
```

### 2. Database Testing Workflow

```lua
-- 1. Open in-memory database
hype> db = kv.open(":memory:")

-- 2. Create bucket
hype> db:open_db("test")

-- 3. Test operations
hype> db:put("test", "key1", "value1")
hype> db:get("test", "key1")
"value1"

-- 4. Test transactions
hype> db:transaction(function()
    db:put("test", "key2", "value2")
    db:put("test", "key3", "value3")
end)

-- 5. Verify
hype> keys = {}
hype> db:foreach("test", function(k, v)
    table.insert(keys, k)
    return true
end)
hype> keys
{"key1", "key2", "key3"}
```

### 3. TUI Development Workflow

```lua
-- 1. Create app
hype> app = tui.newApp()

-- 2. Build interface
hype> text = tui.newTextView("REPL TUI Test")
hype> text:SetBorder(true)
hype> text:SetTitle("Test Window")

-- 3. Set root and run
hype> app:SetRoot(text, true)
hype> go(function() app:Run() end)

-- 4. Update from REPL
hype> app:QueueUpdateDraw(function()
    text:SetText("Updated from REPL!")
end)

-- 5. Stop when done
hype> app:Stop()
```

### 4. Plugin Development Workflow

```lua
-- 1. Define plugin table
hype> myplugin = {}

-- 2. Add functions
hype> function myplugin.hello(name)
    return "Hello, " .. (name or "Plugin")
end

-- 3. Test the function
hype> myplugin.hello("REPL")
"Hello, REPL"

-- 4. Add more features
hype> function myplugin.calculate(a, b)
    return {
        sum = a + b,
        difference = a - b,
        product = a * b,
        quotient = a / b
    }
end

-- 5. Test complete plugin
hype> myplugin.calculate(10, 5)
{
  ["difference"] = 5,
  ["product"] = 50,
  ["quotient"] = 2.0,
  ["sum"] = 15
}

-- 6. Save to file
hype> file = io.open("myplugin.lua", "w")
hype> file:write("return " .. serialize(myplugin))
hype> file:close()
```

## Troubleshooting

### Common Issues

**1. REPL Won't Start**
```bash
# Check Hype version
./hype version
# REPL requires v1.9.0+

# Try simple mode
./hype repl --simple
```

**2. Special Characters Not Working**
```bash
# Check terminal encoding
echo $LANG
# Should include UTF-8

# Try different terminal
# Some terminals handle TUI better
```

**3. Output Panel Not Scrolling**
- Use PageUp/PageDown keys
- Mouse scroll (if terminal supports)
- `:clear` to reset

**4. Memory Issues with Large Data**
```lua
-- Clear large variables
hype> bigdata = nil
hype> collectgarbage()

-- Check memory usage
hype> collectgarbage("count")
1234.56  -- KB used
```

**5. Hanging Operations**
```lua
-- Use Ctrl+C to interrupt
-- Or run in coroutine with timeout
hype> function with_timeout(fn, seconds)
    local co = coroutine.create(fn)
    local start = os.time()
    while coroutine.status(co) ~= "dead" do
        if os.time() - start > seconds then
            error("Timeout")
        end
        coroutine.resume(co)
    end
end
```

### Getting Help

1. **In REPL**: Type `:help`
2. **Documentation**: Check this guide
3. **Examples**: Run example scripts
4. **Community**: GitHub discussions

### Best Practices

1. **Start Simple**: Test basic expressions first
2. **Save Work**: Log important discoveries
3. **Use History**: Recall and modify previous commands
4. **Clean Environment**: Clear variables when done
5. **Test Incrementally**: Build complex code step by step

## Integration with Development

### From REPL to Script

1. Prototype in REPL
2. Save working code to file
3. Test with `hype run`
4. Build with `hype build`

Example workflow:
```lua
-- In REPL: Prototype
hype> function process_data(input)
    -- develop function
end

-- Save to file
hype> file = io.open("processor.lua", "w")
hype> file:write(get_function_source(process_data))
hype> file:close()

-- Test
hype> dofile("processor.lua")
```

### REPL as Debugger

Add REPL breaks to your scripts:
```lua
-- In your script
function start_repl_here()
    print("Starting REPL for debugging...")
    os.execute("./hype repl")
end

-- Call where needed
if debug_mode then
    start_repl_here()
end
```

## Summary

The Hype REPL is a powerful tool for:
- 🚀 Rapid development and prototyping
- 🔍 API exploration and learning
- 🐛 Interactive debugging
- 🧪 Testing code before deployment
- 📚 Understanding Hype's capabilities

Whether using the rich TUI interface or simple mode, the REPL accelerates your Hype development workflow and makes it easy to experiment with ideas before committing them to code.

Happy REPL-ing! 🎉