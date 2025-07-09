# Hype Plugin System Documentation Index

This directory contains comprehensive documentation for Hype's plugin system.

## Documentation Files

### 📚 [PLUGINS.md](PLUGINS.md)
**Complete Plugin System Reference**
- How to use plugins in your applications
- Plugin specification formats and versioning
- Plugin discovery and loading
- Complete API reference
- Advanced topics and troubleshooting

### 🛠️ [PLUGIN_DEVELOPMENT.md](PLUGIN_DEVELOPMENT.md)  
**Plugin Development Guide**
- Step-by-step tutorial for creating plugins
- Real-world plugin examples
- Best practices and patterns
- Testing strategies
- Distribution and sharing guidelines

## Quick Links

### Using Plugins
```bash
# Basic usage
./hype run myapp.lua --plugins fs@1.0.0

# Multiple plugins
./hype run myapp.lua --plugins fs,json@2.1.0,utils

# Build with plugins
./hype build myapp.lua --plugins fs@1.0.0 -o myapp
```

### Creating Plugins
```bash
# 1. Create plugin directory
mkdir my-plugin && cd my-plugin

# 2. Create manifest
cat > hype-plugin.yaml << EOF
name: "my-plugin"
version: "1.0.0"
type: "lua"
main: "plugin.lua"
description: "My awesome plugin"
EOF

# 3. Create plugin code
cat > plugin.lua << EOF
local myplugin = {}
function myplugin.hello(name)
    return "Hello, " .. (name or "World") .. "!"
end
return myplugin
EOF

# 4. Test the plugin
./hype run test.lua --plugins ./my-plugin
```

## Examples

### Built-in Examples
- **`examples/plugins/fs-plugin/`** - Filesystem operations (v1.0.0)
- **`examples/plugins/fs-plugin-v2/`** - Enhanced filesystem (v2.0.0)
- **`examples/test-fs-plugin.lua`** - Plugin usage example
- **`examples/test-versioned-plugins.lua`** - Version-specific loading
- **`examples/test-multiple-plugins.lua`** - Multiple plugin usage

### Documentation Examples
See [PLUGIN_DEVELOPMENT.md](PLUGIN_DEVELOPMENT.md) for more examples:
- File watcher plugin
- Configuration parser plugin  
- Template engine plugin
- Testing frameworks

## Plugin Development Workflow

1. **📖 Read** [PLUGIN_DEVELOPMENT.md](PLUGIN_DEVELOPMENT.md) - Start here for step-by-step guide
2. **🔍 Study** `examples/plugins/` - Look at working examples
3. **🛠️ Create** your plugin following the patterns
4. **🧪 Test** using `./hype run` for rapid iteration
5. **📚 Reference** [PLUGINS.md](PLUGINS.md) for advanced features
6. **🚀 Share** your plugin with the community

## Plugin System Features

### ✅ Currently Supported
- ✅ Lua plugins with version management
- ✅ Automatic plugin discovery
- ✅ Plugin embedding in built executables
- ✅ Multiple plugin loading
- ✅ Custom plugin aliases
- ✅ Version validation
- ✅ Plugin configuration files

### 🚧 Future Enhancements
- 🚧 Go plugins for native performance
- 🚧 Plugin registry and distribution
- 🚧 Semantic version ranges (`^1.0.0`)
- 🚧 Plugin dependency management
- 🚧 Plugin sandboxing and security

## Getting Help

1. **Check the documentation** - Most questions are answered here
2. **Look at examples** - `examples/plugins/` has working code
3. **Test incrementally** - Use `./hype run` for quick testing
4. **Validate your manifest** - Ensure `hype-plugin.yaml` is correct
5. **Check plugin paths** - Verify your plugin is in the right location

## Contributing

Found issues or want to improve the plugin system?
- Report bugs in the main Hype repository
- Suggest improvements for plugin system features
- Contribute example plugins to help others
- Improve documentation and guides

---

**Happy plugin development! 🔌✨**