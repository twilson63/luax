-- Simple HTTP server test
local http = require('http')

print("Creating server...")
local server = http.newServer()

print("Setting up routes...")
server:handle("/", function(req, res)
    print("Handling request to /")
    res:write("Hello from LuaX server!")
end)

server:handle("/api/test", function(req, res)
    print("Handling API request")
    res:json({message = "API works!", time = os.time()})
end)

print("Starting server on port 8080...")
server:listen(8080)

print("Server started! Visit http://localhost:8080")
print("Press Enter to stop...")
io.read()

print("Stopping server...")
server:stop()