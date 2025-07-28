-- Simple Bubble Tea Example for Hype
-- Run with: ./hype run example-simple.lua --plugins bubbletea=./plugins/bubbletea-plugin

local tea = require('bubbletea')

-- Model: Application state
local function initialModel()
    return {
        counter = 0,
        name = "",
        nameInput = tea.textinput.new()
            :setPlaceholder("Enter your name...")
            :focus()
    }
end

-- Update: Handle messages
local function update(model, msg)
    if msg.type == tea.MSG_KEY then
        if msg.key == tea.KEY_CTRL_C or msg.key == "q" then
            return model, tea.quit()
        elseif msg.key == "+" then
            model.counter = model.counter + 1
        elseif msg.key == "-" then
            model.counter = model.counter - 1
        elseif msg.key == tea.KEY_ENTER then
            model.name = model.nameInput:getValue()
            model.nameInput:setValue("")
        else
            -- Update text input
            model.nameInput:update(msg)
        end
    end
    return model, nil
end

-- View: Render the UI
local function view(model)
    local s = tea.style.new()
    
    -- Title
    local title = s:copy()
        :foreground("cyan")
        :setBold(true)
        :render("🫖 Bubble Tea Demo for Hype")
    
    -- Counter
    local counterText = string.format("Counter: %d", model.counter)
    
    -- Name input
    local namePrompt = "What's your name? " .. model.nameInput:view()
    
    -- Greeting
    local greeting = ""
    if model.name ~= "" then
        greeting = s:copy()
            :foreground("green")
            :render("Hello, " .. model.name .. "! 👋")
    end
    
    -- Help
    local help = s:copy()
        :foreground("yellow")
        :render("\nPress +/- to change counter, Enter to submit name, q to quit")
    
    -- Compose view
    return table.concat({
        title,
        "",
        counterText,
        "",
        namePrompt,
        greeting,
        help
    }, "\n")
end

-- Main program
local function main()
    print("Starting Bubble Tea Demo...")
    print("This is a simplified demo. Full input handling requires terminal raw mode.")
    print("")
    
    -- Create and display initial view
    local model = initialModel()
    print(view(model))
    
    -- Simple interaction loop
    print("\nDemo mode: Enter '+' or '-' to change counter, or 'q' to quit:")
    
    while true do
        local input = io.read()
        if not input then break end
        
        local msg = {type = tea.MSG_KEY, key = input}
        model = update(model, msg)
        
        if input == "q" then
            print("Goodbye! 👋")
            break
        end
        
        -- Clear screen and redraw
        io.write("\027[2J\027[H")
        print(view(model))
        print("\nEnter '+', '-', or 'q':")
    end
end

-- Run the demo
main()