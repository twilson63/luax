# Hype Troubleshooting Guide & Common Patterns

> Solutions to common issues and battle-tested patterns for Hype development

## Table of Contents

### Troubleshooting
1. [Installation Issues](#installation-issues)
2. [Build Problems](#build-problems)
3. [Runtime Errors](#runtime-errors)
4. [Platform-Specific Issues](#platform-specific-issues)
5. [Module-Specific Problems](#module-specific-problems)
6. [Performance Issues](#performance-issues)

### Common Patterns
7. [Application Patterns](#application-patterns)
8. [Error Handling Patterns](#error-handling-patterns)
9. [Concurrency Patterns](#concurrency-patterns)
10. [Testing Patterns](#testing-patterns)

---

## Troubleshooting

### Installation Issues

#### Problem: "hype: command not found"
**Symptoms:** After installation, `hype` command is not recognized

**Solutions:**
```bash
# 1. Check if hype is in your PATH
which hype

# 2. Add to PATH manually
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 3. Alternative: use full path
~/.local/bin/hype version

# 4. Reinstall with explicit path
curl -sSL https://raw.githubusercontent.com/twilson63/hype/main/install.sh | bash
```

#### Problem: "Permission denied" during installation
**Symptoms:** Installation script fails with permission errors

**Solutions:**
```bash
# 1. Make installer executable
chmod +x install.sh
./install.sh

# 2. Install to user directory (no sudo needed)
PREFIX=$HOME/.local ./install.sh

# 3. Manual installation
wget https://github.com/twilson63/hype/releases/latest/download/hype-linux-amd64
chmod +x hype-linux-amd64
mv hype-linux-amd64 ~/.local/bin/hype
```

#### Problem: macOS Gatekeeper blocks hype
**Symptoms:** "hype cannot be opened because it is from an unidentified developer"

**Solution:**
```bash
# Remove quarantine attribute
xattr -d com.apple.quarantine /path/to/hype

# Or allow in System Preferences > Security & Privacy
```

### Build Problems

#### Problem: "go: command not found" during build
**Symptoms:** Building executables fails with Go not found

**Explanation:** Hype uses Go to compile executables but doesn't require Go to be installed. This error indicates a corrupted Hype installation.

**Solutions:**
```bash
# 1. Reinstall Hype
curl -sSL https://raw.githubusercontent.com/twilson63/hype/main/install.sh | bash

# 2. Verify Hype installation
./hype version

# 3. Test with simple script
echo 'print("Hello")' > test.lua
./hype build test.lua -o test
```

#### Problem: Build fails with "module not found"
**Symptoms:** Multi-file projects fail to build

**Solutions:**
```lua
-- 1. Use relative paths with ./
local utils = require('./utils')  -- Correct
-- NOT: require('utils')

-- 2. Check file exists
-- utils.lua must be in same directory

-- 3. Use absolute paths if needed
local config = require('/home/user/project/config')
```

**Project structure fix:**
```
project/
├── main.lua
├── utils.lua
└── lib/
    └── helpers.lua

-- In main.lua:
local utils = require('./utils')
local helpers = require('./lib/helpers')
```

#### Problem: Cross-compilation fails
**Symptoms:** Building for different platforms produces errors

**Solutions:**
```bash
# 1. Use GOOS/GOARCH (v1.7.1+)
GOOS=linux GOARCH=amd64 ./hype build app.lua -o app-linux

# 2. Use --target flag (older versions)
./hype build app.lua --target linux -o app-linux

# 3. Verify platform support
# Supported: linux, darwin, windows
# Architectures: amd64, arm64

# 4. Windows executable naming
GOOS=windows ./hype build app.lua -o app.exe
```

### Runtime Errors

#### Problem: "attempt to index a nil value"
**Common causes and solutions:**

```lua
-- 1. Module not loaded
-- Error: attempt to index global 'http' (a nil value)
local http = require('http')  -- Fix: require module first

-- 2. Missing error checking
local resp = http.get(url)
print(resp.body)  -- Error if request failed

-- Fix:
local resp, err = http.get(url)
if err then
    print("Error:", err)
    return
end
print(resp.body)

-- 3. Incorrect method chaining
local app = tui.newApp()
app:SetRoot(text, true):Run():Stop()  -- Error: Run() returns nil

-- Fix:
app:SetRoot(text, true)
app:Run()
-- app:Stop() called elsewhere
```

#### Problem: "too many open files"
**Symptoms:** Application crashes after running for a while

**Solutions:**
```lua
-- 1. Close files explicitly
local file = io.open("data.txt", "r")
local content = file:read("*all")
file:close()  -- Don't forget this!

-- 2. Use helper function
function readFile(path)
    local file, err = io.open(path, "r")
    if not file then return nil, err end
    local content = file:read("*all")
    file:close()
    return content
end

-- 3. Database connections
local db = kv.open("./data.db")
-- ... use database ...
db:close()  -- Close when done

-- 4. Increase system limits (Linux/macOS)
-- ulimit -n 4096
```

#### Problem: "bad argument #1 to 'insert'"
**Symptoms:** Table operations fail

**Solutions:**
```lua
-- 1. Initialize tables before use
local results = {}  -- Don't forget this!
table.insert(results, value)

-- 2. Check if variable is table
if type(data) == "table" then
    table.insert(data, item)
end

-- 3. Avoid reusing variable names
local data = "string"
-- ... later ...
table.insert(data, item)  -- Error!
```

### Platform-Specific Issues

#### Linux Issues

**Problem: Binary doesn't run on older systems**
```bash
# Check glibc version
ldd --version

# Solution: Build on older system or use static linking
# Hype binaries are generally compatible with glibc 2.17+
```

**Problem: TUI colors not displaying correctly**
```bash
# 1. Check terminal support
echo $TERM
# Should be xterm-256color or similar

# 2. Set proper terminal
export TERM=xterm-256color

# 3. Use compatible terminal
# Recommended: gnome-terminal, konsole, xterm
```

#### macOS Issues

**Problem: "killed" message when running binary**
```bash
# macOS kills unsigned binaries
# Solution 1: Remove quarantine
xattr -c ./myapp

# Solution 2: Sign the binary
codesign -s - ./myapp

# Solution 3: Allow in Security preferences
```

**Problem: Performance issues on M1/M2 Macs**
```bash
# Build native ARM64 binary
GOOS=darwin GOARCH=arm64 ./hype build app.lua -o app-m1

# Check architecture
file app-m1
# Should show: Mach-O 64-bit arm64
```

#### Windows Issues

**Problem: "Windows cannot access the specified device"**
```batch
REM 1. Unblock file
powershell -Command "Unblock-File -Path .\myapp.exe"

REM 2. Run as administrator if needed
REM Right-click > Run as administrator

REM 3. Check antivirus quarantine
```

**Problem: TUI not rendering correctly**
```batch
REM 1. Use Windows Terminal (recommended)
REM 2. Enable UTF-8 support
chcp 65001

REM 3. Or use legacy console with limited features
```

### Module-Specific Problems

#### TUI Module Issues

**Problem: "panic: runtime error: invalid memory address"**
```lua
-- Common cause: Using TUI outside of app:Run()
local app = tui.newApp()
local text = tui.newTextView()
text:SetText("Hello")  -- Error: app not running

-- Fix: Set up before Run()
local app = tui.newApp()
local text = tui.newTextView("Hello")
app:SetRoot(text, true)
app:Run()

-- Or update in QueueUpdateDraw
app:QueueUpdateDraw(function()
    text:SetText("Updated")
end)
```

**Problem: TUI not responding to input**
```lua
-- 1. Ensure focus is set
app:SetFocus(inputField)

-- 2. Check focus parameter in AddItem
flex:AddItem(input, 1, 0, true)  -- true = can receive focus

-- 3. Handle input callbacks
input:SetDoneFunc(function(key)
    if key == tui.KeyEnter then
        -- Handle enter
    end
end)
```

#### HTTP Module Issues

**Problem: "connection refused"**
```lua
-- 1. Check server is running
local server = http.newServer()
server:listen(8080)  -- This starts immediately

-- 2. Wait for server to start
local server = http.newServer()
go(function() server:listen(8080) end)
sleep(0.1)  -- Give server time to start

-- 3. Check port availability
-- lsof -i :8080  (Linux/macOS)
-- netstat -an | findstr 8080  (Windows)
```

**Problem: "timeout" errors**
```lua
-- 1. Increase timeout
local resp = http.get(url, {timeout = 60})  -- 60 seconds

-- 2. Handle timeouts gracefully
local resp, err = http.get(url, {timeout = 5})
if err and err:match("timeout") then
    print("Request timed out, retrying...")
    resp, err = http.get(url, {timeout = 10})
end

-- 3. Use connection pooling for multiple requests
-- (Built into Hype's HTTP client)
```

#### Database Module Issues

**Problem: "database is locked"**
```lua
-- 1. Single database connection
local db_instance = nil

function get_db()
    if not db_instance then
        db_instance = kv.open("./data.db")
    end
    return db_instance
end

-- 2. Use transactions for consistency
db:transaction(function()
    db:put("users", "id1", "data1")
    db:put("users", "id2", "data2")
end)

-- 3. Close database properly
local function cleanup()
    if db_instance then
        db_instance:close()
        db_instance = nil
    end
end
```

**Problem: "no such bucket"**
```lua
-- Always create bucket before use
local db = kv.open("./data.db")
db:open_db("users")  -- Create/open bucket
db:put("users", "key", "value")  -- Now safe to use
```

### Performance Issues

#### High Memory Usage
```lua
-- 1. Clear large variables
bigData = nil
collectgarbage()

-- 2. Process in chunks
function processLargeFile(path)
    local file = io.open(path, "r")
    while true do
        local chunk = file:read(1024 * 1024)  -- 1MB chunks
        if not chunk then break end
        processChunk(chunk)
        collectgarbage("step")
    end
    file:close()
end

-- 3. Monitor memory
function printMemory()
    local mem = collectgarbage("count")
    print(string.format("Memory: %.2f MB", mem / 1024))
end
```

#### Slow HTTP Requests
```lua
-- 1. Parallel requests
local urls = {"url1", "url2", "url3"}
local results = {}
local done = 0

for i, url in ipairs(urls) do
    go(function()
        local resp = http.get(url)
        results[i] = resp
        done = done + 1
    end)
end

-- Wait for all
while done < #urls do
    sleep(0.1)
end

-- 2. Cache responses
local cache = {}
function cachedGet(url)
    if cache[url] then
        return cache[url]
    end
    local resp = http.get(url)
    cache[url] = resp
    return resp
end
```

---

## Common Patterns

### Application Patterns

#### CLI Application Pattern
```lua
-- cli-app.lua
local commands = {}

function commands.help()
    print([[
Usage: app <command> [options]

Commands:
  serve     Start HTTP server
  process   Process data files
  help      Show this help
]])
end

function commands.serve(args)
    local port = args[1] or "8080"
    local server = http.newServer()
    server:handle("/", function(req, res)
        res:json({status = "running", port = port})
    end)
    print("Server starting on port " .. port)
    server:listen(tonumber(port))
end

function commands.process(args)
    local file = args[1]
    if not file then
        print("Error: filename required")
        return
    end
    -- Process file
    print("Processing " .. file)
end

-- Main
local cmd = arg[1] or "help"
local args = {}
for i = 2, #arg do
    table.insert(args, arg[i])
end

local handler = commands[cmd] or commands.help
handler(args)
```

#### Service Application Pattern
```lua
-- service.lua
local running = true
local server = nil

-- Signal handling
function shutdown()
    print("\nShutting down...")
    running = false
    if server then
        server:stop()
    end
end

-- Health check endpoint
function healthHandler(req, res)
    res:json({
        status = "healthy",
        uptime = os.time() - startTime,
        version = "1.0.0"
    })
end

-- Main service
function startService()
    server = http.newServer()
    
    -- Routes
    server:handle("/health", healthHandler)
    server:handle("/api/data", dataHandler)
    
    -- Start server
    print("Service starting on :8080")
    server:listen(8080)
end

-- Run service
local startTime = os.time()
go(startService)

-- Keep running
while running do
    sleep(1)
    -- Could add periodic tasks here
end

shutdown()
```

#### Configuration Pattern
```lua
-- config.lua
local M = {}

-- Default configuration
local defaults = {
    server = {
        host = "localhost",
        port = 8080,
        timeout = 30
    },
    database = {
        path = "./data.db",
        buckets = {"users", "sessions", "logs"}
    },
    features = {
        auth = true,
        logging = true,
        metrics = false
    }
}

-- Load from environment
function M.fromEnv()
    local config = deepcopy(defaults)
    
    -- Override from environment
    config.server.port = tonumber(os.getenv("PORT")) or config.server.port
    config.database.path = os.getenv("DB_PATH") or config.database.path
    config.features.auth = os.getenv("DISABLE_AUTH") ~= "true"
    
    return config
end

-- Load from JSON file
function M.fromFile(path)
    local file = io.open(path, "r")
    if not file then
        return deepcopy(defaults)
    end
    
    local content = file:read("*all")
    file:close()
    
    -- Parse JSON (using json plugin)
    local ok, data = pcall(json.decode, content)
    if not ok then
        error("Invalid config file: " .. path)
    end
    
    -- Merge with defaults
    return merge(defaults, data)
end

-- Helper functions
function deepcopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = deepcopy(v)
    end
    return copy
end

function merge(base, override)
    local result = deepcopy(base)
    for k, v in pairs(override) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = merge(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end

return M
```

### Error Handling Patterns

#### Graceful Error Handling
```lua
-- Safe wrapper pattern
function safe(fn)
    return function(...)
        local ok, result = pcall(fn, ...)
        if not ok then
            return nil, result
        end
        return result
    end
end

-- Usage
local safeGet = safe(http.get)
local resp, err = safeGet("https://api.example.com")
if err then
    print("Request failed:", err)
    return
end

-- Result type pattern
function Result(ok, value, error)
    return {
        ok = ok,
        value = value,
        error = error,
        map = function(self, fn)
            if self.ok then
                return Result(true, fn(self.value))
            end
            return self
        end,
        unwrap = function(self)
            if self.ok then
                return self.value
            end
            error(self.error)
        end
    }
end

-- Usage
function divide(a, b)
    if b == 0 then
        return Result(false, nil, "division by zero")
    end
    return Result(true, a / b)
end

local result = divide(10, 2)
if result.ok then
    print("Result:", result.value)
else
    print("Error:", result.error)
end
```

#### Retry Pattern
```lua
function retry(fn, options)
    options = options or {}
    local attempts = options.attempts or 3
    local delay = options.delay or 1
    local backoff = options.backoff or 2
    
    for i = 1, attempts do
        local ok, result = pcall(fn)
        if ok then
            return result
        end
        
        if i < attempts then
            print(string.format("Attempt %d failed: %s", i, result))
            sleep(delay)
            delay = delay * backoff
        else
            error(string.format("Failed after %d attempts: %s", attempts, result))
        end
    end
end

-- Usage
local data = retry(function()
    local resp = http.get("https://flaky-api.com/data")
    if resp.status_code ~= 200 then
        error("HTTP " .. resp.status_code)
    end
    return resp.body
end, {attempts = 5, delay = 0.5})
```

#### Circuit Breaker Pattern
```lua
function CircuitBreaker(options)
    local self = {
        failureThreshold = options.failureThreshold or 5,
        resetTimeout = options.resetTimeout or 60,
        state = "closed",  -- closed, open, half-open
        failures = 0,
        lastFailureTime = 0
    }
    
    function self:call(fn)
        -- Check if should reset
        if self.state == "open" then
            if os.time() - self.lastFailureTime > self.resetTimeout then
                self.state = "half-open"
                self.failures = 0
            else
                return nil, "Circuit breaker is open"
            end
        end
        
        -- Try the call
        local ok, result = pcall(fn)
        
        if ok then
            if self.state == "half-open" then
                self.state = "closed"
            end
            self.failures = 0
            return result
        else
            self.failures = self.failures + 1
            self.lastFailureTime = os.time()
            
            if self.failures >= self.failureThreshold then
                self.state = "open"
                return nil, "Circuit breaker opened: " .. result
            end
            
            return nil, result
        end
    end
    
    return self
end

-- Usage
local apiBreaker = CircuitBreaker({
    failureThreshold = 3,
    resetTimeout = 30
})

local data, err = apiBreaker:call(function()
    return http.get("https://api.example.com/data")
end)
```

### Concurrency Patterns

#### Worker Pool Pattern
```lua
function WorkerPool(size)
    local self = {
        size = size,
        tasks = {},
        results = {},
        running = true
    }
    
    -- Worker function
    function self:worker(id)
        while self.running do
            if #self.tasks > 0 then
                local task = table.remove(self.tasks, 1)
                if task then
                    local ok, result = pcall(task.fn, task.args)
                    table.insert(self.results, {
                        id = task.id,
                        ok = ok,
                        result = result
                    })
                end
            else
                sleep(0.01)
            end
        end
    end
    
    -- Start workers
    function self:start()
        for i = 1, self.size do
            go(function() self:worker(i) end)
        end
    end
    
    -- Add task
    function self:addTask(fn, args)
        local id = #self.tasks + 1
        table.insert(self.tasks, {
            id = id,
            fn = fn,
            args = args
        })
        return id
    end
    
    -- Get results
    function self:getResults()
        local results = self.results
        self.results = {}
        return results
    end
    
    -- Shutdown
    function self:stop()
        self.running = false
    end
    
    return self
end

-- Usage
local pool = WorkerPool(4)
pool:start()

-- Add tasks
for i = 1, 10 do
    pool:addTask(function(n)
        sleep(0.1)
        return n * n
    end, i)
end

-- Wait and collect results
sleep(0.5)
local results = pool:getResults()
for _, r in ipairs(results) do
    print("Task", r.id, "result:", r.result)
end

pool:stop()
```

#### Pub/Sub Pattern
```lua
function PubSub()
    local self = {
        subscribers = {}
    }
    
    function self:subscribe(topic, handler)
        if not self.subscribers[topic] then
            self.subscribers[topic] = {}
        end
        table.insert(self.subscribers[topic], handler)
        
        -- Return unsubscribe function
        return function()
            self:unsubscribe(topic, handler)
        end
    end
    
    function self:unsubscribe(topic, handler)
        if not self.subscribers[topic] then return end
        
        for i, h in ipairs(self.subscribers[topic]) do
            if h == handler then
                table.remove(self.subscribers[topic], i)
                break
            end
        end
    end
    
    function self:publish(topic, data)
        if not self.subscribers[topic] then return end
        
        for _, handler in ipairs(self.subscribers[topic]) do
            go(function()
                local ok, err = pcall(handler, data)
                if not ok then
                    print("Handler error:", err)
                end
            end)
        end
    end
    
    return self
end

-- Usage
local eventBus = PubSub()

-- Subscribe to events
local unsub = eventBus:subscribe("user:login", function(data)
    print("User logged in:", data.username)
end)

eventBus:subscribe("user:login", function(data)
    -- Log to database
    db:put("logins", os.time(), data.username)
end)

-- Publish event
eventBus:publish("user:login", {
    username = "alice",
    timestamp = os.time()
})

-- Unsubscribe when done
unsub()
```

#### Rate Limiter Pattern
```lua
function RateLimiter(rate, burst)
    local self = {
        rate = rate,      -- tokens per second
        burst = burst,    -- max burst size
        tokens = burst,   -- current tokens
        lastUpdate = os.clock()
    }
    
    function self:allow()
        local now = os.clock()
        local elapsed = now - self.lastUpdate
        self.lastUpdate = now
        
        -- Add tokens based on time elapsed
        self.tokens = math.min(
            self.burst,
            self.tokens + elapsed * self.rate
        )
        
        if self.tokens >= 1 then
            self.tokens = self.tokens - 1
            return true
        end
        
        return false
    end
    
    function self:allowWait()
        while not self:allow() do
            sleep(0.01)
        end
        return true
    end
    
    return self
end

-- Usage
local limiter = RateLimiter(10, 20)  -- 10 req/sec, burst 20

-- Fast endpoint
server:handle("/api/fast", function(req, res)
    if not limiter:allow() then
        res:status(429)
        res:json({error = "Rate limit exceeded"})
        return
    end
    
    res:json({data = "response"})
end)

-- Or with waiting
function rateLimitedRequest(url)
    limiter:allowWait()
    return http.get(url)
end
```

### Testing Patterns

#### Unit Testing Framework
```lua
-- test_framework.lua
local TestRunner = {}
TestRunner.tests = {}
TestRunner.results = {passed = 0, failed = 0}

function test(name, fn)
    table.insert(TestRunner.tests, {name = name, fn = fn})
end

function assert(condition, message)
    if not condition then
        error(message or "Assertion failed", 2)
    end
end

function assertEquals(actual, expected)
    if actual ~= expected then
        error(string.format(
            "Expected %s, got %s",
            tostring(expected),
            tostring(actual)
        ), 2)
    end
end

function assertError(fn, message)
    local ok = pcall(fn)
    if ok then
        error(message or "Expected error but none occurred", 2)
    end
end

function TestRunner:run()
    print("Running tests...\n")
    
    for _, t in ipairs(self.tests) do
        io.write(t.name .. " ... ")
        io.flush()
        
        local ok, err = pcall(t.fn)
        if ok then
            print("✓")
            self.results.passed = self.results.passed + 1
        else
            print("✗")
            print("  Error:", err)
            self.results.failed = self.results.failed + 1
        end
    end
    
    print(string.format(
        "\nResults: %d passed, %d failed",
        self.results.passed,
        self.results.failed
    ))
    
    return self.results.failed == 0
end

-- Usage example
-- test_math.lua
test("addition works", function()
    assertEquals(2 + 2, 4)
    assertEquals(0 + 0, 0)
    assertEquals(-1 + 1, 0)
end)

test("division by zero errors", function()
    assertError(function()
        local x = 1 / 0
    end)
end)

test("string concatenation", function()
    assertEquals("hello" .. " " .. "world", "hello world")
end)

-- Run tests
local success = TestRunner:run()
os.exit(success and 0 or 1)
```

#### Integration Testing Pattern
```lua
-- test_integration.lua
function setupTestEnvironment()
    -- Create test database
    local db = kv.open(":memory:")
    db:open_db("test_users")
    
    -- Start test server
    local server = http.newServer()
    local port = 18080  -- Test port
    
    -- Configure routes
    server:handle("/users", function(req, res)
        if req.method == "POST" then
            local id = "user_" .. os.time()
            db:put("test_users", id, req.body)
            res:json({id = id})
        elseif req.method == "GET" then
            local users = {}
            db:foreach("test_users", function(k, v)
                users[k] = v
                return true
            end)
            res:json(users)
        end
    end)
    
    -- Start server in background
    go(function() server:listen(port) end)
    sleep(0.1)  -- Wait for server
    
    return {
        db = db,
        server = server,
        baseUrl = "http://localhost:" .. port
    }
end

function testUserAPI()
    local env = setupTestEnvironment()
    
    -- Test create user
    local resp = http.post(env.baseUrl .. "/users", 
        '{"name":"Test User"}',
        {["Content-Type"] = "application/json"}
    )
    assert(resp.status_code == 200, "Create user failed")
    
    local data = json.decode(resp.body)
    assert(data.id, "No user ID returned")
    
    -- Test get users
    resp = http.get(env.baseUrl .. "/users")
    assert(resp.status_code == 200, "Get users failed")
    
    local users = json.decode(resp.body)
    assert(users[data.id], "Created user not found")
    
    -- Cleanup
    env.server:stop()
    env.db:close()
    
    print("User API tests passed!")
end

-- Run tests
testUserAPI()
```

#### Benchmark Pattern
```lua
function benchmark(name, fn, options)
    options = options or {}
    local iterations = options.iterations or 1000
    local warmup = options.warmup or 100
    
    -- Warmup
    for i = 1, warmup do
        fn()
    end
    
    -- Measure
    collectgarbage()
    local start = os.clock()
    
    for i = 1, iterations do
        fn()
    end
    
    local elapsed = os.clock() - start
    local opsPerSec = iterations / elapsed
    
    print(string.format(
        "%s: %d ops in %.3fs (%.0f ops/sec, %.3fms/op)",
        name,
        iterations,
        elapsed,
        opsPerSec,
        (elapsed / iterations) * 1000
    ))
    
    return {
        name = name,
        iterations = iterations,
        elapsed = elapsed,
        opsPerSec = opsPerSec,
        msPerOp = (elapsed / iterations) * 1000
    }
end

-- Usage
benchmark("SHA256 hashing", function()
    crypto.sha256("test data to hash")
end, {iterations = 10000})

benchmark("JSON encoding", function()
    json.encode({
        name = "test",
        value = 123,
        nested = {a = 1, b = 2}
    })
end, {iterations = 5000})

benchmark("Database write", function()
    db:put("bench", "key", "value")
end, {iterations = 1000})
```

## Summary

This guide provides solutions to common Hype issues and battle-tested patterns for building robust applications. Key takeaways:

### For Troubleshooting:
- Always check error messages carefully
- Use proper error handling
- Understand platform differences
- Close resources properly
- Monitor performance

### For Patterns:
- Use structured application patterns
- Implement proper error handling
- Leverage concurrency safely
- Test your code thoroughly
- Benchmark critical paths

Remember: Hype provides the tools, but good patterns make the difference between a script and a production application.