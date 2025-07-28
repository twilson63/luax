-- Bubble Tea Standalone Demo
-- This version demonstrates the Bubble Tea concepts without full terminal integration
-- Run with: ./hype run example-standalone.lua --plugins bubbletea=./plugins/bubbletea-plugin

local tea = require('bubbletea')

-- Simple demo that shows Bubble Tea concepts
print([[
🫖 Bubble Tea Plugin for Hype - Demo

This plugin brings The Elm Architecture to Hype for building TUIs.
Since we're running as a plugin, we'll demonstrate the API concepts.
]])

-- 1. Model-View-Update Example
print("1. BASIC COUNTER EXAMPLE:")
print("-------------------------")

local counter = {value = 0}

local function updateCounter(model, msg)
    if msg == "increment" then
        model.value = model.value + 1
    elseif msg == "decrement" then
        model.value = model.value - 1
    end
    return model
end

local function viewCounter(model)
    return "Counter: " .. model.value
end

-- Simulate some updates
print(viewCounter(counter))
counter = updateCounter(counter, "increment")
print("After increment: " .. viewCounter(counter))
counter = updateCounter(counter, "increment")
print("After increment: " .. viewCounter(counter))
counter = updateCounter(counter, "decrement")
print("After decrement: " .. viewCounter(counter))

print("\n2. COMPONENT EXAMPLES:")
print("----------------------")

-- Text Input Demo
local input = tea.textinput.new()
    :setPlaceholder("Enter text...")
    :setWidth(20)

print("Text Input (empty): " .. input:view())
input:setValue("Hello, Hype!")
print("Text Input (filled): " .. input:view())

-- List Demo
print("\nList Component:")
local list = tea.list.new({"Apple", "Banana", "Cherry", "Date"})
print(list:view())

-- Progress Demo
print("\nProgress Bar:")
local progress = tea.progress.new(100)
    :setWidth(30)

for i = 0, 100, 20 do
    progress:setCurrent(i)
    print(progress:view())
end

-- Spinner Demo
print("\nSpinner Styles:")
local spinner = tea.spinner.new("dots")
spinner:setText("Loading...")
print("Dots spinner: " .. spinner:view())

print("\n3. STYLING EXAMPLES:")
print("--------------------")

local s = tea.style.new()

print(s:copy():foreground("red"):render("This would be red text"))
print(s:copy():foreground("green"):setBold(true):render("This would be bold green"))
print(s:copy():background("blue"):foreground("white"):render("White on blue background"))

print("\n4. ARCHITECTURE PATTERN:")
print("------------------------")

print([[
The Elm Architecture in Bubble Tea:

1. Model - Your application state (data)
2. Update - Function that handles messages and updates the model  
3. View - Function that renders the UI based on the model

Example structure:

    local function init()
        return { counter = 0, name = "" }
    end

    local function update(model, msg)
        if msg.type == tea.MSG_KEY then
            -- Handle keyboard input
        end
        return model, nil
    end

    local function view(model)
        return "Counter: " .. model.counter
    end

    local program = tea.newProgram(init(), update, view)
    program:run()
]])

print("\n5. AVAILABLE COMPONENTS:")
print("------------------------")

print([[
✓ tea.textinput - Single-line text input
✓ tea.textarea - Multi-line text editor  
✓ tea.list - Scrollable list with selection
✓ tea.spinner - Animated loading indicators
✓ tea.progress - Progress bars
✓ tea.viewport - Scrollable content viewer
✓ tea.style - Terminal styling (colors, bold, etc.)
]])

print("\nTo use Bubble Tea in your own Hype apps:")
print("1. Build with the plugin: ./hype build app.lua --plugins bubbletea=./plugins/bubbletea-plugin -o app")
print("2. Then use the full TUI integration in your built executable")

print("\nFor full interactive demos, build the example as a standalone executable:")
print("./hype build plugins/bubbletea-plugin/example.lua --plugins bubbletea=./plugins/bubbletea-plugin -o bubble-demo")