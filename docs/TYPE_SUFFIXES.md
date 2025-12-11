# Type Suffixes on Numeric Literals

Nimini now supports Nim-style type suffixes on numeric literals, allowing you to explicitly specify the type of integer and floating-point values.

## Overview

Type suffixes are specified using an apostrophe (`'`) followed by a type name:

```nim
var a = 123'i32      # 32-bit signed integer
var b = 3.14'f32     # 32-bit floating-point
var c = 255'u8       # 8-bit unsigned integer
```

This follows the Nim language specification for typed numeric literals.

## Supported Type Suffixes

### Integer Types

| Suffix | Type | Range |
|--------|------|-------|
| `'i8` | int8 | -128 to 127 |
| `'i16` | int16 | -32,768 to 32,767 |
| `'i32` | int32 | -2,147,483,648 to 2,147,483,647 |
| `'i64` | int64 | -9,223,372,036,854,775,808 to 9,223,372,036,854,775,807 |

### Unsigned Integer Types

| Suffix | Type | Range |
|--------|------|-------|
| `'u8` | uint8 | 0 to 255 |
| `'u16` | uint16 | 0 to 65,535 |
| `'u32` | uint32 | 0 to 4,294,967,295 |
| `'u64` | uint64 | 0 to 18,446,744,073,709,551,615 |

### Floating-Point Types

| Suffix | Type | Precision |
|--------|------|-----------|
| `'f32` | float32 | Single precision (32-bit) |
| `'f64` | float64 | Double precision (64-bit) |

## Usage Examples

### Basic Usage

```nim
# Integer literals with type suffixes
var smallNum = 42'i8
var mediumNum = 1000'i16
var largeNum = 999999999'i64

# Unsigned integers
var byte = 255'u8
var counter = 65535'u16

# Floating-point literals
var pi = 3.14159'f32
var precisePi = 3.14159265359'f64
```

### In Expressions

Type suffixes work in any expression context:

```nim
var digitSize = 100
var halfDigit = digitSize / 2'f32  # Force float division

var radius = 10'i32
var diameter = radius * 2'i32

var tolerance = 0.001'f64
var result = measurement + tolerance
```

### Mixed with Type Conversion

You can combine type suffixes with type conversion functions:

```nim
var x = 5'i32
var y = int64(x) + 100'i64  # Convert i32 to i64 and add
```

## Code Generation

### Nim Backend

Type suffixes are preserved in generated Nim code:

**DSL:**
```nim
var radius = 5'i32
var pi = 3.14'f32
```

**Generated Nim:**
```nim
var radius = 5'i32
var pi = 3.14'f32
```

### Python Backend

Python doesn't have type suffixes, so they are omitted (Python uses dynamic typing):

**DSL:**
```nim
var radius = 5'i32
var pi = 3.14'f32
```

**Generated Python:**
```python
radius = 5
pi = 3.14
```

### JavaScript Backend

JavaScript doesn't have type suffixes, so they are omitted (JavaScript uses dynamic typing):

**DSL:**
```nim
var radius = 5'i32
var pi = 3.14'f32
```

**Generated JavaScript:**
```javascript
let radius = 5;
let pi = 3.14;
```

## Runtime Behavior

In the Nimini interpreter, type suffixes are treated as metadata. The runtime stores the numeric value and the type suffix separately, but performs operations using Nim's native integer and float types.

```nim
var a = 100'i8    # Stored as int with suffix "i8"
var b = 200'i8    # Stored as int with suffix "i8"
var c = a + b     # Result is 300 (no overflow checking in runtime)
```

**Note:** The Nimini runtime does not enforce type bounds checking. Type suffixes are primarily for code generation purposes.

## Practical Examples

### Raylib-Style Code

Type suffixes are commonly used in graphics programming for precise type control:

```nim
var screenWidth = 800'i32
var screenHeight = 450'i32
var targetFPS = 60'i32

var posX = 100.0'f32
var posY = 50.0'f32
var speed = 5.0'f32

var alpha = 255'u8  # Color alpha channel
```

### Embedded Systems / Low-Level Code

When working with hardware or binary protocols, explicit types matter:

```nim
var deviceId = 0x42'u8       # 8-bit device identifier
var registerAddr = 0x10'u16  # 16-bit register address
var dataValue = 0xDEADBEEF'u32  # 32-bit data value
```

### Scientific Computing

Specify precision for numerical calculations:

```nim
var gravity = 9.81'f64          # High precision
var timestep = 0.016'f32        # Lower precision is fine
var earthRadius = 6371000'i64   # Meters (large integer)
```

## Comparison with Type Conversion

Type suffixes and type conversion serve different purposes:

**Type Suffixes** - Specify the type of a literal:
```nim
var x = 42'i32     # The literal 42 is explicitly i32
```

**Type Conversion** - Convert a value to a different type:
```nim
var x = 42         # x is int (default)
var y = int32(x)   # Convert x to i32
```

Both approaches work, but type suffixes are more concise and Nim-idiomatic.

## Implementation Details

### Tokenizer

The tokenizer recognizes type suffixes during numeric literal parsing:

1. Parse the numeric value (integer or float)
2. Check for an apostrophe (`'`)
3. If present, read the type suffix identifier
4. Store the complete lexeme including suffix

### Parser

The parser extracts the type suffix from the token:

1. Split the lexeme at the apostrophe
2. Parse the numeric part
3. Extract the suffix part
4. Create an AST node with both value and suffix

### AST

The AST stores type suffixes separately:

```nim
of ekInt:
  intVal*: int
  intTypeSuffix*: string  # e.g., "i32", "u8"

of ekFloat:
  floatVal*: float
  floatTypeSuffix*: string  # e.g., "f32", "f64"
```

### Code Generation

Code generation handles suffixes per backend:

- **Nim**: Append suffix to value (`123'i32`)
- **Python/JavaScript**: Omit suffix (not applicable)

## Testing

Run the type suffix example:

```bash
nim c -r examples/type_suffix_example.nim
```

This demonstrates:
- All supported type suffixes
- Type suffixes in expressions
- Cross-backend code generation
- Runtime execution

## Limitations

1. **No Runtime Type Checking**: The Nimini runtime does not enforce type bounds or overflow checking. Type suffixes are metadata for code generation.

2. **Backend-Specific**: Only the Nim backend generates type suffixes. Python and JavaScript backends ignore them due to dynamic typing.

3. **No Type Inference**: Type suffixes must be explicit. The interpreter doesn't infer types from suffixes.

## Best Practices

1. **Use Type Suffixes for Clarity**: When the specific type matters (graphics, embedded systems), use type suffixes.

2. **Prefer Defaults for General Code**: For typical arithmetic, the default `int` and `float` types are usually sufficient.

3. **Be Consistent**: If using type suffixes, use them consistently within a module.

4. **Consider Target Backend**: If targeting Python or JavaScript, type suffixes have no runtime effect.

## See Also

- [Nim Manual - Numeric Literals](https://nim-lang.org/docs/manual.html#lexical-analysis-numeric-literals)
- [examples/type_suffix_example.nim](../examples/type_suffix_example.nim)
- [Type System Documentation](TYPE_SYSTEM.md)
