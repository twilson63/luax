package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"text/template"
)

// Removed embed for now - we'll generate everything at build time

type BuildConfig struct {
	ScriptPath   string
	OutputName   string
	Target       string
	ScriptContent string
}

func buildExecutable(scriptPath, outputName, target string) error {
	config := &BuildConfig{
		ScriptPath: scriptPath,
		OutputName: outputName,
		Target:     target,
	}

	if config.OutputName == "" {
		base := filepath.Base(scriptPath)
		config.OutputName = strings.TrimSuffix(base, filepath.Ext(base))
	}

	if config.Target == "current" {
		config.Target = runtime.GOOS
	}

	scriptContent, err := os.ReadFile(scriptPath)
	if err != nil {
		return fmt.Errorf("failed to read script file: %w", err)
	}
	config.ScriptContent = string(scriptContent)

	tempDir, err := os.MkdirTemp("", "luax-build-*")
	if err != nil {
		return fmt.Errorf("failed to create temp directory: %w", err)
	}
	defer os.RemoveAll(tempDir)

	if err := generateRuntimeCode(tempDir, config); err != nil {
		return fmt.Errorf("failed to generate runtime code: %w", err)
	}

	if err := buildExecutableFromRuntime(tempDir, config); err != nil {
		return fmt.Errorf("failed to build executable: %w", err)
	}

	return nil
}

func generateRuntimeCode(tempDir string, config *BuildConfig) error {
	runtimeTemplate := `package main

import (
	"fmt"
	"os"
	"github.com/yuin/gopher-lua"
	"github.com/gdamore/tcell/v2"
	"github.com/rivo/tview"
)

const luaScript = ` + "`" + `{{.ScriptContent}}` + "`" + `

func main() {
	L := lua.NewState()
	defer L.Close()

	// Register TUI functions
	registerTUIFunctions(L)

	if err := L.DoString(luaScript); err != nil {
		fmt.Fprintf(os.Stderr, "Error running Lua script: %v\n", err)
		os.Exit(1)
	}
}

func registerTUIFunctions(L *lua.LState) {
	// Create TUI module
	tuiModule := L.NewTable()
	
	// Basic TUI functions
	L.SetField(tuiModule, "newApp", L.NewFunction(luaNewApp))
	L.SetField(tuiModule, "newTextView", L.NewFunction(luaNewTextView))
	L.SetField(tuiModule, "newInputField", L.NewFunction(luaNewInputField))
	L.SetField(tuiModule, "newButton", L.NewFunction(luaNewButton))
	L.SetField(tuiModule, "newFlex", L.NewFunction(luaNewFlex))
	
	L.SetGlobal("tui", tuiModule)
	
	// Set up metatables for TUI objects
	setupTUIMetatables(L)
}

func setupTUIMetatables(L *lua.LState) {
	// App metatable
	appMT := L.NewTypeMetatable("App")
	L.SetField(appMT, "__index", L.NewFunction(appIndex))
	
	// TextView metatable  
	textViewMT := L.NewTypeMetatable("TextView")
	L.SetField(textViewMT, "__index", L.NewFunction(textViewIndex))
	
	// InputField metatable
	inputFieldMT := L.NewTypeMetatable("InputField")
	L.SetField(inputFieldMT, "__index", L.NewFunction(inputFieldIndex))
	
	// Button metatable
	buttonMT := L.NewTypeMetatable("Button")
	L.SetField(buttonMT, "__index", L.NewFunction(buttonIndex))
	
	// Flex metatable
	flexMT := L.NewTypeMetatable("Flex")
	L.SetField(flexMT, "__index", L.NewFunction(flexIndex))
}

func appIndex(L *lua.LState) int {
	ud := L.CheckUserData(1)
	app := ud.Value.(*tview.Application)
	method := L.CheckString(2)
	
	switch method {
	case "SetRoot":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			// Skip the first argument (self)
			rootUD := L.CheckUserData(2)
			fullscreen := L.OptBool(3, true)
			app.SetRoot(rootUD.Value.(tview.Primitive), fullscreen)
			return 0
		}))
	case "Run":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			if err := app.Run(); err != nil {
				L.Push(lua.LString(err.Error()))
				return 1
			}
			return 0
		}))
	case "Stop":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			app.Stop()
			return 0
		}))
	}
	return 1
}

func textViewIndex(L *lua.LState) int {
	ud := L.CheckUserData(1)
	textView := ud.Value.(*tview.TextView)
	method := L.CheckString(2)
	
	switch method {
	case "SetText":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			text := L.CheckString(2)
			textView.SetText(text)
			L.Push(ud)
			return 1
		}))
	}
	return 1
}

func inputFieldIndex(L *lua.LState) int {
	ud := L.CheckUserData(1)
	inputField := ud.Value.(*tview.InputField)
	method := L.CheckString(2)
	
	switch method {
	case "GetText":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			text := inputField.GetText()
			L.Push(lua.LString(text))
			return 1
		}))
	case "SetText":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			text := L.CheckString(2)
			inputField.SetText(text)
			L.Push(ud)
			return 1
		}))
	case "SetDoneFunc":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			fn := L.CheckFunction(2)
			inputField.SetDoneFunc(func(key tcell.Key) {
				L.Push(fn)
				L.Push(lua.LNumber(int(key)))
				L.Call(1, 0)
			})
			L.Push(ud)
			return 1
		}))
	}
	return 1
}

func buttonIndex(L *lua.LState) int {
	ud := L.CheckUserData(1)
	button := ud.Value.(*tview.Button)
	method := L.CheckString(2)
	
	switch method {
	case "SetSelectedFunc":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			fn := L.CheckFunction(2)
			button.SetSelectedFunc(func() {
				L.Push(fn)
				L.Call(0, 0)
			})
			L.Push(ud)
			return 1
		}))
	}
	return 1
}

func flexIndex(L *lua.LState) int {
	ud := L.CheckUserData(1)
	flex := ud.Value.(*tview.Flex)
	method := L.CheckString(2)
	
	switch method {
	case "SetDirection":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			direction := L.CheckInt(2)
			flex.SetDirection(direction)
			L.Push(ud)
			return 1
		}))
	case "AddItem":
		L.Push(L.NewFunction(func(L *lua.LState) int {
			itemUD := L.CheckUserData(2)
			fixedSize := L.CheckInt(3)
			proportion := L.CheckInt(4)
			focus := L.CheckBool(5)
			flex.AddItem(itemUD.Value.(tview.Primitive), fixedSize, proportion, focus)
			L.Push(ud)
			return 1
		}))
	}
	return 1
}

func luaNewApp(L *lua.LState) int {
	app := tview.NewApplication()
	ud := L.NewUserData()
	ud.Value = app
	L.SetMetatable(ud, L.GetTypeMetatable("App"))
	L.Push(ud)
	return 1
}

func luaNewTextView(L *lua.LState) int {
	text := L.OptString(1, "")
	textView := tview.NewTextView().SetText(text).SetDynamicColors(true).SetWrap(true)
	ud := L.NewUserData()
	ud.Value = textView
	L.SetMetatable(ud, L.GetTypeMetatable("TextView"))
	L.Push(ud)
	return 1
}

func luaNewInputField(L *lua.LState) int {
	inputField := tview.NewInputField()
	ud := L.NewUserData()
	ud.Value = inputField
	L.SetMetatable(ud, L.GetTypeMetatable("InputField"))
	L.Push(ud)
	return 1
}

func luaNewButton(L *lua.LState) int {
	label := L.OptString(1, "Button")
	button := tview.NewButton(label)
	ud := L.NewUserData()
	ud.Value = button
	L.SetMetatable(ud, L.GetTypeMetatable("Button"))
	L.Push(ud)
	return 1
}

func luaNewFlex(L *lua.LState) int {
	flex := tview.NewFlex()
	ud := L.NewUserData()
	ud.Value = flex
	L.SetMetatable(ud, L.GetTypeMetatable("Flex"))
	L.Push(ud)
	return 1
}
`

	tmpl, err := template.New("runtime").Parse(runtimeTemplate)
	if err != nil {
		return err
	}

	mainFile := filepath.Join(tempDir, "main.go")
	f, err := os.Create(mainFile)
	if err != nil {
		return err
	}
	defer f.Close()

	return tmpl.Execute(f, config)
}

func buildExecutableFromRuntime(tempDir string, config *BuildConfig) error {
	goModContent := `module luax-runtime

go 1.21

require (
	github.com/yuin/gopher-lua v1.1.1
	github.com/gdamore/tcell/v2 v2.7.0
	github.com/rivo/tview v0.0.0-20240101144852-b3bd1aa5e9f2
)
`

	goModPath := filepath.Join(tempDir, "go.mod")
	if err := os.WriteFile(goModPath, []byte(goModContent), 0644); err != nil {
		return err
	}

	// Run go mod tidy to download dependencies
	tidyCmd := exec.Command("go", "mod", "tidy")
	tidyCmd.Dir = tempDir
	if output, err := tidyCmd.CombinedOutput(); err != nil {
		return fmt.Errorf("go mod tidy failed: %w\nOutput: %s", err, output)
	}

	outputPath := config.OutputName
	if config.Target == "windows" {
		outputPath += ".exe"
	}

	cmd := exec.Command("go", "build", "-o", outputPath, ".")
	cmd.Dir = tempDir
	cmd.Env = append(os.Environ(),
		"GOOS="+config.Target,
		"GOARCH=amd64",
	)

	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("go build failed: %w\nOutput: %s", err, output)
	}

	builtExecutable := filepath.Join(tempDir, filepath.Base(outputPath))
	if _, err := os.Stat(builtExecutable); err == nil {
		return os.Rename(builtExecutable, outputPath)
	}

	return nil
}