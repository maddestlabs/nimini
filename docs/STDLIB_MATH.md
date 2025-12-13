# Nimini Math and Type Conversion Standard Library

Nimini now includes a comprehensive standard library for mathematical operations and type conversions, making it perfect for game development, scientific computing, and general-purpose scripting.

## Quick Start

```nim
import nimini

# Initialize runtime with stdlib
initRuntime()
initStdlib()

# Now you can use all math functions and type conversions!
let code = """
var angle = 45.0
var radians = degToRad(angle)
var result = sin(radians) * cos(radians)
echo("Result: " & $result)
"""

execProgram(parseDsl(tokenizeDsl(code)), runtimeEnv)
```

## Available Functions

### Type Conversion Functions

| Function | Description | Example |
|----------|-------------|---------|
| `int(x)` | Convert to integer | `int(3.7)` → `3` |
| `float(x)` | Convert to float | `float(5)` → `5.0` |
| `bool(x)` | Convert to boolean | `bool(1)` → `true` |
| `str(x)` | Convert to string | `str(42)` → `"42"` |

### Trigonometric Functions

| Function | Description | Example |
|----------|-------------|---------|
| `sin(x)` | Sine of x (radians) | `sin(PI / 2)` → `1.0` |
| `cos(x)` | Cosine of x (radians) | `cos(0)` → `1.0` |
| `tan(x)` | Tangent of x (radians) | `tan(PI / 4)` → `1.0` |
| `arcsin(x)` | Arcsine (inverse sine) | `arcsin(1.0)` → `π/2` |
| `arccos(x)` | Arccosine (inverse cosine) | `arccos(0.0)` → `π/2` |
| `arctan(x)` | Arctangent (inverse tangent) | `arctan(1.0)` → `π/4` |
| `arctan2(y, x)` | Two-argument arctangent | `arctan2(1.0, 1.0)` → `π/4` |

### Exponential and Logarithmic Functions

| Function | Description | Example |
|----------|-------------|---------|
| `sqrt(x)` | Square root of x | `sqrt(16.0)` → `4.0` |
| `pow(x, y)` | x raised to power y | `pow(2.0, 3.0)` → `8.0` |
| `exp(x)` | e raised to power x | `exp(1.0)` → `2.718...` |
| `ln(x)` | Natural logarithm (base e) | `ln(E)` → `1.0` |
| `log10(x)` | Base-10 logarithm | `log10(100.0)` → `2.0` |
| `log2(x)` | Base-2 logarithm | `log2(8.0)` → `3.0` |

### Rounding and Absolute Value

| Function | Description | Example |
|----------|-------------|---------|
| `abs(x)` | Absolute value | `abs(-5.5)` → `5.5` |
| `floor(x)` | Round down to integer | `floor(3.7)` → `3.0` |
| `ceil(x)` | Round up to integer | `ceil(3.2)` → `4.0` |
| `round(x)` | Round to nearest integer | `round(3.5)` → `4.0` |
| `trunc(x)` | Truncate (round toward zero) | `trunc(-3.7)` → `-3.0` |

### Min/Max Functions

| Function | Description | Example |
|----------|-------------|---------|
| `min(a, b)` | Minimum of two values | `min(5.0, 3.0)` → `3.0` |
| `max(a, b)` | Maximum of two values | `max(5.0, 3.0)` → `5.0` |

### Hyperbolic Functions

| Function | Description | Example |
|----------|-------------|---------|
| `sinh(x)` | Hyperbolic sine | `sinh(0.0)` → `0.0` |
| `cosh(x)` | Hyperbolic cosine | `cosh(0.0)` → `1.0` |
| `tanh(x)` | Hyperbolic tangent | `tanh(0.0)` → `0.0` |

### Angle Conversion

| Function | Description | Example |
|----------|-------------|---------|
| `degToRad(deg)` | Degrees to radians | `degToRad(180.0)` → `π` |
| `radToDeg(rad)` | Radians to degrees | `radToDeg(PI)` → `180.0` |

## Mathematical Constants

Nimini provides these mathematical constants automatically:

| Constant | Value | Description |
|----------|-------|-------------|
| `PI` | 3.14159265... | The ratio of a circle's circumference to its diameter |
| `E` | 2.71828182... | Euler's number (base of natural logarithm) |
| `TAU` | 6.28318530... | 2π (full circle in radians) |

## Usage Examples

### Basic Trigonometry

```nim
var angle = 45.0
var radians = degToRad(angle)

echo("sin(" & $angle & "°) = " & $sin(radians))
echo("cos(" & $angle & "°) = " & $cos(radians))
echo("tan(" & $angle & "°) = " & $tan(radians))
```

### Circle Calculations

```nim
var radius = 5.0
var area = PI * pow(radius, 2.0)
var circumference = 2.0 * PI * radius

echo("Circle with radius " & $radius & ":")
echo("  Area = " & $area)
echo("  Circumference = " & $circumference)
```

### Distance Formula

```nim
var x1 = 0.0
var y1 = 0.0
var x2 = 3.0
var y2 = 4.0

var dx = x2 - x1
var dy = y2 - y1
var distance = sqrt(pow(dx, 2.0) + pow(dy, 2.0))

echo("Distance: " & $distance)  # Output: 5.0
```

### Type Conversions

```nim
var floatVal = 3.14
var intVal = 42
var strVal = "123"

echo("int(3.14) = " & $int(floatVal))      # 3
echo("float(42) = " & $float(intVal))      # 42.0
echo("int('123') = " & $int(strVal))       # 123
echo("float('3.14') = " & $float(strVal))  # 3.14
```

### Rounding Numbers

```nim
var num = 3.7

echo("Original: " & $num)
echo("floor: " & $floor(num))    # 3.0
echo("ceil: " & $ceil(num))      # 4.0
echo("round: " & $round(num))    # 4.0
echo("trunc: " & $trunc(num))    # 3.0
```

## For Raylib/Game Development

Perfect for game math:

```nim
# Normalize a vector
proc normalizeVector():
  var x = 3.0
  var y = 4.0
  var length = sqrt(pow(x, 2.0) + pow(y, 2.0))
  var normalizedX = x / length
  var normalizedY = y / length
  echo("Normalized: (" & $normalizedX & ", " & $normalizedY & ")")

# Rotate a point
proc rotatePoint():
  var x = 10.0
  var y = 0.0
  var angle = degToRad(90.0)
  
  var newX = x * cos(angle) - y * sin(angle)
  var newY = x * sin(angle) + y * cos(angle)
  
  echo("Rotated: (" & $newX & ", " & $newY & ")")

# Calculate projectile trajectory
proc projectileHeight():
  var v0 = 20.0  # Initial velocity
  var angle = degToRad(45.0)
  var t = 1.0    # Time
  var g = 9.8    # Gravity
  
  var height = v0 * sin(angle) * t - 0.5 * g * pow(t, 2.0)
  echo("Height: " & $height)
```

## Sequence Operations

Also available from `initStdlib()`:

| Function | Description | Example |
|----------|-------------|---------|
| `newSeq(size)` | Create array of given size | `newSeq(10)` |
| `add(arr, elem)` | Add element to array | `add(arr, 42)` |
| `len(arr)` | Get array length | `len(arr)` |
| `setLen(arr, n)` | Resize array | `setLen(arr, 20)` |
| `delete(arr, i)` | Delete element at index | `delete(arr, 5)` |
| `insert(arr, elem, i)` | Insert element at index | `insert(arr, 99, 0)` |

## Implementation Details

### How It Works

All stdlib functions are registered when you call `initStdlib()`:

```nim
import nimini

initRuntime()  # Initialize runtime environment
initStdlib()   # Register all stdlib functions
```

The stdlib is implemented in pure Nim using:
- `nimini/stdlib/mathops.nim` - Math functions
- `nimini/stdlib/typeconv.nim` - Type conversion functions
- `nimini/stdlib/seqops.nim` - Sequence/array operations

### Zero Dependencies

All math functions use Nim's built-in `std/math` module, which is available everywhere Nim runs. No external dependencies needed!

### Codegen Support

The stdlib functions work in both:
- **Interpreted mode** - Direct execution via `execProgram()`
- **Transpiled mode** - Code generation to Nim/Python/JavaScript

For codegen support, create extensions mapping your DSL functions to target language equivalents.

## Next Steps

- See [examples/stdlib_math_example.nim](../examples/stdlib_math_example.nim) for a complete example
- Check [tests/test_stdlib_math.nim](../tests/test_stdlib_math.nim) for test coverage
- Read [RAYLIB_NIMINI_ANALYSIS.md](../RAYLIB_NIMINI_ANALYSIS.md) for raylib integration guide

## Summary

With `initStdlib()`, nimini provides:
- ✅ 30+ math functions (trig, exponential, rounding, etc.)
- ✅ 4 type conversion functions
- ✅ 3 mathematical constants (PI, E, TAU)
- ✅ 6 sequence/array operations
- ✅ All working in both runtime and codegen modes
- ✅ Zero external dependencies

Perfect for game development, scientific computing, and educational programming!
