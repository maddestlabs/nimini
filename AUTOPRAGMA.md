# Automatic Function Registration with `{.nimini.}` Pragma

Nimini provides a convenient pragma-based system for registering native Nim functions with the scripting runtime. This eliminates boilerplate and makes it easy to expose Nim functions to your scripts.

## Overview

Instead of manually calling `registerNative` for each function:

```nim
# Old way - manual registration
initRuntime()
registerNative("hello", hello)
registerNative("greet", greet)
registerNative("add", add)
# ... repeat for every function
```

You can now mark functions with `{.nimini.}` and register them all at once:

```nim
# New way - pragma-based registration
proc hello(env: ref Env; args: seq[Value]): Value {.nimini.} =
  echo "Hello!"
  return valNil()

proc greet(env: ref Env; args: seq[Value]): Value {.nimini.} =
  echo "Hi there!"
  return valNil()

# Later in your code:
initRuntime()
exportNiminiProcs(hello, greet)  # Register all at once
```

## Usage

### 1. Import the autopragma module

```nim
import nimini
import nimini/autopragma
```

### 2. Mark your functions with `{.nimini.}`

The pragma marks functions that should be exposed to Nimini scripts. Functions must have the standard native function signature:

```nim
proc myFunction(env: ref Env; args: seq[Value]): Value {.nimini.} =
  # Your implementation
  return valNil()
```

### 3. Register marked functions

Use the `exportNiminiProcs` macro to register all marked functions:

```nim
initRuntime()
exportNiminiProcs(func1, func2, func3)
```

The macro automatically uses each function's name as its registration string.

## Complete Example

```nim
import nimini
import nimini/autopragma

# Define functions with {.nimini.} pragma
proc add(env: ref Env; args: seq[Value]): Value {.nimini.} =
  if args.len < 2:
    return valInt(0)
  return valInt(args[0].i + args[1].i)

proc multiply(env: ref Env; args: seq[Value]): Value {.nimini.} =
  if args.len < 2:
    return valInt(0)
  return valInt(args[0].i * args[1].i)

proc greet(env: ref Env; args: seq[Value]): Value {.nimini.} =
  if args.len > 0 and args[0].kind == vkString:
    echo "Hello, ", args[0].s, "!"
  else:
    echo "Hello, world!"
  return valNil()

# Initialize and register
when isMainModule:
  initRuntime()
  exportNiminiProcs(add, multiply, greet)
  
  # Now use them in scripts
  let script = """
    greet("Alice")
    let sum = add(10, 20)
    let product = multiply(5, 6)
  """
  
  let tokens = tokenizeDsl(script)
  let program = parseDsl(tokens)
  execProgram(program, runtimeEnv)
```

## Alternative Registration Methods

### Individual registration

You can also register functions individually:

```nim
proc myFunc(env: ref Env; args: seq[Value]): Value {.nimini.} =
  return valNil()

initRuntime()
registerNimini(myFunc)  # Automatic name detection
```

### Custom name registration

If you need a different name in scripts:

```nim
proc myLongFunctionName(env: ref Env; args: seq[Value]): Value {.nimini.} =
  return valNil()

initRuntime()
registerNimini("short", myLongFunctionName)
```

## Benefits

1. **Less Boilerplate**: No need to repeat function names in registration calls
2. **Self-Documenting**: The `{.nimini.}` pragma clearly marks which functions are exposed
3. **Type Safe**: Compile-time checking ensures functions have correct signatures
4. **Easy Maintenance**: Adding new functions is as simple as marking them with the pragma
5. **Flexible**: Works alongside manual `registerNative` calls when needed

## Function Signature Requirements

All functions marked with `{.nimini.}` must follow the standard native function signature:

```nim
proc functionName(env: ref Env; args: seq[Value]): Value
```

- **env**: Reference to the runtime environment
- **args**: Sequence of argument values passed from the script
- **return**: Must return a `Value` (use `valNil()`, `valInt()`, `valFloat()`, etc.)

## Best Practices

1. **Document your functions**: Use doc comments so users know what each function does
2. **Validate arguments**: Check `args.len` and argument types before use
3. **Return appropriate values**: Use the correct `val*` constructor for your return type
4. **Group related functions**: Register related functions together for clarity
5. **Keep it simple**: The pragma system works best with straightforward function definitions

## See Also

- [examples/autopragma_example.nim](examples/autopragma_example.nim) - Complete working example
- [Plugin System](PLUGIN_ARCHITECTURE.md) - For more complex registration scenarios
- [Runtime API](src/nimini/runtime.nim) - Core runtime and value types
