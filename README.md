# Nimini (Mini Nim)

Nimini is a lightweight, embeddable scripting language built around [Nim](https://nim-lang.org/). Designed for interactive applications, games, and tools that need user-facing scripting without heavy dependencies.

Features:
- Zero external dependencies (Nim stdlib only)
- Familiar Python-like syntax with Nim keywords
- Simple native function binding API
- Event-driven architecture
- Automatic type conversion and error handling
- Compile-time plugin architecture
- DSL to Nim code generation (transpilation)
- Auto-registration to expose procedures with `{.nimini.}` pragma

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

# Initialize runtime
initRuntime()
registerNative("hello", nimHello)

# Parse and execute DSL code
let code = """
hello()
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

## Plugin System

Extend Nimini with custom functions and types:

```nim
let plugin = newPlugin("math", "Author", "1.0.0", "Math utilities")
plugin.registerFunc("sqrt", sqrtFunc)
plugin.registerConstantFloat("PI", 3.14159)

# Add codegen support for transpilation
plugin.addNimImport("std/math")
plugin.mapFunction("sqrt", "sqrt")
plugin.mapConstant("PI", "PI")

loadPlugin(plugin, runtimeEnv)
```

See [PLUGIN_ARCHITECTURE.md](PLUGIN_ARCHITECTURE.md) for details.

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