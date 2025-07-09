# Hype Plugin System

Hype's plugin system allows you to extend your applications with reusable Lua modules. Plugins can add new functionality, integrate with external services, or provide utility functions. They support versioning, automatic discovery, and are embedded into your built executables.

## Table of Contents

- [Quick Start](#quick-start)
- [Using Plugins](#using-plugins)
- [Plugin Specification Formats](#plugin-specification-formats)
- [Creating Lua Plugins](#creating-lua-plugins)
- [Plugin Manifest](#plugin-manifest)
- [Plugin Discovery](#plugin-discovery)
- [Version Management](#version-management)
- [Best Practices](#best-practices)
- [Examples](#examples)
- [Advanced Topics](#advanced-topics)

## Quick Start

### Using an Existing Plugin

```bash
# Run a script with a plugin
./hype run myapp.lua --plugins fs@1.0.0

# Build an executable with embedded plugin
./hype build myapp.lua --plugins fs@1.0.0 -o myapp
```

```lua
-- In your Lua script
local fs = require("fs")
local content, err = fs.readFile("config.txt")
if content then
    print("Config:", content)
else
    print("Error:", err)
end
```

### Creating a Simple Plugin

1. **Create plugin directory:**
```bash
mkdir my-plugin
cd my-plugin
```

2. **Create manifest (`hype-plugin.yaml`):**
```yaml
name: "my-plugin"
version: "1.0.0"
type: "lua"
main: "plugin.lua"
description: "My awesome plugin"
author: "Your Name"
license: "MIT"
```

3. **Create plugin code (`plugin.lua`):**
```lua
local myplugin = {}

function myplugin.greet(name)
    return "Hello, " .. (name or "World") .. "!"
end

return myplugin
```

4. **Use the plugin:**
```bash
./hype run test.lua --plugins ./my-plugin
```

```lua
-- test.lua
local mp = require("my-plugin")
print(mp.greet("Hype"))  -- "Hello, Hype!"
```

## Using Plugins

### Command Line Usage

**Single Plugin:**
```bash
# By name (auto-discovery)
./hype run app.lua --plugins fs

# With specific version
./hype run app.lua --plugins fs@1.0.0

# With explicit path
./hype run app.lua --plugins ./path/to/plugin
```

**Multiple Plugins:**
```bash
# Multiple plugins
./hype run app.lua --plugins fs@1.0.0,json,utils@2.0.0

# With custom aliases
./hype run app.lua --plugins filesystem=fs@1.0.0,parser=json@1.5.0
```

**Plugin Configuration File:**
```bash
# Create plugins.yaml
./hype run app.lua --plugins-config plugins.yaml
```

```yaml
# plugins.yaml
plugins:
  - name: "fs"
    source: "./plugins/filesystem"
    version: "1.0.0"
  - name: "json"
    source: "github.com/user/json-plugin"
    version: "2.1.0"
    alias: "parser"
```

### In Lua Scripts

```lua
-- Load plugins like built-in modules
local fs = require("fs")
local json = require("json")

-- Use plugin functions
local data = {name = "John", age = 30}
local jsonStr = json.encode(data)
fs.writeFile("user.json", jsonStr)

local content = fs.readFile("user.json")
local userData = json.decode(content)
print("User:", userData.name)
```

## Plugin Specification Formats

| Format | Description | Example |
|--------|-------------|---------|
| `name` | Simple name, auto-discovery | `fs` |
| `name@version` | Name with version | `fs@1.0.0` |
| `alias=source` | Custom alias | `myfs=./path/to/plugin` |
| `alias=source@version` | Alias with version | `myfs=./path/to/plugin@2.0.0` |
| `url@version` | Remote source (future) | `github.com/user/plugin@v1.0.0` |

### Auto-Discovery Locations

When using simple names, Hype searches these locations:
1. `./plugins/[name]/`
2. `./examples/plugins/[name]/`
3. `./[name]-plugin/`
4. `./examples/plugins/[name]-plugin/`

## Creating Lua Plugins

### Plugin Structure

```
my-plugin/
├── hype-plugin.yaml    # Required: Plugin manifest
├── plugin.lua          # Required: Main plugin code
├── README.md           # Optional: Documentation
├── LICENSE             # Optional: License file
└── examples/           # Optional: Usage examples
    └── demo.lua
```

### Plugin Code Structure

```lua
-- plugin.lua
local myplugin = {}

-- Simple function
function myplugin.hello(name)
    return "Hello, " .. (name or "World") .. "!"
end

-- Function with error handling (Lua convention)
function myplugin.divide(a, b)
    if b == 0 then
        return nil, "Division by zero"
    end
    return a / b, nil
end

-- Function with optional parameters
function myplugin.format(text, options)
    options = options or {}
    local prefix = options.prefix or ""
    local suffix = options.suffix or ""
    return prefix .. text .. suffix
end

-- Plugin metadata (optional but recommended)
myplugin._VERSION = "1.0.0"
myplugin._DESCRIPTION = "My awesome plugin"

-- Must return the plugin table
return myplugin
```

### Error Handling Conventions

Follow Lua conventions for error handling:

```lua
-- Return value, error pattern
function myplugin.readConfig(file)
    local content, err = readFile(file)
    if not content then
        return nil, "Failed to read config: " .. err
    end
    
    local config, err = parseJSON(content)
    if not config then
        return nil, "Invalid JSON: " .. err
    end
    
    return config, nil
end

-- Usage
local config, err = myplugin.readConfig("app.json")
if config then
    print("Config loaded:", config.name)
else
    print("Error:", err)
end
```

## Plugin Manifest

The `hype-plugin.yaml` file defines plugin metadata:

```yaml
# Required fields
name: "my-plugin"           # Plugin name (used in require())
version: "1.0.0"           # Semantic version
type: "lua"                # Plugin type (currently only "lua")
main: "plugin.lua"         # Entry point file

# Optional fields
description: "Description of what the plugin does"
author: "Your Name <email@example.com>"
license: "MIT"
homepage: "https://github.com/user/my-plugin"
repository: "https://github.com/user/my-plugin.git"

# Dependencies (for future Go plugin support)
dependencies:
  - "some-go-module@v1.0.0"

# Keywords for searchability (future use)
keywords:
  - "filesystem"
  - "utility"
  - "tool"
```

### Version Format

Use [Semantic Versioning](https://semver.org/):
- `1.0.0` - Major.Minor.Patch
- `1.0.0-alpha.1` - Pre-release
- `1.0.0+build.1` - Build metadata

## Plugin Discovery

### Search Order

When you specify `--plugins fs@1.0.0`, Hype searches:

1. **Exact path** (if path-like): `./fs@1.0.0`
2. **Standard locations**:
   - `./plugins/fs/`
   - `./examples/plugins/fs/`
   - `./fs-plugin/`
   - `./examples/plugins/fs-plugin/`
3. **Future: Plugin registry** (planned)
4. **Future: Go modules** (for Go plugins)

### Version Validation

- Exact version matching: `fs@1.0.0` only accepts version `1.0.0`
- Latest: `fs` or `fs@latest` accepts any version
- Future: Semantic ranges like `fs@^1.0.0`, `fs@~1.2.0`

## Version Management

### Plugin Versioning

```bash
# Use specific version
./hype run app.lua --plugins fs@1.0.0

# Use latest available
./hype run app.lua --plugins fs

# Multiple versions with aliases
./hype run app.lua --plugins fs1=fs@1.0.0,fs2=fs@2.0.0
```

### Version Compatibility

```lua
-- Check plugin version in your code
local fs = require("fs")

if fs._VERSION then
    print("Using fs plugin version:", fs._VERSION)
    
    -- Version-specific features
    if fs._VERSION >= "2.0.0" and fs.copyFile then
        fs.copyFile("source.txt", "dest.txt")
    else
        print("copyFile not available in this version")
    end
end
```

## Best Practices

### Plugin Development

1. **Follow Lua conventions:**
   - Return `value, error` for functions that can fail
   - Use `nil` to indicate failure/absence
   - Keep global state minimal

2. **Include metadata:**
   ```lua
   myplugin._VERSION = "1.0.0"
   myplugin._DESCRIPTION = "What this plugin does"
   ```

3. **Validate inputs:**
   ```lua
   function myplugin.processFile(filename, options)
       if type(filename) ~= "string" then
           return nil, "filename must be a string"
       end
       if options and type(options) ~= "table" then
           return nil, "options must be a table"
       end
       -- ... rest of function
   end
   ```

4. **Document your functions:**
   ```lua
   --- Reads a file and returns its contents
   -- @param filepath string: Path to the file to read
   -- @return string|nil: File contents or nil on error
   -- @return string|nil: Error message if operation failed
   function myplugin.readFile(filepath)
       -- implementation
   end
   ```

### Plugin Usage

1. **Pin versions in production:**
   ```bash
   # Good for production
   ./hype build app.lua --plugins fs@1.0.0,json@2.1.0
   
   # Good for development
   ./hype run app.lua --plugins fs,json
   ```

2. **Handle plugin errors gracefully:**
   ```lua
   local success, fs = pcall(require, "fs")
   if not success then
       print("Filesystem plugin not available, using fallback")
       -- Use built-in io functions instead
   end
   ```

3. **Use plugin configuration files:**
   ```yaml
   # plugins.yaml
   plugins:
     - name: "fs"
       version: "1.0.0"
     - name: "json" 
       version: "2.1.0"
   ```

## Examples

### Filesystem Plugin

A complete filesystem plugin example:

```lua
-- filesystem-plugin/plugin.lua
local fs = {}

function fs.readFile(path)
    local file = io.open(path, "r")
    if not file then
        return nil, "Could not open file: " .. path
    end
    
    local content = file:read("*a")
    file:close()
    return content, nil
end

function fs.writeFile(path, content)
    local file = io.open(path, "w")
    if not file then
        return false, "Could not create file: " .. path
    end
    
    file:write(content)
    file:close()
    return true, nil
end

function fs.exists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

fs._VERSION = "1.0.0"
return fs
```

### JSON Plugin

```lua
-- json-plugin/plugin.lua
local json = {}

-- Simple JSON encoder (basic implementation)
function json.encode(obj)
    if type(obj) == "string" then
        return '"' .. obj:gsub('\\', '\\\\'):gsub('"', '\\"') .. '"'
    elseif type(obj) == "number" then
        return tostring(obj)
    elseif type(obj) == "boolean" then
        return obj and "true" or "false"
    elseif type(obj) == "table" then
        local parts = {}
        local isArray = true
        local count = 0
        
        -- Check if it's an array
        for k, v in pairs(obj) do
            count = count + 1
            if type(k) ~= "number" or k ~= count then
                isArray = false
                break
            end
        end
        
        if isArray then
            for i, v in ipairs(obj) do
                table.insert(parts, json.encode(v))
            end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            for k, v in pairs(obj) do
                table.insert(parts, json.encode(tostring(k)) .. ":" .. json.encode(v))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    else
        return "null"
    end
end

-- Basic JSON decoder (simplified)
function json.decode(str)
    -- This is a very basic implementation
    -- In a real plugin, you'd want a proper JSON parser
    local func = load("return " .. str)
    if func then
        return func(), nil
    else
        return nil, "Invalid JSON"
    end
end

json._VERSION = "1.0.0"
return json
```

### HTTP Utilities Plugin

```lua
-- http-utils-plugin/plugin.lua
local httputils = {}

function httputils.parseURL(url)
    local protocol, host, port, path = url:match("^(%w+)://([^:/]+):?(%d*)(.*)$")
    if not protocol then
        return nil, "Invalid URL format"
    end
    
    return {
        protocol = protocol,
        host = host,
        port = port ~= "" and tonumber(port) or (protocol == "https" and 443 or 80),
        path = path ~= "" and path or "/"
    }, nil
end

function httputils.buildQuery(params)
    local parts = {}
    for k, v in pairs(params) do
        table.insert(parts, k .. "=" .. tostring(v))
    end
    return table.concat(parts, "&")
end

function httputils.parseHeaders(headerString)
    local headers = {}
    for line in headerString:gmatch("[^\r\n]+") do
        local name, value = line:match("^([^:]+):%s*(.+)$")
        if name and value then
            headers[name:lower()] = value
        end
    end
    return headers
end

httputils._VERSION = "1.0.0"
return httputils
```

## Advanced Topics

### Plugin Loading Lifecycle

1. **Parse plugin specification** (`fs@1.0.0`)
2. **Discover plugin location** (search paths)
3. **Load manifest** (`hype-plugin.yaml`)
4. **Validate version** (exact match)
5. **Load plugin code** (`plugin.lua`)
6. **Register with Lua** (`require("fs")` works)
7. **Embed in build** (for `hype build`)

### Plugin Isolation

Currently, Hype plugins share the same Lua state. Future improvements may include:
- Plugin sandboxing
- Resource limits
- API access controls

### Performance Considerations

- Plugins are loaded once at startup
- Plugin code is embedded in built executables
- No runtime plugin loading overhead
- Version validation happens at load time

### Future Enhancements

- **Go plugins**: Native performance plugins
- **Plugin registry**: Central plugin repository
- **Semantic versioning**: Range matching (`^1.0.0`)
- **Plugin dependencies**: Plugins that depend on other plugins
- **Hot reloading**: Development mode plugin reloading

## Troubleshooting

### Common Issues

**Plugin not found:**
```bash
Error: failed to load plugin fs: failed to fetch plugin: unsupported plugin source: fs
```
- Check plugin exists in search paths
- Try explicit path: `--plugins ./path/to/plugin`

**Version mismatch:**
```bash
Error: version validation failed: plugin version mismatch: requested 2.0.0, found 1.0.0
```
- Check plugin manifest version
- Use correct version or `@latest`

**Plugin load error:**
```bash
Error: failed to execute Lua plugin: [string "plugin code"]:5: attempt to call a nil value
```
- Check plugin syntax
- Ensure plugin returns a table
- Validate function implementations

### Debug Tips

1. **Test plugin independently:**
   ```bash
   lua plugin.lua  # Test plugin syntax
   ```

2. **Use development mode:**
   ```bash
   ./hype run --plugins fs test.lua  # Faster iteration
   ```

3. **Check plugin locations:**
   ```bash
   ls -la ./plugins/fs/
   ls -la ./examples/plugins/fs/
   ```

4. **Validate manifest:**
   ```bash
   # Check YAML syntax
   python -c "import yaml; yaml.safe_load(open('hype-plugin.yaml'))"
   ```

---

For more examples and advanced use cases, see the `examples/plugins/` directory in the Hype repository.