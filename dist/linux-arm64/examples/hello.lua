-- Simple Hello World TUI application
local app = tui.newApp()
local textView = tui.newTextView("Hello, World from Lua!\n\nThis is a TUI application created with Hype.\nPress Ctrl+C to exit.")

app:SetRoot(textView, true)
app:Run()