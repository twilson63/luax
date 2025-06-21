# LuaX - Lua Script to Executable Packager

LuaX is a tool that packages Lua scripts into standalone executables with TUI (Terminal User Interface) support. It combines a Lua runtime with your scripts to create cross-platform applications.

## Features

- Package Lua scripts into standalone executables
- Cross-platform support (Linux, macOS, Windows)
- Built-in TUI library for creating terminal applications
- No external dependencies required in the final executable

## Installation

```bash
go build -o luax .
```

## Usage

### Basic Usage

```bash
# Build a Lua script into an executable
./luax build script.lua

# Specify output name
./luax build script.lua -o myapp

# Build for different platforms
./luax build script.lua -t linux
./luax build script.lua -t windows
./luax build script.lua -t darwin
```

### TUI API

LuaX provides a `tui` module with the following functions:

- `tui.newApp()` - Create a new TUI application
- `tui.newTextView(text)` - Create a text display widget
- `tui.newInputField()` - Create a text input widget
- `tui.newButton(label)` - Create a button widget
- `tui.newFlex()` - Create a flexible layout container

## Examples

### Hello World

```lua
local app = tui.newApp()
local textView = tui.newTextView("Hello, World!")
app:SetRoot(textView, true)
app:Run()
```

### Interactive Application

```lua
local app = tui.newApp()
local flex = tui.newFlex()
local textView = tui.newTextView("Enter your name:")
local inputField = tui.newInputField()

flex:SetDirection(0) -- Vertical
flex:AddItem(textView, 0, 1, false)
flex:AddItem(inputField, 0, 1, true)

inputField:SetDoneFunc(function(key)
    if key == 13 then -- Enter
        local name = inputField:GetText()
        textView:SetText("Hello, " .. name .. "!")
    end
end)

app:SetRoot(flex, true)
app:Run()
```

## Building and Testing

```bash
# Build the luax tool
go build -o luax .

# Test with example scripts
./luax build examples/hello.lua -o hello
./hello

./luax build examples/interactive.lua -o interactive
./interactive
```