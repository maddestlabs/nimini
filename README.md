# Nimini (Mini Nim)

Nimini is a lightweight, embeddable scripting language that feels like Nim. Designed for interactive applications, games, and tools that need user-facing scripting without heavy dependencies.

Features:
- Zero external dependencies (Nim stdlib only)
- Familiar Python-like syntax with Nim keywords
- Simple native function binding API
- Event-driven architecture
- Automatic type conversion and error handling

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
nimble install nimini
```

Then in your `.nim` code:
```nim
import nimini
```

## History and Future

Nimini started in a markdown based story telling engine. It was decoupled for use with the terminal version of that same engine, so both engines share the same, core scripting functionality.

One of the larger goals of using Nim for scripting is that Nim's powerful macro system allows for compilation of the same code being used for scripting purposes. So users create apps and games in an engine using Nimini, then they relatively port that same Nim code directly to Nim for native compilation. They get all the speed, power and target platforms of native Nim after using Nim for prototyping.

Nimini's future is largely tied in to that use case. It's capable for quick and easy prototyping but provides a dead simple path to native compilation as well.

## Why not Nimscripter?

[Nimscripter](https://github.com/beef331/nimscripter) is awesome, but it's massive. Nimini is super simple and adds very little to compiled binaries.