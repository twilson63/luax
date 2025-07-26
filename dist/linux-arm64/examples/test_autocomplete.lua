-- Test autocomplete for history
local app = tui.newApp()
local flex = tui.newFlex()
local outputView = tui.newTextView("Test autocomplete - type 'h' to see history\n")
local inputField = tui.newInputField()

local history = {"hello world", "help me", "history test", "hype is cool"}

-- Configure
flex:SetDirection(0)
outputView:SetBorder(true)
inputField:SetBorder(true)
inputField:SetLabel("test> ")

-- Set up autocomplete
inputField:SetAutocompleteFunc(function(currentText)
    if currentText == "" then
        return {}
    end
    
    local suggestions = {}
    for _, cmd in ipairs(history) do
        if cmd:sub(1, #currentText) == currentText then
            table.insert(suggestions, cmd)
        end
    end
    return suggestions
end)

-- Done handler
inputField:SetDoneFunc(function(key)
    if key == 13 then
        local text = inputField:GetText()
        outputView:SetText(outputView:GetText() .. "\nYou entered: " .. text)
        inputField:SetText("")
    end
end)

-- Layout
flex:AddItem(outputView, 0, 1, false)
flex:AddItem(inputField, 3, 0, true)

app:SetRoot(flex, true)
app:SetFocus(inputField)
app:Run()