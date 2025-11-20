# Nimini (Mini Nim)

Nimini is a lightweight, embeddable scripting language that feels like Nim. 
Designed for interactive applications, games, and tools that need user-facing 
scripting without heavy dependencies.

Features:
- Zero external dependencies (Nim stdlib only)
- Familiar Python-like syntax with Nim keywords
- Simple native function binding API
- Event-driven architecture
- Automatic type conversion and error handling

Nimini trades some expressiveness for simplicity and ease of integration. 
If you need maximum power, consider Lua. If you want Nim-like familiarity 
with minimal dependencies, Nimini is your tool.

🔌 Simple Integration
Register your Nim functions in 3 lines. Your DSL scripts call them like native 
functions. Type conversion handled automatically.

## Quick Example

```nim
import nimini

# Define a native function
proc dslHello(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
  echo "Hello from DSL!"
  valNil()

# Initialize runtime
initRuntime()
registerNative("hello", dslHello)

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
