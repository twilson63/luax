-- Debug version of REPL to see what's happening
local outputText = ""
local history = {}
local historyIndex = 0

-- Create TUI components
local app = tui.newApp()
local flex = tui.newFlex()
local outputView = tui.newTextView("")
local inputField = tui.newInputField()

-- Configure components
flex:SetDirection(0)
flex:SetBorder(true)
outputView:SetBorder(true)
inputField:SetBorder(true)
inputField:SetLabel("test> ")

-- Helper function
local function appendOutput(text)
    outputText = outputText .. text .. "\n"
    outputView:SetText(outputText)
end

appendOutput("Debug REPL - Type and press Enter")

-- Input handler
inputField:SetDoneFunc(function(key)
    if key == 13 then
        local text = inputField:GetText()
        appendOutput("You typed: " .. text)
        inputField:SetText("")
    end
end)

-- Key capture with debug
app:SetInputCapture(function(event)
    local key = event:Key()
    
    -- Show what key was pressed
    appendOutput("Key pressed: " .. tostring(key))
    
    if key == 3 then -- Ctrl+C
        app:Stop()
        return nil
    end
    
    -- Pass through everything else
    return event
end)

-- Layout
flex:AddItem(outputView, 0, 1, false)
flex:AddItem(inputField, 3, 0, true)

app:SetRoot(flex, true)
app:SetFocus(inputField)
app:Run()

print("Debug session ended")