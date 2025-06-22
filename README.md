# LuaX - Lua Script to Executable Packager

LuaX is a powerful tool that packages Lua scripts into standalone executables with TUI (Terminal User Interface), HTTP, and embedded database support. It combines a Lua runtime with your scripts to create cross-platform applications with zero external dependencies.

## Features

- 📦 **Package Lua scripts into standalone executables**
- 🌍 **Cross-platform support** (Linux, macOS, Windows)
- 🖥️ **Built-in TUI library** for creating terminal applications
- 🌐 **HTTP client and server** support for web applications
- 🗄️ **Embedded key-value database** with BoltDB
- 🔄 **Transaction support** with ACID properties
- 🔍 **Database iteration and querying** with cursor support
- ✨ **Zero external dependencies** in final executables
- 🚀 **Simple deployment** - single binary distribution

## Installation

```bash
git clone https://github.com/twilson63/luax.git
cd luax
go build -o luax .
```

## Quick Start

```bash
# Create a simple TUI app
echo 'local app = tui.newApp()
local text = tui.newTextView("Hello from LuaX!")
app:SetRoot(text, true)
app:Run()' > hello.lua

# Build and run
./luax build hello.lua -o hello
./hello
```

## Usage

### Command Line Interface

```bash
# Build a Lua script into an executable
./luax build script.lua

# Specify output name
./luax build script.lua -o myapp

# Build for different platforms
./luax build script.lua -t linux
./luax build script.lua -t windows
./luax build script.lua -t darwin
```

## API Reference

### TUI Module

Create beautiful terminal user interfaces:

```lua
local tui = require('tui') -- Available by default

-- Core components
local app = tui.newApp()              -- Main application
local textView = tui.newTextView(text) -- Text display
local inputField = tui.newInputField() -- Text input
local button = tui.newButton(label)   -- Clickable button
local flex = tui.newFlex()            -- Layout container
```

### HTTP Module

Build web applications and APIs:

```lua
local http = require('http')

-- HTTP Client
local response, err = http.get("https://api.example.com/data", {
    timeout = 30,
    headers = { ["User-Agent"] = "LuaX/1.0" }
})

-- HTTP Server
local server = http.newServer()
server:handle("/api/users", function(req, res)
    res:json({ message = "Hello from LuaX server!" })
end)
server:listen(8080)
```

### Key-Value Database

Embedded database with no external dependencies:

```lua
local kv = require('kv')

-- Open database
local db, err = kv.open("./myapp.db")

-- Create bucket and basic operations
db:open_db("users")
db:put("users", "user1", "John Doe")
local value, err = db:get("users", "user1")
db:delete("users", "user1")

-- Transactions
local txn, err = db:begin_txn(false)
txn:put("users", "user2", "Jane Smith")
txn:commit()

-- Iteration and querying
local keys, err = db:keys("users", "admin:") -- Prefix search
db:foreach("users", function(key, value)
    print(key .. " = " .. value)
    return true -- continue iteration
end)

db:close()
```

## Examples

### Simple TUI Application

```lua
local app = tui.newApp()
local textView = tui.newTextView("Hello, World from LuaX!\n\nPress Ctrl+C to exit.")

textView:SetWrap(true)
textView:SetWordWrap(true)

app:SetRoot(textView, true)
app:Run()
```

### Interactive Form

```lua
local app = tui.newApp()
local flex = tui.newFlex()
local textView = tui.newTextView("Enter your information:")
local nameField = tui.newInputField()
local submitButton = tui.newButton("Submit")

nameField:SetLabel("Name: ")
nameField:SetPlaceholder("Enter your name")

submitButton:SetSelectedFunc(function()
    local name = nameField:GetText()
    textView:SetText("Hello, " .. name .. "!")
end)

flex:SetDirection(1) -- Column layout
flex:AddItem(textView, 1, 0, false)
flex:AddItem(nameField, 1, 0, true)
flex:AddItem(submitButton, 1, 0, false)

app:SetRoot(flex, true)
app:Run()
```

### Web Server with Database

```lua
local http = require('http')
local kv = require('kv')

-- Setup database
local db = kv.open("./users.db")
db:open_db("users")

-- Create web server
local server = http.newServer()

-- API endpoint to create user
server:handle("/users", function(req, res)
    if req.method == "POST" then
        local id = "user" .. os.time()
        db:put("users", id, req.body)
        res:json({ id = id, message = "User created" })
    elseif req.method == "GET" then
        local users = {}
        db:foreach("users", function(key, value)
            users[key] = value
            return true
        end)
        res:json(users)
    end
end)

print("Server starting on http://localhost:8080")
server:listen(8080)

-- Keep server running
while true do
    os.execute("sleep 1")
end
```

### Plain Text Browser

```lua
local http = require('http')
local app = tui.newApp()
local flex = tui.newFlex()
local addressBar = tui.newInputField()
local contentView = tui.newTextView("")
local statusBar = tui.newTextView("Ready - Enter URL and press Enter")

addressBar:SetLabel("URL: ")
addressBar:SetPlaceholder("https://example.com")

local function loadPage(url)
    statusBar:SetText("Loading " .. url .. "...")
    local response, err = http.get(url)
    
    if err then
        contentView:SetText("Error: " .. err)
        statusBar:SetText("Error loading page")
    else
        -- Strip HTML tags for plain text display
        local content = response.body:gsub("<[^>]*>", "")
        contentView:SetText(content)
        statusBar:SetText("Loaded " .. url .. " (Status: " .. response.status .. ")")
    end
end

addressBar:SetDoneFunc(function(key)
    if key == 13 then -- Enter key
        local url = addressBar:GetText()
        if url ~= "" then
            loadPage(url)
        end
    end
end)

flex:SetDirection(1)
flex:AddItem(addressBar, 1, 0, true)
flex:AddItem(contentView, 0, 1, false)
flex:AddItem(statusBar, 1, 0, false)

app:SetRoot(flex, true)
app:Run()
```

## Database Operations

### Basic CRUD Operations

```lua
local kv = require('kv')
local db = kv.open("./app.db")

-- Create bucket
db:open_db("products")

-- Create
db:put("products", "prod1", "Laptop Computer")

-- Read
local product, err = db:get("products", "prod1")
if product then
    print("Product:", product)
end

-- Update
db:put("products", "prod1", "Gaming Laptop")

-- Delete
db:delete("products", "prod1")

db:close()
```

### Advanced Querying

```lua
-- List all keys
local keys, err = db:keys("products")
for i = 1, #keys do
    print("Key:", keys[i])
end

-- Prefix search
local adminProducts = db:keys("products", "admin:")

-- Iterate with callback
db:foreach("products", function(key, value)
    print(key .. " = " .. value)
    
    -- Early termination
    if key == "stop_here" then
        return false
    end
    
    return true -- continue
end)
```

### Transactions

```lua
-- Begin transaction
local txn, err = db:begin_txn(false) -- false = read-write
if err then
    error("Failed to start transaction: " .. err)
end

-- Perform operations
txn:put("users", "batch1", "User One")
txn:put("users", "batch2", "User Two")
txn:put("users", "batch3", "User Three")

-- Commit or rollback
local err = txn:commit()
if err then
    print("Transaction failed:", err)
    txn:abort()
else
    print("Transaction committed successfully")
end
```

## Building and Testing

```bash
# Build the luax tool
go build -o luax .

# Test with example scripts
./luax build examples/hello.lua -o hello && ./hello
./luax build examples/kv-test.lua -o kv-test && ./kv-test
./luax build examples/browser.lua -o browser && ./browser
./luax build examples/webserver.lua -o webserver && ./webserver
./luax build examples/showcase.lua -o showcase && ./showcase
```

## Cross-Platform Builds

```bash
# Build for Linux
./luax build myapp.lua -t linux -o myapp-linux

# Build for Windows  
./luax build myapp.lua -t windows -o myapp-windows

# Build for macOS
./luax build myapp.lua -t darwin -o myapp-macos
```

## Use Cases

- 🖥️ **Terminal Applications**: Interactive CLI tools, system monitors, development utilities
- 🌐 **Web Applications**: REST APIs, web servers, microservices  
- 🗄️ **Data Tools**: Database utilities, data processing scripts, ETL tools
- 📦 **Distributed Software**: Single-binary deployments, embedded systems
- 🔧 **DevOps Tools**: Build scripts, deployment automation, monitoring tools

## Why LuaX?

- **Zero Dependencies**: No external libraries or runtimes needed
- **Small Binaries**: Efficient packaging with reasonable file sizes  
- **Cross-Platform**: Write once, run anywhere
- **Rich APIs**: TUI, HTTP, and database support built-in
- **Easy Deployment**: Single executable file distribution
- **Lua Simplicity**: Clean, readable scripting language
- **Go Performance**: Fast startup and execution times

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see [LICENSE](LICENSE) file for details.