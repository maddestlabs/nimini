# String Operations in Nimini

Nimini now supports comprehensive string handling with operations that work across all backends (Nim, Python, and JavaScript).

## Features

### 1. The `$` Stringify Operator

The `$` operator converts values to strings. It works with integers, floats, booleans, and other types.

**DSL Syntax:**
```nim
var num = 42
var str = $num  # Converts 42 to "42"
```

**Backend Code Generation:**
- **Nim:** `$(num)`
- **Python:** `str(num)`
- **JavaScript:** `String(num)`

**Example:**
```nim
var temperature = 25
echo "Temperature: " & $temperature & " degrees"
```

### 2. String Slicing

Extract substrings using range operators:
- `..` for inclusive ranges
- `..<` for exclusive ranges

**Inclusive Range (`..`):**
```nim
var text = "Hello, World!"
var hello = text[0..4]  # "Hello" (includes character at index 4)
```

**Exclusive Range (`..<`):**
```nim
var text = "Programming"
var prog = text[0..<4]  # "Prog" (excludes character at index 4)
```

**Backend Code Generation:**

For `text[0..4]`:
- **Nim:** `text[0..4]`
- **Python:** `text[0:4+1]`
- **JavaScript:** `text.slice(0, 4+1)`

For `text[0..<4]`:
- **Nim:** `text[0..<4]`
- **Python:** `text[0:4]`
- **JavaScript:** `text.slice(0, 4)`

### 3. String Length Property

Get the length of a string, array, or map using the `.len` property.

**Syntax:**
```nim
var name = "Nimini"
var length = name.len  # 6
```

**Backend Code Generation:**
- **Nim:** `name.len`
- **Python:** `len(name)`
- **JavaScript:** `name.length`

### 4. String Methods (with Method Call Syntax)

Common string methods are supported with cross-backend compatibility:

#### Case Conversion

```nim
var text = "Hello World"
var upper = text.toUpper()  # "HELLO WORLD"
var lower = text.toLower()  # "hello world"
```

**Backend Mappings:**
- `toUpper()`:
  - **Nim:** `.toUpper()`
  - **Python:** `.upper()`
  - **JavaScript:** `.toUpperCase()`

- `toLower()`:
  - **Nim:** `.toLower()`
  - **Python:** `.lower()`
  - **JavaScript:** `.toLowerCase()`

#### String Trimming

```nim
var padded = "   spaces   "
var trimmed = padded.strip()  # "spaces"
```

**Backend Mappings:**
- `strip()` / `trim()`:
  - **Nim:** `.strip()`
  - **Python:** `.strip()`
  - **JavaScript:** `.trim()`

#### Other String Methods

The following methods are also supported (implementation may vary by backend):
- `split(separator)` - Split string into array
- `join(separator)` - Join array elements into string
- `replace(old, new)` - Replace occurrences
- `contains(substring)` - Check if contains substring
- `startsWith(prefix)` - Check if starts with prefix
- `endsWith(suffix)` - Check if ends with suffix

## Complete Example

```nim
# String operations example
var message = "Hello, World!"
var num = 42

# Stringify operator
var numStr = $num
echo "Number: " & numStr

# String slicing (inclusive)
var hello = message[0..4]      # "Hello"
var world = message[7..11]     # "World"

# String slicing (exclusive)
var prog = "Programming"
var slice = prog[0..<4]        # "Prog"

# String length
var name = "Nimini"
var length = name.len
echo "Name length: " & $length

# Case conversion (with method call syntax)
var upper = message.toUpper()  # "HELLO, WORLD!"
var lower = message.toLower()  # "hello, world!"

# String trimming
var padded = "   text   "
var trimmed = padded.strip()   # "text"
```

## Runtime Support

All string operations work in both:
1. **Interpreted mode** - Executed directly by the Nimini runtime
2. **Transpiled mode** - Generated as backend-specific code

The runtime automatically handles:
- Type conversion for `$` operator
- Range-based slicing for strings and arrays
- Property access for `.len`
- String method calls (when implemented)

## Implementation Details

### Parser Changes
- `$` is recognized as a unary prefix operator
- Range operators (`..` and `..<`) work in index expressions
- Method call syntax (`object.method()`) is supported

### Runtime Changes
- Unary `$` operator evaluates to string conversion
- Range operators create special range values
- Index operations detect range values and perform slicing
- Dot access handles `.len` property for strings, arrays, and maps

### Code Generation Changes
- Backend-specific string conversion for `$` operator
- Smart slice syntax generation based on range inclusivity
- Cross-backend method name mapping for string operations

## Cross-Backend Compatibility Table

| Operation | Nim | Python | JavaScript |
|-----------|-----|--------|------------|
| `$value` | `$value` | `str(value)` | `String(value)` |
| `str[a..b]` | `str[a..b]` | `str[a:b+1]` | `str.slice(a, b+1)` |
| `str[a..<b]` | `str[a..<b]` | `str[a:b]` | `str.slice(a, b)` |
| `str.len` | `str.len` | `len(str)` | `str.length` |
| `str.toUpper()` | `str.toUpper()` | `str.upper()` | `str.toUpperCase()` |
| `str.toLower()` | `str.toLower()` | `str.lower()` | `str.toLowerCase()` |
| `str.strip()` | `str.strip()` | `str.strip()` | `str.trim()` |

## Testing

Run the example:
```bash
nim c -r examples/string_ops_demo.nim
```

This will show:
1. DSL code execution in the interpreter
2. Generated Nim code
3. Generated Python code
4. Generated JavaScript code

All backends produce equivalent functionality with backend-appropriate syntax.
