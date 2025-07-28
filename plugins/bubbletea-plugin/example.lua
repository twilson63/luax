-- Example: Bubble Tea Plugin for Hype
-- A complete example showing the Elm Architecture in action

-- This example would be run with:
-- ./hype run example.lua --plugins bubbletea=./plugins/bubbletea-plugin

local tea = require('bubbletea')

-- Model: Application state
local function initialModel()
    return {
        -- App state
        currentView = "menu",  -- menu, input, list, loading
        
        -- Menu state
        menuCursor = 1,
        menuItems = {
            "Text Input Demo",
            "List Selection Demo", 
            "Loading Spinner Demo",
            "Progress Bar Demo",
            "Viewport Demo",
            "Style Gallery",
            "Quit"
        },
        
        -- Text input state
        nameInput = tea.textinput.new()
            :setPlaceholder("Enter your name...")
            :setWidth(30)
            :focus(),
        submittedName = "",
        
        -- List state
        listComponent = tea.list.new({
            "Apple", "Banana", "Cherry", "Date", "Elderberry",
            "Fig", "Grape", "Honeydew", "Kiwi", "Lemon",
            "Mango", "Nectarine", "Orange", "Papaya", "Quince"
        }):setHeight(10),
        selectedFruit = "",
        
        -- Loading state
        spinner = tea.spinner.new("dots"):setText("Loading data..."),
        loadingProgress = 0,
        
        -- Progress state
        downloadProgress = tea.progress.new(100):setWidth(40),
        
        -- Viewport state
        viewportContent = nil,
        viewport = nil,
        
        -- Window dimensions
        width = 80,
        height = 24
    }
end

-- Initialize function
local function init()
    -- Load content for viewport
    local content = [[
# Bubble Tea for Hype

Welcome to the Bubble Tea plugin for Hype! This plugin brings the power of
The Elm Architecture to Lua, allowing you to build interactive terminal
user interfaces with ease.

## Features

- **Elm Architecture**: Clean separation of Model, View, and Update
- **Rich Components**: Text input, lists, spinners, progress bars, and more
- **Styling System**: Lip Gloss-inspired styling with colors and borders
- **Keyboard Navigation**: Full keyboard support with customizable bindings
- **Mouse Support**: Optional mouse interaction for modern terminals

## The Elm Architecture

The Elm Architecture is a pattern for building interactive programs:

1. **Model**: Your application state
2. **View**: A function that renders the UI based on the model
3. **Update**: A function that handles messages and updates the model

This pattern makes your code predictable, testable, and easy to understand.

## Components

### Text Input
Full-featured text input with placeholder text, validation, and echo modes.

### List
Scrollable lists with filtering, custom rendering, and keyboard navigation.

### Spinner
Multiple animated spinner styles for loading states.

### Progress Bar
Customizable progress indicators with various styles.

### Viewport
Scrollable viewport for displaying content larger than the terminal.

### Textarea
Multi-line text editor with syntax highlighting support.

## Styling

The style module provides a fluent API for terminal styling:

```lua
local s = tea.style.new()
    :foreground("blue")
    :background("white")  
    :setBold(true)
    :border("rounded")
    :padding(1)
    
print(s:render("Styled text!"))
```

## Getting Started

Check out the examples to see how to build your own TUI applications
with Bubble Tea and Hype!
]]
    
    return tea.windowSize(80, 24)
end

-- Update function: Handle messages and update model
local function update(model, msg)
    -- Handle global keys
    if msg.type == tea.MSG_KEY then
        if msg.key == tea.KEY_CTRL_C then
            return model, tea.quit()
        end
        
        -- Navigation between views
        if msg.key == tea.KEY_ESC and model.currentView ~= "menu" then
            model.currentView = "menu"
            return model, nil
        end
    end
    
    -- Handle window resize
    if msg.type == tea.MSG_WINDOW_SIZE then
        model.width = msg.width
        model.height = msg.height
        
        -- Update component dimensions
        model.listComponent:setHeight(math.min(10, msg.height - 10))
        model.downloadProgress:setWidth(math.min(40, msg.width - 20))
        
        if model.viewport then
            model.viewport:resize(msg.width - 4, msg.height - 6)
        end
        
        return model, nil
    end
    
    -- Handle view-specific updates
    if model.currentView == "menu" then
        if msg.type == tea.MSG_KEY then
            if msg.key == "up" or msg.key == "k" then
                model.menuCursor = math.max(1, model.menuCursor - 1)
            elseif msg.key == "down" or msg.key == "j" then
                model.menuCursor = math.min(#model.menuItems, model.menuCursor + 1)
            elseif msg.key == tea.KEY_ENTER then
                local selected = model.menuItems[model.menuCursor]
                
                if selected == "Text Input Demo" then
                    model.currentView = "input"
                    model.nameInput:focus()
                elseif selected == "List Selection Demo" then
                    model.currentView = "list"
                elseif selected == "Loading Spinner Demo" then
                    model.currentView = "loading"
                    model.loadingProgress = 0
                    return model, tea.tick(100, function()
                        return {type = "loading_tick"}
                    end)
                elseif selected == "Progress Bar Demo" then
                    model.currentView = "progress"
                    model.downloadProgress:setCurrent(0)
                    return model, tea.tick(50, function()
                        return {type = "progress_tick"}
                    end)
                elseif selected == "Viewport Demo" then
                    model.currentView = "viewport"
                    if not model.viewport then
                        model.viewport = tea.viewport.new(model.width - 4, model.height - 6)
                        model.viewport:setContent(model.viewportContent or content)
                    end
                elseif selected == "Style Gallery" then
                    model.currentView = "styles"
                elseif selected == "Quit" then
                    return model, tea.quit()
                end
            end
        end
        
    elseif model.currentView == "input" then
        if msg.type == tea.MSG_KEY then
            if msg.key == tea.KEY_ENTER then
                model.submittedName = model.nameInput:getValue()
                model.nameInput:setValue("")
            else
                model.nameInput:update(msg)
            end
        end
        
    elseif model.currentView == "list" then
        local newList, cmd = model.listComponent:update(msg)
        model.listComponent = newList
        
        if cmd and cmd.type == "select" then
            model.selectedFruit = cmd.item or ""
        end
        
    elseif model.currentView == "loading" then
        model.spinner:update(msg)
        
        if msg.type == "loading_tick" then
            model.loadingProgress = model.loadingProgress + 10
            if model.loadingProgress < 100 then
                return model, tea.tick(100, function()
                    return {type = "loading_tick"}
                end)
            else
                model.currentView = "menu"
            end
        end
        
    elseif model.currentView == "progress" then
        if msg.type == "progress_tick" then
            local current = model.downloadProgress.current
            if current < 100 then
                model.downloadProgress:increment(2)
                return model, tea.tick(50, function()
                    return {type = "progress_tick"}
                end)
            else
                model.currentView = "menu"
            end
        end
        
    elseif model.currentView == "viewport" then
        if model.viewport then
            model.viewport:update(msg)
        end
    end
    
    return model, nil
end

-- View function: Render the UI
local function view(model)
    local s = tea.style.new()
    
    if model.currentView == "menu" then
        local title = s:copy()
            :foreground("cyan")
            :setBold(true)
            :setAlign("center")
            :setWidth(model.width)
            :render("🫖 Bubble Tea Demo for Hype")
        
        local menu = {title, ""}
        
        for i, item in ipairs(model.menuItems) do
            local itemStyle = s:copy()
            if i == model.menuCursor then
                itemStyle:foreground("yellow"):setBold(true)
                table.insert(menu, "  ▸ " .. item)
            else
                table.insert(menu, "    " .. item)
            end
        end
        
        table.insert(menu, "")
        table.insert(menu, s:copy():foreground("brightBlack")
            :render("Use ↑/↓ to navigate, Enter to select, Ctrl+C to quit"))
        
        return table.concat(menu, "\n")
        
    elseif model.currentView == "input" then
        local title = s:copy():foreground("green"):setBold(true)
            :render("Text Input Demo")
        
        local prompt = s:copy():foreground("cyan")
            :render("What's your name?")
        
        local input = model.nameInput:view()
        
        local result = ""
        if model.submittedName ~= "" then
            result = s:copy():foreground("yellow")
                :render("\nHello, " .. model.submittedName .. "! 👋")
        end
        
        local help = s:copy():foreground("brightBlack")
            :render("\nPress Enter to submit, Esc to go back")
        
        return table.concat({title, "", prompt, input, result, help}, "\n")
        
    elseif model.currentView == "list" then
        local title = s:copy():foreground("magenta"):setBold(true)
            :render("List Selection Demo")
        
        local subtitle = "Select your favorite fruit:"
        
        local list = model.listComponent:view()
        
        local selected = ""
        if model.selectedFruit ~= "" then
            selected = s:copy():foreground("green")
                :render("\nYou selected: " .. model.selectedFruit .. " 🍎")
        end
        
        return table.concat({title, subtitle, "", list, selected}, "\n")
        
    elseif model.currentView == "loading" then
        local title = s:copy():foreground("blue"):setBold(true)
            :render("Loading Demo")
        
        local spinner = model.spinner:view()
        
        local progress = string.format("Progress: %d%%", model.loadingProgress)
        
        local help = s:copy():foreground("brightBlack")
            :render("\nPress Esc to cancel")
        
        return table.concat({title, "", spinner, progress, help}, "\n")
        
    elseif model.currentView == "progress" then
        local title = s:copy():foreground("green"):setBold(true)
            :render("Progress Bar Demo")
        
        local subtitle = "Downloading file..."
        
        local progress = model.downloadProgress:view()
        
        local status = ""
        if model.downloadProgress:isComplete() then
            status = s:copy():foreground("green"):setBold(true)
                :render("\n✓ Download complete!")
        end
        
        local help = s:copy():foreground("brightBlack")
            :render("\nPress Esc to go back")
        
        return table.concat({title, "", subtitle, progress, status, "", help}, "\n")
        
    elseif model.currentView == "viewport" then
        local title = s:copy():foreground("yellow"):setBold(true)
            :border("rounded")
            :padding(0, 1)
            :render("Viewport Demo")
        
        local content = ""
        if model.viewport then
            content = model.viewport:view()
        end
        
        local help = s:copy():foreground("brightBlack")
            :render("Use ↑/↓ or j/k to scroll, Esc to go back")
        
        return table.concat({title, "", content, "", help}, "\n")
        
    elseif model.currentView == "styles" then
        local title = s:copy():foreground("cyan"):setBold(true)
            :setAlign("center")
            :setWidth(model.width)
            :render("Style Gallery")
        
        local examples = {
            "",
            s:copy():foreground("red"):render("Red text"),
            s:copy():foreground("green"):render("Green text"),
            s:copy():foreground("yellow"):render("Yellow text"),
            s:copy():foreground("blue"):render("Blue text"),
            s:copy():foreground("magenta"):render("Magenta text"),
            s:copy():foreground("cyan"):render("Cyan text"),
            "",
            s:copy():setBold(true):render("Bold text"),
            s:copy():setItalic(true):render("Italic text"),
            s:copy():setUnderline(true):render("Underlined text"),
            "",
            s:copy():background("blue"):foreground("white"):padding(1):render("Padded with background"),
            "",
            s:copy():border("normal"):padding(1):render("Normal border"),
            s:copy():border("rounded"):padding(1):render("Rounded border"),
            s:copy():border("double"):padding(1):render("Double border"),
            "",
            s:copy():foreground("brightBlack"):render("Press Esc to go back")
        }
        
        return title .. table.concat(examples, "\n")
    end
    
    return "Unknown view"
end

-- Main program
local function main()
    local program = tea.newProgram(initialModel(), update, view, init)
        :withAltScreen()
        :withMouseCellMotion()
    
    program:run()
end

-- Run the demo
main()