-- Enhanced Plain Text Browser with Advanced TUI Styling
-- Features: Beautiful design, bottom address bar, improved text rendering

local http = require('http')

-- Color constants for consistent theming
local COLORS = {
    PRIMARY = 39,      -- Bright blue
    SUCCESS = 46,      -- Bright green  
    WARNING = 226,     -- Bright yellow
    DANGER = 196,      -- Bright red
    SECONDARY = 245,   -- Light gray
    DARK = 235,        -- Dark gray
    DARKER = 232,      -- Very dark gray
    LIGHT = 255,       -- White
    ACCENT = 201,      -- Bright magenta
    INFO = 51          -- Bright cyan
}

-- Application state
local currentUrl = ""
local loadTime = 0
local pageSize = 0
local isLoading = false

-- Create main application
local app = tui.newApp()
local mainFlex = tui.newFlex()

-- Create UI components with enhanced styling - simplified to two panels
local contentView = tui.newTextView("")
local addressBar = tui.newInputField()

-- Enhanced HTML to plain text conversion
local function htmlToPlainText(html)
    if not html or html == "" then
        return "No content received"
    end
    
    local text = html
    
    -- Handle common HTML structures with proper formatting
    -- Headers with spacing
    text = text:gsub("<h[1-6][^>]*>(.-)</h[1-6]>", function(content)
        return "\n\n" .. content:upper() .. "\n" .. string.rep("=", #content) .. "\n"
    end)
    
    -- Paragraphs with spacing
    text = text:gsub("<p[^>]*>(.-)</p>", "%1\n\n")
    
    -- Line breaks
    text = text:gsub("<br[^>]*>", "\n")
    
    -- Lists with bullets
    text = text:gsub("<li[^>]*>(.-)</li>", "• %1\n")
    text = text:gsub("<ul[^>]*>", "\n")
    text = text:gsub("</ul>", "\n")
    text = text:gsub("<ol[^>]*>", "\n")
    text = text:gsub("</ol>", "\n")
    
    -- Links (show URL)
    text = text:gsub('<a[^>]*href="([^"]*)"[^>]*>(.-)</a>', function(url, link_text)
        return link_text .. " [" .. url .. "]"
    end)
    
    -- Bold and italic formatting
    text = text:gsub("<b[^>]*>(.-)</b>", "**%1**")
    text = text:gsub("<strong[^>]*>(.-)</strong>", "**%1**")
    text = text:gsub("<i[^>]*>(.-)</i>", "*%1*")
    text = text:gsub("<em[^>]*>(.-)</em>", "*%1*")
    
    -- Code blocks
    text = text:gsub("<code[^>]*>(.-)</code>", "`%1`")
    text = text:gsub("<pre[^>]*>(.-)</pre>", function(code)
        return "\n" .. string.rep("-", 40) .. "\n" .. code .. "\n" .. string.rep("-", 40) .. "\n"
    end)
    
    -- Remove all remaining HTML tags
    text = text:gsub("<[^>]*>", "")
    
    -- Decode HTML entities
    local entities = {
        ["&amp;"] = "&",
        ["&lt;"] = "<",
        ["&gt;"] = ">",
        ["&quot;"] = '"',
        ["&#39;"] = "'",
        ["&apos;"] = "'",
        ["&nbsp;"] = " ",
        ["&mdash;"] = "—",
        ["&ndash;"] = "–",
        ["&ldquo;"] = '"',
        ["&rdquo;"] = '"',
        ["&lsquo;"] = "'",
        ["&rsquo;"] = "'",
        ["&hellip;"] = "…"
    }
    
    for entity, replacement in pairs(entities) do
        text = text:gsub(entity, replacement)
    end
    
    -- Clean up whitespace
    text = text:gsub("\r\n", "\n")
    text = text:gsub("\r", "\n")
    text = text:gsub("\n\n\n+", "\n\n")
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    
    return text
end

-- Simple status update function
local function updateStatus(message, level)
    level = level or "INFO"
    local icon = "ℹ️"
    
    if level == "SUCCESS" then icon = "✅"
    elseif level == "WARNING" then icon = "⚠️"
    elseif level == "ERROR" then icon = "❌"
    elseif level == "LOADING" then icon = "🔄"
    end
    
    -- Update address bar placeholder with status
    addressBar:SetPlaceholder(icon .. " " .. message .. " | Enter URL here...")
end

-- Load a URL
local function loadUrl(url)
    if url == "" then
        updateStatus("Please enter a URL", "WARNING")
        return
    end
    
    -- Add protocol if missing
    if not url:match("^https?://") then
        url = "http://" .. url
    end
    
    currentUrl = url
    isLoading = true
    updateStatus("Loading page...", "LOADING")
    
    local startTime = os.clock()
    
    -- Make HTTP request
    local response, err = http.get(url, {
        timeout = 15,
        headers = {
            ["User-Agent"] = "Hype-Enhanced-Browser/2.0",
            ["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
        }
    })
    
    loadTime = string.format("%.2f", os.clock() - startTime)
    isLoading = false
    
    if response and response.body then
        local plainText = htmlToPlainText(response.body)
        pageSize = tostring(#plainText)
        
        -- Add page header with metadata
        local pageHeader = string.format([[
%s
🌐 %s
%s

Status: %s | Size: %s chars | Load Time: %s seconds | Controls: Ctrl+L=Address, Ctrl+R=Reload, Ctrl+Q=Quit
%s

]], 
            string.rep("=", 80),
            currentUrl,
            string.rep("=", 80),
            response.status or "200",
            pageSize,
            loadTime,
            string.rep("=", 80)
        )
        
        contentView:SetText(pageHeader .. plainText)
        updateStatus("Page loaded successfully", "SUCCESS")
    else
        local errorMsg = err or "Unknown error occurred"
        contentView:SetText(string.format([[
%s
ERROR LOADING PAGE
%s

URL: %s
Error: %s
Time: %s seconds

Please check the URL and try again.
Some common issues:
• URL might be invalid or unreachable
• Network connection problems
• Server timeout or unavailable

Try these working URLs:
• httpbin.org/get
• example.com
• api.github.com/users/octocat
• jsonplaceholder.typicode.com/posts/1
]], 
            string.rep("=", 50),
            string.rep("=", 50),
            currentUrl,
            errorMsg,
            loadTime
        ))
        updateStatus("Failed to load page: " .. errorMsg, "ERROR")
    end
end

-- Configure main layout - simplified to two panels
mainFlex:SetDirection(0) -- 0 = Vertical (top to bottom), 1 = Horizontal (left to right)
mainFlex:SetBorder(true)
mainFlex:SetTitle("🌐 Enhanced Plain Text Browser")
mainFlex:SetBorderColor(COLORS.PRIMARY)
mainFlex:SetBackgroundColor(COLORS.DARKER)

-- Configure content view (top panel)
contentView:SetDynamicColors(true)
contentView:SetBorder(true)
contentView:SetTitle("📄 Web Content")
contentView:SetBorderColor(COLORS.SUCCESS)
contentView:SetBackgroundColor(COLORS.DARK)
contentView:SetWrap(true)
contentView:SetWordWrap(true)
contentView:SetScrollable(true)

-- Configure address bar (bottom panel)
addressBar:SetLabel("🌐 URL: ")
addressBar:SetPlaceholder("✅ Ready | Enter URL (e.g., example.com or https://httpbin.org/get)")
addressBar:SetBorder(true)
addressBar:SetTitle("🔗 Address Bar - Press Enter to Load")
addressBar:SetBorderColor(COLORS.ACCENT)
addressBar:SetFieldBackgroundColor(COLORS.DARKER)
addressBar:SetFieldTextColor(COLORS.LIGHT)

-- Address bar handler
addressBar:SetDoneFunc(function(key)
    if key == 13 then -- Enter key
        local url = addressBar:GetText()
        loadUrl(url)
    end
end)

-- Set up key bindings
app:SetInputCapture(function(event)
    local key = event:Key()
    
    if key == 17 then -- Ctrl+Q
        app:Stop()
        return nil
    elseif key == 12 then -- Ctrl+L
        app:SetFocus(addressBar)
        addressBar:SetText("")
        return nil
    elseif key == 18 then -- Ctrl+R
        if currentUrl ~= "" then
            loadUrl(currentUrl)
        else
            updateStatus("No page to reload", "WARNING")
        end
        return nil
    elseif key == 27 then -- Escape
        app:SetFocus(contentView)
        return nil
    end
    
    return event
end)

-- Simple two-panel layout assembly  
mainFlex:AddItem(contentView, 0, 1, false)    -- Content (flexible top panel)
mainFlex:AddItem(addressBar, 4, 0, true)      -- Address bar (fixed 4 lines bottom panel)

-- Set initial focus and root
app:SetFocus(addressBar)
app:SetRoot(mainFlex, true)

-- Initialize with welcome content
contentView:SetText(string.format([[
%s
🌐 ENHANCED PLAIN TEXT BROWSER
%s

Welcome! This is a beautifully styled text-based web browser.

✨ FEATURES:
• Enhanced HTML-to-text conversion with proper formatting
• Beautiful color-coded interface with professional styling
• Simplified two-panel layout: content above, address bar below
• Smart text rendering with headers, links, and code blocks
• Real-time status updates and error handling

🎯 HOW TO USE:
1. Enter a URL in the address bar at the bottom (currently focused)
2. Press Enter to load the page
3. Use arrow keys to scroll through content
4. Use Ctrl+L to focus address bar and clear it
5. Use Ctrl+R to reload the current page
6. Use Ctrl+Q to quit the browser

🌐 SUGGESTED URLS TO TRY:
• httpbin.org/get - JSON API response
• example.com - Simple test page  
• api.github.com/users/octocat - GitHub API
• jsonplaceholder.typicode.com/posts/1 - Sample data

🔧 TECHNICAL FEATURES:
• Native HTTP support via Lua's http module
• Automatic protocol detection (adds http:// if missing)
• Advanced HTML parsing and entity decoding
• Professional TUI styling with custom colors and borders
• Scrollable content with proper text wrapping

Ready to browse! The address bar is focused - just type a URL and press Enter.
]], 
    string.rep("=", 75),
    string.rep("=", 75)
))

-- Print startup info
print("🌐 Enhanced Plain Text Browser")
print("════════════════════════════════════════")
print("Enhanced TUI Features:")
print("• Dynamic colors and markup")
print("• Custom borders and themes") 
print("• Improved layout design")
print("• Better HTML-to-text conversion")
print("• Professional styling")
print("")
print("Controls:")
print("• Ctrl+Q: Quit browser")
print("• Ctrl+L: Focus address bar")
print("• Ctrl+R: Reload page")
print("• Arrow keys: Scroll content")
print("")

-- Start the application
app:Run()