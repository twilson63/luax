# Hype REPL Examples

Hype provides two REPL (Read-Eval-Print Loop) interfaces for interactive Lua development:

## 1. Simple REPL

Run with: `./hype repl`

Features:
- Traditional command-line interface
- Multiline support (automatic detection or use `\` at line end)
- Command history
- Session state retention
- `load(filename)` function to load Lua scripts
- All Hype modules available (tui, http, kv, crypto, ws)

Example session:
```lua
hype> 2 + 2
4
hype> x = 10
hype> y = 20
hype> x + y
30
hype> function factorial(n)
....>     if n <= 1 then return 1 end
....>     return n * factorial(n-1)
....> end
hype> factorial(5)
120
```

## 2. TUI REPL

Run with: `./hype run examples/tui_repl_final.lua`

Features:
- Two-panel terminal UI interface
- Top panel: Output display with scrolling
- Bottom panel: Input field
- Command history (Up/Down arrows)
- Visual feedback
- All output captured including print() statements

Controls:
- Enter: Execute expression
- Up/Down: Navigate command history
- Escape: Clear current input
- Ctrl+C: Exit REPL

## Loading Files

Both REPLs support loading external Lua files:

```lua
-- In simple REPL
hype> load("examples/repl-test.lua")

-- The loaded functions and variables are available
hype> greet("World")
Hello, World!
```

## Tips

1. Use the simple REPL for quick testing and scripting
2. Use the TUI REPL for longer sessions with lots of output
3. Both REPLs maintain state between commands
4. All Hype modules are pre-loaded and ready to use
5. Use multiline mode for defining functions and complex structures