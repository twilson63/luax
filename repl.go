package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	"github.com/yuin/gopher-lua"
	"github.com/spf13/cobra"
)

var replCmd = &cobra.Command{
	Use:   "repl",
	Short: "Start an interactive Lua REPL",
	Long:  `Start an interactive Lua Read-Eval-Print Loop (REPL).

By default, starts a TUI (Terminal UI) REPL with:
- Two-panel interface: output panel (top) and input panel (bottom)
- Persistent session state across expressions
- Access to all Hype modules (tui, http, kv, crypto, ws)
- Command history navigation with Up/Down arrows
- Visual feedback and syntax error handling

Controls:
- Enter: Execute the current expression
- Up/Down: Navigate command history
- Escape: Clear current input
- Ctrl+C: Exit the REPL

Use --simple flag for a basic command-line REPL without TUI.`,
	Run: func(cmd *cobra.Command, args []string) {
		simple, _ := cmd.Flags().GetBool("simple")
		if err := runREPL(simple); err != nil {
			fmt.Fprintf(os.Stderr, "Error running REPL: %v\n", err)
			os.Exit(1)
		}
	},
}

func init() {
	replCmd.Flags().BoolP("simple", "s", false, "Use simple mode instead of TUI")
}

func runREPL(simpleMode bool) error {
	// Create Lua state with all modules
	L := lua.NewState()
	defer L.Close()

	// Open standard libraries
	lua.OpenBase(L)
	lua.OpenPackage(L)
	lua.OpenCoroutine(L)
	lua.OpenTable(L)
	lua.OpenIo(L)
	lua.OpenOs(L)
	lua.OpenString(L)
	lua.OpenMath(L)
	lua.OpenDebug(L)

	// Register all modules
	registerHTTPModule(L)
	registerKVModule(L)
	registerTUIFunctions(L)
	registerCryptoModule(L)
	registerHTTPSigModule(L)
	registerWebSocketModule(L)
	

	if simpleMode {
		return runSimpleREPL(L)
	}
	
	// Run TUI REPL
	return runTUIREPL(L)
}

// Run TUI REPL
func runTUIREPL(L *lua.LState) error {
	tuiREPLCode := `
-- Initialize state
local outputText = ""
local history = {}
local historyIndex = 0

-- Create TUI components
local app = tui.newApp()
local flex = tui.newFlex()
local outputView = tui.newTextView("")
local inputField = tui.newInputField()

-- Configure main layout
flex:SetDirection(0) -- Vertical
flex:SetBorder(true)
flex:SetTitle("🚀 Hype Lua REPL v1.8.0")

-- Configure output view (top panel)
outputView:SetBorder(true)
outputView:SetTitle("📤 Output")
outputView:SetDynamicColors(false)  -- Disable to show brackets properly
outputView:SetWrap(true)
outputView:SetWordWrap(true)
outputView:SetScrollable(true)

-- Configure input field (bottom panel)
inputField:SetBorder(true)
inputField:SetTitle("📥 Input - Press Enter to Execute | Ctrl+C to Exit")
inputField:SetLabel("hype> ")
inputField:SetPlaceholder("Enter Lua expression...")
inputField:SetFieldBackgroundColor(235)  -- Dark gray for better readability

-- Helper function to append output
local function appendOutput(text)
    if outputText ~= "" then
        outputText = outputText .. "\n"
    end
    outputText = outputText .. text
    -- Debug: print what we're setting
    -- print("DEBUG: Setting text:", text)
    outputView:SetText(outputText)
end

-- Welcome message
appendOutput("🚀 Hype Lua REPL v1.8.0")
appendOutput("========================")
appendOutput("")
appendOutput("Available modules: tui, http, kv, crypto, ws")
appendOutput("")
appendOutput("Controls:")
appendOutput("• Enter: Execute expression")
appendOutput("• Ctrl+C: Exit REPL")
appendOutput("")
appendOutput("Commands:")
appendOutput("• :help       - Show help")
appendOutput("• :history    - Show command history (:h for short)")
appendOutput("• :h=N        - Recall command N from history")
appendOutput("• :clear      - Clear output")
appendOutput("")
appendOutput("Example commands:")
appendOutput('  2 + 2')
appendOutput('  print("Hello, World!")')
appendOutput('  local http = require("http")')
appendOutput('  math.sqrt(16)')
appendOutput("")
appendOutput("Ready! Type your Lua expressions below.")
appendOutput("=====================================")

-- Override print to capture output
local originalPrint = print
_G.print = function(...)
    local args = {...}
    local parts = {}
    for i, v in ipairs(args) do
        table.insert(parts, tostring(v))
    end
    appendOutput(table.concat(parts, "\t"))
end

-- Table formatting function
local function formatTable(t, indent)
    indent = indent or ""
    local parts = {}
    local keys = {}
    
    -- Collect all keys
    for k in pairs(t) do
        table.insert(keys, k)
    end
    
    -- Sort keys for consistent output
    table.sort(keys, function(a, b)
        if type(a) == type(b) then
            return tostring(a) < tostring(b)
        else
            return type(a) < type(b)
        end
    end)
    
    -- Format the table
    table.insert(parts, "{")
    for i, k in ipairs(keys) do
        local v = t[k]
        local key_str
        if type(k) == "string" then
            key_str = '"' .. k .. '"'
        else
            key_str = tostring(k)
        end
        local val_str
        
        if type(v) == "table" then
            if indent:len() < 20 then  -- Limit nesting depth
                val_str = formatTable(v, indent .. "  ")
            else
                val_str = "<nested table>"
            end
        elseif type(v) == "string" then
            val_str = '"' .. v .. '"'
        elseif type(v) == "function" then
            val_str = "<function>"
        elseif type(v) == "userdata" then
            val_str = "<userdata>"
        elseif type(v) == "thread" then
            val_str = "<thread>"
        else
            val_str = tostring(v)
        end
        
        table.insert(parts, indent .. "  [" .. key_str .. "] = " .. val_str .. (i < #keys and "," or ""))
    end
    table.insert(parts, indent .. "}")
    
    return table.concat(parts, "\n")
end

-- Function to execute code (returns recalled command if any)
local function executeCode(code)
    if code == "" then return nil end
    
    -- Special commands
    if code == ":history" or code == ":h" then
        appendOutput("Command History:")
        for i, cmd in ipairs(history) do
            appendOutput(string.format("  %d: %s", i, cmd))
        end
        if #history > 0 then
            appendOutput("")
            appendOutput("Use :h=N to recall command N (e.g., :h=1)")
        end
        return nil
    elseif code:match("^:h=(%d+)$") then
        local index = tonumber(code:match("^:h=(%d+)$"))
        if index and index >= 1 and index <= #history then
            local recalled = history[index]
            appendOutput("Recalled: " .. recalled)
            return recalled  -- Return the recalled command
        else
            appendOutput("Error: Invalid history index. Use :history to see available commands.")
            return nil
        end
    elseif code == ":clear" then
        outputText = ""
        outputView:SetText("")
        appendOutput("Output cleared.")
        return nil
    elseif code == ":help" then
        appendOutput("Special Commands:")
        appendOutput("  :history or :h      - Show command history")
        appendOutput("  :h=N               - Recall command N from history")
        appendOutput("  :clear             - Clear output")
        appendOutput("  :help              - Show this help")
        appendOutput("")
        appendOutput("Tips:")
        appendOutput("  - Type expressions like: 2 + 2")
        appendOutput("  - Tables are formatted nicely: {a=1, b=2}")
        appendOutput("  - Access modules: math, string, table, etc.")
        return nil
    end
    
    -- Add to history
    table.insert(history, code)
    historyIndex = #history + 1
    
    -- Show the command
    appendOutput("hype> " .. code)
    
    -- Try to execute as expression first (to get return value)
    local func, err = loadstring("return " .. code)
    
    if not func then
        -- If that fails, try as statement
        func, err = loadstring(code)
    end
    
    if func then
        -- Execute the function
        local results = {pcall(func)}
        local ok = table.remove(results, 1)
        
        if ok then
            -- Print any return values
            if #results > 0 then
                local output = {}
                for _, v in ipairs(results) do
                    if type(v) == "table" then
                        table.insert(output, formatTable(v))
                    elseif type(v) == "function" then
                        table.insert(output, "<function>")
                    elseif type(v) == "userdata" then
                        table.insert(output, "<userdata>")
                    elseif type(v) == "thread" then
                        table.insert(output, "<thread>")
                    else
                        table.insert(output, tostring(v))
                    end
                end
                appendOutput(table.concat(output, "\t"))
            end
        else
            appendOutput("Error: " .. tostring(results[1]))
        end
    else
        appendOutput("Syntax Error: " .. tostring(err))
    end
end

-- Input field done handler
inputField:SetDoneFunc(function(key)
    if key == 13 then -- Enter key
        local code = inputField:GetText()
        local recalled = executeCode(code)
        if recalled then
            -- Set the recalled command in the input field
            inputField:SetText(recalled)
        else
            -- Clear the input field for normal commands
            inputField:SetText("")
        end
    end
end)

-- Simple key handler for Ctrl+C only
app:SetInputCapture(function(event)
    if event:Key() == 3 then -- Ctrl+C
        app:Stop()
        return nil
    end
    return event
end)

-- Layout assembly
flex:AddItem(outputView, 0, 1, false)  -- Output view (flexible, takes most space)
flex:AddItem(inputField, 3, 0, true)   -- Input field (fixed height of 3 lines)

-- Set initial focus and root
app:SetRoot(flex, true)
app:SetFocus(inputField)

-- Start the application
app:Run()

-- Restore original print when done
_G.print = originalPrint
print("\nTUI REPL session ended.")
`

	// Execute the TUI REPL code
	if err := L.DoString(tuiREPLCode); err != nil {
		// If TUI fails, fall back to simple REPL
		fmt.Printf("Failed to start TUI REPL: %v\n", err)
		fmt.Println("Falling back to simple mode...")
		fmt.Println()
		return runSimpleREPL(L)
	}

	return nil
}

// Fallback simple REPL without TUI
func runSimpleREPL(L *lua.LState) error {
	fmt.Println("Hype Lua REPL v1.8.0 (Simple Mode)")
	fmt.Println("Type expressions and press Enter. Use Ctrl+C to exit.")
	fmt.Println()
	fmt.Println("Available modules: tui, http, kv, crypto, ws")
	fmt.Println("Multiline: Use '\\' at end of line or let incomplete statements continue")
	fmt.Println()

	// Simple line-by-line REPL with multiline support
	scanner := bufio.NewScanner(os.Stdin)
	var buffer string
	var prompt string
	
	for {
		if buffer == "" {
			prompt = "hype> "
		} else {
			prompt = "....> "
		}
		fmt.Print(prompt)
		
		if !scanner.Scan() {
			break
		}
		
		line := scanner.Text()
		
		// Check for explicit line continuation
		if strings.HasSuffix(line, "\\") {
			buffer += strings.TrimSuffix(line, "\\") + "\n"
			continue
		}
		
		// Add line to buffer
		if buffer != "" {
			buffer += line + "\n"
		} else {
			buffer = line
		}
		
		// Check if the statement is complete
		_, err := L.LoadString(buffer)
		if err != nil && strings.Contains(err.Error(), "<eof>") {
			// Incomplete statement, continue collecting lines
			buffer += "\n"
			continue
		}
		
		// Statement is complete (or has a different error), execute it
		code := buffer
		buffer = "" // Reset buffer
		
		if code == "" {
			continue
		}
		
		// Save the current stack size
		oldTop := L.GetTop()
		
		// Try to execute as expression first (for return values)
		err = L.DoString("return " + code)
		hasReturnValue := false
		
		if err != nil {
			// If that fails, try as statement
			L.SetTop(oldTop) // Restore stack
			err = L.DoString(code)
		} else {
			hasReturnValue = true
		}
		
		if err != nil {
			fmt.Println("Error:", err)
		} else if hasReturnValue {
			// Print any NEW return values (after oldTop)
			n := L.GetTop()
			if n > oldTop {
				results := []string{}
				for i := oldTop + 1; i <= n; i++ {
					lv := L.Get(i)
					var result string
					switch lv.Type() {
					case lua.LTNil:
						result = "nil"
					case lua.LTBool:
						result = fmt.Sprintf("%v", lua.LVAsBool(lv))
					case lua.LTNumber:
						result = fmt.Sprintf("%v", lua.LVAsNumber(lv))
					case lua.LTString:
						result = lua.LVAsString(lv)
					case lua.LTTable:
						// For tables, just show it's a table
						result = "<table>"
					case lua.LTFunction:
						result = "<function>"
					default:
						result = fmt.Sprintf("<%s>", lv.Type().String())
					}
					results = append(results, result)
				}
				fmt.Println(strings.Join(results, "\t"))
			}
			L.SetTop(oldTop) // Restore stack
		}
	}
	
	return scanner.Err()
}