-- Hype TUI REPL Implementation
local outputText = ""
local history = {}
local historyIndex = 0

-- Create TUI components
local app = tui.newApp()
local flex = tui.newFlex()
local outputView = tui.newTextView("")
local inputField = tui.newInputField()

-- Configure layout
flex:SetDirection(0) -- Vertical
flex:SetBorder(true)
flex:SetTitle("🚀 Hype Lua REPL v1.8.0")

-- Configure output view
outputView:SetBorder(true)
outputView:SetTitle("📤 Output")
outputView:SetDynamicColors(true)
outputView:SetWrap(true)
outputView:SetWordWrap(true)

-- Configure input field
inputField:SetBorder(true)
inputField:SetTitle("📥 Input (Press Enter to Execute, Ctrl+C to Exit)")
inputField:SetLabel("hype> ")

-- Helper to add output
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
addOutput("Special functions: load(filename)")
addOutput("")
addOutput("Controls:")
addOutput("• Enter: Execute expression")
addOutput("• Ctrl+C: Exit REPL")
addOutput("• Up/Down: Command history")
addOutput("")
addOutput("Ready! Type your Lua expressions below.")
addOutput("=====================================")

-- Override print to capture output
_G._original_print = _G.print
_G.print = function(...)
    local args = {...}
    local parts = {}
    for i, v in ipairs(args) do
        table.insert(parts, tostring(v))
    end
    addOutput(table.concat(parts, "\t"))
end

-- Execute code
local function executeCode(code)
    if code == "" then return end
    
    -- Add to history
    table.insert(history, code)
    historyIndex = #history + 1
    
    -- Show command
    addOutput("hype> " .. code)
    
    -- Try as expression first
    local func, err = load("return " .. code, "repl", "t", _G)
    if not func then
        func, err = load(code, "repl", "t", _G)
    end
    
    if func then
        local ok, result = pcall(func)
        if ok then
            if result ~= nil then
                addOutput(tostring(result))
            end
        else
            addOutput("Error: " .. tostring(result))
        end
    else
        addOutput("Syntax Error: " .. tostring(err))
    end
end

-- Input handler
inputField:SetDoneFunc(function(key)
    if key == 13 then -- Enter
        local code = inputField:GetText()
        executeCode(code)
        inputField:SetText("")
    end
end)

-- History navigation
inputField:SetInputCapture(function(event)
    local key = event:Key()
    
    if key == 38 then -- Up arrow
        if historyIndex > 1 then
            historyIndex = historyIndex - 1
            inputField:SetText(history[historyIndex] or "")
        end
        return nil
    elseif key == 40 then -- Down arrow  
        if historyIndex <= #history then
            historyIndex = historyIndex + 1
            inputField:SetText(history[historyIndex] or "")
        end
        return nil
    end
    
    return event
end)

-- Global key handler
app:SetInputCapture(function(event)
    if event:Key() == 3 then -- Ctrl+C
        app:Stop()
        return nil
    end
    return event
end)

-- Assemble layout
flex:AddItem(outputView, 0, 1, false)  -- Flexible output
flex:AddItem(inputField, 3, 0, true)   -- Fixed input

-- Run
app:SetRoot(flex, true)
app:SetFocus(inputField)

print("Starting TUI REPL...")
app:Run()
print("\nTUI REPL ended.")

-- Restore print
_G.print = _G._original_print