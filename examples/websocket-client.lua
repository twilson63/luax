-- WebSocket Client Example
-- This connects to a WebSocket server and sends/receives messages

local websocket = require("websocket")

print("Connecting to WebSocket server...")

-- Connect to WebSocket server
local client = websocket.connect("ws://localhost:8080/ws")

if not client then
    print("Failed to connect to WebSocket server")
    os.exit(1)
end

print("Connected to WebSocket server!")

-- Set up client handlers
client:onMessage(function(message)
    print("Received: " .. message.data)
end)

client:onClose(function()
    print("Connection closed")
end)

client:onError(function(err)
    print("WebSocket error: " .. err)
end)

-- Send some test messages
client:send("Hello from Lua client!")

-- Wait a moment for response
os.execute("sleep 1")

client:send("This is a test message")

-- Wait a moment for response
os.execute("sleep 1")

client:send("Goodbye!")

-- Wait for final response before closing
os.execute("sleep 1")

-- Close the connection
client:close()

print("Client example completed")