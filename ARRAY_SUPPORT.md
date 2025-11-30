# Array and Indexing Support in Nimini

## Overview

Array literals and array indexing have been successfully implemented in Nimini, making it suitable for interacting with C libraries that heavily use arrays.

## Features Added

### 1. AST Support
- **`ekArray`**: Expression kind for array literals
- **`ekIndex`**: Expression kind for array indexing
- Constructor functions: `newArray()` and `newIndex()`

### 2. Tokenizer Support
- **`tkLBracket`**: `[` token
- **`tkRBracket`**: `]` token

### 3. Parser Support
- Array literals: `[1, 2, 3, 4, 5]`
- Array indexing: `arr[0]`, `arr[i+1]`
- Nested arrays: `[[1, 2], [3, 4]]`
- Chained indexing: `matrix[0][1]`

### 4. Code Generation
All three backends support array syntax:

**Nim Backend:**
```nim
let nums = @[1, 2, 3, 4, 5]
let first = nums[0]
```

**Python Backend:**
```python
nums = [1, 2, 3, 4, 5]
first = nums[0]
```

**JavaScript Backend:**
```javascript
const nums = [1, 2, 3, 4, 5];
const first = nums[0];
```

### 5. Runtime Support
- **`vkArray`**: New value type for arrays
- Full support for:
  - Creating arrays
  - Indexing with bounds checking
  - Nested arrays
  - Array expressions in all contexts

## Example Usage

```nim
# Array literals
let nums = [1, 2, 3, 4, 5]
let first = nums[0]
let last = nums[4]

# Array with expressions
var data = [10, 20, 30]
let doubled = data[1] * 2

# Nested arrays
let matrix = [[1, 2], [3, 4]]
let value = matrix[0][1]
```

## C Library Integration

This implementation is perfect for C library bindings because:

1. **Direct mapping**: Arrays in Nimini map directly to C arrays
2. **Index syntax**: Uses standard `array[index]` notation
3. **Multi-dimensional**: Supports nested arrays for multi-dimensional C arrays
4. **Expression support**: Indices can be any expression, not just literals

## Example C Library Interaction

```nim
# Calling C library functions with arrays
let imageData = [255, 128, 64, 32, 16]
let pixel = imageData[2]

# Multi-dimensional arrays for matrices
let transform = [[1.0, 0.0], [0.0, 1.0]]
let element = transform[0][1]
```

## Testing

Run the test suite:
```bash
nim c -r test_arrays.nim
```

This demonstrates:
- Parsing array syntax
- Code generation to all three backends
- Runtime execution with correct results

## Future Enhancements

Potential additions for enhanced C library support:
- Array slicing: `arr[1..3]`
- Array length: `arr.len`
- Array methods: `arr.push()`, `arr.pop()`
- Pointer syntax for C interop: `arr.addr`
