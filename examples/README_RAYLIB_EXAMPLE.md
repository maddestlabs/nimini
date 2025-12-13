# Raylib Audio Example with Nimini

This example demonstrates how to create a complete raylib application using nimini scripts with the enhanced math stdlib.

## What This Demonstrates

✅ **Complete raylib integration** - Window, drawing, input, and audio
✅ **Math stdlib in action** - sin(), PI, type conversions
✅ **Array operations** - newSeq(), array indexing and assignment
✅ **Real-time audio** - Sine wave generation and visualization
✅ **Interactive controls** - Mouse input for frequency and panning

## Files

- `test_raylib_nimini.nim` - The nimini script (pure scripting, no compilation)
- `raylib_audio_host.nim` - The Nim host application (exposes raylib to scripts)

## The Nimini Script

The script is written in pure nimini and uses:

```nim
# Built-in math functions from stdlib
var angle = 2.0 * PI * float(i) / float(waveLength)
data[i] = int(sin(angle) * 32000.0)

# Built-in type conversions
var freqText = "sine frequency: " & $int(frequency)

# Built-in array operations
var data = newSeq(MaxSamples)
```

**No compilation needed for the script!** It's interpreted at runtime.

## How It Works

### 1. The Host Application (Nim)

The host application (`raylib_audio_host.nim`):
- Imports nimini and raylib (naylib)
- Exposes raylib functions as native nimini functions using `{.nimini.}` pragma
- Initializes nimini runtime with stdlib (`initStdlib()`)
- Loads and executes the nimini script

### 2. The Script (Nimini)

The script (`test_raylib_nimini.nim`):
- Uses nimini's enhanced stdlib (sin, PI, int, float, newSeq, etc.)
- Calls raylib functions exposed by the host
- Implements the game/audio logic
- **Can be modified without recompiling the host!**

## Building and Running

### Prerequisites

```bash
# Install naylib (Nim raylib bindings)
nimble install naylib
```

### Compile the Host

```bash
cd examples
nim c -r raylib_audio_host.nim ../test_raylib_nimini.nim
```

Or specify a different script:

```bash
./raylib_audio_host my_custom_script.nim
```

## Hot Reloading

Since the script is interpreted, you can:

1. Run the host application
2. Modify `test_raylib_nimini.nim`
3. Restart the host (no recompilation needed!)

For true hot-reloading, you could extend the host to:
- Watch the script file for changes
- Reload and re-execute when modified
- Keep the raylib window open

## What Makes This Possible

### Nimini's Enhanced Stdlib

All these functions are built into nimini now:

**Math Functions (30+)**
- Trigonometric: sin, cos, tan, arcsin, arccos, arctan
- Exponential: sqrt, pow, exp, ln, log10, log2
- Rounding: abs, floor, ceil, round, trunc
- Utility: min, max, degToRad, radToDeg
- Hyperbolic: sinh, cosh, tanh

**Type Conversions**
- int(), float(), bool(), str()

**Constants**
- PI, E, TAU

**Array Operations**
- newSeq(), add(), len(), setLen(), delete(), insert()

### Simple Binding API

Exposing raylib to nimini is straightforward:

```nim
proc niminiInitWindow(env: ref Env; args: seq[Value]): Value {.nimini.} =
  let width = args[0].i.int32
  let height = args[1].i.int32
  let title = args[2].s
  initWindow(width, height, title)
  return valNil()

# Later, just call:
exportNiminiProcs(niminiInitWindow, ...)
```

## Extending This Example

### Add More Raylib Functions

Just create more `{.nimini.}` functions in the host:

```nim
proc niminiDrawCircle(env: ref Env; args: seq[Value]): Value {.nimini.} =
  let x = args[0].i.int32
  let y = args[1].i.int32
  let radius = toFloat(args[2]).float32
  drawCircle(x, y, radius, Red)
  return valNil()

# Register it
exportNiminiProcs(..., niminiDrawCircle)
```

Then use in your script:

```nim
DrawCircle(400, 300, 50.0)
```

### Create Custom Game Objects

Define object types in your script:

```nim
type Player = object
  x: float
  y: float
  speed: float
  health: int

var player = Player(x: 100.0, y: 100.0, speed: 5.0, health: 100)
```

### Implement Physics

Use the math stdlib:

```nim
# Gravity
var velocityY = 0.0
var gravity = 0.5

proc update():
  velocityY = velocityY + gravity
  player.y = player.y + velocityY
  
  # Collision with ground
  if player.y > 400.0:
    player.y = 400.0
    velocityY = -10.0  # Bounce
```

## Performance Considerations

**For prototyping and game logic**: Nimini is perfect!
- Event handlers
- Game state management
- UI logic
- Level scripting

**For performance-critical code**: Use native Nim
- Physics engines
- Rendering pipelines
- Audio processing
- AI pathfinding

**Best of both worlds**: Use nimini for high-level logic, native Nim for performance-critical systems.

## Comparison with Original

### Original (Native Nim with Raylib)
```nim
# Requires compilation
# Pointer manipulation
# C FFI knowledge
proc audioInputCallback(buffer: pointer; frames: uint32) {.cdecl.} =
  let d = cast[ptr UncheckedArray[int16]](buffer)
  for i in 0..<frames:
    d[i] = int16(32000'f32*sin(2*PI*sineIdx))
```

### Nimini Version
```nim
# No compilation of script
# No pointers
# Pure nimini syntax
for i in 0..<waveLength * 2:
  var angle = 2.0 * PI * float(i) / float(waveLength)
  data[i] = int(sin(angle) * 32000.0)
```

The nimini version is:
- ✅ Easier to understand
- ✅ Safer (no pointer manipulation)
- ✅ Hot-reloadable
- ✅ Scriptable by non-programmers
- ✅ Still performant for game logic

## Next Steps

1. **Try the example** - Build and run it
2. **Modify the script** - Change frequencies, colors, add features
3. **Extend the host** - Add more raylib functions
4. **Create your game** - Use this as a template

Happy scripting! 🎮
