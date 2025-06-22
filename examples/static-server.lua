-- Static File Web Server
-- Example demonstrating HTTP server with command line arguments
local http = require('http')

-- Default configuration
local port = 8080
local directory = "./public"
local host = "localhost"

-- Parse command line arguments
for i = 1, #arg do
    if arg[i] == "--port" or arg[i] == "-p" then
        if arg[i+1] then
            port = tonumber(arg[i+1])
        end
    elseif arg[i] == "--dir" or arg[i] == "-d" then
        if arg[i+1] then
            directory = arg[i+1]
        end
    elseif arg[i] == "--host" or arg[i] == "-h" then
        if arg[i+1] then
            host = arg[i+1]
        end
    elseif arg[i] == "--help" then
        print("Static File Web Server")
        print("Usage: " .. arg[0] .. " [options]")
        print("")
        print("Options:")
        print("  --port, -p <port>    Server port (default: 8080)")
        print("  --dir, -d <dir>      Directory to serve (default: ./public)")
        print("  --host, -h <host>    Host to bind to (default: localhost)")
        print("  --help               Show this help message")
        print("")
        print("Examples:")
        print("  " .. arg[0] .. " --port 3000")
        print("  " .. arg[0] .. " --dir /var/www --port 8000")
        os.exit(0)
    end
end

-- Create server
local server = http.newServer()

-- Serve static files
server:handle("/", function(req, res)
    local path = req.url
    
    -- Security: prevent directory traversal
    if string.find(path, "%.%.") then
        res:json({ error = "Access denied", code = 403 })
        return
    end
    
    -- Default to index.html for root
    if path == "/" then
        path = "/index.html"
    end
    
    local filepath = directory .. path
    
    -- Try to read file
    local file = io.open(filepath, "r")
    if file then
        local content = file:read("*all")
        file:close()
        
        -- Set content type based on extension
        local ext = string.match(filepath, "%.([^%.]+)$")
        if ext then
            if ext == "html" or ext == "htm" then
                res.headers = { ["Content-Type"] = "text/html" }
            elseif ext == "css" then
                res.headers = { ["Content-Type"] = "text/css" }
            elseif ext == "js" then
                res.headers = { ["Content-Type"] = "application/javascript" }
            elseif ext == "json" then
                res.headers = { ["Content-Type"] = "application/json" }
            end
        end
        
        res:write(content)
    else
        -- File not found
        res:json({ 
            error = "File not found", 
            path = path,
            code = 404 
        })
    end
end)

-- API endpoint for server info
server:handle("/api/info", function(req, res)
    res:json({
        server = "Hype Static Server",
        directory = directory,
        port = port,
        host = host,
        files_served = true
    })
end)

-- Health check endpoint
server:handle("/health", function(req, res)
    res:json({ status = "healthy", timestamp = os.time() })
end)

-- Start server
print("=== Hype Static File Server ===")
print("Directory: " .. directory)
print("Server: http://" .. host .. ":" .. port)
print("Health: http://" .. host .. ":" .. port .. "/health")
print("Info: http://" .. host .. ":" .. port .. "/api/info")
print("")
print("Press Ctrl+C to stop server")

server:listen(port)

-- Keep server running
while true do
    os.execute("sleep 1")
end