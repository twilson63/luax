package main

import (
	"context"
	"fmt"
	"go/build"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"plugin"
	"reflect"
	"strings"

	"github.com/yuin/gopher-lua"
	"gopkg.in/yaml.v2"
)

// HypePlugin represents a plugin that can extend hype functionality
type HypePlugin interface {
	// Plugin metadata
	Name() string
	Version() string
	Description() string

	// Module registration - registers the plugin as a Lua module
	Register(L *lua.LState) error

	// Go dependencies needed for building
	Dependencies() []string

	// Cleanup resources if needed
	Close() error
}

// PluginSpec represents a plugin specification from CLI or config
type PluginSpec struct {
	Name    string `yaml:"name"`
	Source  string `yaml:"source"`  // URL, file path, or module path
	Version string `yaml:"version"` // Git tag, commit, or version
	Alias   string `yaml:"alias"`   // Optional alias for the module name
}

// PluginManifest represents the plugin's manifest file
type PluginManifest struct {
	Name         string   `yaml:"name"`
	Version      string   `yaml:"version"`
	Type         string   `yaml:"type"` // "go" or "lua"
	Main         string   `yaml:"main"`
	Module       string   `yaml:"module"`       // Go module path
	Description  string   `yaml:"description"`
	Author       string   `yaml:"author"`
	License      string   `yaml:"license"`
	Dependencies []string `yaml:"dependencies"` // Go dependencies
}

// PluginRegistry manages loaded plugins
type PluginRegistry struct {
	plugins []HypePlugin
	specs   []PluginSpec
}

// NewPluginRegistry creates a new plugin registry
func NewPluginRegistry() *PluginRegistry {
	return &PluginRegistry{
		plugins: make([]HypePlugin, 0),
		specs:   make([]PluginSpec, 0),
	}
}

// LoadPlugins loads plugins from specifications
func (r *PluginRegistry) LoadPlugins(ctx context.Context, specs []PluginSpec) error {
	r.specs = specs
	
	for _, spec := range specs {
		plugin, err := r.loadPlugin(ctx, spec)
		if err != nil {
			return fmt.Errorf("failed to load plugin %s: %w", spec.Name, err)
		}
		r.plugins = append(r.plugins, plugin)
	}
	
	return nil
}

// RegisterAll registers all loaded plugins with the Lua state
func (r *PluginRegistry) RegisterAll(L *lua.LState) error {
	for _, plugin := range r.plugins {
		if err := plugin.Register(L); err != nil {
			return fmt.Errorf("failed to register plugin %s: %w", plugin.Name(), err)
		}
	}
	return nil
}

// GetAllDependencies returns all Go dependencies from loaded plugins
func (r *PluginRegistry) GetAllDependencies() []string {
	var deps []string
	for _, plugin := range r.plugins {
		deps = append(deps, plugin.Dependencies()...)
	}
	return deps
}

// Close closes all plugins
func (r *PluginRegistry) Close() error {
	for _, plugin := range r.plugins {
		if err := plugin.Close(); err != nil {
			return err
		}
	}
	return nil
}

// loadPlugin loads a single plugin from a specification
func (r *PluginRegistry) loadPlugin(ctx context.Context, spec PluginSpec) (HypePlugin, error) {
	// Create temporary directory for plugin
	tempDir, err := ioutil.TempDir("", "hype-plugin-*")
	if err != nil {
		return nil, fmt.Errorf("failed to create temp dir: %w", err)
	}
	defer os.RemoveAll(tempDir)

	// Download/copy plugin source
	pluginDir, err := r.fetchPlugin(ctx, spec, tempDir)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch plugin: %w", err)
	}

	// Load plugin manifest
	manifest, err := r.loadManifest(pluginDir)
	if err != nil {
		return nil, fmt.Errorf("failed to load manifest: %w", err)
	}

	// Validate plugin version if specified
	if err := r.validatePluginVersion(spec, manifest); err != nil {
		return nil, fmt.Errorf("version validation failed: %w", err)
	}

	// Build and load the plugin
	switch manifest.Type {
	case "go":
		return r.loadGoPlugin(ctx, spec, manifest, pluginDir)
	case "lua":
		return r.loadLuaPlugin(spec, manifest, pluginDir)
	default:
		return nil, fmt.Errorf("unsupported plugin type: %s", manifest.Type)
	}
}

// fetchPlugin downloads or copies plugin source to target directory
func (r *PluginRegistry) fetchPlugin(ctx context.Context, spec PluginSpec, tempDir string) (string, error) {
	pluginDir := filepath.Join(tempDir, "plugin")

	if strings.HasPrefix(spec.Source, "http://") || strings.HasPrefix(spec.Source, "https://") {
		// Handle HTTP(S) URLs
		return "", fmt.Errorf("HTTP plugin loading not yet implemented")
	} else if filepath.IsAbs(spec.Source) || strings.HasPrefix(spec.Source, "./") || strings.HasPrefix(spec.Source, "../") {
		// Handle local file paths
		return r.copyLocalPlugin(spec.Source, pluginDir)
	} else if strings.Contains(spec.Source, "/") {
		// Handle Go module paths (e.g., github.com/user/plugin)
		return r.fetchGoModule(ctx, spec, pluginDir)
	}

	return "", fmt.Errorf("unsupported plugin source: %s", spec.Source)
}

// fetchGoModule fetches a Go module using go mod download
func (r *PluginRegistry) fetchGoModule(ctx context.Context, spec PluginSpec, targetDir string) (string, error) {
	// Create a temporary go.mod to download the module
	tempGoMod := filepath.Join(filepath.Dir(targetDir), "go.mod")
	goModContent := "module temp\n\ngo 1.21\n"
	if err := ioutil.WriteFile(tempGoMod, []byte(goModContent), 0644); err != nil {
		return "", fmt.Errorf("failed to create temp go.mod: %w", err)
	}

	// Construct module path with version
	modulePath := spec.Source
	if spec.Version != "" && spec.Version != "latest" {
		modulePath += "@" + spec.Version
	}

	// Download the module
	cmd := exec.CommandContext(ctx, "go", "mod", "download", "-x", modulePath)
	cmd.Dir = filepath.Dir(tempGoMod)
	if output, err := cmd.CombinedOutput(); err != nil {
		return "", fmt.Errorf("failed to download module %s: %w\nOutput: %s", modulePath, err, output)
	}

	// Find the downloaded module in GOPATH/pkg/mod
	gopath := build.Default.GOPATH
	if gopath == "" {
		gopath = filepath.Join(os.Getenv("HOME"), "go")
	}
	
	// Convert module path to filesystem path
	modPath := strings.ReplaceAll(spec.Source, "/", string(filepath.Separator))
	if spec.Version != "" && spec.Version != "latest" {
		modPath += "@" + spec.Version
	}
	
	sourceDir := filepath.Join(gopath, "pkg", "mod", modPath)
	
	// Copy from GOPATH to our target directory
	return r.copyLocalPlugin(sourceDir, targetDir)
}

// copyLocalPlugin copies a local plugin to target directory
func (r *PluginRegistry) copyLocalPlugin(sourcePath, targetDir string) (string, error) {
	if err := os.MkdirAll(targetDir, 0755); err != nil {
		return "", fmt.Errorf("failed to create target dir: %w", err)
	}

	// Copy files
	err := filepath.Walk(sourcePath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		relPath, err := filepath.Rel(sourcePath, path)
		if err != nil {
			return err
		}

		targetPath := filepath.Join(targetDir, relPath)

		if info.IsDir() {
			return os.MkdirAll(targetPath, info.Mode())
		}

		sourceFile, err := os.Open(path)
		if err != nil {
			return err
		}
		defer sourceFile.Close()

		targetFile, err := os.Create(targetPath)
		if err != nil {
			return err
		}
		defer targetFile.Close()

		_, err = targetFile.ReadFrom(sourceFile)
		return err
	})

	return targetDir, err
}

// loadManifest loads the plugin manifest
func (r *PluginRegistry) loadManifest(pluginDir string) (*PluginManifest, error) {
	manifestPath := filepath.Join(pluginDir, "hype-plugin.yaml")
	if _, err := os.Stat(manifestPath); os.IsNotExist(err) {
		// Try alternative names
		manifestPath = filepath.Join(pluginDir, "hype-plugin.yml")
		if _, err := os.Stat(manifestPath); os.IsNotExist(err) {
			return nil, fmt.Errorf("plugin manifest not found (hype-plugin.yaml)")
		}
	}

	data, err := ioutil.ReadFile(manifestPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read manifest: %w", err)
	}

	var manifest PluginManifest
	if err := yaml.Unmarshal(data, &manifest); err != nil {
		return nil, fmt.Errorf("failed to parse manifest: %w", err)
	}

	return &manifest, nil
}

// loadGoPlugin builds and loads a Go plugin
func (r *PluginRegistry) loadGoPlugin(ctx context.Context, spec PluginSpec, manifest *PluginManifest, pluginDir string) (HypePlugin, error) {
	// Build the plugin as a Go plugin (.so file)
	pluginPath := filepath.Join(pluginDir, "plugin.so")
	
	mainFile := filepath.Join(pluginDir, manifest.Main)
	if manifest.Main == "" {
		mainFile = filepath.Join(pluginDir, "plugin.go")
	}

	// Build the plugin
	cmd := exec.CommandContext(ctx, "go", "build", "-buildmode=plugin", "-o", pluginPath, mainFile)
	cmd.Dir = pluginDir
	cmd.Env = append(os.Environ(), "CGO_ENABLED=1") // Required for plugins
	
	if output, err := cmd.CombinedOutput(); err != nil {
		return nil, fmt.Errorf("failed to build plugin: %w\nOutput: %s", err, output)
	}

	// Load the plugin
	p, err := plugin.Open(pluginPath)
	if err != nil {
		return nil, fmt.Errorf("failed to load plugin: %w", err)
	}

	// Look for NewPlugin function
	newPluginSym, err := p.Lookup("NewPlugin")
	if err != nil {
		return nil, fmt.Errorf("plugin missing NewPlugin function: %w", err)
	}

	// Use reflection to call NewPlugin function
	newPluginValue := reflect.ValueOf(newPluginSym)
	if newPluginValue.Kind() != reflect.Func {
		return nil, fmt.Errorf("NewPlugin is not a function")
	}
	
	// Check function signature: should have no parameters and return one value
	funcType := newPluginValue.Type()
	if funcType.NumIn() != 0 || funcType.NumOut() != 1 {
		return nil, fmt.Errorf("NewPlugin function has wrong signature: expected func() interface{}, got %s", funcType)
	}
	
	// Call the function
	results := newPluginValue.Call(nil)
	if len(results) != 1 {
		return nil, fmt.Errorf("NewPlugin function returned wrong number of values")
	}
	
	pluginInstance := results[0].Interface()
	
	return &GoPluginWrapper{
		plugin:   pluginInstance,
		manifest: manifest,
		spec:     spec,
	}, nil
}

// loadLuaPlugin loads a Lua plugin
func (r *PluginRegistry) loadLuaPlugin(spec PluginSpec, manifest *PluginManifest, pluginDir string) (HypePlugin, error) {
	mainFile := filepath.Join(pluginDir, manifest.Main)
	if manifest.Main == "" {
		mainFile = filepath.Join(pluginDir, "plugin.lua")
	}

	content, err := ioutil.ReadFile(mainFile)
	if err != nil {
		return nil, fmt.Errorf("failed to read Lua plugin: %w", err)
	}

	return &LuaPluginWrapper{
		content:  string(content),
		manifest: manifest,
		spec:     spec,
	}, nil
}

// GoPluginWrapper wraps a Go plugin
type GoPluginWrapper struct {
	plugin   interface{} // Use interface{} instead of HypePlugin to avoid type assertion issues
	manifest *PluginManifest
	spec     PluginSpec
}

func (w *GoPluginWrapper) Name() string {
	if w.spec.Alias != "" {
		return w.spec.Alias
	}
	return w.callPluginMethod("Name").(string)
}

func (w *GoPluginWrapper) Version() string { 
	return w.callPluginMethod("Version").(string)
}

func (w *GoPluginWrapper) Description() string { 
	return w.callPluginMethod("Description").(string)
}

func (w *GoPluginWrapper) Dependencies() []string {
	deps := w.callPluginMethod("Dependencies").([]string)
	deps = append(deps, w.manifest.Dependencies...)
	return deps
}

func (w *GoPluginWrapper) Register(L *lua.LState) error { 
	result := w.callPluginMethodWithArgs("Register", L)
	if result == nil {
		return nil
	}
	return result.(error)
}

func (w *GoPluginWrapper) Close() error {
	result := w.callPluginMethod("Close")
	if result == nil {
		return nil
	}
	return result.(error)
}

// callPluginMethod calls a method on the plugin using reflection
func (w *GoPluginWrapper) callPluginMethod(methodName string) interface{} {
	return w.callPluginMethodWithArgs(methodName)
}

// callPluginMethodWithArgs calls a method on the plugin with arguments using reflection
func (w *GoPluginWrapper) callPluginMethodWithArgs(methodName string, args ...interface{}) interface{} {
	pluginValue := reflect.ValueOf(w.plugin)
	method := pluginValue.MethodByName(methodName)
	
	if !method.IsValid() {
		panic(fmt.Sprintf("plugin method %s not found", methodName))
	}
	
	// Convert arguments to reflect.Value
	argValues := make([]reflect.Value, len(args))
	for i, arg := range args {
		argValues[i] = reflect.ValueOf(arg)
	}
	
	// Call the method
	results := method.Call(argValues)
	
	// Return the first result (or nil if no results)
	if len(results) == 0 {
		return nil
	}
	
	return results[0].Interface()
}

// LuaPluginWrapper wraps a Lua plugin
type LuaPluginWrapper struct {
	content  string
	manifest *PluginManifest
	spec     PluginSpec
}

func (w *LuaPluginWrapper) Name() string {
	if w.spec.Alias != "" {
		return w.spec.Alias
	}
	return w.manifest.Name
}

func (w *LuaPluginWrapper) Version() string     { return w.manifest.Version }
func (w *LuaPluginWrapper) Description() string { return w.manifest.Description }
func (w *LuaPluginWrapper) Dependencies() []string {
	return w.manifest.Dependencies
}

func (w *LuaPluginWrapper) Register(L *lua.LState) error {
	// Create a temporary Lua state to load the plugin
	tempL := lua.NewState()
	defer tempL.Close()

	// Execute the plugin code
	if err := tempL.DoString(w.content); err != nil {
		return fmt.Errorf("failed to execute Lua plugin: %w", err)
	}

	// Get the plugin table from the Lua state
	pluginTable := tempL.Get(-1)
	if pluginTable.Type() != lua.LTTable {
		return fmt.Errorf("Lua plugin must return a table")
	}

	// Register the plugin as a module
	L.PreloadModule(w.Name(), func(L *lua.LState) int {
		// Copy the plugin table to the main Lua state
		newTable := L.NewTable()
		
		pluginTable.(*lua.LTable).ForEach(func(key, value lua.LValue) {
			L.SetField(newTable, key.String(), value)
		})
		
		L.Push(newTable)
		return 1
	})

	return nil
}

func (w *LuaPluginWrapper) Close() error { return nil }

// ParsePluginSpecs parses plugin specifications from CLI arguments
func ParsePluginSpecs(plugins []string) ([]PluginSpec, error) {
	var specs []PluginSpec

	for _, pluginStr := range plugins {
		// Handle different formats:
		// - "alias=source@version"     (explicit alias and source with version)
		// - "alias=source"             (explicit alias and source) 
		// - "name@version"             (simple name with version - looks for plugin named 'name')
		// - "source@version"           (full source path with version)
		// - "name" or "source"         (simple name or source)
		
		var spec PluginSpec
		
		// Check for alias= prefix (explicit alias assignment)
		if strings.Contains(pluginStr, "=") {
			parts := strings.SplitN(pluginStr, "=", 2)
			spec.Alias = parts[0]
			pluginStr = parts[1]
		}
		
		// Check for @version suffix
		if strings.Contains(pluginStr, "@") {
			parts := strings.SplitN(pluginStr, "@", 2)
			spec.Source = parts[0]
			spec.Version = parts[1]
		} else {
			spec.Source = pluginStr
			spec.Version = "latest"
		}
		
		// Determine the plugin name and handle simple name@version format
		if spec.Alias == "" {
			// If source contains "/", it's a path/URL - use basename as name
			if strings.Contains(spec.Source, "/") {
				spec.Name = filepath.Base(spec.Source)
			} else {
				// Simple name format (e.g., "fs@1.0" or "fs")
				// Use the source as both name and try to resolve it
				spec.Name = spec.Source
				
				// For simple names, we need to try different resolution strategies:
				// 1. Look for local plugin in conventional locations
				// 2. Look for it as a Go module (future)
				// 3. Look in plugin registry (future)
				
				// For now, try conventional local plugin directory structure
				if !strings.HasPrefix(spec.Source, "./") && !strings.HasPrefix(spec.Source, "../") && !filepath.IsAbs(spec.Source) {
					// Check common plugin locations
					possiblePaths := []string{
						fmt.Sprintf("./plugins/%s", spec.Source),
						fmt.Sprintf("./examples/plugins/%s", spec.Source),
						fmt.Sprintf("./%s-plugin", spec.Source),
						fmt.Sprintf("./examples/plugins/%s-plugin", spec.Source),
					}
					
					// Try to find the plugin in conventional locations
					for _, path := range possiblePaths {
						if _, err := os.Stat(path); err == nil {
							spec.Source = path
							break
						}
					}
				}
			}
		} else {
			spec.Name = spec.Alias
		}
		
		specs = append(specs, spec)
	}

	return specs, nil
}

// validatePluginVersion validates that the plugin version matches the requested version
func (r *PluginRegistry) validatePluginVersion(spec PluginSpec, manifest *PluginManifest) error {
	// If no specific version requested, accept any version
	if spec.Version == "" || spec.Version == "latest" {
		return nil
	}
	
	// Exact version match
	if manifest.Version == spec.Version {
		return nil
	}
	
	// For now, we'll do exact matching. In the future, we could add:
	// - Semantic version matching (^1.0.0, ~1.2.0, etc.)
	// - Version range support (>=1.0.0 <2.0.0)
	// - Pre-release handling (1.0.0-alpha.1)
	
	return fmt.Errorf("plugin version mismatch: requested %s, found %s", spec.Version, manifest.Version)
}

// LoadPluginConfig loads plugin configuration from file
func LoadPluginConfig(configPath string) ([]PluginSpec, error) {
	data, err := ioutil.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read plugin config: %w", err)
	}

	var config struct {
		Plugins []PluginSpec `yaml:"plugins"`
	}

	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("failed to parse plugin config: %w", err)
	}

	return config.Plugins, nil
}