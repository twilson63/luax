-- Hype TUI REPL - Working Version
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
flex:SetTitle("🚀 Hype Lua REPL v1.8.0")

-- Configure output view (top panel)
outputView:SetBorder(true)
outputView:SetTitle("📤 Output")
outputView:SetDynamicColors(true)
outputView:SetWrap(true)
outputView:SetWordWrap(true)
outputView:SetScrollable(true)

-- Configure input field (bottom panel)
inputField:SetBorder(true)
inputField:SetTitle("📥 Input - Press Enter to Execute | Ctrl+C to Exit")
inputField:SetLabel("hype> ")
inputField:SetPlaceholder("Enter Lua expression...")

-- Helper function to append output
local function appendOutput(text)
    if outputText ~= "" then
        outputText = outputText .. "\n"
    end
    outputText = outputText .. text
    outputView:SetText(outputText)
end

-- Welcome message
appendOutput("🚀 Hype Lua REPL v1.8.0")
appendOutput("========================")
appendOutput("")
appendOutput("Available modules: tui, http, kv, crypto, ws")
appendOutput("")
appendOutput("Controls:")
appendOutput("• Enter: Execute expression")
appendOutput("• Ctrl+C: Exit REPL")
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

-- Function to execute code
local function executeCode(code)
    if code == "" then return end
    
    -- Add to history (simple implementation without navigation for now)
    table.insert(history, code)
    
    -- Show the command
    appendOutput("hype> " .. code)
    
    -- Try to execute as expression first (to get return value)
    local func, err = load("return " .. code, "repl", "t", _G)
    
    if not func then
        -- If that fails, try as statement
        func, err = load(code, "repl", "t", _G)
    end
    
    if func then
        -- Execute the function
        local results = {pcall(func)}
        local ok = table.remove(results, 1)
        
        if ok then
            -- Print any return values
            if #results > 0 and results[1] ~= nil then
                local output = {}
                for _, v in ipairs(results) do
                    if type(v) == "table" then
                        table.insert(output, "<table>")
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

-- Global key bindings (on app, not inputField)
app:SetInputCapture(function(event)
    local key = event:Key()
    
    if key == 3 then -- Ctrl+C
        app:Stop()
        return nil
    end
    
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