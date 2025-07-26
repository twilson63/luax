-- Fixed TUI REPL
print("Starting TUI REPL...")

local app = tui.newApp()
local flex = tui.newFlex()
local output = tui.newTextView("")
local input = tui.newInputField()

-- Keep output in a string variable
local outputText = "🚀 Hype TUI REPL v1.8.0\n"
outputText = outputText .. "========================\n"
outputText = outputText .. "Available modules: tui, http, kv, crypto, ws\n"
outputText = outputText .. "Enter expressions and press Enter. Ctrl+C to exit.\n"
outputText = outputText .. "================================\n\n"

-- Setup
flex:SetDirection(0)
flex:SetBorder(true)
flex:SetTitle("🚀 Hype Lua REPL")

output:SetBorder(true)
output:SetTitle("📤 Output")
output:SetText(outputText)
output:SetWrap(true)
output:SetWordWrap(true)

input:SetBorder(true)
input:SetTitle("📥 Input - Press Enter to Execute | Ctrl+C to Exit")
input:SetLabel("hype> ")

flex:AddItem(output, 0, 1, false)
flex:AddItem(input, 3, 0, true)

-- Helper to append output
local function appendOutput(text)
    outputText = outputText .. text .. "\n"
    output:SetText(outputText)
end

-- Simple input handler
input:SetDoneFunc(function(key)
    if key == 13 then -- Enter
        local code = input:GetText()
        if code ~= "" then
            appendOutput("hype> " .. code)
            
            -- Try to execute
            local f, err = load("return " .. code)
            if not f then
                f, err = load(code)
            end
            
            if f then
                local ok, result = pcall(f)
                if ok then
                    if result ~= nil then
                        appendOutput(tostring(result))
                    end
                else
                    appendOutput("Error: " .. tostring(result))
                end
            else
                appendOutput("Syntax error: " .. tostring(err))
            end
        end
        
        input:SetText("")
    end
end)

-- Exit on Ctrl+C
app:SetInputCapture(function(event)
    if event:Key() == 3 then
        app:Stop()
        return nil
    end
    return event
end)

app:SetRoot(flex, true)
app:SetFocus(input)

print("TUI loaded, starting main loop...")
app:Run()
print("TUI REPL ended.")