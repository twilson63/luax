-- Simplified TUI REPL
print("Starting simple TUI REPL...")

local app = tui.newApp()
local flex = tui.newFlex()
local output = tui.newTextView("REPL Output\n")
local input = tui.newInputField()

-- Setup
flex:SetDirection(0)
flex:AddItem(output, 0, 1, false)
flex:AddItem(input, 3, 0, true)

input:SetLabel("hype> ")

-- Simple input handler
input:SetDoneFunc(function(key)
    if key == 13 then -- Enter
        local text = input:GetText()
        local current = output:GetText(false)
        output:SetText(current .. "hype> " .. text .. "\n")
        
        -- Try to execute
        local f, err = load("return " .. text)
        if not f then
            f, err = load(text)
        end
        
        if f then
            local ok, result = pcall(f)
            if ok and result ~= nil then
                output:SetText(output:GetText(false) .. tostring(result) .. "\n")
            elseif not ok then
                output:SetText(output:GetText(false) .. "Error: " .. tostring(result) .. "\n")
            end
        else
            output:SetText(output:GetText(false) .. "Syntax error: " .. tostring(err) .. "\n")
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

print("Running TUI...")
app:Run()
print("Done!")