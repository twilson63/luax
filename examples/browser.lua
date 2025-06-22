-- Plain Text Browser using Lua TUI and HTTP module
-- Uses require('http') for HTTP requests

local http = require('http')

-- Create main application
local app = tui.newApp()
local flex = tui.newFlex()

-- Create UI components
local addressBar = tui.newInputField()
local contentView = tui.newTextView("")
local statusBar = tui.newTextView("Ready - Enter URL and press Enter")

-- Helper function to format text content
local function formatContent(content)
    -- Basic text formatting - remove HTML tags if present
    content = content:gsub("<[^>]*>", "")
    -- Decode common HTML entities
    content = content:gsub("&amp;", "&")
    content = content:gsub("&lt;", "<")
    content = content:gsub("&gt;", ">")
    content = content:gsub("&quot;", '"')
    content = content:gsub("&#39;", "'")
    content = content:gsub("&nbsp;", " ")
    
    -- Clean up extra whitespace
    content = content:gsub("\r\n", "\n")
    content = content:gsub("\r", "\n")
    content = content:gsub("\n\n\n+", "\n\n")
    
    return content
end

-- Address bar handler
addressBar:SetDoneFunc(function(key)
    if key == 13 then -- Enter key
        local url = addressBar:GetText()
        if url == "" then
            return
        end
        
        -- Add protocol if missing
        if not url:match("^https?://") then
            url = "http://" .. url
        end
        
        -- Update status
        statusBar:SetText("Fetching: " .. url)
        
        -- Make HTTP request
        local response, err = http.get(url, {
            timeout = 10,
            headers = {
                ["User-Agent"] = "LuaX-Browser/1.0"
            }
        })
        
        if response and response.body then
            local formatted = formatContent(response.body)
            contentView:SetText(formatted)
            local status = response.status or "200"
            statusBar:SetText("Loaded: " .. url .. " (Status: " .. status .. ", " .. #formatted .. " chars)")
        else
            local error_msg = err or "Unknown error"
            contentView:SetText("Error: " .. error_msg)
            statusBar:SetText("Failed to load: " .. url)
        end
    end
end)

-- Set up layout
flex:SetDirection(0) -- Vertical layout

-- Address bar with label
local addressContainer = tui.newFlex()
addressContainer:SetDirection(1) -- Horizontal
local addressLabel = tui.newTextView("URL: ")
addressContainer:AddItem(addressLabel, 5, 0, false)
addressContainer:AddItem(addressBar, 0, 1, true)

-- Add components to main layout
flex:AddItem(addressContainer, 3, 0, false)  -- Address bar (3 lines)
flex:AddItem(contentView, 0, 1, false)      -- Content area (flexible)
flex:AddItem(statusBar, 1, 0, false)        -- Status bar (1 line)

-- Configure content view
contentView:SetWrap(true)
contentView:SetWordWrap(true)

-- Configure address bar
addressBar:SetLabel("")
addressBar:SetPlaceholder("Enter URL (e.g., example.com or https://httpbin.org/get)")

-- Configure status bar
statusBar:SetTextColor(0x00ff00) -- Green text

-- Set up key bindings
app:SetInputCapture(function(event)
    -- Ctrl+C to quit
    if event:Key() == 3 then -- Ctrl+C
        app:Stop()
        return nil
    end
    
    -- Ctrl+L to focus address bar
    if event:Key() == 12 then -- Ctrl+L
        app:SetFocus(addressBar)
        return nil
    end
    
    -- Escape to focus content view for scrolling
    if event:Key() == 27 then -- Escape
        app:SetFocus(contentView)
        return nil
    end
    
    return event
end)

-- Set initial focus and root
app:SetFocus(addressBar)
app:SetRoot(flex, true)

-- Show initial help
contentView:SetText([[
Welcome to LuaX Plain Text Browser!

This is a simple text-based web browser built with Lua and TUI.

Instructions:
1. Enter a URL in the address bar above
2. Press Enter to fetch the page
3. Use Ctrl+L to focus the address bar
4. Use Escape to focus content for scrolling
5. Use Ctrl+C to quit

Try these URLs:
- httpbin.org/get
- example.com
- api.github.com/users/octocat
- jsonplaceholder.typicode.com/posts/1

The browser uses Lua's HTTP module for reliable HTTP requests.
HTML tags are stripped for better readability.

Features:
- Native HTTP support via require('http')
- Automatic protocol detection (adds http:// if missing)
- HTML tag removal and entity decoding
- Proper text formatting and cleanup
- Status updates with HTTP response codes
- 10-second request timeout
]])

statusBar:SetText("Ready - Enter URL and press Enter | Ctrl+L: Focus address bar | Ctrl+C: Quit")

-- Start the application
app:Run()