-- WebSocket Echo Server Example
-- This creates a WebSocket server that echoes back any message it receives

local websocket = require("websocket")

print("Starting WebSocket echo server on port 8080...")

-- Create WebSocket server
local server = websocket.newServer()

-- Handle WebSocket connections at /ws endpoint
server:handle("/ws", function(conn)
    print("New WebSocket connection established")
    
    -- Set up connection handlers
    conn:onMessage(function(message)
        print("Received: " .. message.data)
        -- Echo the message back
        conn:send("Echo: " .. message.data)
    end)
    
    conn:onClose(function()
        print("Connection closed")
    end)
    
    conn:onError(function(err)
        print("WebSocket error: " .. err)
    end)
    
    -- Send welcome message
    conn:send("Welcome to the WebSocket server!")
end)

-- Start the server
server:listen(8080)
print("WebSocket server running at ws://localhost:8080/ws")
print("Press Ctrl+C to stop")

-- Keep the server running
while true do
    -- Sleep to prevent busy waiting
    os.execute("sleep 1")
end