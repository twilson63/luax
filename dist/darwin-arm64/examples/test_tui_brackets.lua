-- Test if TUI TextView handles brackets properly
local app = tui.newApp()
local textView = tui.newTextView("")

textView:SetBorder(true)
textView:SetTitle("Test Brackets")
textView:SetDynamicColors(true)

-- Test various bracket formats
local testText = [[
Test 1: [name] = value
Test 2: ["name"] = value
Test 3: ['name'] = value
Test 4: {
  ["age"] = 30,
  ["name"] = "John"
}
Test 5: Plain text with [brackets]
Test 6: Color tags [red]This should be red[white]
]]

textView:SetText(testText)

app:SetInputCapture(function(event)
    if event:Key() == 3 then -- Ctrl+C
        app:Stop()
    end
    return event
end)

app:SetRoot(textView, true)
app:Run()

print("Test complete")