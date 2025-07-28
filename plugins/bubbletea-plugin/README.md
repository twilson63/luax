# Bubble Tea Plugin for Hype

A modern TUI framework for Hype based on The Elm Architecture, inspired by the Go Bubble Tea library. Build beautiful, interactive terminal applications with a clean and predictable architecture.

## Features

- 🎯 **Elm Architecture**: Clean Model-View-Update pattern
- 🧩 **Rich Components**: Text inputs, lists, spinners, progress bars, and more
- 🎨 **Styling System**: Lip Gloss-inspired fluent styling API
- ⌨️ **Keyboard First**: Full keyboard navigation with customizable bindings
- 🖱️ **Mouse Support**: Optional mouse interaction for modern terminals
- 🚀 **Zero Dependencies**: Runs anywhere Hype runs

## Installation

Place the plugin in your Hype plugins directory or reference it directly:

```bash
# Run with the plugin
./hype run myapp.lua --plugins bubbletea=./plugins/bubbletea-plugin

# Build with embedded plugin
./hype build myapp.lua --plugins bubbletea=./plugins/bubbletea-plugin -o myapp
```

## Quick Start

```lua
local tea = require('bubbletea')

-- Define your model (application state)
local function initialModel()
    return {
        counter = 0,
        quitting = false
    }
end

-- Handle updates (messages modify the model)
local function update(model, msg)
    if msg.type == tea.MSG_KEY then
        if msg.key == tea.KEY_CTRL_C or msg.key == "q" then
            model.quitting = true
            return model, tea.quit()
        elseif msg.key == "+" or msg.key == tea.KEY_UP then
            model.counter = model.counter + 1
        elseif msg.key == "-" or msg.key == tea.KEY_DOWN then
            model.counter = model.counter - 1
        end
    end
    return model, nil
end

-- Render the view
local function view(model)
    if model.quitting then
        return "Goodbye! 👋\n"
    end
    
    return string.format([[
Counter: %d

Press +/↑ to increment
Press -/↓ to decrement
Press q or Ctrl+C to quit
]], model.counter)
end

-- Run the program
local program = tea.newProgram(initialModel(), update, view)
    :withAltScreen()  -- Use alternate screen buffer
program:run()
```

## Components

### Text Input

```lua
local input = tea.textinput.new()
    :setPlaceholder("Enter your name...")
    :setWidth(30)
    :focus()

-- In your update function
input:update(msg)

-- In your view function
local rendered = input:view()
```

### List

```lua
local list = tea.list.new({"Apple", "Banana", "Cherry"})
    :setHeight(10)
    :setItemRenderer(function(item, index, selected)
        if selected then
            return "> " .. item
        end
        return "  " .. item
    end)
```

### Spinner

```lua
local spinner = tea.spinner.new("dots")
    :setText("Loading...")

-- Update with tick messages
spinner:update(msg)
```

### Progress Bar

```lua
local progress = tea.progress.new(100)
    :setWidth(40)
    :setCurrent(33)

-- Or use preset styles
local download = tea.progress.download(bytesReceived, totalBytes)
```

### Viewport

```lua
local viewport = tea.viewport.new(80, 24)
    :setContent(longText)

-- Handles scrolling automatically
viewport:update(msg)
```

### Textarea

```lua
local editor = tea.textarea.new()
    :setSize(80, 20)
    :setValue("Initial content")
    :focus()
```

## Styling

The style module provides a fluent API for terminal styling:

```lua
local s = tea.style.new()

-- Basic styling
local red = s:copy():foreground("red"):render("Error!")
local bold = s:copy():setBold(true):render("Important")

-- Complex styling
local fancy = s:copy()
    :foreground("cyan")
    :background("blue")
    :setBold(true)
    :setItalic(true)
    :border("rounded")
    :padding(1, 2)  -- vertical, horizontal
    :margin(1)
    :render("Fancy Box!")

-- Preset styles
local error = tea.style.presets.error():render("Something went wrong")
local success = tea.style.presets.success():render("All good!")
```

## Architecture Pattern

The Elm Architecture provides a clean separation of concerns:

1. **Model**: Your application state (data)
2. **Update**: Function that handles messages and updates the model
3. **View**: Function that renders the UI based on the model

```lua
-- Model: What data do we need?
local function initialModel()
    return {
        todos = {},
        input = tea.textinput.new(),
        selected = 1
    }
end

-- Update: How do we handle events?
local function update(model, msg)
    if msg.type == tea.MSG_KEY then
        -- Handle keyboard input
    end
    return model, nil  -- Return updated model and optional command
end

-- View: How do we display it?
local function view(model)
    -- Return a string representation of your UI
    return "TODO List\n" .. renderTodos(model.todos)
end
```

## Commands

Commands are used to trigger side effects:

```lua
-- Quit the program
return model, tea.quit()

-- Run something after a delay
return model, tea.tick(500, function()
    return {type = "timer_expired"}
end)

-- Run multiple commands
return model, tea.batch(
    tea.tick(100, timerFunc),
    tea.cmd(fetchDataFunc)
)
```

## Advanced Examples

### Custom Components

```lua
-- Create a custom button component
function Button(label, onClick)
    local self = {
        label = label,
        onClick = onClick,
        focused = false,
        style = tea.style.new()
    }
    
    function self:focus()
        self.focused = true
        return self
    end
    
    function self:blur()
        self.focused = false
        return self
    end
    
    function self:update(msg)
        if self.focused and msg.type == tea.MSG_KEY then
            if msg.key == tea.KEY_ENTER or msg.key == " " then
                return self, self.onClick()
            end
        end
        return self, nil
    end
    
    function self:view()
        local s = self.style:copy()
        if self.focused then
            s:foreground("yellow"):setBold(true)
        end
        return s:border("rounded"):padding(0, 2):render(self.label)
    end
    
    return self
end
```

### Form Handling

```lua
local function createForm()
    return {
        name = tea.textinput.new():setPlaceholder("Name"),
        email = tea.textinput.new():setPlaceholder("Email"),
        message = tea.textarea.new():setSize(40, 5),
        currentField = 1,
        fields = {"name", "email", "message"}
    }
end

local function updateForm(form, msg)
    if msg.type == tea.MSG_KEY then
        if msg.key == tea.KEY_TAB then
            -- Move to next field
            form[form.fields[form.currentField]]:blur()
            form.currentField = (form.currentField % #form.fields) + 1
            form[form.fields[form.currentField]]:focus()
        else
            -- Update current field
            local field = form.fields[form.currentField]
            form[field]:update(msg)
        end
    end
    return form
end
```

## Best Practices

1. **Keep Models Simple**: Store only the data you need
2. **Pure Updates**: Update functions should not have side effects
3. **Commands for I/O**: Use commands for async operations
4. **Component Composition**: Build complex UIs from simple components
5. **Styling Consistency**: Create a style guide for your app

## Comparison with tview

While Hype's built-in `tui` module (based on tview) uses an imperative, callback-based approach, Bubble Tea uses a functional, message-based architecture:

**tview (imperative)**:
```lua
local app = tui.newApp()
local input = tui.newInputField()
input:SetDoneFunc(function(key)
    -- Handle input
end)
app:SetRoot(input, true)
app:Run()
```

**Bubble Tea (functional)**:
```lua
local function update(model, msg)
    -- All state changes in one place
    return model, nil
end

local function view(model)
    -- Pure rendering function
    return model.input:view()
end
```

## Troubleshooting

### Performance

- Use `withAltScreen()` for full-screen apps
- Batch updates when possible
- Avoid recreating components in update functions

### Debugging

```lua
-- Add debug view
local function debugView(model)
    return string.format("Debug: %s", json.encode(model))
end

-- Log messages
local function update(model, msg)
    print("Message:", json.encode(msg))
    -- ... rest of update
end
```

## License

MIT License - Same as Hype

## Credits

Inspired by:
- [Bubble Tea](https://github.com/charmbracelet/bubbletea) for Go
- [The Elm Architecture](https://guide.elm-lang.org/architecture/)
- [Lip Gloss](https://github.com/charmbracelet/lipgloss) for styling