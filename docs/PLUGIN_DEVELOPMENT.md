# Hype Plugin Development Guide

This guide walks you through creating Hype plugins from scratch, with practical examples and best practices.

## Prerequisites

- Basic Lua knowledge
- Hype installed and working
- Text editor

## Creating Your First Plugin

### Step 1: Plugin Setup

Create a new directory for your plugin:

```bash
mkdir my-first-plugin
cd my-first-plugin
```

### Step 2: Create the Manifest

Create `hype-plugin.yaml`:

```yaml
name: "my-first-plugin"
version: "1.0.0"
type: "lua"
main: "plugin.lua"
description: "My first Hype plugin"
author: "Your Name"
license: "MIT"
```

### Step 3: Create the Plugin Code

Create `plugin.lua`:

```lua
-- My first Hype plugin
local myfirst = {}

-- Simple greeting function
function myfirst.greet(name)
    return "Hello, " .. (name or "World") .. " from my first plugin!"
end

-- Function with error handling
function myfirst.divide(a, b)
    -- Validate inputs
    if type(a) ~= "number" or type(b) ~= "number" then
        return nil, "Both arguments must be numbers"
    end
    
    if b == 0 then
        return nil, "Division by zero"
    end
    
    return a / b, nil
end

-- Plugin metadata
myfirst._VERSION = "1.0.0"
myfirst._DESCRIPTION = "My first Hype plugin"

-- Must return the plugin table
return myfirst
```

### Step 4: Test the Plugin

Create a test script `test.lua`:

```lua
-- Test script for my-first-plugin
local myfirst = require("my-first-plugin")

-- Test greeting
print(myfirst.greet("Developer"))

-- Test division
local result, err = myfirst.divide(10, 2)
if result then
    print("10 / 2 =", result)
else
    print("Error:", err)
end

-- Test error handling
local result, err = myfirst.divide(10, 0)
if result then
    print("Result:", result)
else
    print("Expected error:", err)
end
```

Run the test:

```bash
./hype run test.lua --plugins ./my-first-plugin
```

Expected output:
```
Hello, Developer from my first plugin!
10 / 2 =	5
Expected error:	Division by zero
```

## Plugin Development Patterns

### Error Handling Pattern

```lua
function myplugin.operation(input)
    -- Validate input
    if not input then
        return nil, "Input is required"
    end
    
    if type(input) ~= "string" then
        return nil, "Input must be a string"
    end
    
    -- Perform operation
    local result = processInput(input)
    
    -- Check for errors
    if not result then
        return nil, "Processing failed"
    end
    
    return result, nil
end
```

### Optional Parameters Pattern

```lua
function myplugin.format(text, options)
    -- Default options
    options = options or {}
    
    local prefix = options.prefix or ""
    local suffix = options.suffix or ""
    local uppercase = options.uppercase or false
    
    local result = prefix .. text .. suffix
    
    if uppercase then
        result = result:upper()
    end
    
    return result
end

-- Usage:
-- myplugin.format("hello")                           -> "hello"
-- myplugin.format("hello", {prefix = ">> "})         -> ">> hello"
-- myplugin.format("hello", {uppercase = true})       -> "HELLO"
```

### State Management Pattern

```lua
local myplugin = {}

-- Private state
local cache = {}
local initialized = false

-- Private functions
local function init()
    if initialized then return end
    
    -- Initialize plugin state
    cache = {}
    initialized = true
end

-- Public functions
function myplugin.set(key, value)
    init()
    cache[key] = value
    return true
end

function myplugin.get(key)
    init()
    return cache[key]
end

function myplugin.clear()
    cache = {}
    return true
end

return myplugin
```

## Real-World Plugin Examples

### File Watcher Plugin

```lua
-- file-watcher-plugin/plugin.lua
local watcher = {}

-- Store watched files and their last modification times
local watched = {}

function watcher.watch(filepath)
    local file = io.open(filepath, "r")
    if not file then
        return false, "File not found: " .. filepath
    end
    file:close()
    
    -- Get file modification time (simplified)
    local handle = io.popen("stat -c %Y " .. filepath .. " 2>/dev/null")
    local mtime = handle:read("*a")
    handle:close()
    
    watched[filepath] = tonumber(mtime) or 0
    return true, nil
end

function watcher.checkChanges()
    local changes = {}
    
    for filepath, oldtime in pairs(watched) do
        local handle = io.popen("stat -c %Y " .. filepath .. " 2>/dev/null")
        local newtime = tonumber(handle:read("*a")) or 0
        handle:close()
        
        if newtime > oldtime then
            table.insert(changes, filepath)
            watched[filepath] = newtime
        end
    end
    
    return changes
end

function watcher.unwatch(filepath)
    watched[filepath] = nil
    return true
end

watcher._VERSION = "1.0.0"
return watcher
```

### Configuration Plugin

```lua
-- config-plugin/plugin.lua
local config = {}

-- Private state
local settings = {}

-- Parse simple INI-style config
local function parseINI(content)
    local result = {}
    local section = "default"
    
    for line in content:gmatch("[^\r\n]+") do
        line = line:match("^%s*(.-)%s*$") -- trim whitespace
        
        if line:match("^%[(.+)%]$") then
            -- Section header
            section = line:match("^%[(.+)%]$")
            result[section] = result[section] or {}
        elseif line:match("^([^=]+)=(.*)$") then
            -- Key=value pair
            local key, value = line:match("^([^=]+)=(.*)$")
            key = key:match("^%s*(.-)%s*$")
            value = value:match("^%s*(.-)%s*$")
            
            result[section] = result[section] or {}
            result[section][key] = value
        end
    end
    
    return result
end

function config.load(filepath)
    local file = io.open(filepath, "r")
    if not file then
        return false, "Could not read config file: " .. filepath
    end
    
    local content = file:read("*a")
    file:close()
    
    settings = parseINI(content)
    return true, nil
end

function config.get(section, key, default)
    if not settings[section] then
        return default
    end
    
    local value = settings[section][key]
    if value == nil then
        return default
    end
    
    -- Try to convert to number or boolean
    if value == "true" then
        return true
    elseif value == "false" then
        return false
    elseif tonumber(value) then
        return tonumber(value)
    else
        return value
    end
end

function config.set(section, key, value)
    settings[section] = settings[section] or {}
    settings[section][key] = tostring(value)
    return true
end

function config.save(filepath)
    local lines = {}
    
    for section, keys in pairs(settings) do
        table.insert(lines, "[" .. section .. "]")
        for key, value in pairs(keys) do
            table.insert(lines, key .. "=" .. value)
        end
        table.insert(lines, "")
    end
    
    local file = io.open(filepath, "w")
    if not file then
        return false, "Could not write config file: " .. filepath
    end
    
    file:write(table.concat(lines, "\n"))
    file:close()
    
    return true, nil
end

config._VERSION = "1.0.0"
return config
```

### Template Engine Plugin

```lua
-- template-plugin/plugin.lua
local template = {}

-- Simple template engine with {{variable}} syntax
function template.render(templateStr, variables)
    if type(templateStr) ~= "string" then
        return nil, "Template must be a string"
    end
    
    if type(variables) ~= "table" then
        return nil, "Variables must be a table"
    end
    
    local result = templateStr
    
    -- Replace {{variable}} with values
    result = result:gsub("{{%s*([%w_]+)%s*}}", function(varname)
        local value = variables[varname]
        if value ~= nil then
            return tostring(value)
        else
            return "{{" .. varname .. "}}" -- leave unchanged if not found
        end
    end)
    
    return result, nil
end

function template.renderFile(templatePath, variables, outputPath)
    -- Read template
    local file = io.open(templatePath, "r")
    if not file then
        return false, "Could not read template: " .. templatePath
    end
    
    local templateStr = file:read("*a")
    file:close()
    
    -- Render template
    local result, err = template.render(templateStr, variables)
    if not result then
        return false, "Template rendering failed: " .. err
    end
    
    -- Write output
    if outputPath then
        local outFile = io.open(outputPath, "w")
        if not outFile then
            return false, "Could not write output: " .. outputPath
        end
        
        outFile:write(result)
        outFile:close()
    end
    
    return result, nil
end

template._VERSION = "1.0.0"
return template
```

## Testing Your Plugins

### Unit Testing Approach

Create `tests/test_plugin.lua`:

```lua
-- Simple test framework
local tests = {}
local passed = 0
local failed = 0

function tests.assert(condition, message)
    if condition then
        passed = passed + 1
        print("✓ " .. (message or "Test passed"))
    else
        failed = failed + 1
        print("✗ " .. (message or "Test failed"))
    end
end

function tests.assertEqual(actual, expected, message)
    local condition = actual == expected
    if not condition then
        message = (message or "Values not equal") .. 
                 " (expected: " .. tostring(expected) .. 
                 ", actual: " .. tostring(actual) .. ")"
    end
    tests.assert(condition, message)
end

function tests.finish()
    print("\nTest Results:")
    print("Passed: " .. passed)
    print("Failed: " .. failed)
    print("Total: " .. (passed + failed))
    
    if failed > 0 then
        os.exit(1)
    end
end

-- Test the plugin
local myplugin = require("my-plugin")

-- Test greeting
local result = myplugin.greet("Test")
tests.assertEqual(result, "Hello, Test from my first plugin!", "Greeting test")

-- Test division success
local result, err = myplugin.divide(10, 2)
tests.assertEqual(result, 5, "Division success")
tests.assertEqual(err, nil, "No error on success")

-- Test division by zero
local result, err = myplugin.divide(10, 0)
tests.assertEqual(result, nil, "Division by zero returns nil")
tests.assert(err ~= nil, "Division by zero returns error")

tests.finish()
```

Run tests:

```bash
./hype run tests/test_plugin.lua --plugins ./my-plugin
```

## Advanced Plugin Development

### Plugin with Dependencies

If your plugin needs external Lua modules, document them:

```yaml
# hype-plugin.yaml
name: "advanced-plugin"
version: "1.0.0"
type: "lua"
main: "plugin.lua"
description: "Plugin with dependencies"

# Document required modules (for user awareness)
requirements:
  - "Built-in lua modules only"
  - "No external dependencies"

notes: |
  This plugin uses only Lua standard library functions
  and is compatible with Hype's embedded Lua runtime.
```

### Version Evolution

When updating your plugin, maintain backward compatibility:

```lua
-- plugin.lua v2.0.0
local myplugin = {}

-- New function in v2.0.0
function myplugin.newFeature()
    return "This is new in v2.0.0"
end

-- Existing function (maintain compatibility)
function myplugin.oldFunction(arg)
    -- v2.0.0: enhanced but still compatible
    return "Enhanced: " .. (arg or "default")
end

-- Version-specific behavior
function myplugin.adaptiveFunction()
    -- Check if we're in a newer version context
    if myplugin._VERSION >= "2.0.0" then
        return myplugin.newFeature()
    else
        return "Fallback behavior"
    end
end

myplugin._VERSION = "2.0.0"
return myplugin
```

### Performance Optimization

```lua
-- Optimize for performance
local myplugin = {}

-- Cache expensive computations
local cache = {}

-- Pre-compile patterns
local emailPattern = "[%w%._%+%-]+@[%w%._%+%-]+%.%w+"

function myplugin.validateEmail(email)
    -- Use cached result if available
    if cache[email] ~= nil then
        return cache[email]
    end
    
    local isValid = email:match(emailPattern) ~= nil
    cache[email] = isValid
    
    return isValid
end

-- Limit cache size to prevent memory leaks
local function limitCache()
    local count = 0
    for _ in pairs(cache) do
        count = count + 1
        if count > 1000 then
            cache = {} -- Clear cache if too large
            break
        end
    end
end

-- Clean up periodically
function myplugin.cleanup()
    limitCache()
    return true
end

return myplugin
```

## Distribution and Sharing

### Plugin Documentation

Create `README.md` for your plugin:

```markdown
# My Plugin

Brief description of what your plugin does.

## Installation

```bash
./hype run myapp.lua --plugins ./my-plugin
```

## Usage

```lua
local myplugin = require("my-plugin")
local result = myplugin.doSomething("input")
```

## API Reference

### myplugin.doSomething(input)

Description of the function.

**Parameters:**
- `input` (string): Description of parameter

**Returns:**
- `result` (string): Description of return value
- `error` (string|nil): Error message if operation failed

## Examples

See `examples/` directory for usage examples.

## License

MIT License
```

### Versioning Strategy

Follow semantic versioning:

- **Major** (1.0.0 → 2.0.0): Breaking changes
- **Minor** (1.0.0 → 1.1.0): New features, backward compatible
- **Patch** (1.0.0 → 1.0.1): Bug fixes, backward compatible

### Plugin Checklist

Before releasing your plugin:

- [ ] Plugin manifest is complete and valid
- [ ] Plugin code follows Lua conventions
- [ ] Error handling is comprehensive
- [ ] Functions are documented
- [ ] Version metadata is included
- [ ] Tests are written and passing
- [ ] README documentation exists
- [ ] Examples are provided
- [ ] License is specified

## Next Steps

1. **Study existing plugins** in `examples/plugins/`
2. **Create your own plugin** following this guide
3. **Share with the community** by creating a repository
4. **Contribute improvements** to the plugin system

For more advanced topics and the complete plugin system reference, see [PLUGINS.md](PLUGINS.md).