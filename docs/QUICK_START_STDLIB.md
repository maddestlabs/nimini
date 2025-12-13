# Quick Start: Nimini with Math Stdlib

## Three Steps to Get Started

### 1. Import and Initialize

```nim
import nimini

initRuntime()  # Initialize the runtime
initStdlib()   # ← Register all stdlib functions (math, type conversion, etc.)
```

### 2. Write Your Script

```nim
let gameScript = """
# Math functions work out of the box!
var angle = 45.0
var radians = degToRad(angle)
var result = sin(radians)

# Type conversions
var intValue = int(3.14)
var floatValue = float(42)

# Arrays
var data = newSeq(100)
for i in 0..<100:
  data[i] = int(sin(float(i) * PI / 50.0) * 100.0)

# Constants available: PI, E, TAU
var area = PI * pow(5.0, 2.0)

echo("Angle: " & $angle)
echo("Result: " & $result)
echo("Area: " & $area)
"""
```

### 3. Execute

```nim
let program = parseDsl(tokenizeDsl(gameScript))
execProgram(program, runtimeEnv)
```

## That's It!

Your scripts now have:
- ✅ 30+ math functions (sin, cos, sqrt, pow, abs, etc.)
- ✅ Type conversions (int, float, bool, str)
- ✅ Math constants (PI, E, TAU)
- ✅ Array operations (newSeq, add, len, etc.)

## Common Patterns

### Vector Math
```nim
var x = 3.0
var y = 4.0
var length = sqrt(pow(x, 2.0) + pow(y, 2.0))
var normalizedX = x / length
var normalizedY = y / length
```

### Rotation
```nim
var angle = degToRad(45.0)
var newX = x * cos(angle) - y * sin(angle)
var newY = x * sin(angle) + y * cos(angle)
```

### Clamping
```nim
var clamped = min(max(value, 0.0), 100.0)
```

### Sine Wave
```nim
var data = newSeq(512)
for i in 0..<512:
  var angle = 2.0 * PI * float(i) / 50.0
  data[i] = int(sin(angle) * 32000.0)
```

## Full Documentation

- [STDLIB_SUMMARY.md](STDLIB_SUMMARY.md) - Overview
- [docs/STDLIB_MATH.md](docs/STDLIB_MATH.md) - Complete reference
- [examples/stdlib_math_example.nim](examples/stdlib_math_example.nim) - Working examples

Happy scripting! 🚀
