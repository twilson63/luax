# Complete Plugin Development Guide for Hype

> Build powerful, reusable plugins that extend Hype's capabilities

## Table of Contents
1. [Plugin Architecture](#plugin-architecture)
2. [Creating Your First Plugin](#creating-your-first-plugin)
3. [Advanced Plugin Patterns](#advanced-plugin-patterns)
4. [Real-World Plugin Examples](#real-world-plugin-examples)
5. [Testing & Distribution](#testing--distribution)
6. [Best Practices](#best-practices)

## Plugin Architecture

### What Are Plugins?

Plugins are versioned Lua modules that:
- Extend Hype's functionality
- Embed directly into executables
- Follow semantic versioning
- Work across all platforms

### Plugin Structure
```
myplugin/
├── hype-plugin.yaml    # Required: Plugin manifest
├── plugin.lua          # Required: Main entry point
├── lib/                # Optional: Additional modules
│   ├── utils.lua
│   └── helpers.lua
├── assets/             # Optional: Embedded files
│   └── config.json
├── tests/              # Recommended: Test files
│   └── test.lua
└── README.md           # Recommended: Documentation
```

### Manifest File (hype-plugin.yaml)
```yaml
name: "myplugin"
version: "1.0.0"
type: "lua"
main: "plugin.lua"
description: "My awesome Hype plugin"
author: "Your Name"
license: "MIT"
repository: "https://github.com/user/myplugin"
dependencies:
  - "json@1.0.0"    # Optional: Plugin dependencies
```

## Creating Your First Plugin

### Step 1: Basic Plugin Structure

Create `fs-extra/hype-plugin.yaml`:
```yaml
name: "fs-extra"
version: "1.0.0"
type: "lua"
main: "plugin.lua"
description: "Extended filesystem operations for Hype"
```

Create `fs-extra/plugin.lua`:
```lua
-- fs-extra: Extended filesystem operations
local M = {}

-- Plugin version
M.VERSION = "1.0.0"

-- Read file with error handling
function M.readFile(path)
    local file, err = io.open(path, "r")
    if not file then
        return nil, "Cannot open file: " .. (err or path)
    end
    
    local content = file:read("*all")
    file:close()
    return content
end

-- Write file with directory creation
function M.writeFile(path, content)
    -- Extract directory
    local dir = path:match("(.*/)")
    if dir then
        os.execute("mkdir -p " .. dir)
    end
    
    local file, err = io.open(path, "w")
    if not file then
        return false, "Cannot write file: " .. (err or path)
    end
    
    file:write(content)
    file:close()
    return true
end

-- Check if file exists
function M.exists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

-- Get file size
function M.size(path)
    local file = io.open(path, "r")
    if not file then
        return nil, "File not found"
    end
    
    local size = file:seek("end")
    file:close()
    return size
end

-- List directory contents
function M.listDir(path)
    local cmd = "ls -1 " .. path .. " 2>/dev/null"
    local handle = io.popen(cmd)
    local result = handle:read("*all")
    handle:close()
    
    local files = {}
    for file in result:gmatch("[^\n]+") do
        table.insert(files, file)
    end
    
    return files
end

-- Create directory
function M.mkdir(path, recursive)
    local cmd = recursive and "mkdir -p " or "mkdir "
    local ok = os.execute(cmd .. path)
    return ok == 0
end

-- Copy file
function M.copyFile(src, dst)
    local input, err = M.readFile(src)
    if not input then
        return false, err
    end
    
    return M.writeFile(dst, input)
end

-- Move file
function M.moveFile(src, dst)
    -- Try rename first (fastest)
    local ok = os.rename(src, dst)
    if ok then
        return true
    end
    
    -- Fall back to copy + delete
    local ok, err = M.copyFile(src, dst)
    if not ok then
        return false, err
    end
    
    os.remove(src)
    return true
end

-- Delete file or directory
function M.remove(path, recursive)
    if recursive then
        os.execute("rm -rf " .. path)
    else
        os.remove(path)
    end
    return true
end

-- Read JSON file
function M.readJSON(path)
    local content, err = M.readFile(path)
    if not content then
        return nil, err
    end
    
    -- Simple JSON parsing (or use json plugin)
    local ok, data = pcall(function()
        return load("return " .. content:gsub('("[^"]*"):', '[%1]='))()
    end)
    
    if not ok then
        return nil, "Invalid JSON"
    end
    
    return data
end

-- Write JSON file
function M.writeJSON(path, data)
    -- Simple JSON encoding
    local function encode(v)
        if type(v) == "string" then
            return '"' .. v:gsub('"', '\\"') .. '"'
        elseif type(v) == "table" then
            local parts = {}
            local isArray = #v > 0
            
            if isArray then
                for i, item in ipairs(v) do
                    parts[i] = encode(item)
                end
                return "[" .. table.concat(parts, ",") .. "]"
            else
                for k, item in pairs(v) do
                    table.insert(parts, '"' .. k .. '":' .. encode(item))
                end
                return "{" .. table.concat(parts, ",") .. "}"
            end
        else
            return tostring(v)
        end
    end
    
    return M.writeFile(path, encode(data))
end

-- Watch file for changes
function M.watch(path, callback, interval)
    interval = interval or 1
    
    local lastModified = nil
    return function()
        while true do
            local file = io.open(path, "r")
            if file then
                local info = file:seek("end")
                file:close()
                
                if lastModified and info ~= lastModified then
                    callback(path, "changed")
                end
                lastModified = info
            elseif lastModified then
                callback(path, "deleted")
                break
            end
            
            sleep(interval)
        end
    end
end

return M
```

### Step 2: Test Your Plugin

Create `test.lua`:
```lua
-- Test the plugin during development
local fs = require('./fs-extra/plugin')

-- Test basic operations
print("Plugin version:", fs.VERSION)

-- Write a file
local ok, err = fs.writeFile("test.txt", "Hello from plugin!")
print("Write:", ok, err)

-- Read it back
local content, err = fs.readFile("test.txt")
print("Read:", content)

-- Check existence
print("Exists:", fs.exists("test.txt"))

-- Get size
local size = fs.size("test.txt")
print("Size:", size, "bytes")

-- JSON operations
local data = {
    name = "Test",
    values = {1, 2, 3},
    active = true
}

fs.writeJSON("test.json", data)
local loaded = fs.readJSON("test.json")
print("JSON loaded:", loaded.name)

-- Cleanup
fs.remove("test.txt")
fs.remove("test.json")
```

Run with:
```bash
./hype run test.lua
```

## Advanced Plugin Patterns

### 1. Stateful Plugin with Configuration

```lua
-- plugin.lua: Database connection pool plugin
local M = {}

-- Private state
local connections = {}
local config = {
    maxConnections = 10,
    timeout = 30
}

-- Initialize plugin
function M.init(options)
    if options then
        for k, v in pairs(options) do
            config[k] = v
        end
    end
    return M
end

-- Get or create connection
function M.getConnection(name)
    name = name or "default"
    
    if not connections[name] then
        if #connections >= config.maxConnections then
            return nil, "Connection limit reached"
        end
        
        connections[name] = {
            name = name,
            created = os.time(),
            lastUsed = os.time()
        }
    end
    
    connections[name].lastUsed = os.time()
    return connections[name]
end

-- Close connection
function M.close(name)
    connections[name or "default"] = nil
end

-- Cleanup old connections
function M.cleanup()
    local now = os.time()
    for name, conn in pairs(connections) do
        if now - conn.lastUsed > config.timeout then
            connections[name] = nil
        end
    end
end

return M
```

### 2. Plugin with Sub-modules

```lua
-- plugin.lua: Main entry point
local M = {}

-- Load sub-modules
M.crypto = require('./lib/crypto')
M.compress = require('./lib/compress')
M.validate = require('./lib/validate')

-- Re-export common functions
M.hash = M.crypto.hash
M.gzip = M.compress.gzip
M.isEmail = M.validate.isEmail

return M
```

```lua
-- lib/crypto.lua: Crypto utilities
local M = {}

function M.hash(data, algorithm)
    algorithm = algorithm or "sha256"
    -- Implementation
end

function M.randomString(length)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = {}
    
    for i = 1, length do
        local idx = math.random(#chars)
        result[i] = chars:sub(idx, idx)
    end
    
    return table.concat(result)
end

return M
```

### 3. Event-Driven Plugin

```lua
-- plugin.lua: Event emitter plugin
local M = {}

-- Event storage
local events = {}

-- Register event handler
function M.on(event, handler)
    if not events[event] then
        events[event] = {}
    end
    table.insert(events[event], handler)
    
    -- Return unsubscribe function
    return function()
        M.off(event, handler)
    end
end

-- Remove event handler
function M.off(event, handler)
    if not events[event] then return end
    
    for i, h in ipairs(events[event]) do
        if h == handler then
            table.remove(events[event], i)
            break
        end
    end
end

-- Emit event
function M.emit(event, ...)
    if not events[event] then return end
    
    for _, handler in ipairs(events[event]) do
        local ok, err = pcall(handler, ...)
        if not ok then
            print("Event handler error:", err)
        end
    end
end

-- One-time event handler
function M.once(event, handler)
    local function wrapper(...)
        M.off(event, wrapper)
        handler(...)
    end
    M.on(event, wrapper)
end

return M
```

### 4. Async Plugin with Coroutines

```lua
-- plugin.lua: Async HTTP client
local M = {}
local http = require('http')

-- Promise-like async function
function M.fetch(url)
    local co = coroutine.running()
    local result = nil
    local error = nil
    
    go(function()
        local resp, err = http.get(url)
        result = resp
        error = err
        coroutine.resume(co)
    end)
    
    coroutine.yield()
    
    if error then
        return nil, error
    end
    return result
end

-- Parallel requests
function M.fetchAll(urls)
    local results = {}
    local errors = {}
    local completed = 0
    local co = coroutine.running()
    
    for i, url in ipairs(urls) do
        go(function()
            local resp, err = http.get(url)
            results[i] = resp
            errors[i] = err
            completed = completed + 1
            
            if completed == #urls then
                coroutine.resume(co)
            end
        end)
    end
    
    coroutine.yield()
    
    return results, errors
end

-- Usage:
-- local result = plugin.fetch("https://api.example.com/data")
-- local results = plugin.fetchAll({"url1", "url2", "url3"})

return M
```

## Real-World Plugin Examples

### 1. Redis Client Plugin

```lua
-- redis/plugin.lua: Redis client
local M = {}
local socket = require('socket')  -- Hypothetical socket library

local connections = {}

function M.connect(host, port)
    host = host or "localhost"
    port = port or 6379
    
    local conn = socket.connect(host, port)
    if not conn then
        return nil, "Connection failed"
    end
    
    local client = {
        conn = conn,
        host = host,
        port = port
    }
    
    -- Command method
    function client:command(cmd, ...)
        local args = {...}
        local request = {"*" .. (#args + 1), cmd}
        
        for _, arg in ipairs(args) do
            table.insert(request, tostring(arg))
        end
        
        -- Send request (simplified)
        self.conn:send(table.concat(request, "\r\n") .. "\r\n")
        
        -- Read response
        return self:readResponse()
    end
    
    -- Convenience methods
    function client:get(key)
        return self:command("GET", key)
    end
    
    function client:set(key, value)
        return self:command("SET", key, value)
    end
    
    function client:expire(key, seconds)
        return self:command("EXPIRE", key, seconds)
    end
    
    function client:close()
        self.conn:close()
    end
    
    return client
end

return M
```

### 2. Template Engine Plugin

```lua
-- template/plugin.lua: Simple template engine
local M = {}

-- Cache compiled templates
local cache = {}

-- Compile template
function M.compile(template)
    if cache[template] then
        return cache[template]
    end
    
    local code = "local __out = {} "
    code = code .. "local function __write(s) table.insert(__out, tostring(s)) end "
    
    -- Replace {{variable}}
    template = template:gsub("{{(.-)}}}", function(expr)
        return '__write(' .. expr .. ') '
    end)
    
    -- Replace {% code %}
    template = template:gsub("{%%(.-)%%}", function(code)
        return code .. " "
    end)
    
    -- Replace {= expression =}
    template = template:gsub("{=(.-)=}", function(expr)
        return '__write(' .. expr .. ') '
    end)
    
    -- Handle plain text
    template = template:gsub("([^{]*)([{]?)", function(text, bracket)
        if text ~= "" then
            return '__write([=[' .. text .. ']=]) ' .. bracket
        end
        return bracket
    end)
    
    code = code .. " return table.concat(__out)"
    
    local fn, err = load(code)
    if not fn then
        return nil, err
    end
    
    cache[template] = fn
    return fn
end

-- Render template
function M.render(template, data)
    local fn, err = M.compile(template)
    if not fn then
        return nil, err
    end
    
    -- Set up environment
    local env = {}
    for k, v in pairs(data or {}) do
        env[k] = v
    end
    
    -- Add helpers
    env.escape = M.escape
    env.json = M.json
    
    setfenv(fn, env)
    
    local ok, result = pcall(fn)
    if not ok then
        return nil, result
    end
    
    return result
end

-- HTML escape
function M.escape(str)
    str = tostring(str)
    str = str:gsub("&", "&amp;")
    str = str:gsub("<", "&lt;")
    str = str:gsub(">", "&gt;")
    str = str:gsub('"', "&quot;")
    str = str:gsub("'", "&#39;")
    return str
end

-- JSON helper
function M.json(data)
    -- Simple JSON encoding
    if type(data) == "table" then
        local parts = {}
        for k, v in pairs(data) do
            table.insert(parts, '"' .. k .. '":' .. M.json(v))
        end
        return "{" .. table.concat(parts, ",") .. "}"
    elseif type(data) == "string" then
        return '"' .. data:gsub('"', '\\"') .. '"'
    else
        return tostring(data)
    end
end

-- Load template from file
function M.loadFile(path)
    local file = io.open(path, "r")
    if not file then
        return nil, "Template not found"
    end
    
    local template = file:read("*all")
    file:close()
    
    return template
end

-- Render file
function M.renderFile(path, data)
    local template, err = M.loadFile(path)
    if not template then
        return nil, err
    end
    
    return M.render(template, data)
end

return M
```

Usage example:
```lua
local template = require('template')

local tmpl = [[
<h1>{{escape(title)}}</h1>
<ul>
{% for i, item in ipairs(items) do %}
    <li>{= item =}</li>
{% end %}
</ul>
<script>
const data = {= json(data) =};
</script>
]]

local html = template.render(tmpl, {
    title = "My <List>",
    items = {"First", "Second", "Third"},
    data = {foo = "bar", num = 42}
})

print(html)
```

### 3. Validation Plugin

```lua
-- validate/plugin.lua: Data validation
local M = {}

-- Validators
local validators = {}

-- Email validation
function validators.email(value)
    if type(value) ~= "string" then
        return false, "must be a string"
    end
    
    if not value:match("^[%w._%+-]+@[%w.-]+%.[%w]+$") then
        return false, "invalid email format"
    end
    
    return true
end

-- String validators
function validators.string(options)
    return function(value)
        if type(value) ~= "string" then
            return false, "must be a string"
        end
        
        if options.min and #value < options.min then
            return false, "too short (minimum " .. options.min .. " characters)"
        end
        
        if options.max and #value > options.max then
            return false, "too long (maximum " .. options.max .. " characters)"
        end
        
        if options.pattern and not value:match(options.pattern) then
            return false, "invalid format"
        end
        
        return true
    end
end

-- Number validators
function validators.number(options)
    return function(value)
        if type(value) ~= "number" then
            return false, "must be a number"
        end
        
        if options.min and value < options.min then
            return false, "too small (minimum " .. options.min .. ")"
        end
        
        if options.max and value > options.max then
            return false, "too large (maximum " .. options.max .. ")"
        end
        
        if options.integer and math.floor(value) ~= value then
            return false, "must be an integer"
        end
        
        return true
    end
end

-- Required validator
function validators.required(value)
    if value == nil or value == "" then
        return false, "is required"
    end
    return true
end

-- Schema validation
function M.validate(data, schema)
    local errors = {}
    
    for field, rules in pairs(schema) do
        local value = data[field]
        
        -- Check if required
        if rules.required then
            local valid, err = validators.required(value)
            if not valid then
                errors[field] = err
                goto continue
            end
        elseif value == nil then
            goto continue
        end
        
        -- Type validation
        if rules.type then
            local validator = validators[rules.type]
            if validator then
                local valid, err
                if type(validator) == "function" then
                    valid, err = validator(value)
                else
                    valid, err = validator(rules)(value)
                end
                
                if not valid then
                    errors[field] = err
                end
            end
        end
        
        -- Custom validator
        if rules.custom then
            local valid, err = rules.custom(value, data)
            if not valid then
                errors[field] = err
            end
        end
        
        ::continue::
    end
    
    if next(errors) then
        return false, errors
    end
    
    return true
end

-- Convenience functions
M.isEmail = validators.email

function M.isString(value, min, max)
    return validators.string({min = min, max = max})(value)
end

function M.isNumber(value, min, max)
    return validators.number({min = min, max = max})(value)
end

-- Usage example in plugin
function M.example()
    local schema = {
        username = {
            required = true,
            type = "string",
            min = 3,
            max = 20,
            pattern = "^[%w_]+$"
        },
        email = {
            required = true,
            type = "email"
        },
        age = {
            type = "number",
            min = 18,
            max = 120,
            integer = true
        },
        password = {
            required = true,
            type = "string",
            min = 8,
            custom = function(value)
                if not value:match("%d") then
                    return false, "must contain at least one number"
                end
                return true
            end
        }
    }
    
    local data = {
        username = "john_doe",
        email = "john@example.com",
        age = 25,
        password = "secret123"
    }
    
    local valid, errors = M.validate(data, schema)
    if valid then
        print("Data is valid!")
    else
        print("Validation errors:")
        for field, err in pairs(errors) do
            print("  " .. field .. ": " .. err)
        end
    end
end

return M
```

## Testing & Distribution

### Unit Testing

Create `tests/test_myplugin.lua`:
```lua
-- Simple test framework
local tests = {}
local passed = 0
local failed = 0

function test(name, fn)
    io.write("Testing " .. name .. "... ")
    io.flush()
    
    local ok, err = pcall(fn)
    if ok then
        print("✓")
        passed = passed + 1
    else
        print("✗")
        print("  Error:", err)
        failed = failed + 1
    end
end

function assert(condition, message)
    if not condition then
        error(message or "Assertion failed", 2)
    end
end

function assertEquals(actual, expected)
    if actual ~= expected then
        error(string.format("Expected %s, got %s", tostring(expected), tostring(actual)), 2)
    end
end

-- Load plugin
local plugin = require('../plugin')

-- Run tests
test("version", function()
    assert(plugin.VERSION == "1.0.0")
end)

test("readFile", function()
    -- Create test file
    local f = io.open("test.txt", "w")
    f:write("test content")
    f:close()
    
    local content = plugin.readFile("test.txt")
    assertEquals(content, "test content")
    
    -- Cleanup
    os.remove("test.txt")
end)

test("writeFile", function()
    local ok = plugin.writeFile("output.txt", "hello")
    assert(ok == true)
    
    local content = plugin.readFile("output.txt")
    assertEquals(content, "hello")
    
    os.remove("output.txt")
end)

test("exists", function()
    assertEquals(plugin.exists("nonexistent.txt"), false)
    
    plugin.writeFile("exists.txt", "")
    assertEquals(plugin.exists("exists.txt"), true)
    
    os.remove("exists.txt")
end)

-- Summary
print("\nTest Results:")
print("  Passed: " .. passed)
print("  Failed: " .. failed)
print("  Total:  " .. (passed + failed))

if failed > 0 then
    os.exit(1)
end
```

### Integration Testing

```lua
-- Test with actual Hype
-- test_integration.lua
local fs = require('fs-extra')

-- Test in TUI app
local app = tui.newApp()
local text = tui.newTextView("")

-- Test file operations
local ok = fs.writeFile("app.log", "Application started\n")
if ok then
    text:SetText("Log file created")
else
    text:SetText("Failed to create log")
end

app:SetRoot(text, true):Run()
```

Run with:
```bash
./hype run test_integration.lua --plugins fs-extra=./fs-extra
```

### Distribution

#### 1. GitHub Repository Structure
```
hype-plugin-fs-extra/
├── .github/
│   └── workflows/
│       └── test.yml
├── hype-plugin.yaml
├── plugin.lua
├── lib/
├── tests/
├── examples/
├── README.md
├── LICENSE
└── CHANGELOG.md
```

#### 2. README Template
```markdown
# FS-Extra Plugin for Hype

Extended filesystem operations for Hype applications.

## Installation

```bash
# Use with hype run
hype run app.lua --plugins fs-extra@1.0.0

# Build with plugin
hype build app.lua --plugins fs-extra@1.0.0 -o myapp
```

## Features

- Read/write files with error handling
- JSON file support
- Directory operations
- File watching
- Cross-platform compatibility

## Usage

```lua
local fs = require('fs-extra')

-- Read file
local content, err = fs.readFile("data.txt")
if not content then
    print("Error:", err)
    return
end

-- Write JSON
local data = {name = "Hype", awesome = true}
fs.writeJSON("config.json", data)

-- Watch for changes
go(fs.watch("config.json", function(path, event)
    print("File", path, "was", event)
end))
```

## API Reference

### `fs.readFile(path) → content, error`
Read entire file contents.

### `fs.writeFile(path, content) → success, error`
Write content to file, creating directories as needed.

[... more documentation ...]

## License

MIT
```

#### 3. Version Management

Create tags for releases:
```bash
git tag v1.0.0
git push origin v1.0.0
```

Users can then reference:
```bash
# From GitHub
hype run app.lua --plugins fs-extra=github.com/user/hype-plugin-fs-extra@1.0.0

# From local path
hype run app.lua --plugins fs-extra=./plugins/fs-extra@1.0.0
```

## Best Practices

### 1. Error Handling
```lua
-- Always return nil + error instead of throwing
function M.riskyOperation(input)
    if not input then
        return nil, "Input required"
    end
    
    local ok, result = pcall(doSomethingRisky, input)
    if not ok then
        return nil, "Operation failed: " .. result
    end
    
    return result
end
```

### 2. Resource Management
```lua
-- Clean up resources
function M.process(path)
    local file, err = io.open(path, "r")
    if not file then
        return nil, err
    end
    
    -- Ensure cleanup even on error
    local ok, result = pcall(function()
        -- Process file
        return processContent(file:read("*all"))
    end)
    
    file:close()
    
    if not ok then
        return nil, result
    end
    
    return result
end
```

### 3. Configuration
```lua
-- Allow configuration
local defaultConfig = {
    timeout = 30,
    retries = 3,
    debug = false
}

local config = {}

function M.configure(options)
    config = {}
    for k, v in pairs(defaultConfig) do
        config[k] = v
    end
    
    if options then
        for k, v in pairs(options) do
            config[k] = v
        end
    end
end

-- Initialize with defaults
M.configure()
```

### 4. Logging
```lua
-- Optional debug logging
local function log(level, ...)
    if config.debug or level == "ERROR" then
        print("[" .. M.NAME .. "]", level .. ":", ...)
    end
end

function M.someOperation()
    log("DEBUG", "Starting operation")
    -- ...
    log("ERROR", "Operation failed:", err)
end
```

### 5. Cross-Platform
```lua
-- Handle platform differences
local isWindows = package.config:sub(1,1) == '\\'

function M.pathSeparator()
    return isWindows and '\\' or '/'
end

function M.joinPath(...)
    local parts = {...}
    return table.concat(parts, M.pathSeparator())
end
```

### 6. Documentation
```lua
--- Read file contents
-- @param path string The file path to read
-- @return string|nil The file contents, or nil on error
-- @return string|nil Error message if operation failed
function M.readFile(path)
    -- Implementation
end
```

### 7. Testing
- Write comprehensive tests
- Test error conditions
- Test cross-platform behavior
- Include integration tests
- Benchmark performance

### 8. Versioning
- Follow semantic versioning
- Update CHANGELOG.md
- Tag releases
- Maintain backwards compatibility

## Plugin Ideas

1. **Database Plugins**
   - SQLite wrapper
   - MongoDB client
   - Redis client

2. **Web Plugins**
   - OAuth authentication
   - JWT utilities
   - GraphQL client

3. **Utility Plugins**
   - UUID generation
   - Date/time formatting
   - Color manipulation

4. **Integration Plugins**
   - AWS SDK
   - Discord bot
   - Slack notifications

5. **Development Plugins**
   - Hot reload
   - Testing framework
   - Documentation generator

## Summary

Plugins are the key to extending Hype without bloating the core. By following these patterns and best practices, you can create powerful, reusable plugins that work seamlessly across all platforms. Start simple, test thoroughly, and share with the community!