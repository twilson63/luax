-- Bubble Tea Example - Integrated with Hype's TUI
-- Run with: ./hype run example-integrated.lua --plugins bubbletea=./plugins/bubbletea-plugin

local tea = require('bubbletea')

-- Model: Application state
local function initialModel()
    return {
        view = "menu",
        menuItems = tea.list.new({
            "Counter Demo",
            "Text Input Demo",
            "Progress Demo",
            "Style Gallery",
            "Quit"
        }):setHeight(5),
        
        -- Counter state
        counter = 0,
        
        -- Text input state
        nameInput = tea.textinput.new()
            :setPlaceholder("Enter your name...")
            :setWidth(30),
        submittedName = "",
        
        -- Progress state
        progress = tea.progress.new(100)
            :setWidth(40),
        progressRunning = false,
        
        -- Size
        width = 80,
        height = 24
    }
end

-- Update: Handle messages and update model
local function update(model, msg)
    -- Global key handling
    if msg.type == tea.MSG_KEY then
        if msg.key == tea.KEY_CTRL_C then
            return model, tea.quit()
        elseif msg.key == tea.KEY_ESC and model.view ~= "menu" then
            model.view = "menu"
            return model, nil
        end
    end
    
    -- View-specific updates
    if model.view == "menu" then
        local newList, cmd = model.menuItems:update(msg)
        model.menuItems = newList
        
        if cmd and cmd.type == "select" then
            local selected = cmd.item
            if selected == "Counter Demo" then
                model.view = "counter"
            elseif selected == "Text Input Demo" then
                model.view = "input"
                model.nameInput:focus()
            elseif selected == "Progress Demo" then
                model.view = "progress"
                model.progress:setCurrent(0)
                model.progressRunning = true
            elseif selected == "Style Gallery" then
                model.view = "styles"
            elseif selected == "Quit" then
                return model, tea.quit()
            end
        end
        
    elseif model.view == "counter" then
        if msg.type == tea.MSG_KEY then
            if msg.key == "+" or msg.key == tea.KEY_UP then
                model.counter = model.counter + 1
            elseif msg.key == "-" or msg.key == tea.KEY_DOWN then
                model.counter = model.counter - 1
            elseif msg.key == "r" then
                model.counter = 0
            end
        end
        
    elseif model.view == "input" then
        if msg.type == tea.MSG_KEY then
            if msg.key == tea.KEY_ENTER then
                model.submittedName = model.nameInput:getValue()
                model.nameInput:setValue("")
            else
                model.nameInput:update(msg)
            end
        end
        
    elseif model.view == "progress" then
        if model.progressRunning and model.progress.current < 100 then
            model.progress:increment(2)
            if model.progress:isComplete() then
                model.progressRunning = false
            end
        end
    end
    
    return model, nil
end

-- View: Render the UI
local function view(model)
    local s = tea.style.new()
    local output = {}
    
    -- Header
    table.insert(output, s:copy()
        :foreground("cyan")
        :setBold(true)
        :render("🫖 Bubble Tea + Hype Demo"))
    table.insert(output, "")
    
    if model.view == "menu" then
        table.insert(output, "Select a demo:")
        table.insert(output, "")
        table.insert(output, model.menuItems:view())
        table.insert(output, "")
        table.insert(output, s:copy():foreground("gray"):render("Use ↑/↓ to navigate, Enter to select, Ctrl+C to quit"))
        
    elseif model.view == "counter" then
        table.insert(output, s:copy():foreground("yellow"):render("Counter Demo"))
        table.insert(output, "")
        table.insert(output, string.format("Current value: [green:black] %d [-]", model.counter))
        table.insert(output, "")
        table.insert(output, "Controls:")
        table.insert(output, "  [yellow]+[-] or [yellow]↑[-] : Increment")
        table.insert(output, "  [yellow]-[-] or [yellow]↓[-] : Decrement")
        table.insert(output, "  [yellow]r[-]     : Reset")
        table.insert(output, "  [yellow]Esc[-]   : Back to menu")
        
    elseif model.view == "input" then
        table.insert(output, s:copy():foreground("green"):render("Text Input Demo"))
        table.insert(output, "")
        table.insert(output, "What's your name?")
        table.insert(output, model.nameInput:view())
        table.insert(output, "")
        
        if model.submittedName ~= "" then
            table.insert(output, s:copy()
                :foreground("yellow")
                :render("Hello, " .. model.submittedName .. "! 👋"))
        end
        
        table.insert(output, "")
        table.insert(output, s:copy():foreground("gray"):render("Press Enter to submit, Esc to go back"))
        
    elseif model.view == "progress" then
        table.insert(output, s:copy():foreground("magenta"):render("Progress Demo"))
        table.insert(output, "")
        
        if model.progressRunning then
            table.insert(output, "Loading...")
        else
            table.insert(output, s:copy():foreground("green"):render("✓ Complete!"))
        end
        
        table.insert(output, "")
        table.insert(output, model.progress:view())
        table.insert(output, "")
        table.insert(output, s:copy():foreground("gray"):render("Press Esc to go back"))
        
    elseif model.view == "styles" then
        table.insert(output, s:copy():foreground("yellow"):render("Style Gallery"))
        table.insert(output, "")
        
        -- Color examples
        table.insert(output, "Colors:")
        table.insert(output, "  " .. s:copy():foreground("red"):render("Red text"))
        table.insert(output, "  " .. s:copy():foreground("green"):render("Green text"))
        table.insert(output, "  " .. s:copy():foreground("yellow"):render("Yellow text"))
        table.insert(output, "  " .. s:copy():foreground("blue"):render("Blue text"))
        table.insert(output, "  " .. s:copy():foreground("magenta"):render("Magenta text"))
        table.insert(output, "  " .. s:copy():foreground("cyan"):render("Cyan text"))
        table.insert(output, "")
        
        -- Style examples
        table.insert(output, "Styles:")
        table.insert(output, "  " .. s:copy():setBold(true):render("Bold text"))
        table.insert(output, "  " .. s:copy():setItalic(true):render("Italic text"))
        table.insert(output, "  " .. s:copy():setUnderline(true):render("Underlined text"))
        table.insert(output, "  " .. s:copy():setStrikethrough(true):render("Strikethrough text"))
        table.insert(output, "")
        
        -- Combinations
        table.insert(output, "Combinations:")
        table.insert(output, "  " .. s:copy()
            :foreground("yellow")
            :background("blue")
            :setBold(true)
            :render("Bold yellow on blue"))
        table.insert(output, "")
        
        table.insert(output, s:copy():foreground("gray"):render("Press Esc to go back"))
    end
    
    return table.concat(output, "\n")
end

-- Timer for progress updates
local function tickCmd()
    return function()
        sleep(0.05)  -- 50ms
        return {type = tea.MSG_TICK}
    end
end

-- Modified update to handle ticks
local updateWithTick = function(model, msg)
    local newModel, cmd = update(model, msg)
    
    -- Auto-tick for progress
    if newModel.view == "progress" and newModel.progressRunning then
        return newModel, tickCmd()
    end
    
    return newModel, cmd
end

-- Main program
local program = tea.newProgram(initialModel(), updateWithTick, view)
program:run()