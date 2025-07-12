# Hype v1.5.0 Release Notes - Plugin System

**Release Date:** July 9, 2025  
**Version:** 1.5.0  
**Major Feature:** Complete Plugin System Implementation

## 🎉 What's New

### 🔌 Plugin System
Hype now features a complete plugin system that allows you to extend your applications with versioned Lua modules. This is the biggest feature addition since the initial release!

#### Key Features:
- **Versioned Plugins**: Use `name@version` syntax (e.g., `fs@1.0.0`)
- **Automatic Discovery**: Plugins are found in conventional directories
- **Zero Dependencies**: Plugins are embedded in built executables
- **Multiple Plugins**: Load multiple plugins with custom aliases
- **Version Validation**: Exact version matching ensures compatibility

## 🚀 Quick Start with Plugins

### Using Plugins
```bash
# Simple plugin usage
./hype run myapp.lua --plugins fs@1.0.0

# Multiple plugins
./hype run myapp.lua --plugins fs,json@2.1.0,utils

# Custom aliases
./hype run myapp.lua --plugins myfs=./path/to/plugin@1.2.0

# Build with embedded plugins
./hype build myapp.lua --plugins fs@1.0.0 -o myapp
```

### In Your Lua Scripts
```lua
-- Use plugins like built-in modules
local fs = require("fs")
local content, err = fs.readFile("config.txt")
if content then
    print("Config loaded:", content)
else
    print("Error:", err)
end
```

## 📦 Included Examples

### Ready-to-Use Plugins
- **`fs-plugin` (v1.0.0)**: Basic filesystem operations
  - `readFile()`, `writeFile()`, `exists()`, `size()`, `listDir()`, `mkdir()`
- **`fs-plugin-v2` (v2.0.0)**: Enhanced filesystem operations
  - All v1.0.0 features plus `copyFile()`, `moveFile()`, `deleteFile()`, `version()`

### Test Scripts
- **`test-fs-plugin.lua`**: Comprehensive filesystem plugin test
- **`test-versioned-plugins.lua`**: Version-specific plugin testing
- **`test-multiple-plugins.lua`**: Multiple plugin usage example

## 🛠️ Plugin Development

### Creating a Plugin
```bash
# 1. Create plugin directory
mkdir my-plugin

# 2. Create manifest (hype-plugin.yaml)
cat > my-plugin/hype-plugin.yaml << EOF
name: "my-plugin"
version: "1.0.0"
type: "lua"
main: "plugin.lua"
description: "My awesome plugin"
EOF

# 3. Create plugin code (plugin.lua)
cat > my-plugin/plugin.lua << EOF
local myplugin = {}
function myplugin.hello(name)
    return "Hello, " .. (name or "World") .. "!"
end
return myplugin
EOF

# 4. Use the plugin
./hype run test.lua --plugins ./my-plugin
```

## 📚 Documentation

### New Documentation Added
- **[docs/PLUGINS.md](docs/PLUGINS.md)**: Complete plugin system reference
- **[docs/PLUGIN_DEVELOPMENT.md](docs/PLUGIN_DEVELOPMENT.md)**: Step-by-step development guide
- **[docs/PLUGIN_INDEX.md](docs/PLUGIN_INDEX.md)**: Documentation navigation hub
- **Updated README.md**: Plugin system overview and quick start

### Plugin Specification Formats
- `fs` - Simple name with auto-discovery
- `fs@1.0.0` - Name with specific version requirement
- `myfs=./path/to/plugin` - Custom alias with explicit path
- `myfs=./path/to/plugin@2.0.0` - Alias with path and version
- `github.com/user/plugin@v1.0.0` - Go module support (framework ready)

## 🔧 Technical Details

### Plugin Discovery
Hype automatically searches for plugins in:
- `./plugins/[name]/`
- `./examples/plugins/[name]/`
- `./[name]-plugin/`
- `./examples/plugins/[name]-plugin/`

### Version Management
- Exact version matching: `fs@1.0.0` only accepts version `1.0.0`
- Latest version: `fs` or `fs@latest` accepts any version
- Version validation prevents compatibility issues

### Build Integration
- Plugins are embedded in built executables
- No runtime dependencies required
- Same zero-dependency deployment model
- Cross-platform plugin support

## 🎯 Use Cases

### Enhanced Applications
```lua
-- Configuration management
local config = require("config")
config.load("app.conf")
local port = config.get("server", "port", 8080)

-- Advanced file operations
local fs = require("fs")
fs.copyFile("template.html", "output.html")
fs.moveFile("old.log", "archive/old.log")

-- Template processing
local template = require("template")
local html = template.renderFile("page.html", {title = "My App"})
```

### Plugin Ecosystem
- **Filesystem operations**: File I/O, directory management
- **Configuration parsing**: INI, JSON, YAML parsers
- **Template engines**: Dynamic content generation
- **HTTP utilities**: URL parsing, request builders
- **Data processing**: JSON, CSV, XML handlers

## 🔄 Backward Compatibility

### Fully Compatible
- All existing hype applications continue to work unchanged
- No breaking changes to existing APIs
- Optional plugin system - use when needed

### Migration Path
- Existing apps work as-is
- Add plugins incrementally
- Migrate utility functions to plugins over time

## 🚀 Installation

### Download Pre-built Binaries
- **macOS**: `curl -sSL https://raw.githubusercontent.com/twilson63/hype/main/install-mac.sh | bash`
- **Linux**: `curl -sSL https://raw.githubusercontent.com/twilson63/hype/main/install-linux.sh | bash`
- **Windows**: Download from [GitHub Releases](https://github.com/twilson63/hype/releases)

### Build from Source
```bash
git clone https://github.com/twilson63/hype.git
cd hype
go build -o hype .
```

## 📊 Release Statistics

### Code Changes
- **16 files changed**
- **2,567 lines added**
- **22 lines removed**
- **4 new documentation files**
- **3 example plugins created**

### New Files Added
- `plugin.go` - Core plugin system implementation
- `docs/PLUGINS.md` - Plugin system reference
- `docs/PLUGIN_DEVELOPMENT.md` - Development guide
- `docs/PLUGIN_INDEX.md` - Documentation hub
- `examples/plugins/` - Plugin examples

## 🔮 Future Roadmap

### Planned Enhancements
- **Go Plugins**: Native performance plugins
- **Plugin Registry**: Central plugin repository
- **Semantic Versioning**: Range matching (`^1.0.0`, `~1.2.0`)
- **Plugin Dependencies**: Plugins that depend on other plugins
- **Hot Reloading**: Development mode plugin reloading

### Community
- Plugin sharing guidelines
- Plugin quality standards
- Community plugin registry
- Plugin certification process

## 🤝 Contributing

### Ways to Contribute
1. **Create plugins** for common use cases
2. **Improve documentation** with examples and tutorials
3. **Report bugs** and suggest improvements
4. **Share plugins** with the community
5. **Contribute to core** plugin system features

### Plugin Development
- Follow the [Plugin Development Guide](docs/PLUGIN_DEVELOPMENT.md)
- Use the provided examples as templates
- Test thoroughly with different hype versions
- Document your plugins well

## 🐛 Known Issues

### Current Limitations
- Only Lua plugins supported (Go plugins framework ready)
- Exact version matching only (no semantic ranges yet)
- No plugin dependency resolution
- No plugin sandboxing

### Workarounds
- Use version aliases for flexible plugin management
- Bundle related functionality into single plugins
- Use conditional loading for optional features

## 📞 Support

### Getting Help
- **Documentation**: Check [docs/PLUGINS.md](docs/PLUGINS.md) first
- **Examples**: Look at `examples/plugins/` for working code
- **Issues**: Report bugs on GitHub Issues
- **Discussions**: Join GitHub Discussions for questions

### Testing
- Use `./hype run` for rapid plugin development
- Test plugins with different hype versions
- Validate plugin manifests before distribution

## 🎊 Conclusion

Hype v1.5.0 represents a major leap forward in extensibility and developer experience. The plugin system opens up endless possibilities for creating reusable, shareable components that enhance your applications while maintaining hype's core philosophy of simplicity and zero-dependency deployment.

**Happy coding with plugins! 🔌✨**

---

**Full Changelog**: [CHANGELOG.md](CHANGELOG.md)  
**Plugin Documentation**: [docs/PLUGINS.md](docs/PLUGINS.md)  
**Development Guide**: [docs/PLUGIN_DEVELOPMENT.md](docs/PLUGIN_DEVELOPMENT.md)  
**GitHub Release**: [v1.5.0](https://github.com/twilson63/hype/releases/tag/v1.5.0)