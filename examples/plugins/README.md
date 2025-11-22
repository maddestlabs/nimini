# Nimini Plugin System

This directory contains example plugins demonstrating the Nimini compile-time plugin architecture.

## Overview

The Nimini plugin system allows you to extend the DSL with custom native functions, constants, and types at compile-time. Plugins are written in Nim and compiled directly into your application.

## Core Types

### Plugin

The main plugin type that contains:
- **info**: Metadata (name, author, version, description)
- **functions**: Table of native functions
- **constants**: Table of constant values
- **nodes**: Custom AST node definitions (for future extensions)
- **hooks**: Lifecycle callbacks (onLoad, onUnload)

### NativeFunc

Type alias for native function implementations:
```nim
NativeFunc = proc(env: ref Env; args: seq[Value]): Value {.gcsafe.}
```

### NodeDef

Describes custom AST nodes (currently for documentation/planning):
```nim
NodeDef = object
  name: string
  description: string
```

## Creating a Plugin

### Basic Plugin Structure

```nim
import nimini

proc myFunction(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
  # Your implementation here
  return valInt(42)

proc createMyPlugin*(): Plugin =
  result = newPlugin(
    name: "myplugin",
    author: "Your Name",
    version: "1.0.0",
    description: "My custom plugin"
  )

  # Register functions
  result.registerFunc("myFunction", myFunction)

  # Register constants
  result.registerConstantInt("MAX_SIZE", 1024)
  result.registerConstantString("DEFAULT_NAME", "untitled")

  # Optional: Set lifecycle hooks
  result.setOnLoad(proc(ctx: PluginContext): void =
    echo "Plugin loaded!"
  )
```

### Registering Functions

```nim
proc addNumbers(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
  if args.len >= 2:
    return valInt(args[0].i + args[1].i)
  return valNil()

plugin.registerFunc("add", addNumbers)
```

### Registering Constants

```nim
# Integer constants
plugin.registerConstantInt("MAX_PLAYERS", 4)

# Float constants
plugin.registerConstantFloat("PI", 3.14159)

# String constants
plugin.registerConstantString("VERSION", "1.0.0")

# Boolean constants
plugin.registerConstantBool("DEBUG_MODE", false)

# Or use the generic version
plugin.registerConstant("CUSTOM", valInt(100))
```

### Lifecycle Hooks

```nim
plugin.setOnLoad(proc(ctx: PluginContext): void =
  echo "[MyPlugin] Initializing..."
  # Perform initialization
)

plugin.setOnUnload(proc(ctx: PluginContext): void =
  echo "[MyPlugin] Cleaning up..."
  # Release resources
)
```

## Using Plugins

### In Nim Code

```nim
import nimini
import myplugin

proc main() =
  # Initialize runtime
  initRuntime()

  # Create and register plugin
  let plugin = createMyPlugin()
  registerPlugin(plugin)
  loadPlugin(plugin, runtimeEnv)

  # Parse and execute DSL
  let code = """
var x = myFunction()
var y = MAX_SIZE
"""
  let prog = parseDsl(tokenizeDsl(code))
  execProgram(prog, runtimeEnv)
```

### In DSL Code

Once loaded, plugin functions and constants are available directly:

```nimini
# Use plugin constants
var maxSize = MAX_SIZE
var greeting = DEFAULT_NAME

# Call plugin functions
var result = myFunction()
var sum = add(10, 20)
```

## Plugin Registry

### Global Registry

```nim
# Initialize the global plugin system
initPluginSystem()

# Register plugins globally
registerPlugin(myPlugin)

# Check if a plugin is registered
if hasPlugin("myplugin"):
  echo "Plugin found!"

# Get a registered plugin
let plugin = getPlugin("myplugin")

# List all plugins
let names = listPlugins()
```

### Local Registry

```nim
# Create a local registry
let registry = newPluginRegistry()

# Register multiple plugins
registry.registerPlugin(plugin1)
registry.registerPlugin(plugin2)

# Load all plugins at once
registry.loadAllPlugins(runtimeEnv)
```

## Example Plugins

### Raylib Plugin

See `raylib_plugin.nim` for a complete example demonstrating:
- Window management functions
- Drawing functions
- Color constants
- Lifecycle hooks
- Stub implementation for testing

### Math Plugin Example

```nim
import nimini

proc sinFunc(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
  if args.len > 0:
    return valFloat(sin(args[0].f))
  return valNil()

proc cosFunc(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
  if args.len > 0:
    return valFloat(cos(args[0].f))
  return valNil()

proc createMathPlugin*(): Plugin =
  result = newPlugin(
    name: "math",
    author: "Math Team",
    version: "1.0.0",
    description: "Advanced math functions"
  )

  result.registerFunc("sin", sinFunc)
  result.registerFunc("cos", cosFunc)
  result.registerConstantFloat("PI", 3.14159265359)
  result.registerConstantFloat("E", 2.71828182846)
```

Usage in DSL:
```nimini
var angle = 0.5
var s = sin(angle)
var c = cos(angle)
var circumference = 2.0 * PI * radius
```

## Best Practices

1. **Error Handling**: Always validate argument count and types
2. **Documentation**: Use descriptive names and add comments
3. **Type Safety**: Use the appropriate `registerConstant*` method
4. **Lifecycle**: Clean up resources in onUnload hooks
5. **Testing**: Write tests for your plugin functions

## Type Conversions

When working with Value types in native functions:

```nim
# Get integer value
let n = args[0].i

# Get float value
let f = args[0].f

# Get string value
let s = args[0].s

# Get boolean value
let b = args[0].b

# Check type
if args[0].kind == vkInt:
  # Handle integer

# Return values
return valInt(42)
return valFloat(3.14)
return valString("hello")
return valBool(true)
return valNil()
```

## Advanced Features

### Custom Node Definitions

Register custom AST node types for documentation and future extensions:

```nim
plugin.registerNode("DrawCall", "A graphics drawing operation")
plugin.registerNode("SoundEffect", "An audio playback command")
```

### Plugin Dependencies

While not enforced by the system, document dependencies in your plugin:

```nim
result = newPlugin(
  name: "advanced_graphics",
  author: "Graphics Team",
  version: "2.0.0",
  description: "Requires: raylib plugin v0.1.0+"
)
```

## Testing Plugins

Add tests to `tests/tests.nim`:

```nim
suite "My Plugin Tests":
  test "plugin function works":
    initRuntime()
    let plugin = createMyPlugin()
    loadPlugin(plugin, runtimeEnv)

    let code = "var result = myFunction()"
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)

    let result = getVar(runtimeEnv, "result")
    assert result.i == 42
```

## Future Enhancements

Potential future additions to the plugin system:
- Dynamic plugin loading at runtime
- Plugin dependency resolution
- Namespace support (e.g., `raylib.InitWindow()`)
- Plugin sandboxing and permissions
- Plugin hot-reloading for development
- Full custom AST node support

## Contributing

When creating plugins for Nimini:
1. Follow the existing code style
2. Add comprehensive tests
3. Document all functions and constants
4. Include usage examples
5. Test with the DSL runtime

## License

Plugins follow the same license as Nimini (see LICENSE in root directory).
