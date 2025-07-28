-- Todo App with Bubble Tea
-- A complete todo application demonstrating The Elm Architecture
-- Build: ./hype build todo-app.lua -o todo-app

local tui = require('tui')
local tea = require('bubbletea')

-- Model
local function initialModel()
    return {
        todos = {},
        input = tea.textinput.new()
            :setPlaceholder("What needs to be done?")
            :setWidth(50)
            :focus(),
        filter = "all", -- all, active, completed
        todoList = tea.list.new({}):setHeight(10)
    }
end

-- Messages
local MSG_ADD_TODO = "add_todo"
local MSG_TOGGLE_TODO = "toggle_todo"
local MSG_DELETE_TODO = "delete_todo"
local MSG_FILTER_CHANGE = "filter_change"

-- Update
local function update(model, msg)
    if msg.type == tea.MSG_KEY then
        if msg.key == tea.KEY_CTRL_C then
            return model, tea.quit()
        elseif msg.key == tea.KEY_TAB then
            -- Cycle through filters
            local filters = {"all", "active", "completed"}
            for i, f in ipairs(filters) do
                if f == model.filter then
                    model.filter = filters[(i % #filters) + 1]
                    break
                end
            end
            -- Update list view
            updateTodoList(model)
        elseif msg.key == tea.KEY_ENTER then
            -- Add new todo
            local text = model.input:getValue()
            if text ~= "" then
                table.insert(model.todos, {
                    id = os.time(),
                    text = text,
                    done = false,
                    created = os.date()
                })
                model.input:setValue("")
                updateTodoList(model)
            end
        elseif msg.key == " " then
            -- Toggle selected todo
            local _, cmd = model.todoList:update({type = tea.MSG_KEY, key = tea.KEY_ENTER})
            if cmd and cmd.type == "select" then
                local selectedIdx = cmd.index
                local visibleTodos = getVisibleTodos(model)
                if selectedIdx <= #visibleTodos then
                    local todo = visibleTodos[selectedIdx]
                    todo.done = not todo.done
                    updateTodoList(model)
                end
            end
        elseif msg.key == "d" then
            -- Delete selected todo
            local _, cmd = model.todoList:update({type = tea.MSG_KEY, key = tea.KEY_ENTER})
            if cmd and cmd.type == "select" then
                local selectedIdx = cmd.index
                local visibleTodos = getVisibleTodos(model)
                if selectedIdx <= #visibleTodos then
                    local todoToDelete = visibleTodos[selectedIdx]
                    -- Find and remove from main list
                    for i, todo in ipairs(model.todos) do
                        if todo.id == todoToDelete.id then
                            table.remove(model.todos, i)
                            break
                        end
                    end
                    updateTodoList(model)
                end
            end
        else
            -- Update input or list
            if model.input.focused then
                model.input:update(msg)
            else
                model.todoList:update(msg)
            end
        end
    end
    
    return model, nil
end

-- Helper to get visible todos based on filter
function getVisibleTodos(model)
    local visible = {}
    for _, todo in ipairs(model.todos) do
        if model.filter == "all" or
           (model.filter == "active" and not todo.done) or
           (model.filter == "completed" and todo.done) then
            table.insert(visible, todo)
        end
    end
    return visible
end

-- Helper to update todo list display
function updateTodoList(model)
    local items = {}
    local visibleTodos = getVisibleTodos(model)
    
    for _, todo in ipairs(visibleTodos) do
        local checkbox = todo.done and "[✓]" or "[ ]"
        local text = todo.text
        if todo.done then
            text = "[gray:s]" .. text .. "[-]"
        end
        table.insert(items, checkbox .. " " .. text)
    end
    
    model.todoList:setItems(items)
end

-- View
local function view(model)
    local s = tea.style.new()
    local output = {}
    
    -- Header
    table.insert(output, s:copy()
        :foreground("cyan")
        :setBold(true)
        :render("📝 Todo App with Bubble Tea"))
    table.insert(output, "")
    
    -- Input
    table.insert(output, model.input:view())
    table.insert(output, "")
    
    -- Filter tabs
    local filterBar = ""
    for _, f in ipairs({"all", "active", "completed"}) do
        local style = s:copy()
        if f == model.filter then
            style:foreground("yellow"):setUnderline(true)
        else
            style:foreground("gray")
        end
        filterBar = filterBar .. style:render(f) .. "   "
    end
    table.insert(output, filterBar)
    table.insert(output, "")
    
    -- Todo list
    if #model.todos == 0 then
        table.insert(output, s:copy():foreground("gray"):render("No todos yet. Add one above!"))
    else
        table.insert(output, model.todoList:view())
    end
    
    table.insert(output, "")
    
    -- Stats
    local total = #model.todos
    local completed = 0
    for _, todo in ipairs(model.todos) do
        if todo.done then completed = completed + 1 end
    end
    local active = total - completed
    
    table.insert(output, s:copy():foreground("gray"):render(
        string.format("%d active • %d completed • %d total", active, completed, total)
    ))
    
    -- Help
    table.insert(output, "")
    table.insert(output, s:copy():foreground("gray"):render(
        "Enter: add • Space: toggle • d: delete • Tab: filter • Ctrl+C: quit"
    ))
    
    return table.concat(output, "\n")
end

-- Initialize with window size
local function init()
    return tea.windowSize(80, 24)
end

-- Main
local function main()
    -- When built as executable, use Hype's TUI integration
    local app = tui.newApp()
    local textView = tui.newTextView()
    
    local model = initialModel()
    updateTodoList(model)
    
    textView:SetDynamicColors(true)
    textView:SetScrollable(false)
    
    local function render()
        textView:Clear()
        textView:SetText(view(model))
    end
    
    render()
    
    textView:SetInputCapture(function(event)
        local msg = nil
        
        -- Convert TUI event to Bubble Tea message
        if event.Key() == tui.KeyEsc then
            msg = {type = tea.MSG_KEY, key = tea.KEY_ESC}
        elseif event.Key() == tui.KeyEnter then
            msg = {type = tea.MSG_KEY, key = tea.KEY_ENTER}
        elseif event.Key() == tui.KeyTab then
            msg = {type = tea.MSG_KEY, key = tea.KEY_TAB}
        elseif event.Key() == tui.KeyBackspace or event.Key() == tui.KeyBackspace2 then
            msg = {type = tea.MSG_KEY, key = tea.KEY_BACKSPACE}
        elseif event.Key() == tui.KeyDelete then
            msg = {type = tea.MSG_KEY, key = tea.KEY_DELETE}
        elseif event.Key() == tui.KeyUp then
            msg = {type = tea.MSG_KEY, key = tea.KEY_UP}
        elseif event.Key() == tui.KeyDown then
            msg = {type = tea.MSG_KEY, key = tea.KEY_DOWN}
        elseif event.Key() == tui.KeyLeft then
            msg = {type = tea.MSG_KEY, key = tea.KEY_LEFT}
        elseif event.Key() == tui.KeyRight then
            msg = {type = tea.MSG_KEY, key = tea.KEY_RIGHT}
        elseif event.Key() == tui.KeyCtrlC then
            msg = {type = tea.MSG_KEY, key = tea.KEY_CTRL_C}
        elseif event.Rune() ~= 0 then
            msg = {type = tea.MSG_KEY, key = string.char(event.Rune())}
        end
        
        if msg then
            local newModel, cmd = update(model, msg)
            model = newModel
            
            if cmd then
                -- Handle quit
                local result = cmd()
                if result and result.type == tea.MSG_QUIT then
                    app:Stop()
                    return event
                end
            end
            
            app:QueueUpdateDraw(render)
        end
        
        return event
    end)
    
    app:SetRoot(textView, true)
    app:Run()
end

main()