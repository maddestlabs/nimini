# Nimini Code Generation

## Overview

Nimini includes a work-in-progress code generation system that transpiles Nimini DSL code to native [Nim](https://nim-lang.org/) code. This enables a smooth progression path:

1. **Prototype** with Nimini (interpreted, fast iteration)
2. **Transpile** to Nim (automated code generation)
3. **Compile** with Nim (native performance)

This aligns with Nimini's goal of being a "dead simple path to native compilation". Nim is a beautiful language built on powerful concepts. We want zero barriers to getting started with it, that's the larger purpose behind Nimini.

## Architecture

### Core Components

1. **codegen.nim** - Code generation engine
   - AST traversal and Nim code generation
   - Import management
   - Function and constant mapping
   - Context tracking

2. **Plugin Codegen Metadata** - Plugin integration
   - `CodegenMapping` type for each plugin
   - Import declarations
   - Function name mappings (DSL → Nim)
   - Constant value mappings (DSL → Nim)

### Code Generation Flow

```
Nimini DSL Source
       ↓
  Tokenizer
       ↓
    Parser
       ↓
   AST (Abstract Syntax Tree)
       ↓
  Codegen Context ← Plugin Metadata
       ↓
  Generated Nim Code
       ↓
  Nim Compiler
       ↓
  Native Binary
```

## Basic Usage

### Simple Code Generation

```nim
import nimini

# Parse DSL code
let dslCode = """
var x = 10
var y = 20
var sum = x + y
"""

let prog = parseDsl(tokenizeDsl(dslCode))

# Generate Nim code
let ctx = newCodegenContext()
let nimCode = generateNimCode(prog, ctx)

echo nimCode
# Output:
# var x = 10
# var y = 20
# var sum = (x + y)
```

### With Plugin Integration

```nim
import nimini

# Create a plugin with codegen support
proc createMathPlugin(): Plugin =
  result = newPlugin("math", "Author", "1.0.0", "Math functions")

  # Runtime function
  proc sqrtFunc(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
    return valFloat(sqrt(args[0].f))

  result.registerFunc("sqrt", sqrtFunc)
  result.registerConstantFloat("PI", 3.14159)

  # Codegen mappings
  result.addNimImport("std/math")
  result.mapFunction("sqrt", "sqrt")     # DSL sqrt → Nim sqrt
  result.mapConstant("PI", "PI")         # DSL PI → Nim PI

# Use the plugin
initRuntime()
let plugin = createMathPlugin()
registerPlugin(plugin)
loadPlugin(plugin, runtimeEnv)

# Parse DSL code that uses plugin functions
let dslCode = """
var radius = 5.0
var area = PI * radius * radius
var side = sqrt(area)
"""

let prog = parseDsl(tokenizeDsl(dslCode))

# Generate Nim code with plugin mappings
let ctx = newCodegenContext()
loadPluginsCodegen(ctx)  # Load all plugin codegen metadata
let nimCode = generateNimCode(prog, ctx)

echo nimCode
# Output:
# import std/math
#
# var radius = 5.0
# var area = (PI * (radius * radius))
# var side = sqrt(area)
```

## Plugin Codegen API

### Adding Import Declarations

```nim
plugin.addNimImport("std/math")
plugin.addNimImport("raylib")
plugin.addNimImport("std/strutils")
```

### Mapping Functions

Map DSL function names to their Nim implementations:

```nim
# Simple mapping (same name)
plugin.mapFunction("sqrt", "sqrt")

# Module-qualified mapping
plugin.mapFunction("InitWindow", "raylib.InitWindow")

# Different name mapping
plugin.mapFunction("print", "echo")
```

### Mapping Constants

Map DSL constants to their Nim values:

```nim
# Standard library constants
plugin.mapConstant("PI", "PI")
plugin.mapConstant("E", "E")

# Module-qualified constants
plugin.mapConstant("RED", "raylib.RED")
plugin.mapConstant("BLUE", "raylib.BLUE")

# Custom values
plugin.mapConstant("MAX_PLAYERS", "4")
```

## Complete Example: Raylib Plugin

```nim
import nimini

proc createRaylibPlugin(): Plugin =
  result = newPlugin(
    name: "raylib",
    author: "Your Name",
    version: "1.0.0",
    description: "Raylib bindings for Nimini"
  )

  # Register runtime functions (stubs shown)
  result.registerFunc("InitWindow", rlInitWindow)
  result.registerFunc("BeginDrawing", rlBeginDrawing)
  result.registerFunc("EndDrawing", rlEndDrawing)
  result.registerFunc("ClearBackground", rlClearBackground)
  result.registerFunc("DrawText", rlDrawText)
  result.registerFunc("CloseWindow", rlCloseWindow)

  # Register runtime constants
  result.registerConstant("RED", colorToValue(RED))
  result.registerConstant("BLUE", colorToValue(BLUE))
  result.registerConstant("WHITE", colorToValue(WHITE))

  # Codegen: Add required import
  result.addNimImport("raylib")

  # Codegen: Map functions to native raylib
  result.mapFunction("InitWindow", "raylib.InitWindow")
  result.mapFunction("BeginDrawing", "raylib.BeginDrawing")
  result.mapFunction("EndDrawing", "raylib.EndDrawing")
  result.mapFunction("ClearBackground", "raylib.ClearBackground")
  result.mapFunction("DrawText", "raylib.DrawText")
  result.mapFunction("CloseWindow", "raylib.CloseWindow")

  # Codegen: Map constants to native raylib
  result.mapConstant("RED", "raylib.RED")
  result.mapConstant("BLUE", "raylib.BLUE")
  result.mapConstant("WHITE", "raylib.WHITE")

# DSL game code
let gameCode = """
InitWindow(800, 600, "My Game")

for frame in range(0, 60):
  BeginDrawing()
  ClearBackground(BLUE)
  DrawText("Hello Nimini!", 100, 100, 20, WHITE)
  EndDrawing()

CloseWindow()
"""

# Setup and generate
initRuntime()
let plugin = createRaylibPlugin()
registerPlugin(plugin)

let prog = parseDsl(tokenizeDsl(gameCode))
let ctx = newCodegenContext()
loadPluginsCodegen(ctx)
let nimCode = generateNimCode(prog, ctx)

# Write to file
writeFile("game.nim", nimCode)

# Now compile with: nim c -r game.nim
```

## CodegenContext API

### Creating a Context

```nim
let ctx = newCodegenContext()
```

### Adding Imports Manually

```nim
ctx.addImport("std/math")
ctx.addImport("std/strutils")
```

### Adding Mappings Manually

```nim
ctx.addFunctionMapping("myDslFunc", "nim.realFunc")
ctx.addConstantMapping("MY_CONST", "42")
```

### Loading Plugin Metadata

```nim
# Load from global plugin registry
loadPluginsCodegen(ctx)

# Load from specific registry
let registry = newPluginRegistry()
loadPluginsCodegen(ctx, registry)

# Load specific plugin
applyPluginCodegen(myPlugin, ctx)
```

## Generated Code Characteristics

### Code Structure

The generated Nim code maintains the same semantics as the DSL:

- **Variables**: `var x = 42` → `var x = 42`
- **Constants**: `let pi = 3.14` → `let pi = 3.14`
- **Assignments**: `x = y + 1` → `x = (y + 1)`
- **If statements**: Proper indentation and structure
- **For loops**: Converted to Nim's `for i in start ..< end`
- **Proc definitions**: Standard Nim proc syntax
- **Function calls**: Direct or mapped calls

### Expressions

Expressions are wrapped in parentheses to ensure correct precedence:

```nim
# DSL
var result = a + b * c

# Generated Nim
var result = (a + (b * c))
```

### Control Flow

Control flow statements maintain Python-like indentation:

```nim
# DSL
if x > 5:
  var y = 10
elif x > 0:
  var y = 5
else:
  var y = 0

# Generated Nim
if (x > 5):
  var y = 10
elif (x > 0):
  var y = 5
else:
  var y = 0
```

## Testing Codegen

The test suite includes comprehensive codegen tests:

```nim
suite "Codegen Tests":
  test "generate code for simple variable"
  test "generate code for arithmetic"
  test "generate code for if statement"
  test "generate code for for loop"
  test "generate code for function call"
  test "generate code with function mapping"
  test "generate code with constant mapping"
  test "generate code with imports"
  test "plugin codegen integration"
  test "apply plugin codegen to context"
```

Run tests with:
```bash
nim c -r tests/tests.nim
```

## Workflow: From DSL to Native

### 1. Development Phase

Write and test with interpreted DSL:

```nim
import nimini

initRuntime()
let plugin = createMyPlugin()
loadPlugin(plugin, runtimeEnv)

let code = readFile("mygame.nimini")
let prog = parseDsl(tokenizeDsl(code))
execProgram(prog, runtimeEnv)  # Fast iteration
```

### 2. Optimization Phase

Generate native Nim code:

```nim
import nimini

let plugin = createMyPlugin()
registerPlugin(plugin)

let code = readFile("mygame.nimini")
let prog = parseDsl(tokenizeDsl(code))

let ctx = newCodegenContext()
loadPluginsCodegen(ctx)
let nimCode = generateNimCode(prog, ctx)

writeFile("mygame.nim", nimCode)
```

### 3. Production Phase

Compile and distribute:

```bash
nim c -d:release -o:mygame mygame.nim
./mygame  # Native performance!
```

## Best Practices

### Plugin Design

1. **Always provide codegen mappings** for production plugins
2. **Use qualified names** when mapping to external libraries
3. **Document required dependencies** in plugin description
4. **Test both runtime and codegen** paths

### Code Generation

1. **Keep DSL semantics simple** for easier transpilation
2. **Avoid runtime-specific features** that can't be transpiled
3. **Test generated code** before production use
4. **Review generated code** for optimization opportunities

### Performance Considerations

- **Development**: Use interpreted DSL for fast iteration
- **Testing**: Use interpreted DSL for quick feedback
- **Production**: Use generated Nim code for performance
- **Distribution**: Compile generated code to native binary

## Limitations

### Current Limitations

1. **No FFI types**: Complex C types require manual handling
2. **No macros**: Nim macro system not accessible from DSL
3. **Limited metaprogramming**: Static analysis not supported
4. **Manual plugin creation**: Plugins must be manually written

### Future Enhancements

1. **Type inference**: Better type mapping for generated code
2. **Optimization passes**: Dead code elimination, constant folding
3. **Error recovery**: Better handling of invalid DSL constructs
4. **Source maps**: Map generated Nim lines back to DSL source
5. **Interactive transpilation**: Real-time Nim code preview

## Examples

See the `examples/` directory for complete examples:

- `examples/codegen_example.nim` - Basic codegen demonstration
- `examples/plugins/raylib_plugin.nim` - Full plugin with codegen
- `examples/plugins/raylib_example.nim` - Using raylib plugin

## API Reference

### Core Functions

```nim
proc newCodegenContext(): CodegenContext
proc generateNimCode(prog: Program; ctx: CodegenContext = nil): string
proc genExpr(e: Expr; ctx: CodegenContext): string
proc genStmt(s: Stmt; ctx: CodegenContext): string
proc genProgram(prog: Program; ctx: CodegenContext): string
```

### Context Management

```nim
proc addImport(ctx: CodegenContext; module: string)
proc addFunctionMapping(ctx: CodegenContext; dslName, nimCode: string)
proc addConstantMapping(ctx: CodegenContext; dslName, nimCode: string)
```

### Plugin Integration

```nim
proc addNimImport(plugin: Plugin; module: string)
proc mapFunction(plugin: Plugin; dslName, nimCode: string)
proc mapConstant(plugin: Plugin; dslName, nimValue: string)
proc applyPluginCodegen(plugin: Plugin; ctx: CodegenContext)
proc loadPluginsCodegen(ctx: CodegenContext)
proc loadPluginsCodegen(ctx: CodegenContext; registry: PluginRegistry)
```

## Conclusion

The Nimini codegen system provides a seamless path from rapid prototyping to native performance. By maintaining plugin codegen metadata, you ensure that DSL code can always be transpiled to equivalent Nim code for production deployment.

This approach combines the best of both worlds:
- **Development speed** of interpreted scripting
- **Production performance** of native compilation
