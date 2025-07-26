-- Hype TUI REPL Example
-- A terminal-based Lua REPL with TUI interface

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

-- Helper function to add output
local function addOutput(text)
    if outputText ~= "" then
        outputText = outputText .. "\n"
    end
    outputText = outputText .. text
    outputView:SetText(outputText)
end

-- Welcome message
addOutput("🚀 Hype Lua REPL v1.8.0")
addOutput("========================")
addOutput("")
addOutput("Available modules: tui, http, kv, crypto, ws")
addOutput("Special functions: dofile_repl(filename) - Load and execute a Lua file")
addOutput("")
addOutput("Controls:")
addOutput("• Enter: Execute expression")
addOutput("• Ctrl+C: Exit REPL")
addOutput("• Up/Down: Navigate command history")
addOutput("• Escape: Clear current input")
addOutput("")
addOutput("Example commands:")
addOutput('  > 2 + 2')
addOutput('  > print("Hello, World!")')
addOutput('  > local http = require("http")')
addOutput('  > math.sqrt(16)')
addOutput("")
addOutput("Ready! Type your Lua expressions below.")
addOutput("=====================================")

-- Override print to capture output
local originalPrint = _G.print
_G.print = function(...)
    local args = {...}
    local parts = {}
    for i, v in ipairs(args) do
        table.insert(parts, tostring(v))
    end
    addOutput(table.concat(parts, "\t"))
end

-- Add dofile function for loading scripts
_G.dofile_repl = function(filename)
    local f, err = loadfile(filename)
    if not f then
        addOutput("Error loading file: " .. tostring(err))
        return false, err
    end
    
    local ok, result = pcall(f)
    if not ok then
        addOutput("Error executing file: " .. tostring(result))
        return false, result
    end
    
    return true
end

-- Function to execute code
local function executeCode(code)
    if code == "" then return end
    
    -- Add to history
    table.insert(history, code)
    historyIndex = #history + 1
    
    -- Show the command
    addOutput("hype> " .. code)
    
    -- Try to execute as expression first (to get return value)
    local func, err = load("return " .. code, "repl", "t", _G)
    
    if not func then
        -- If that fails, try as statement
        func, err = load(code, "repl", "t", _G)
    end
    
    if func then
        -- Execute the function
        local ok, result = pcall(func)
        if ok then
            if result ~= nil then
                -- Convert result to string for display
                local resultStr
                if type(result) == "table" then
                    resultStr = "<table>"
                elseif type(result) == "function" then
                    resultStr = "<function>"
                elseif type(result) == "userdata" then
                    resultStr = "<userdata>"
                else
                    resultStr = tostring(result)
                end
                addOutput(resultStr)
            end
        else
            addOutput("Error: " .. tostring(result))
        end
    else
        addOutput("Syntax Error: " .. tostring(err))
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

-- Input field key handler for history
inputField:SetInputCapture(function(event)
    local key = event:Key()
    
    if key == 38 or key == 65 then -- Up arrow (38 for some terminals, 65 for others)
        if historyIndex > 1 then
            historyIndex = historyIndex - 1
            inputField:SetText(history[historyIndex])
        end
        return nil
    elseif key == 40 or key == 66 then -- Down arrow
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
    
    return event
end)

-- Global key bindings
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
app:SetFocus(inputField)
app:SetRoot(flex, true)

-- Print startup info (will be captured by output view)
print("TUI REPL started successfully!")
print("Try typing some expressions...")

-- Start the application
app:Run()

-- Restore original print when done
_G.print = originalPrint
print("REPL session ended.")