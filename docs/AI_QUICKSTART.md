# Nimini Scripting Engine - AI Quick Start Guide

> **For Claude AI and other AI assistants**: This document provides comprehensive context about the Nimini scripting engine to help you provide excellent assistance to developers using this library.

## Project Overview

**Nimini** (Mini Nim) is a lightweight, embeddable scripting language built around Nim. It's designed for interactive applications, games, and tools that need user-facing scripting without heavy dependencies.

- **Repository**: https://github.com/maddestlabs/nimini
- **License**: MIT
- **Language**: Nim (requires Nim >= 1.6.0)
- **Dependencies**: Zero external dependencies (Nim stdlib only)

## Core Philosophy

Nimini trades some expressiveness for simplicity and ease of integration. Key design principles:

1. **Zero dependencies** - Only uses Nim's standard library
2. **Simple API** - Native function binding should be trivial
3. **Familiar syntax** - Python-like syntax with Nim keywords
4. **Embeddable** - Designed to be embedded in larger applications
5. **Multi-language** - Support for multiple input languages and output backends

## Key Features

### 1. Basic Scripting Runtime
- Interpreted DSL with runtime execution
- Python-like syntax (indentation-based, familiar operators)
- Dynamic typing with automatic conversions
- Function calls, variables, control flow, loops
- Native function binding from host application

### 2. Multi-Frontend Support (Input Languages)
Nimini can accept code written in different languages:
- ✅ **Nim** - Full support (default, native)
- 🚧 **JavaScript** - Stub implementation (planned)
- 🚧 **Python** - Stub implementation (planned)

All frontends compile to a universal AST, enabling cross-language features.

### 3. Multi-Backend Support (Output Languages)
Generate code for different target platforms:
- ✅ **Nim** - Full codegen support
- ✅ **Python** - Full codegen support
- ✅ **JavaScript** - Full codegen support

This enables **transpilation**: write in one language, output to another.

### 4. Auto-Registration with `{.nimini.}` Pragma
Mark Nim functions with a pragma for automatic registration:
```nim
proc myFunc(env: ref Env; args: seq[Value]): Value {.nimini.} =
  # implementation

exportNiminiProcs(myFunc)  # Auto-registers all marked functions
```

### 5. Codegen Extension System
Extend code generation with reusable extensions that map functions across backends:
- Runtime function registration via autopragma
- Multi-backend codegen mappings (Nim, Python, JavaScript)
- Import declarations per backend
- Constant mappings across languages

### 6. Advanced Language Features
- **Lambda expressions** with closure support
- **Tuples** (named and unnamed) with unpacking
- **Object types** with field access and construction
- **Enum types** with ordinal values
- **Case statements** with multiple values and elif branches
- **Type suffixes** on numeric literals (`'i32`, `'f64`, `'u8`, etc.)
- **String operations** (slicing, methods, interpolation with `$`)
- **Advanced loops** with labels, break/continue, multi-variable iteration
- **Defer statements** for cleanup code
- **Var parameters** for pass-by-reference

### 7. Code Generation (Transpilation)
Convert Nimini AST to native code in various languages for performance.

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                   Input Source Code                  │
│              (Nim, JS, Python syntax)                │
└─────────────────────┬───────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────┐
│                    Frontends                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │   Nim    │  │JavaScript│  │  Python  │          │
│  │ Frontend │  │ Frontend │  │ Frontend │          │
│  └──────────┘  └──────────┘  └──────────┘          │
└─────────────────────┬───────────────────────────────┘
                      │ tokenize() + parse()
                      ▼
┌─────────────────────────────────────────────────────┐
│              Universal AST (ast.nim)                 │
│   Expr, Stmt, Program - language-independent         │
└─────────────┬───────────────────┬───────────────────┘
              │                   │
              ▼                   ▼
┌───────────────────────┐  ┌──────────────────────────┐
│  Runtime Execution    │  │   Code Generation        │
│   (runtime.nim)       │  │   (codegen.nim)          │
│                       │  │                          │
│  • Interpret AST      │  │  • Generate source code  │
│  • Native functions   │  │  • Multiple backends:    │
│  • Dynamic values     │  │    - Nim                 │
│  • Event system       │  │    - Python              │
└───────────────────────┘  │    - JavaScript          │
                           └──────────────────────────┘
```

## Module Reference

### Core Modules

1. **`ast.nim`** - Abstract Syntax Tree definitions
   - `Expr` - Expression nodes (literals, operations, calls)
   - `Stmt` - Statement nodes (var, if, for, proc, etc.)
   - `Program` - Top-level program structure
   - `TypeNode` - Type annotations

2. **`tokenizer.nim`** - Lexical analysis
   - `Token` - Token type
   - `tokenizeDsl()` - Tokenize source code

3. **`parser.nim`** - Syntax analysis
   - `parseDsl()` - Parse tokens into AST

4. **`runtime.nim`** - Execution engine
   - `Value` - Runtime value types (int, float, string, bool, array, function, etc.)
   - `Env` - Variable environment
   - `initRuntime()` - Initialize runtime
   - `registerNative()` - Register native functions
   - `execProgram()` - Execute AST
   - `runtimeEnv` - Global environment

5. **`frontend.nim`** - Abstract frontend interface
   - `Frontend` - Base type for language frontends
   - `compile()` - Tokenize + parse in one step
   - `compileSource()` - Auto-detect and compile

6. **`backend.nim`** - Abstract backend interface
   - `CodegenBackend` - Base type for code generators
   - Methods for generating expressions, statements, control flow

7. **`codegen.nim`** - Code generation orchestration
   - `generateCode()` - Generate code from AST using a backend

8. **`codegen_ext.nim`** - Codegen extension system
   - `CodegenExtension` - Extension type for cross-backend mappings
   - `newCodegenExtension()` - Create extension
   - `addImport()` - Add backend-specific import
   - `mapFunction()` - Map function across backends
   - `mapConstant()` - Map constant across backends
   - `registerExtension()` - Register extension globally

9. **`import_analyzer.nim`** - Import analysis for target libraries
   - `FunctionMetadata` - Function metadata registry
   - `generateImportList()` - Generate required imports

### Frontend Implementations

- **`frontends/nim_frontend.nim`** - Nim syntax support
- **`frontends/js_frontend.nim`** - JavaScript syntax support (in development)
- **`frontends/py_frontend.nim`** - Python syntax support (in development)

### Backend Implementations

- **`backends/nim_backend.nim`** - Generate Nim code
- **`backends/python_backend.nim`** - Generate Python code
- **`backends/javascript_backend.nim`** - Generate JavaScript code

### Language Extensions

- **`lang/nim_extensions.nim`** - Nim-specific features
  - `nimini` pragma for auto-registration
  - `exportNiminiProcs()` macro for batch registration
  - `registerNimini()` helper functions

### Standard Library

- **`stdlib/seqops.nim`** - Sequence/array operations
  - `niminiAdd()` - Add element to sequence
  - `niminiLen()` - Get length
  - `niminiNewSeq()` - Create new sequence
  - `niminiSetLen()` - Set sequence length
  - `niminiDelete()` - Delete element
  - `niminiInsert()` - Insert element

## Common Use Cases & Code Examples

### 1. Basic Script Execution

```nim
import nimini

# Define native function
proc hello(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
  echo "Hello from DSL!"
  return valNil()

# Setup and execute
initRuntime()
registerNative("hello", hello)

let code = "hello()"
let tokens = tokenizeDsl(code)
let program = parseDsl(tokens)
execProgram(program, runtimeEnv)
```

### 2. Using Auto-Registration

```nim
import nimini
import nimini/autopragma

proc add(env: ref Env; args: seq[Value]): Value {.nimini.} =
  return valInt(args[0].i + args[1].i)

proc multiply(env: ref Env; args: seq[Value]): Value {.nimini.} =
  return valInt(args[0].i + args[1].i)

initRuntime()
exportNiminiProcs(add, multiply)  # Register all at once

execProgram(parseDsl(tokenizeDsl("let x = add(2, 3)")), runtimeEnv)
```

### 3. Multi-Frontend Compilation

```nim
import nimini

# Auto-detect language
let program = compileSource(sourceCode)

# Or specify explicitly
let program = compileSource(sourceCode, getNimFrontend())
let program = compileSource(sourceCode, getJsFrontend())
let program = compileSource(sourceCode, getPyFrontend())
```

### 4. Code Generation (Transpilation)

```nim
import nimini

let program = compileSource(dslCode)

# Generate different languages
let nimCode = generateCode(program, newNimBackend())
let pythonCode = generateCode(program, newPythonBackend())
let jsCode = generateCode(program, newJavaScriptBackend())
```

### 5. Codegen Extension System

```nim
import nimini
import std/math

# Define runtime functions with autopragma
proc sqrt(env: ref Env; args: seq[Value]): Value {.nimini.} =
  return valFloat(sqrt(args[0].f))

proc pow(env: ref Env; args: seq[Value]): Value {.nimini.} =
  return valFloat(pow(args[0].f, args[1].f))

# Initialize runtime
initRuntime()
exportNiminiProcs(sqrt, pow)
defineVar(runtimeEnv, "PI", valFloat(3.14159))

# Create codegen extension for transpilation
let mathExt = newCodegenExtension("math")

# Nim backend mappings
mathExt.addNimImport("std/math")
mathExt.mapNimFunction("sqrt", "sqrt")
mathExt.mapNimFunction("pow", "pow")
mathExt.mapNimConstant("PI", "PI")

# Python backend mappings
mathExt.addImport("Python", "math")
mathExt.mapFunction("Python", "sqrt", "math.sqrt")
mathExt.mapFunction("Python", "pow", "math.pow")
mathExt.mapConstant("Python", "PI", "math.pi")

# JavaScript backend mappings
mathExt.mapFunction("JavaScript", "sqrt", "Math.sqrt")
mathExt.mapFunction("JavaScript", "pow", "Math.pow")
mathExt.mapConstant("JavaScript", "PI", "Math.PI")

# Register extension
registerExtension(mathExt)

# Now you can transpile code using these functions
let program = compileSource("var x = sqrt(PI)")
echo generateCode(program, newPythonBackend())
```

## Native Function Signature

All native functions exposed to Nimini must follow this signature:

```nim
proc functionName(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
  # Implementation
  return someValue
```

- **`env: ref Env`** - Access to variable environment
- **`args: seq[Value]`** - Arguments passed from script
- **Returns `Value`** - Result value

### Value Type Reference

```nim
type ValueKind = enum
  vkNil, vkInt, vkFloat, vkBool, vkString,
  vkFunction, vkMap, vkArray, vkPointer

# Constructors
valNil()           # nil value
valInt(42)         # integer
valFloat(3.14)     # float
valBool(true)      # boolean
valString("text")  # string
valArray(@[...])   # array
```

### Accessing Value Fields

```nim
let val: Value = args[0]

case val.kind
of vkInt: echo val.i        # Access integer
of vkFloat: echo val.f      # Access float
of vkBool: echo val.b       # Access boolean
of vkString: echo val.s     # Access string
of vkArray: echo val.arr    # Access array (seq[Value])
of vkMap: echo val.map      # Access map (Table[string, Value])
else: discard
```

## Nimini DSL Syntax

The default Nimini syntax is Python-like with Nim keywords:

### Variables
```nim
let x = 10        # Immutable
var y = 20        # Mutable
const PI = 3.14   # Compile-time constant
```

### Control Flow
```nim
if condition:
  # code
elif other:
  # code
else:
  # code

case value
of 1, 2, 3:
  # Match multiple values
  echo("small number")
of 10:
  # Single value
  echo("ten")
elif value > 100:
  # Optional elif for range checks
  echo("large")
else:
  # Optional else branch
  echo("other")

for item in collection:
  # code

while condition:
  # code
```

### Functions
```nim
proc add(a, b):
  return a + b

let result = add(5, 3)
```

### Lambda Expressions
```nim
# Lambda assigned to variable
var square = proc(x: int):
  return x * x

# Lambda as argument
var result = map([1, 2, 3], proc(x): return x * 2)
```

### Tuples
```nim
# Unnamed tuples
let coords = (10, 20, 30)
let (x, y, z) = coords  # Unpacking

# Named tuples
let person = (name: "Alice", age: 25)
echo(person.name)
```

### Object Types
```nim
# Define object type
type Vector2 = object
  x: float
  y: float

# Construct object
var pos = Vector2(x: 10.0, y: 20.0)

# Access fields
var xCoord = pos.x
pos.y = 15.0
```

### Enums and Case Statements
```nim
# Define enum
type Color = enum
  Red = 0
  Green
  Blue

# Case statement with multiple values
case color
of Red, Green:
  echo("Warm colors")
of Blue:
  echo("Cool color")
elif brightness > 0.5:
  echo("Bright")
else:
  echo("Other")
```

### Advanced Loops
```nim
# Multi-variable iteration
for idx, item in array:
  echo(idx, ": ", item)

# Labeled loops with break
block outer:
  for i in 0..<10:
    for j in 0..<10:
      if condition:
        break outer
```

### String Operations
```nim
# String interpolation
var num = 42
var str = $num  # Convert to string

# String slicing
var text = "Hello"
var sub = text[0..2]    # "Hel" (inclusive)
var sub2 = text[0..<2]  # "He" (exclusive)

# String methods
var upper = text.toUpper()
var len = text.len
```

### Type Suffixes
```nim
var a = 123'i32      # 32-bit integer
var b = 3.14'f32     # 32-bit float
var c = 255'u8       # Unsigned 8-bit
```

### Defer and Cleanup
```nim
proc openFile():
  var file = open("data.txt")
  defer:
    file.close()
  # File automatically closed at scope exit
```

### Arrays and Indexing
```nim
let arr = [1, 2, 3, 4]
let first = arr[0]
arr[1] = 99
```

### Type Casting and Pointers
```nim
let ptr = cast[ptr int](someValue)
let addr = addr(variable)
let val = ptr[]  # Dereference
```

## Common Patterns for AI Assistance

When helping users with Nimini:

### 1. Creating Native Functions
- Always use the correct signature: `proc(env: ref Env; args: seq[Value]): Value`
- Add `{.gcsafe.}` pragma (or use `{.nimini.}` for autopragma)
- Handle argument validation (check `args.len`, `args[i].kind`)
- Return appropriate `Value` using constructors

### 2. Error Handling
- Check argument counts and types
- Return `valNil()` for errors (or custom error handling)
- Use runtime safety checks

### 3. Codegen Extension Development
- Register runtime functions with `exportNiminiProcs()` (autopragma)
- Create extension with `newCodegenExtension()`
- Add imports per backend with `addImport()` or `addNimImport()`
- Map functions with `mapFunction()` or `mapNimFunction()`
- Map constants with `mapConstant()` or `mapNimConstant()`
- Register with `registerExtension()`

### 4. Multi-Language Features
- Use frontends for parsing different languages (only Nim is fully implemented)
- Use backends for generating different outputs (Nim, Python, JS all work)
- AST is language-independent

### 5. Performance Optimization
- Use codegen/transpilation for production
- Runtime is for dynamic/interactive scenarios
- Extension system allows extending both runtime and codegen

## Project Structure

```
nimini/
├── src/
│   └── nimini/
│       ├── ast.nim              # AST definitions
│       ├── tokenizer.nim        # Lexer
│       ├── parser.nim           # Parser
│       ├── runtime.nim          # Interpreter
│       ├── frontend.nim         # Frontend interface
│       ├── backend.nim          # Backend interface
│       ├── codegen.nim          # Code generation
│       ├── plugin.nim           # Plugin system
│       ├── backends/            # Output backends
│       ├── frontends/           # Input frontends
│       ├── lang/                # Language extensions
│       └── stdlib/              # Standard library
├── examples/                    # Usage examples
├── tests/                       # Test suite
└── docs/                        # Documentation

```

## Important Files for Reference

- **README.md** - Project overview and quick start
- **AUTOPRAGMA.md** - Auto-registration guide with `{.nimini.}` pragma
- **LAMBDA_SUPPORT.md** - Lambda expression documentation
- **TUPLE_SUPPORT.md** - Tuple syntax and unpacking
- **OBJECT_TYPES_IMPLEMENTATION.md** - Object types and enum types
- **STRING_OPERATIONS.md** - String operations and methods
- **LOOP_FEATURES.md** - Advanced loop features (labels, multi-var)
- **TYPE_SUFFIXES.md** - Type suffixes on numeric literals
- **examples/autopragma_example.nim** - Auto-registration example
- **examples/codegen_example.nim** - Code generation example
- **examples/universal_extension_example.nim** - Multi-backend extension example
- **examples/lambda_showcase.nim** - Lambda expression examples
- **examples/object_example.nim** - Object type examples
- **examples/tuple_example.nim** - Tuple examples

## Installation & Building

```bash
# Install from GitHub
nimble install https://github.com/maddestlabs/nimini

# Or clone and develop
git clone https://github.com/maddestlabs/nimini
cd nimini
nimble install

# Run tests
nimble test

# Run examples
nimble example_autopragma
nimble example_codegen
```

## Debugging Tips

1. **Token inspection**: Use `tokenizeDsl()` separately to debug lexer
2. **AST inspection**: Print `program` after `parseDsl()` to see structure
3. **Runtime values**: Use `echo $value` to inspect Value objects
4. **Codegen output**: Check generated code for correctness

## Common Gotchas

1. **Native function signatures**: Must exactly match `proc(env: ref Env; args: seq[Value]): Value`
2. **GC safety**: Add `{.gcsafe.}` pragma to native functions (or use `{.nimini.}` with autopragma)
3. **Value access**: Always check `val.kind` before accessing fields like `val.i`, `val.s`
4. **Import paths**: The main module is `nimini`, submodules are `nimini/[module]`
5. **Frontend/Backend registration**: Nim frontend is auto-registered; only Nim frontend is fully implemented (JS/Python are stubs)
6. **Codegen extensions**: Must register extension with `registerExtension()` for codegen to use mappings
7. **Lambda syntax**: Use `proc(params): body` not `lambda` or `fn` keywords
8. **Tuple unpacking**: Requires `let` or `var` with parentheses: `let (x, y) = tuple`
9. **Type suffixes**: Use apostrophe: `123'i32` not `123i32`

## Links & Resources

- **GitHub**: https://github.com/maddestlabs/nimini
- **Claude Chat**: [Link back to this conversation for help]
- **Nim Language**: https://nim-lang.org/

## How to Use This Guide

When a user asks for help with Nimini:

1. **Identify the use case**: Runtime execution, codegen, plugins, frontends, etc.
2. **Reference relevant modules**: Point to the right `import` statements
3. **Provide complete examples**: Include all necessary boilerplate
4. **Validate signatures**: Ensure native functions match the required signature
5. **Test recommendations**: Suggest running examples from `examples/` directory
6. **Link to docs**: Reference specific documentation files when relevant

---

**This guide is maintained to help AI assistants provide accurate, helpful support for Nimini users. For the latest information, always refer to the repository at https://github.com/maddestlabs/nimini**
