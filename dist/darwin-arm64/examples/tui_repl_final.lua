-- Hype TUI REPL - Final Version
-- A fully-featured REPL with TUI interface

-- Initialize state
local outputText = ""
local history = {}
local historyIndex = 0

-- Create TUI components
local app = tui.newApp()
local flex = tui.newFlex()
local outputView = tui.newTextView("")
local inputField = tui.newInputField()

-- Configure main layout
flex:SetDirection(0) -- Vertical
flex:SetBorder(true)
flex:SetTitle("🚀 Hype Lua REPL v1.9.0")

-- Configure output view (top panel)
outputView:SetBorder(true)
outputView:SetTitle("📤 Output")
outputView:SetDynamicColors(false)  -- Disable to show brackets properly
outputView:SetWrap(true)
outputView:SetWordWrap(true)
outputView:SetScrollable(true)

-- Configure input field (bottom panel)
inputField:SetBorder(true)
inputField:SetTitle("📥 Input - Press Enter to Execute | Ctrl+C to Exit")
inputField:SetLabel("hype> ")
inputField:SetPlaceholder("Enter Lua expression...")
inputField:SetFieldBackgroundColor(235)  -- Dark gray for better readability

-- Helper function to append output
local function appendOutput(text)
    if outputText ~= "" then
        outputText = outputText .. "\n"
    end
    outputText = outputText .. text
    outputView:SetText(outputText)
end

-- Welcome message
appendOutput("🚀 Hype Lua REPL v1.9.0")
appendOutput("========================")
appendOutput("")
appendOutput("Available modules: tui, http, kv, crypto, ws")
appendOutput("")
appendOutput("Controls:")
appendOutput("• Enter: Execute expression")
appendOutput("• Up/Down: Navigate command history")
appendOutput("• Ctrl+C: Exit REPL")
appendOutput("• Escape: Clear current input")
appendOutput("")
appendOutput("Example commands:")
appendOutput('  2 + 2')
appendOutput('  print("Hello, World!")')
appendOutput('  local http = require("http")')
appendOutput('  math.sqrt(16)')
appendOutput("")
appendOutput("Ready! Type your Lua expressions below.")
appendOutput("=====================================")

-- Override print to capture output
local originalPrint = print
_G.print = function(...)
    local args = {...}
    local parts = {}
    for i, v in ipairs(args) do
        table.insert(parts, tostring(v))
    end
    appendOutput(table.concat(parts, "\t"))
end

-- Table formatting function
local function formatTable(t, indent)
    indent = indent or ""
    local parts = {}
    local keys = {}
    
    -- Collect all keys
    for k in pairs(t) do
        table.insert(keys, k)
    end
    
    -- Sort keys for consistent output
    table.sort(keys, function(a, b)
        if type(a) == type(b) then
            return tostring(a) < tostring(b)
        else
            return type(a) < type(b)
        end
    end)
    
    -- Format the table
    table.insert(parts, "{")
    for i, k in ipairs(keys) do
        local v = t[k]
        local key_str = type(k) == "string" and string.format("%q", k) or tostring(k)
        local val_str
        
        if type(v) == "table" then
            if indent:len() < 20 then  -- Limit nesting depth
                val_str = formatTable(v, indent .. "  ")
            else
                val_str = "<nested table>"
            end
        elseif type(v) == "string" then
            val_str = string.format("%q", v)
        elseif type(v) == "function" then
            val_str = "<function>"
        elseif type(v) == "userdata" then
            val_str = "<userdata>"
        elseif type(v) == "thread" then
            val_str = "<thread>"
        else
            val_str = tostring(v)
        end
        
        table.insert(parts, string.format("%s  [%s] = %s%s", indent, key_str, val_str, i < #keys and "," or ""))
    end
    table.insert(parts, indent .. "}")
    
    return table.concat(parts, "\n")
end

-- Function to execute code
local function executeCode(code)
    if code == "" then return end
    
    -- Add to history
    table.insert(history, code)
    historyIndex = #history + 1
    
    -- Show the command
    appendOutput("hype> " .. code)
    
    -- Try to execute as expression first (to get return value)
    local func, err = loadstring("return " .. code)
    
    if not func then
        -- If that fails, try as statement
        func, err = loadstring(code)
    end
    
    if func then
        -- Execute the function
        local results = {pcall(func)}
        local ok = table.remove(results, 1)
        
        if ok then
            -- Print any return values
            if #results > 0 then
                local output = {}
                for _, v in ipairs(results) do
                    if type(v) == "table" then
                        table.insert(output, formatTable(v))
                    elseif type(v) == "function" then
                        table.insert(output, "<function>")
                    elseif type(v) == "userdata" then
                        table.insert(output, "<userdata>")
                    elseif type(v) == "thread" then
                        table.insert(output, "<thread>")
                    else
                        table.insert(output, tostring(v))
                    end
                end
                appendOutput(table.concat(output, "\t"))
            end
        else
            appendOutput("Error: " .. tostring(results[1]))
        end
    else
        appendOutput("Syntax Error: " .. tostring(err))
    end
end

-- Input field done handler
inputField:SetDoneFunc(function(key)
    if key == 13 then -- Enter key
        local code = inputField:GetText()
        executeCode(code)
        inputField:SetText("")
    end
end)

-- History state for navigation
local navigatingHistory = false

-- Global key bindings
app:SetInputCapture(function(event)
    local key = event:Key()
    
    if key == 3 then -- Ctrl+C
        app:Stop()
        return nil
    elseif key == 256 then -- Up arrow (tcell.KeyUp)
        if historyIndex > 1 then
            historyIndex = historyIndex - 1
            inputField:SetText(history[historyIndex])
        end
        return nil
    elseif key == 257 then -- Down arrow (tcell.KeyDown)
        if historyIndex < #history then
            historyIndex = historyIndex + 1
            inputField:SetText(history[historyIndex])
        elseif historyIndex == #history then
            historyIndex = historyIndex + 1
            inputField:SetText("")
        end
        return nil
    elseif key == 27 then -- Escape
        inputField:SetText("")
        return nil
    end
    
    -- Pass through all other events
    return event
end)

-- Layout assembly
flex:AddItem(outputView, 0, 1, false)  -- Output view (flexible, takes most space)
flex:AddItem(inputField, 3, 0, true)   -- Input field (fixed height of 3 lines)

-- Set initial focus and root
app:SetRoot(flex, true)
app:SetFocus(inputField)

-- Start the application
app:Run()

-- Restore original print when done
_G.print = originalPrint
print("\nTUI REPL session ended.")