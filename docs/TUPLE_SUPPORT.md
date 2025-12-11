# Tuple Support in Nimini

This document describes the tuple support added to Nimini, a lightweight Nim-inspired DSL.

## Overview

Tuples in Nimini are heterogeneous storage containers that can hold multiple values of different types. They follow the Nim tuple semantics and support both named and unnamed tuples.

## Features

### 1. Unnamed Tuples

Simple tuples with positional elements:

```nim
let coordinates = (10, 20, 30)
let mixed = (1, "hello", true, 3.14)
```

### 2. Named Tuples

Tuples with labeled fields for better readability:

```nim
let person = (name: "Alice", age: 25, city: "NYC")
let point = (x: 10, y: 20, z: 30)
```

### 3. Tuple Unpacking

Destructuring tuples into individual variables:

```nim
# Unpacking unnamed tuples
let (x, y, z) = coordinates

# Unpacking from function calls
proc getDimensions(): (int, int) =
  return (1920, 1080)

let (width, height) = getDimensions()
```

### 4. Special Cases

- **Empty tuple**: `let empty = ()`
- **Single element tuple**: `let single = (42,)` (requires trailing comma)
- **Nested tuples**: `let matrix = ((1, 2), (3, 4))`
- **Trailing commas**: `let numbers = (1, 2, 3,)` (allowed)

## Implementation Details

### AST Changes

Added `ekTuple` expression kind to support tuple literals:

```nim
type
  ExprKind* = enum
    # ... existing kinds ...
    ekTuple  # Tuple literal (1, 2, 3) or (name: "Bob", age: 30)

  Expr* = ref object
    # ... existing fields ...
    of ekTuple:
      tupleElements*: seq[Expr]
      tupleFields*: seq[tuple[name: string, value: Expr]]
      isNamedTuple*: bool
```

### Parser Changes

- Modified parentheses parsing to distinguish between:
  - Parenthesized expressions: `(expr)`
  - Single-element tuples: `(expr,)`
  - Multi-element tuples: `(expr1, expr2, ...)`
  - Named tuples: `(field1: expr1, field2: expr2, ...)`

- Added tuple unpacking support in `var` and `let` statements:
  ```nim
  let (x, y, z) = getTuple()
  var (a, b) = (1, 2)
  ```

### Code Generation

Tuple literals generate Nim-compatible tuple syntax:

```nim
# Unnamed tuple
(1, "hello", true)

# Named tuple
(name: "Bob", age: 30)

# Tuple unpacking
let (x, y) = getTuple()
```

### Runtime Support

- Unnamed tuples are represented as arrays (`vkArray`)
- Named tuples are represented as maps/tables (`vkMap`)
- Tuple unpacking extracts elements and assigns them to individual variables

## Examples

See the following example files:

- `examples/tuple_example.nim` - Comprehensive examples of all tuple features
- `examples/tuple_demo.nim` - Executable demo with output
- `examples/tuple_codegen_test.nim` - Code generation test
- `tests/test_tuples.nim` - Unit tests for tuple functionality

## Usage

```nim
import nimini

# Parse Nimini code with tuples
let code = """
let point = (x: 10, y: 20)
let (a, b) = (1, 2)
"""

let tokens = tokenizeDsl(code)
let prog = parseDsl(tokens)

# Generate Nim code
let ctx = newCodegenContext()
let nimCode = genProgram(prog, ctx)
```

## Limitations

- Tuple type annotations are not yet supported in unpacking: `let (x: int, y: string) = ...`
- Const unpacking is not supported: `const (x, y) = ...`

## Future Enhancements

Potential improvements for tuple support:

1. Tuple type declarations: `type Point = tuple[x: int, y: int]`
2. Tuple indexing: `myTuple[0]`, `myTuple[1]`
3. Field access for named tuples: `person.name`, `person.age`
4. Tuple iteration
5. Type-safe unpacking with type annotations

## Testing

Run the tuple tests:

```bash
nim c -r tests/test_tuples.nim
```

Run the demo:

```bash
nim c -r examples/tuple_demo.nim
```
