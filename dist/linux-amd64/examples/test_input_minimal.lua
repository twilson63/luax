-- Minimal test for input field
local app = tui.newApp()
local flex = tui.newFlex()
local inputField = tui.newInputField()

inputField:SetLabel("Test> ")
inputField:SetBorder(true)

-- Simple done handler
inputField:SetDoneFunc(function(key)
    if key == 13 then -- Enter
        local text = inputField:GetText()
        print("Got: " .. text)
        app:Stop()
    end
end)

flex:AddItem(inputField, 3, 0, true)
app:SetRoot(flex, true)
app:SetFocus(inputField)

print("Type something and press Enter...")
app:Run()
print("Done")