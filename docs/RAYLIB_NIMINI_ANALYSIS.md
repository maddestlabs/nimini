# Raylib Example Compatibility Analysis for Nimini

## Summary

**YES, this is doable!** The raylib audio streaming example can be implemented in nimini with minimal extensions. Nimini already supports ~95% of the required features.

## Currently Supported Features ✅

Nimini already handles all these features used in the raylib example:

1. **Variable Declarations**
   - ✅ `var` (mutable variables)
   - ✅ `const` (constants)
   - ✅ Module-level variables for global state

2. **Data Types**
   - ✅ `int`, `float`, `bool`, `string`
   - ✅ Arrays/sequences
   - ✅ Object types with fields

3. **Control Flow**
   - ✅ `if` statements
   - ✅ `while` loops
   - ✅ `for` loops with ranges: `for i in 0..10`, `for i in 0..<10`
   - ✅ `not` operator for boolean negation

4. **Arrays**
   - ✅ Array creation: `[1, 2, 3]`
   - ✅ Array indexing: `arr[i]`
   - ✅ Array assignment: `arr[i] = value`
   - ✅ Array length: `arr.len`

5. **Object Types**
   - ✅ Object type definitions
   - ✅ Object construction: `Vector2(x: 10.0, y: 20.0)`
   - ✅ Field access: `obj.x`, `obj.y`
   - ✅ Field assignment: `obj.x = 5.0`

6. **Expressions**
   - ✅ Arithmetic: `+`, `-`, `*`, `/`, `%`
   - ✅ Comparisons: `<`, `>`, `<=`, `>=`, `==`, `!=`
   - ✅ String concatenation: `&`
   - ✅ Type conversion with `$`: `$int(frequency)`

7. **Functions**
   - ✅ Procedure definitions
   - ✅ Parameters and return types
   - ✅ Calling native functions

## Required Extensions (Minimal) 🔧

These are the **only** features needed to fully support the raylib example:

### 1. Array Creation with Size (Easy - Native Function)

**Current:** Arrays created with literals `[1, 2, 3]`
**Needed:** Create array of specific size

**Solution:** Expose as native function in host app:

```nim
# In host Nim application:
proc newIntArray(env: ref Env; args: seq[Value]): Value {.nimini.} =
  let size = args[0].i
  var arr = newSeq[int](size)
  var values: seq[Value] = @[]
  for i in 0..<size:
    values.add(valInt(0))
  return valArray(values)

proc newFloatArray(env: ref Env; args: seq[Value]): Value {.nimini.} =
  let size = args[0].i
  var values: seq[Value] = @[]
  for i in 0..<size:
    values.add(valFloat(0.0))
  return valArray(values)

# Register with nimini
exportNiminiProcs(newIntArray, newFloatArray)
```

**Usage in nimini script:**
```nim
var data = newIntArray(512)
var writeBuf = newIntArray(4096)
```

### 2. Math Functions (Easy - Native Functions)

**Needed:** `sin()`, `cos()`, etc.

**Solution:** Expose as native functions:

```nim
import std/math

proc sin(env: ref Env; args: seq[Value]): Value {.nimini.} =
  return valFloat(math.sin(args[0].f))

proc cos(env: ref Env; args: seq[Value]): Value {.nimini.} =
  return valFloat(math.cos(args[0].f))

exportNiminiProcs(sin, cos)
```

### 3. Type Conversion Functions (Easy - Native or Parser Extension)

**Current:** Stringify with `$` works
**Needed:** `int()` and `float()` for explicit conversions

**Solution A - Native Functions:**
```nim
proc toInt(env: ref Env; args: seq[Value]): Value {.nimini.} =
  case args[0].kind
  of vkFloat: return valInt(int(args[0].f))
  of vkInt: return args[0]
  of vkString: return valInt(parseInt(args[0].s))
  else: return valInt(0)

proc toFloat(env: ref Env; args: seq[Value]): Value {.nimini.} =
  case args[0].kind
  of vkInt: return valFloat(float(args[0].i))
  of vkFloat: return args[0]
  of vkString: return valFloat(parseFloat(args[0].s))
  else: return valFloat(0.0)
```

**Solution B - Parser Extension (if you want `int(x)` syntax):**
Add special handling in parser for `int()` and `float()` as type conversion calls.

## Callback Handling Note ⚠️

The original example uses a C callback (`AudioInputCallback`). There are several ways to handle this:

### Option 1: Pre-computed Buffer (Recommended for Nimini)
Instead of callbacks, compute the audio buffer in the main loop:

```nim
# No callback needed - compute in main loop
if IsAudioStreamProcessed(stream):
  # Fill buffer here
  for i in 0..<MaxSamplesPerUpdate:
    writeBuf[i] = int(32000.0 * sin(2.0 * PI * sineIdx))
    sineIdx = sineIdx + (audioFrequency / 44100.0)
    if sineIdx > 1.0:
      sineIdx = sineIdx - 1.0
  UpdateAudioStream(stream, writeBuf)
```

### Option 2: Native Callback Wrapper
Have the host application handle the callback natively, exposing only the high-level functions to nimini.

### Option 3: Lambda Support (Already Supported!)
Nimini **already supports lambdas**, so you could potentially pass a lambda as a callback:

```nim
SetAudioStreamCallback(stream, proc():
  audioFrequency = frequency + (audioFrequency - frequency) * 0.95
  # ... rest of callback
)
```

This would require the native `SetAudioStreamCallback` function to handle nimini lambda values.

## What Nimini CANNOT Do (and doesn't need to)

These features are **not needed** for this example and would require compiler-level support:

❌ **C FFI / External library imports** - Not needed; raylib functions are exposed as native functions
❌ **Pointer manipulation** - Not needed; handled internally by native functions
❌ **Cast operations** - Not needed; type conversions handled by native functions
❌ **Pragmas** - Not needed; only used by host app for registration
❌ **Memory management** - Not needed; handled by runtime

## Implementation Strategy

Here's how to make this work:

### Step 1: Create Raylib Bindings Module

```nim
# raylib_bindings.nim
import nimini
import nimini/autopragma
import raylib
import std/math

# Window management
proc InitWindow(env: ref Env; args: seq[Value]): Value {.nimini.} =
  raylib.initWindow(args[0].i.int32, args[1].i.int32, args[2].s)
  return valNil()

proc CloseWindow(env: ref Env; args: seq[Value]): Value {.nimini.} =
  raylib.closeWindow()
  return valNil()

proc WindowShouldClose(env: ref Env; args: seq[Value]): Value {.nimini.} =
  return valBool(raylib.windowShouldClose())

# Drawing
proc BeginDrawing(env: ref Env; args: seq[Value]): Value {.nimini.} =
  raylib.beginDrawing()
  return valNil()

proc EndDrawing(env: ref Env; args: seq[Value]): Value {.nimini.} =
  raylib.endDrawing()
  return valNil()

proc ClearBackground(env: ref Env; args: seq[Value]): Value {.nimini.} =
  # Assuming color is passed as int (or expose Color object)
  raylib.clearBackground(raylib.Color(r: 245, g: 245, b: 245, a: 255))
  return valNil()

# Audio
proc InitAudioDevice(env: ref Env; args: seq[Value]): Value {.nimini.} =
  raylib.initAudioDevice()
  return valNil()

# ... more bindings ...

# Math functions
proc sin(env: ref Env; args: seq[Value]): Value {.nimini.} =
  return valFloat(math.sin(args[0].f))

# Array creation
proc newIntArray(env: ref Env; args: seq[Value]): Value {.nimini.} =
  let size = args[0].i
  var values: seq[Value] = @[]
  for i in 0..<size:
    values.add(valInt(0))
  return valArray(values)

# Export all at once
proc initRaylibBindings*() =
  initRuntime()
  exportNiminiProcs(
    InitWindow, CloseWindow, WindowShouldClose,
    BeginDrawing, EndDrawing, ClearBackground,
    InitAudioDevice,
    sin, newIntArray
    # ... all other functions
  )
```

### Step 2: Define Object Types in Nimini Script

```nim
# In your nimini script
type Vector2 = object
  x: float
  y: float
```

Or expose from host:

```nim
# In host app - register as type definition
proc registerVector2Type() =
  let typeCode = """
type Vector2 = object
  x: float
  y: float
"""
  execProgram(parseDsl(tokenizeDsl(typeCode)), runtimeEnv)
```

### Step 3: Run Your Nimini Script

```nim
# main.nim
import nimini
import raylib_bindings

initRaylibBindings()

let scriptCode = staticRead("raylib_game.nimini")
let program = parseDsl(tokenizeDsl(scriptCode))
execProgram(program, runtimeEnv)
```

## Conclusion

**This is absolutely doable!** The nimini scripting engine already has all the core features needed:

- ✅ All control flow structures
- ✅ Arrays with indexing
- ✅ Object types with field access
- ✅ Math expressions
- ✅ Native function calls
- ✅ Module-level variables

Only 2-3 simple native functions need to be added:
1. Array creation with size (`newIntArray`, `newFloatArray`)
2. Math functions (`sin`, `cos`)
3. Type conversions (`int`, `float`)

None of these require **any changes to nimini itself** - they're just native functions exposed through the existing `{.nimini.}` pragma system.

The key insight is that nimini doesn't need C interop because **the host application provides the raylib bindings**. Nimini scripts just call those pre-registered native functions.

This makes nimini an excellent choice for:
- Game scripting with raylib
- Hot-reloadable game logic
- User-created content/mods
- Live coding in games
- Educational game programming

The scripting layer handles high-level logic while the host app handles low-level graphics/audio via raylib.
