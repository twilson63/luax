-- Minimal TUI test
print("Starting minimal TUI test...")

local app = tui.newApp()
local flex = tui.newFlex()
local text = tui.newTextView("Hello, TUI!")

flex:AddItem(text, 0, 1, true)
app:SetRoot(flex, true)

print("About to call app:Run()...")
app:Run()
print("Done!")