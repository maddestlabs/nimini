# Nimini Engine Guide for External Projects

This guide explains how to use the Nimini scripting engine in your Nim projects. Nimini is a lightweight, embeddable scripting language with Python-like syntax and Nim keywords, designed for easy integration into games, tools, and interactive applications.

## Installation

```bash
nimble install https://github.com/maddestlabs/nimini
```

Then import in your code:

```nim
import nimini
```

## Core Concepts

### 1. The Nimini Pipeline

Nimini processes scripts through a three-stage pipeline:

```
Source Code (String)
       ↓
   Tokenizer  → Tokens
       ↓
    Parser    → AST (Abstract Syntax Tree)
       ↓
   Executor   → Runtime Execution
```

Or optionally:

```
    Parser    → AST
       ↓
   Codegen    → Native Nim Code
       ↓
Nim Compiler  → Native Binary
```

### 2. Basic Workflow

```nim
import nimini

# 1. Initialize the runtime environment
initRuntime()

# 2. (Optional) Register native Nim functions
registerNative("myFunc", myNimFunction)

# 3. Tokenize your DSL source code
let tokens = tokenizeDsl(sourceCode)

# 4. Parse tokens into an AST
let program = parseDsl(tokens)

# 5. Execute the program
execProgram(program, runtimeEnv)
```

## Language Features

Nimini supports:

- **Variables**: `var x = 10` (mutable), `let y = 20` (immutable)
- **Types**: Integers, floats, booleans, strings, maps, functions
- **Operators**: `+`, `-`, `*`, `/`, `%`, `and`, `or`, `not`, comparisons
- **Control Flow**: `if`/`elif`/`else`, `while` loops, `for` loops
- **Functions**: `proc` definitions with parameters and return values
- **Ranges**: `1..10` (inclusive), `0..<10` (exclusive)
- **Native Bindings**: Call Nim functions from scripts

### Example Script

```nim
# Variables
var health = 100
let maxHealth = 100

# Functions
proc heal(amount):
  health = health + amount
  if health > maxHealth:
    health = maxHealth

# Control flow
if health < 50:
  heal(25)

# Loops
for i in 1..5:
  print("Tick:", i)

while health > 0:
  takeDamage(10)
```

## Exposing Nim Functions to Scripts

### Method 1: Auto-Registration with Pragma (Recommended)

The simplest way to expose Nim functions:

```nim
import nimini
import nimini/autopragma

# Mark functions with {.nimini.} pragma
proc hello(env: ref Env; args: seq[Value]): Value {.nimini.} =
  echo "Hello from Nim!"
  return valNil()

proc add(env: ref Env; args: seq[Value]): Value {.nimini.} =
  return valInt(args[0].i + args[1].i)

# Initialize and register all marked functions at once
initRuntime()
exportNiminiProcs(hello, add)

# Now use them in scripts
execProgram(parseDsl(tokenizeDsl("hello()")), runtimeEnv)
```

### Method 2: Manual Registration

More control over function names:

```nim
import nimini

proc myNimFunction(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
  # Access arguments
  let arg1 = args[0].i  # Integer
  let arg2 = args[1].s  # String
  
  # Return a value
  return valInt(42)

initRuntime()
registerNative("myFunction", myNimFunction)
```

### Native Function Signature

All native functions must follow this signature:

```nim
proc functionName(env: ref Env; args: seq[Value]): Value
```

- **env**: The runtime environment (for variable access)
- **args**: Sequence of argument values from the script
- **return**: Must return a `Value` object

### Working with Values

```nim
# Access value data by type
let intVal = args[0].i        # Int
let floatVal = args[0].f      # Float
let stringVal = args[0].s     # String
let boolVal = args[0].b       # Bool

# Check value type
if args[0].kind == vkInt:
  echo "It's an integer!"

# Create return values
return valNil()              # nil/void
return valInt(42)            # Integer
return valFloat(3.14)        # Float
return valString("hello")    # String
return valBool(true)         # Boolean
return valMap()              # Map/Dictionary
```

### Accessing Environment Variables

```nim
proc myFunc(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
  # Get a variable from the script
  let playerHealth = getVar(env, "health")
  
  # Set a variable in the script
  defineVar(env, "newVar", valInt(100))
  
  return valNil()
```

## Plugin System

For larger integrations, use the plugin system to bundle related functions, constants, and types.

### Creating a Plugin

```nim
import nimini

proc createMyPlugin(): Plugin =
  # Create plugin
  let plugin = newPlugin(
    name: "mygame",
    author: "Your Name",
    version: "1.0.0",
    description: "Game functions for Nimini"
  )
  
  # Register runtime functions
  proc damage(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
    echo "Taking ", args[0].i, " damage!"
    return valNil()
  
  plugin.registerFunc("damage", damage)
  
  # Register constants
  plugin.registerConstantInt("MAX_HEALTH", 100)
  plugin.registerConstantFloat("GRAVITY", 9.8)
  plugin.registerConstantString("VERSION", "1.0.0")
  
  return plugin

# Load the plugin
initRuntime()
let plugin = createMyPlugin()
registerPlugin(plugin)
loadPlugin(plugin, runtimeEnv)

# Now scripts can use: damage(50), MAX_HEALTH, etc.
```

### Plugin with Code Generation Support

If you want to transpile scripts to native Nim code:

```nim
proc createMyPlugin(): Plugin =
  let plugin = newPlugin("mygame", "Author", "1.0.0", "Game plugin")
  
  # Runtime function
  proc damage(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
    echo "Damage: ", args[0].i
    return valNil()
  
  plugin.registerFunc("damage", damage)
  plugin.registerConstantInt("MAX_HEALTH", 100)
  
  # Codegen mappings (for transpilation to Nim)
  plugin.addNimImport("mygame")  # Import needed for generated code
  plugin.mapFunction("damage", "mygame.damage")
  plugin.mapConstant("MAX_HEALTH", "mygame.MAX_HEALTH")
  
  return plugin
```

## Code Generation / Transpilation

Nimini can transpile DSL scripts to native Nim code for production deployment.

### Basic Transpilation

```nim
import nimini

# Your DSL code
let dslCode = """
var x = 10
var y = 20
var sum = x + y
"""

# Parse
let prog = parseDsl(tokenizeDsl(dslCode))

# Generate Nim code
let ctx = newCodegenContext()
let nimCode = generateNimCode(prog, ctx)

# Save to file
writeFile("output.nim", nimCode)

# Compile with: nim c -r output.nim
```

### Transpilation with Plugins

```nim
import nimini

# Create and register plugin
let plugin = createMyPlugin()
registerPlugin(plugin)

# Parse DSL
let prog = parseDsl(tokenizeDsl(dslCode))

# Generate Nim code with plugin mappings
let ctx = newCodegenContext()
loadPluginsCodegen(ctx)  # Load plugin codegen metadata
let nimCode = generateNimCode(prog, ctx)

writeFile("game.nim", nimCode)
```

The generated code will include proper imports and map DSL function calls to their native Nim implementations.

### Development Workflow

1. **Prototype**: Use interpreted execution for fast iteration
2. **Test**: Run scripts through the runtime for debugging
3. **Optimize**: Transpile to Nim code when ready for production
4. **Deploy**: Compile generated Nim code to native binary

## Complete Integration Example

Here's a full example integrating Nimini into a game:

```nim
import nimini
import nimini/autopragma

# Define your game API
var playerHealth = 100
var playerScore = 0

proc heal(env: ref Env; args: seq[Value]): Value {.nimini.} =
  let amount = args[0].i
  playerHealth = min(playerHealth + amount, 100)
  echo "Healed! Health: ", playerHealth
  return valNil()

proc damage(env: ref Env; args: seq[Value]): Value {.nimini.} =
  let amount = args[0].i
  playerHealth = max(playerHealth - amount, 0)
  echo "Damaged! Health: ", playerHealth
  return valNil()

proc addScore(env: ref Env; args: seq[Value]): Value {.nimini.} =
  let points = args[0].i
  playerScore += points
  echo "Score: ", playerScore
  return valInt(playerScore)

proc getHealth(env: ref Env; args: seq[Value]): Value {.nimini.} =
  return valInt(playerHealth)

# Initialize Nimini
initRuntime()
exportNiminiProcs(heal, damage, addScore, getHealth)

# Load and run a script
let scriptPath = "scripts/game_logic.nimini"
let scriptCode = readFile(scriptPath)

try:
  let tokens = tokenizeDsl(scriptCode)
  let program = parseDsl(tokens)
  execProgram(program, runtimeEnv)
except:
  echo "Script error: ", getCurrentExceptionMsg()
```

## Error Handling

Nimini will raise exceptions for:
- Syntax errors during parsing
- Undefined variables or functions
- Type mismatches
- Runtime errors in script execution

Wrap script execution in try/except blocks:

```nim
try:
  let tokens = tokenizeDsl(sourceCode)
  let program = parseDsl(tokens)
  execProgram(program, runtimeEnv)
except:
  echo "Error executing script: ", getCurrentExceptionMsg()
```

## Advanced Features

### Maps/Dictionaries

Scripts can use maps:

```nim
# In DSL script:
var player = {}
player.health = 100
player.name = "Hero"
```

Access from Nim:

```nim
let playerMap = getVar(env, "player")
let health = playerMap["health"]  # Access map key
```

### Custom Iterables

For loops work with:
- Range operators: `1..10`, `0..<5`
- Function calls: `range(1, 10)`
- Any expression that evaluates to an iterable

### Procedures in Scripts

Scripts can define their own functions:

```nim
proc fibonacci(n):
  if n <= 1:
    return n
  return fibonacci(n - 1) + fibonacci(n - 2)

let result = fibonacci(10)
```

## Performance Considerations

- **Interpreted**: Fast iteration, slower execution
- **Transpiled**: Near-native performance after compilation
- **Minimal overhead**: Zero external dependencies, small binary size
- **Compile-time plugins**: No runtime plugin loading overhead

## Best Practices

1. **Use auto-registration**: Simplifies function exposure with `{.nimini.}` pragma
2. **Validate arguments**: Always check `args.len` and types in native functions
3. **Return appropriate values**: Use correct `val*` constructors
4. **Document your API**: Use doc comments on native functions
5. **Organize with plugins**: Group related functionality into plugins
6. **Test both modes**: Verify scripts work in both interpreted and transpiled modes
7. **Handle errors**: Wrap script execution in try/except blocks
8. **Prototype first**: Use interpreted mode during development
9. **Transpile for production**: Generate native code for release builds

## Key Differences from Full Nim

Nimini is intentionally simplified:

- No static typing (runtime type checking only)
- No generics or templates
- No macro system
- No direct C/FFI access
- No module system
- Simpler expression syntax

These limitations make Nimini easier to embed and learn, while still providing familiar Nim-like syntax.

## API Quick Reference

### Initialization
- `initRuntime()` - Initialize the runtime environment
- `runtimeEnv` - Global runtime environment

### Parsing & Execution
- `tokenizeDsl(source: string): seq[Token]`
- `parseDsl(tokens: seq[Token]): Program`
- `execProgram(prog: Program; env: ref Env)`

### Registration
- `registerNative(name: string; fn: NativeFunc)`
- `exportNiminiProcs(procs...)`  - Auto-register pragma-marked procs

### Value Constructors
- `valNil()`, `valInt(i)`, `valFloat(f)`, `valString(s)`, `valBool(b)`, `valMap()`

### Environment Access
- `getVar(env: ref Env; name: string): Value`
- `defineVar(env: ref Env; name, value)`
- `setVar(env: ref Env; name, value)`

### Plugins
- `newPlugin(name, author, version, description): Plugin`
- `plugin.registerFunc(name, fn)`
- `plugin.registerConstant*(name, value)`
- `registerPlugin(plugin)` - Register for codegen
- `loadPlugin(plugin, env)` - Load into runtime

### Code Generation
- `newCodegenContext(): CodegenContext`
- `generateNimCode(prog: Program; ctx = nil): string`
- `loadPluginsCodegen(ctx)` - Load plugin mappings

## Troubleshooting

### "Undefined variable" errors
Make sure to initialize runtime before execution: `initRuntime()`

### Native function not found
Check that you've registered it: `registerNative("name", func)` or `exportNiminiProcs(...)`

### Type mismatch
Use `.kind` to check value types before accessing `.i`, `.f`, `.s`, etc.

### Codegen missing imports
Add required imports to plugin: `plugin.addNimImport("module")`

### Generated code doesn't compile
Ensure plugin mappings match actual Nim function signatures

## Resources

- **Examples**: See `examples/` directory in the repository
- **Tests**: Check `tests/` for comprehensive usage examples
- **Documentation**:
  - `AUTOPRAGMA.md` - Auto-registration system
  - `CODEGEN.md` - Code generation details
  - `LOOP_IMPLEMENTATION.md` - Loop syntax reference

## Summary

Nimini provides a lightweight scripting solution with three integration levels:

1. **Quick Start**: Use auto-registration pragma for simple function exposure
2. **Standard**: Manual registration for full control
3. **Advanced**: Plugin system with codegen support for production builds

Choose the level that fits your project's complexity. All approaches support the same DSL syntax and can be mixed as needed.

Happy scripting! 🎮✨
