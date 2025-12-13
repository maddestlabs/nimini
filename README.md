# Nimini (Mini Nim)

Nimini is a lightweight, embeddable scripting language built around [Nim](https://nim-lang.org/). Designed for interactive applications, games, and tools that need user-facing scripting without heavy dependencies.

Features:
- Zero external dependencies (Nim stdlib only)
- Familiar Python-like syntax with Nim keywords
- **Comprehensive math stdlib** (30+ functions, type conversions)
- **Lambda expressions** and **do notation** for functional programming
- Simple native function binding API
- Event-driven architecture
- Automatic type conversion and error handling
- DSL to Nim code generation (transpilation)
- Auto-registration to expose procedures with `{.nimini.}` pragma
- Codegen extensions for multi-backend transpilation

Nimini trades some expressiveness for simplicity and ease of integration. If you need maximum power, consider Lua. If you want Nim-like familiarity with minimal dependencies, Nimini can help.

## Quick Start

Easiest way to get started, with AI assistance from Claude:
https://claude.ai/share/9db417e6-e697-4995-920f-3192639c598a

Alternatively, provide any AI tool with this [AI QUICKSTART](https://github.com/maddestlabs/nimini/blob/main/docs/AI_QUICKSTART.md).

## Quick Example

```nim
import nimini

# Define a native function
proc nimHello(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
  echo "Hello from DSL!"
  valNil()

# Initialize runtime with stdlib
initRuntime()
initStdlib()  # Register math, type conversion, and sequence functions
registerNative("hello", nimHello)

# Parse and execute DSL code with math functions
let code = """
hello()
var radius = 5.0
var area = PI * pow(radius, 2.0)
echo("Circle area: " & $area)
"""
let tokens = tokenizeDsl(code)
let program = parseDsl(tokens)
execProgram(program, runtimeEnv)
```

That's it. Three lines of registration. Your DSL scripts call your Nim code.

## Auto-Registration with `{.nimini.}` Pragma

Even simpler - mark your functions and register them all at once:

```nim
import nimini
import nimini/autopragma

# Mark functions with {.nimini.} pragma
proc hello(env: ref Env; args: seq[Value]): Value {.nimini.} =
  echo "Hello from DSL!"
  return valNil()

proc add(env: ref Env; args: seq[Value]): Value {.nimini.} =
  return valInt(args[0].i + args[1].i)

# Register all marked functions at once
initRuntime()
exportNiminiProcs(hello, add)

# Use them in scripts
execProgram(parseDsl(tokenizeDsl("hello()")), runtimeEnv)
```

See [AUTOPRAGMA.md](AUTOPRAGMA.md) for full documentation.

## Getting Started

```bash
nimble install https://github.com/maddestlabs/nimini
```

Then in your `.nim` code:
```nim
import nimini
```

## Multi-Language Support

Nimini now supports **multiple input languages** and **multiple output backends**:

### Frontend Support (Input Languages)

Write your code in any supported language:

```nim
import nimini

# Option 1: Auto-detect language
let program = compileSource(myCode)

# Option 2: Explicit frontend
let program = compileSource(myCode, getNimFrontend())

# Option 3: Backward compatible
let program = parseDsl(tokenizeDsl(myCode))
```

**Currently supported:**
- ✅ **Nim** - Full support (default)
- 🔜 **JavaScript** - Coming soon
- 🔜 **Python** - Coming soon

See [FRONTEND.md](FRONTEND.md) for details.

### Backend Support (Output Languages)

Generate code for any backend:

```nim
import nimini

let program = compileSource(dslCode)

# Generate Nim code
let nimCode = generateCode(program, newNimBackend())

# Generate Python code
let pythonCode = generateCode(program, newPythonBackend())

# Generate JavaScript code
let jsCode = generateCode(program, newJavaScriptBackend())
```

**Cross-language compilation:**
- Write in Nim → Generate JS, Python, or Nim
- Write in JS (future) → Generate Nim, Python, or JS
- Write in Python (future) → Generate Nim, JS, or Python

See [MULTI_BACKEND.md](MULTI_BACKEND.md) for comprehensive documentation.

## Codegen Extensions

For transpilation, create codegen extensions to map your functions across backends:

```nim
# Runtime registration (use autopragma)
proc sqrt(env: ref Env; args: seq[Value]): Value {.nimini.} =
  return valFloat(sqrt(args[0].f))

initRuntime()
exportNiminiProcs(sqrt)
defineVar(runtimeEnv, "PI", valFloat(3.14159))

# Codegen extension for transpilation
let mathExt = newCodegenExtension("math")
mathExt.addNimImport("std/math")
mathExt.mapNimFunction("sqrt", "sqrt")
mathExt.mapNimConstant("PI", "PI")

# Multi-backend support
mathExt.addImport("Python", "math")
mathExt.mapFunction("Python", "sqrt", "math.sqrt")
mathExt.mapConstant("Python", "PI", "math.pi")

registerExtension(mathExt)
```

See [examples/universal_extension_example.nim](examples/universal_extension_example.nim) for a complete example.

## String Operations

Nimini provides comprehensive string handling with cross-backend support:

### Stringify Operator (`$`)

Convert any value to a string:
```nim
var num = 42
var str = $num  # "42"
echo "Value: " & $num
```

### String Slicing

Extract substrings using range operators:
```nim
var text = "Hello, World!"
var hello = text[0..4]   # "Hello" (inclusive)
var world = text[7..<12] # "World" (exclusive)
```

### String Properties and Methods

```nim
var name = "Nimini"
var length = name.len              # 6
var upper = name.toUpper()         # "NIMINI"
var lower = name.toLower()         # "nimini"
var trimmed = "  text  ".strip()   # "text"
```

All string operations work in both interpreted mode and transpiled code, generating appropriate backend-specific syntax. See [docs/STRING_OPERATIONS.md](docs/STRING_OPERATIONS.md) for complete documentation.

### Type Suffixes on Numeric Literals

Nimini supports Nim-style type suffixes for explicit type specification:

```nim
var radius = 5'i32          # 32-bit integer
var pi = 3.14'f32           # 32-bit float
var byte = 255'u8           # 8-bit unsigned
var precise = 2.718'f64     # 64-bit float

var halfSize = digitSize / 2'f32  # Force float division
```

**Supported suffixes:**
- Integer: `'i8`, `'i16`, `'i32`, `'i64`
- Unsigned: `'u8`, `'u16`, `'u32`, `'u64`
- Float: `'f32`, `'f64`

Type suffixes are preserved in Nim codegen, omitted in Python/JavaScript (dynamic typing). See [docs/TYPE_SUFFIXES.md](docs/TYPE_SUFFIXES.md) for full documentation.

### Lambda Expressions and Do Notation

Nimini supports full lambda expressions (anonymous procedures) with closure semantics:

```nim
# Lambda assigned to variable
var square = proc(x: int):
  return x * x

echo($square(5))  # 25

# Lambda passed as argument
proc runTwice(fn: int):
  fn()
  fn()

runTwice(proc():
  echo("Hello!")
)

# Do notation (syntactic sugar)
proc withBlock(callback: int):
  echo("Before")
  callback()
  echo("After")

withBlock():
  echo("Inside the do block!")
```

**Features:**
- Full statement blocks in lambda bodies
- Closure support (access to outer scope variables)
- Inline single-statement lambdas
- Do notation for cleaner callback syntax
- Works in both interpreted and transpiled code

See [docs/LAMBDA_SUPPORT.md](docs/LAMBDA_SUPPORT.md) for comprehensive documentation and examples.

## History and Future

Nimini started in a markdown based story telling engine. It was decoupled for use with the terminal version of that same engine, so both engines share the same, core scripting functionality.

One of the larger goals of using Nim for scripting is that Nim's powerful macro system allows for compilation of the same code being used for scripting purposes. So users create apps and games in an engine using Nimini, then they relatively easily port that same Nim code directly to Nim for native compilation. They get all the speed, power and target platforms of native Nim after using Nim for prototyping.

**This is becoming a reality with Nimini's code generation system.** Using Nimini:
1. **Prototype** with interpreted execution (fast iteration)
2. **Transpile** to Nim code (automated)
3. **Compile** with Nim (native performance)

Nimini provides a dead simple path to native compilation.

## Why not Nimscripter?

[Nimscripter](https://github.com/beef331/nimscripter) is awesome, but it's massive. Nimini is super simple and adds very little to compiled binaries.