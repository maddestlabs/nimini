# Nimini Plugin Architecture

## Overview

Nimini now features a compile-time plugin architecture that allows extending the DSL with custom native functions, constants, and types. This document describes the architecture, design decisions, and usage patterns.

## Architecture Design

### Core Components

1. **nimini/plugin.nim** - Plugin system core
   - Plugin type and metadata
   - Plugin registry and management
   - Lifecycle hooks
   - Registration API

2. **nimini/runtime.nim** - Runtime integration
   - Native function interface (NativeFunc)
   - Value types and conversions
   - Environment/scope management

3. **examples/plugins/** - Example plugins
   - Raylib bindings (stub implementation)
   - Plugin usage examples
   - Documentation and best practices

### Type Hierarchy

```
Plugin
├── PluginInfo (metadata)
│   ├── name: string
│   ├── author: string
│   ├── version: string
│   └── description: string
├── functions: Table[string, NativeFunc]
├── constants: Table[string, Value]
├── nodes: seq[NodeDef]
├── hooks: PluginHooks
│   ├── onLoad: proc(ctx: PluginContext)
│   └── onUnload: proc(ctx: PluginContext)
└── enabled: bool

PluginRegistry
├── plugins: Table[string, Plugin]
└── loadOrder: seq[string]

PluginContext
├── env: ref Env
└── metadata: Table[string, string]

NodeDef
├── name: string
└── description: string
```

### Design Decisions

#### 1. Compile-Time Only

**Decision**: Plugins are compiled into the application at build time.

**Rationale**:
- Simpler implementation
- Better performance (no runtime loading overhead)
- Type safety enforced at compile time
- No security concerns with dynamic code loading
- Easier debugging and testing

**Future**: Dynamic loading can be added later without breaking the API.

#### 2. Table-Based Registration

**Decision**: Use `Table[string, NativeFunc]` for function storage.

**Rationale**:
- O(1) lookup performance
- Natural key-value mapping
- Easy to iterate and introspect
- Flexible for future extensions

#### 3. Unified Value Type

**Decision**: Re-use existing `Value` type from runtime.

**Rationale**:
- Consistency with existing codebase
- No additional type conversions needed
- Plugins integrate seamlessly with DSL
- All existing runtime features available

#### 4. Lifecycle Hooks

**Decision**: Optional onLoad/onUnload callbacks.

**Rationale**:
- Enables initialization logic
- Resource management
- Logging and debugging
- Future extension points

#### 5. Plugin Context

**Decision**: Pass `PluginContext` to hooks instead of raw environment.

**Rationale**:
- Encapsulation of plugin state
- Future-proof (can add fields without breaking API)
- Metadata storage per plugin
- Clean separation of concerns

## Implementation Details

### Native Function Interface

All native functions follow this signature:
```nim
proc(env: ref Env; args: seq[Value]): Value {.gcsafe.}
```

**Parameters**:
- `env`: Access to runtime environment and variables
- `args`: Evaluated arguments passed from DSL

**Return**: Value to be used in DSL expression

**Constraints**:
- Must be `{.gcsafe.}` for thread safety
- Should validate argument count and types
- Should handle errors gracefully (return valNil or quit with error)

### Plugin Registration Flow

```
1. Create Plugin
   ↓
2. Register Functions & Constants
   ↓
3. Set Lifecycle Hooks (optional)
   ↓
4. Register Plugin with Registry
   ↓
5. Load Plugin into Runtime
   ↓
6. Functions/Constants Available in DSL
```

### Load Process

When a plugin is loaded:

1. Create `PluginContext` with runtime environment
2. Call `onLoad` hook if present
3. Register all functions via `registerNative()`
4. Define all constants in environment via `defineVar()`
5. Mark plugin as enabled

### Unload Process

When a plugin is unloaded:

1. Call `onUnload` hook if present
2. Mark plugin as disabled
3. Note: Functions/constants remain in environment for compatibility

## Example: Complete Plugin

```nim
import nimini
import std/math

# Native function implementations
proc sqrtFunc(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
  if args.len < 1:
    quit "sqrt requires 1 argument"
  if args[0].kind notin {vkInt, vkFloat}:
    quit "sqrt requires numeric argument"
  return valFloat(sqrt(args[0].f))

proc powFunc(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
  if args.len < 2:
    quit "pow requires 2 arguments"
  let base = args[0].f
  let exp = args[1].f
  return valFloat(pow(base, exp))

# Lifecycle hooks
proc onLoad(ctx: PluginContext): void =
  echo "[MathPlugin] Loaded - Advanced math functions available"

proc onUnload(ctx: PluginContext): void =
  echo "[MathPlugin] Unloaded"

# Plugin factory
proc createMathPlugin*(): Plugin =
  result = newPlugin(
    name: "math_advanced",
    author: "Nimini Team",
    version: "1.0.0",
    description: "Advanced mathematical functions"
  )

  # Register functions
  result.registerFunc("sqrt", sqrtFunc)
  result.registerFunc("pow", powFunc)

  # Register constants
  result.registerConstantFloat("PI", 3.14159265359)
  result.registerConstantFloat("E", 2.71828182846)
  result.registerConstantFloat("PHI", 1.61803398875)

  # Register node definitions (for documentation)
  result.registerNode("MathOp", "Advanced mathematical operation")

  # Set hooks
  result.setOnLoad(onLoad)
  result.setOnUnload(onUnload)

# Usage
when isMainModule:
  initRuntime()
  let plugin = createMathPlugin()
  registerPlugin(plugin)
  loadPlugin(plugin, runtimeEnv)

  let code = """
var radius = 5.0
var area = PI * pow(radius, 2.0)
var hypotenuse = sqrt(9.0 + 16.0)
"""
  execProgram(parseDsl(tokenizeDsl(code)), runtimeEnv)
```

## Plugin Categories

Plugins can serve different purposes:

### 1. Library Bindings
Wrap existing libraries (raylib, SDL, etc.)
```nim
createRaylibPlugin()
createSDLPlugin()
createSQLitePlugin()
```

### 2. Utility Functions
Provide helper functions for common tasks
```nim
createStringUtilsPlugin()
createMathUtilsPlugin()
createFileIOPlugin()
```

### 3. Domain-Specific
Add domain-specific functionality
```nim
createGameEnginePlugin()
create2DPhysicsPlugin()
createAudioPlugin()
```

### 4. Standard Library
Core functionality shipped with Nimini
```nim
createCorePlugin()      # Basic I/O, string ops
createCollectionsPlugin()  # Arrays, tables
createSystemPlugin()    # OS, file system
```

## Integration with Nimini

### Current Integration Points

1. **Runtime Environment**: Plugins register into `runtimeEnv`
2. **Function Calls**: Plugins use existing `evalCall` mechanism
3. **Constants**: Plugins use existing `defineVar` for constants
4. **Type System**: Plugins use existing `Value` types

### No Changes Required To:
- Tokenizer (lexical analysis)
- Parser (syntax analysis)
- AST definitions
- Execution engine

### Future Integration Points

1. **Custom AST Nodes**: Extend parser to recognize plugin-defined syntax
2. **Type Checking**: Add optional static type analysis
3. **Namespaces**: Support `plugin.function()` syntax
4. **Imports**: `import raylib` to load plugins in DSL

## Testing Strategy

### Unit Tests (tests/tests.nim)

```nim
suite "Plugin System Tests":
  test "create plugin with metadata"
  test "register function with plugin"
  test "register constants with plugin"
  test "plugin lifecycle hooks"
  test "load plugin into runtime"
  test "plugin with multiple functions"
  test "global plugin registry"
  test "load all plugins"
```

### Integration Tests

Test complete plugin workflows:
```nim
test "raylib plugin integration":
  # Load plugin
  # Execute DSL with raylib functions
  # Verify output
```

### Example-Based Tests

Run actual example files:
```bash
nim c -r examples/plugins/raylib_plugin.nim
nim c -r examples/plugins/raylib_example.nim
```

## Performance Considerations

### Compile-Time
- Plugin code compiled directly into binary
- No runtime overhead for plugin system itself
- Function calls use direct proc pointers

### Runtime
- Function lookup: O(1) via Table
- Constant access: O(1) via environment lookup
- No reflection or dynamic dispatch

### Memory
- Each plugin: ~few hundred bytes (metadata + tables)
- Functions: Only pointer storage
- Constants: Full Value objects in environment

## Security Considerations

### Current Model
- Plugins are trusted (compiled into application)
- No sandboxing needed
- No runtime code execution

### Future Considerations
If dynamic loading is added:
- Validate plugin signatures
- Sandbox plugin execution
- Resource limits
- Permission system

## Code Generation Support

**NEW**: Plugins now support code generation metadata for transpiling DSL to Nim.

Each plugin can specify:
- **Nim imports** required when generating code
- **Function mappings** from DSL names to Nim implementations
- **Constant mappings** from DSL constants to Nim values

Example:
```nim
let plugin = createMathPlugin()

# Runtime registration
plugin.registerFunc("sqrt", sqrtFunc)
plugin.registerConstantFloat("PI", 3.14159)

# Codegen registration
plugin.addNimImport("std/math")
plugin.mapFunction("sqrt", "sqrt")
plugin.mapConstant("PI", "PI")
```

This enables DSL code using plugin functions to be transpiled to native Nim:

```nim
# DSL code
var area = PI * radius * radius
var side = sqrt(area)

# Generated Nim code (with plugin mappings)
import std/math

var area = (PI * (radius * radius))
var side = sqrt(area)
```

See [CODEGEN.md](CODEGEN.md) for complete documentation.

## Future Enhancements

### Short Term
1. Standard library plugins (io, string, math)
2. More example plugins
3. Plugin documentation generator
4. Plugin testing utilities

### Medium Term
1. Namespace support in DSL
2. Plugin import syntax
3. Dependency resolution
4. Plugin versioning system
5. Enhanced codegen with type hints

### Long Term
1. Dynamic plugin loading
2. Custom AST node support
3. Plugin marketplace/registry
4. Hot-reloading for development
5. Incremental codegen and compilation

## API Reference

### Plugin Creation
```nim
newPlugin(name, author, version, description: string): Plugin
newPluginContext(env: ref Env): PluginContext
newPluginRegistry(): PluginRegistry
```

### Function Registration
```nim
registerFunc(plugin: Plugin; name: string; fn: NativeFunc)
```

### Constant Registration
```nim
registerConstant(plugin: Plugin; name: string; value: Value)
registerConstantInt(plugin: Plugin; name: string; value: int)
registerConstantFloat(plugin: Plugin; name: string; value: float)
registerConstantString(plugin: Plugin; name: string; value: string)
registerConstantBool(plugin: Plugin; name: string; value: bool)
```

### Node Registration
```nim
registerNode(plugin: Plugin; name, description: string)
```

### Lifecycle Hooks
```nim
setOnLoad(plugin: Plugin; hook: proc(ctx: PluginContext): void)
setOnUnload(plugin: Plugin; hook: proc(ctx: PluginContext): void)
```

### Codegen Registration
```nim
addNimImport(plugin: Plugin; module: string)
mapFunction(plugin: Plugin; dslName, nimCode: string)
mapConstant(plugin: Plugin; dslName, nimValue: string)
```

### Registry Management
```nim
initPluginSystem()
registerPlugin(registry: PluginRegistry; plugin: Plugin)
registerPlugin(plugin: Plugin)  # Use global registry
loadPlugin(registry: PluginRegistry; plugin: Plugin; env: ref Env)
loadPlugin(plugin: Plugin; env: ref Env)  # Use global registry
loadAllPlugins(registry: PluginRegistry; env: ref Env)
loadAllPlugins(env: ref Env)  # Use global registry
unloadPlugin(registry: PluginRegistry; name: string; env: ref Env)
```

### Introspection
```nim
hasPlugin(registry: PluginRegistry; name: string): bool
hasPlugin(name: string): bool  # Use global registry
getPlugin(registry: PluginRegistry; name: string): Plugin
getPlugin(name: string): Plugin  # Use global registry
listPlugins(registry: PluginRegistry): seq[string]
listPlugins(): seq[string]  # Use global registry
getPluginInfo(plugin: Plugin): PluginInfo
```

## Conclusion

The Nimini plugin architecture provides a clean, type-safe way to extend the DSL with custom functionality. The compile-time design ensures optimal performance and simplicity while leaving room for future enhancements like dynamic loading and custom AST nodes.

The architecture is validated through:
- Comprehensive test suite
- Working example plugins (raylib)
- Clean integration with existing runtime
- Minimal changes to core codebase

This foundation enables building rich, domain-specific languages on top of Nimini with native-level performance.
