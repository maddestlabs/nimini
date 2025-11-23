# Nimini (Mini Nim)

Nimini is a lightweight, embeddable scripting language that feels like Nim. Designed for interactive applications, games, and tools that need user-facing scripting without heavy dependencies.

Features:
- Zero external dependencies (Nim stdlib only)
- Familiar Python-like syntax with Nim keywords
- Simple native function binding API
- Event-driven architecture
- Automatic type conversion and error handling
- Compile-time plugin architecture
- DSL to Nim code generation (transpilation)

Nimini trades some expressiveness for simplicity and ease of integration. If you need maximum power, consider Lua. If you want Nim-like familiarity with minimal dependencies, Nimini can help.

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

## Getting Started

```bash
nimble install https://github.com/maddestlabs/nimini
```

Then in your `.nim` code:
```nim
import nimini
```

## Code Generation

Nimini now includes a code generation system that transpiles DSL code to native Nim:

```nim
import nimini

# Your DSL code
let dslCode = """
var x = 10
var y = 20
var sum = x + y
"""

# Parse and generate Nim code
let prog = parseDsl(tokenizeDsl(dslCode))
let nimCode = generateNimCode(prog)

# Result: Native Nim code ready for compilation
writeFile("output.nim", nimCode)
```

See [CODEGEN.md](CODEGEN.md) for comprehensive documentation.

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

One of the larger goals of using Nim for scripting is that Nim's powerful macro system allows for compilation of the same code being used for scripting purposes. So users create apps and games in an engine using Nimini, then they relatively port that same Nim code directly to Nim for native compilation. They get all the speed, power and target platforms of native Nim after using Nim for prototyping.

**This is now a reality with Nimini's code generation system.** Write once in Nimini DSL, then:
1. **Prototype** with interpreted execution (fast iteration)
2. **Transpile** to Nim code (automated)
3. **Compile** with Nim (native performance)

Nimini provides a dead simple path to native compilation.

## Why not Nimscripter?

[Nimscripter](https://github.com/beef331/nimscripter) is awesome, but it's massive. Nimini is super simple and adds very little to compiled binaries.