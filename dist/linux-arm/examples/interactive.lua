-- Interactive TUI application with input
local app = tui.newApp()
local flex = tui.newFlex()
local textView = tui.newTextView("Welcome to the Interactive Lua App!\n\nType something below and press Enter:")
local inputField = tui.newInputField()
local button = tui.newButton("Submit")

-- Set up the layout
flex:SetDirection(0) -- Vertical
flex:AddItem(textView, 0, 3, false)
flex:AddItem(inputField, 0, 1, true)
flex:AddItem(button, 0, 1, false)

-- Set up input handler
inputField:SetDoneFunc(function(key)
    if key == 13 then -- Enter key
        local text = inputField:GetText()
        textView:SetText("You entered: " .. text .. "\n\nType something else:")
        inputField:SetText("")
    end
end)

app:SetRoot(flex, true)
app:Run()