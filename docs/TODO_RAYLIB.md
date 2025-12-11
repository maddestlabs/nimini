# Nimini Raylib Support - Required Features

This document outlines the Nim language features needed for Nimini to handle raylib examples like `digital_clock.nim`.

## Current Nimini Status

Nimini **already supports** many of the features needed:
- ✅ `const` declarations
- ✅ `defer` statements  
- ✅ `if`/`elif`/`else` control flow
- ✅ `while` loops
- ✅ `proc` definitions
- ✅ `var` declarations
- ✅ Type annotations (`TypeNode`)
- ✅ `case` statements
- ✅ `break` and `continue` statements

## Missing Features Required for digital_clock.nim

### 1. **Import Statements** (Critical) 🔴

**Example from digital_clock.nim:**
```nim
import raylib, std/[math, times]
```

**Current Status:** No AST node or parser support for imports

**Required Implementation:**
- Add `skImport` statement kind to `StmtKind`
- Add import statement AST node with module list
- Parser support for `import` keyword with comma-separated modules
- Support bracket notation for stdlib: `std/[module1, module2]`
- Codegen support for all backends (Nim, Python, JavaScript)

**AST Changes:**
```nim
type
  StmtKind* = enum
    # ... existing kinds ...
    skImport  # Import statement

  Stmt* = ref object
    # ... existing fields ...
    of skImport:
      importModules*: seq[string]  # List of modules to import
```

---

### 2. **Enum Type Definitions** (High Priority) 🟠

**Example from digital_clock.nim:**
```nim
type
  ClockMode = enum
    ModeNormal = 0
    ModeHandsFree
```

**Current Status:** 
- AST has basic `skType` statement but no enum-specific handling
- No `tkEnum` in `TypeKind`

**Required Implementation:**
- Add `tkEnum` to `TypeKind`
- Support enum value definitions with optional explicit ordinal values
- Enum value access in expressions (as identifiers)
- Enum comparison operations

**AST Changes:**
```nim
type
  TypeKind* = enum
    tkSimple, tkPointer, tkGeneric, tkProc,
    tkEnum,      # Enum type
    tkObject     # Object type

  TypeNode* = ref object
    case kind*: TypeKind
    # ... existing cases ...
    of tkEnum:
      enumValues*: seq[(string, Option[int])]  # (name, optional ordinal value)
    of tkObject:
      objectFields*: seq[(string, TypeNode)]    # (field name, field type)
```

---

### 3. **Object Type Definitions** (High Priority) 🟠

**Example from digital_clock.nim:**
```nim
type
  ClockHand = object
    value: int32
    origin: Vector2
    angle: float32
    length: int32
    thickness: int32
    color: Color
```

**Current Status:** 
- AST has `TypeNode` but no object field definitions
- See AST changes in Enum section above

**Required Implementation:**
- Add `tkObject` to `TypeKind`
- Object field list with names and types
- Field type declarations
- Support for both `object` and `ref object`

---

### 4. **Object Construction Expressions** (Critical) 🔴

**Example from digital_clock.nim:**
```nim
var myClock = Clock(
  mode: ModeNormal,
  second: ClockHand(
    angle: 45,
    length: 140,
    thickness: 3,
    color: Beige,
    value: 0,
    origin: Vector2(x: 0, y: 0)
  )
)
```

**Current Status:** No parser support for named field initialization syntax

**Required Implementation:**
- New `ExprKind` for object construction
- Named parameter syntax `field: value`
- Nested object construction
- Parser support for `Type(field1: val1, field2: val2)`

**AST Changes:**
```nim
type
  ExprKind* = enum
    # ... existing kinds ...
    ekObjConstr  # Object construction

  Expr* = ref object
    # ... existing fields ...
    of ekObjConstr:
      objType*: string                           # Type name (e.g., "Clock")
      objFields*: seq[(string, Expr)]            # (field name, field value)
```

---

### 5. **Dot Notation for Field Access** (Critical) 🔴

**Example from digital_clock.nim:**
```nim
clock.second.value
myClock.mode
centerPosition.x
clock.hour.angle
```

**Current Status:** No AST node for member access

**Required Implementation:**
- Add `ekDot` or `ekFieldAccess` expression kind
- Chained member access support (a.b.c)
- Assignment to fields: `obj.field = value`
- Codegen for all backends

**AST Changes:**
```nim
type
  ExprKind* = enum
    # ... existing kinds ...
    ekDot  # Field access (dot notation)

  Expr* = ref object
    # ... existing fields ...
    of ekDot:
      dotTarget*: Expr     # The object being accessed
      dotField*: string    # The field name
```

**Parser Example:**
```nim
# Parse: clock.second.value
# As: Dot(Dot(Ident("clock"), "second"), "value")
```

---

### 6. **Type Suffixes on Literals** ✅ (Implemented)

**Example from digital_clock.nim:**
```nim
DigitSize/2'f32
int32(centerPosition.x + ...)
```

**Status:** ✅ **IMPLEMENTED**

Type suffixes are now fully supported on numeric literals:
- Integer suffixes: `'i8`, `'i16`, `'i32`, `'i64`, `'u8`, `'u16`, `'u32`, `'u64`
- Float suffixes: `'f32`, `'f64`
- Examples: `123'i32`, `3.14'f32`, `255'u8`

**Implementation:**
- ✅ Tokenizer recognizes type suffixes (apostrophe followed by type name)
- ✅ Parser extracts and preserves type suffix information
- ✅ AST stores type suffixes on int and float literals
- ✅ Runtime handles typed literals (values are the same, suffix is metadata)
- ✅ Codegen outputs type suffixes for Nim backend
- ✅ Python and JavaScript backends ignore suffixes (not applicable)

**Example:**
```nim
var radius = 5'i32
var pi = 3.14'f32
var halfDigit = digitSize / 2'f32
```

**Note:** Type conversion functions also work: `int32(expr)`, `float32(expr)`

See [examples/type_suffix_example.nim](../examples/type_suffix_example.nim) for a complete demonstration.

---

### 7. **String Interpolation / Stringify Operator** (Medium Priority) 🟡

**Example from digital_clock.nim:**
```nim
drawText($clock.second.value, ...)  # $ is the stringify operator
```

**Current Status:** No `$` operator support

**Required Implementation:**
- Add `$` as unary operator in tokenizer/parser
- Runtime support for converting values to strings
- Codegen to appropriate string conversion per backend:
  - Nim: `$value`
  - Python: `str(value)`
  - JavaScript: `String(value)` or template literals

---

### 8. **Special Block Syntax / Templates** (Framework-Specific) 🟡

**Example from digital_clock.nim:**
```nim
drawing():
  clearBackground(RayWhite)
  drawCircle(400, 225, 5, Black)
```

**Current Status:** Can be handled as regular function call

**Notes:**
- `drawing():` is a Nim template that takes a code block
- Could be parsed as a function call with a lambda/callback parameter
- Alternatively, treat as special syntax sugar
- Not strictly necessary if templates are provided as native functions

**Possible Workaround:**
```nim
# Could rewrite as:
drawing(proc(): 
  clearBackground(RayWhite)
  drawCircle(400, 225, 5, Black)
)
```

---

### 9. **Procedure Parameter Modifiers** (Medium Priority) 🟡

**Example from digital_clock.nim:**
```nim
proc updateClock(clock: var Clock)  # var parameter for pass-by-reference
proc drawClock(clock: Clock, centerPosition: Vector2)  # value parameters
```

**Current Status:** No `var` parameter support in proc definitions

**Required Implementation:**
- Parser support for `var` modifier on parameters
- Track which parameters are `var` (mutable/by-reference)
- Codegen considerations per backend:
  - Nim: Native `var` support
  - Python: All objects are references anyway
  - JavaScript: Objects are references; may need special handling

**AST Changes:**
```nim
# Current: params: seq[(string, string)]  # (name, type)
# Updated: params: seq[(string, string, bool)]  # (name, type, isVar)
# Or better: params: seq[ProcParam]

type
  ProcParam* = object
    name*: string
    paramType*: string
    isVar*: bool  # true if `var` parameter
```

---

### 10. **Module-level Code / Main Pattern** (Low Priority) 🟢

**Example from digital_clock.nim:**
```nim
proc main() =
  # initialization
  initWindow(...)
  # main loop
  while not windowShouldClose():
    # game logic
  
main()  # Call at module level
```

**Current Status:** Nimini likely handles this through top-level statements already

**Note:** This pattern should already work in Nimini since it supports:
- Proc definitions at top level
- Expression statements at top level
- The `main()` call is just a function call

---

## Implementation Priority for Raylib Support

### Phase 1: Minimum Viable (Must Have) 🔴
These features are absolutely required for basic raylib examples:

1. **Import statements** - Can't use external libraries without this
2. **Object type definitions** - Most raylib types are objects
3. **Object construction & field access** - Creating and using raylib objects
4. **Enum definitions** - Many raylib constants are enums

### Phase 2: Highly Recommended 🟠
These features greatly improve usability:

5. **String interpolation (`$` operator)** - Common in Nim code
6. **`var` parameter modifiers** - Important for efficiency and semantics
7. **Type suffixes** - Or ensure type conversion functions work well

### Phase 3: Nice to Have 🟡
These features can be worked around:

8. **Special block syntax** - Can use callbacks or alternative syntax
9. **More complete enum support** - Ordinal operations (`ord()`, `succ()`, etc.)
10. **Named tuple support** - Currently tuples aren't fully supported

---

## Example Transformation

### Original Nim (digital_clock.nim):
```nim
import raylib

type
  ClockMode = enum
    ModeNormal, ModeHandsFree
  
  ClockHand = object
    value: int32
    angle: float32

var clock = ClockHand(value: 0, angle: 45.0)
clock.angle = 90.0
```

### What Nimini Needs to Support:
```nim
# 1. Import statement
import raylib

# 2. Enum definition
type ClockMode = enum
  ModeNormal
  ModeHandsFree

# 3. Object definition
type ClockHand = object
  value: int32
  angle: float32

# 4. Object construction
var clock = ClockHand(value: 0, angle: 45.0)

# 5. Field access (read and write)
clock.angle = 90.0
echo(clock.value)
```

---

## Notes on Existing Infrastructure

### What's Already in Place:
- **Type system foundation:** `TypeNode` with `TypeKind` enum exists
- **Type definitions:** `skType` statement exists for type declarations
- **Expression system:** Extensible `ExprKind` enum for new expression types
- **Statement system:** Extensible `StmtKind` enum for new statement types
- **Multi-backend codegen:** Architecture supports Nim, Python, JavaScript backends

### Architecture Benefits:
The existing multi-backend architecture means that once these features are added to the AST and parser:
- Each backend (Nim, Python, JavaScript) can generate appropriate code
- Core logic is language-independent
- Frontends (Nim, Python, JavaScript) can all benefit from these features

---

## Related TODO Items

From `docs/TODO.md`, the following are relevant:

- **Object types** (High Priority in TODO.md)
  - Object definitions with fields
  - Field access: `obj.fieldName`
  - Object construction

- **Enums** (High Priority in TODO.md)
  - Enum definitions: `type Color = enum red, green, blue`
  - Enum values and comparisons

- **Tuples** (High Priority in TODO.md)
  - Named tuples: `(name: "Bob", age: 30)`

These align perfectly with raylib support requirements!

---

## Testing Strategy

Once features are implemented, test with progressively complex raylib examples:

1. **Simple example:** Import raylib, create basic types
2. **Object construction:** Create raylib objects with field initialization
3. **Field access:** Read and modify object fields
4. **Full example:** digital_clock.nim or similar complete programs

---

## Summary

The most critical gap for raylib support is **object-oriented features**:
- Object type definitions
- Object construction with named fields
- Dot notation for field access
- Enum types

These are foundational features that would enable Nimini to handle not just raylib, but most structured Nim code that interacts with external libraries.

Import statements are also essential for modularity and library usage.

The good news is that the AST infrastructure is already extensible and well-designed to accommodate these features!
