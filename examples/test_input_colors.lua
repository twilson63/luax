-- Test InputField color options
local app = tui.newApp()
local flex = tui.newFlex()

-- Create multiple input fields with different color settings
local inputs = {}
local labels = {
    "Default (no color set):",
    "SetFieldBackgroundColor(-1):",
    "SetFieldBackgroundColor(0):",
    "SetFieldBackgroundColor(tcell.ColorDefault):",
}

-- Test different color values
local colorValues = {nil, -1, 0, -16777216}  -- nil, -1, 0, tcell.ColorDefault

for i, label in ipairs(labels) do
    local inputField = tui.newInputField()
    inputField:SetLabel(label)
    inputField:SetBorder(true)
    
    if colorValues[i] ~= nil then
        inputField:SetFieldBackgroundColor(colorValues[i])
    end
    
    table.insert(inputs, inputField)
    flex:AddItem(inputField, 3, 0, false)
end

-- Add instructions
local textView = tui.newTextView("Test different background colors. Press Tab to switch fields, Ctrl+C to exit.")
textView:SetBorder(true)
flex:AddItem(textView, 3, 0, false)

flex:SetDirection(0) -- Vertical
app:SetRoot(flex, true)
app:SetFocus(inputs[1])

app:SetInputCapture(function(event)
    if event:Key() == 3 then -- Ctrl+C
        app:Stop()
    end
    return event
end)

app:Run()
print("Test complete")