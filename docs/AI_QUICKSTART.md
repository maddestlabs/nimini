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
- 🚧 **JavaScript** - In development
- 🚧 **Python** - In development

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

### 5. Plugin System
Extend Nimini with reusable plugins that provide:
- Runtime functions
- Constants
- Codegen mappings (for transpilation)
- Import declarations

### 6. Code Generation (Transpilation)
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

8. **`plugin.nim`** - Plugin system
   - `Plugin` - Plugin type
   - `newPlugin()` - Create plugin
   - `registerFunc()` - Add runtime function
   - `mapFunction()` - Add codegen mapping

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
- **`autopragma`** - Automatic function registration with `{.nimini.}` pragma

### Standard Library

- **`stdlib/seqops.nim`** - Sequence/array operations

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

### 5. Plugin System

```nim
import nimini
import std/math

let mathPlugin = newPlugin("math", "Author", "1.0.0", "Math utilities")

# Runtime function
proc sqrtFunc(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
  return valFloat(sqrt(args[0].f))

mathPlugin.registerFunc("sqrt", sqrtFunc)
mathPlugin.registerConstantFloat("PI", 3.14159)

# Codegen support
mathPlugin.addNimImport("std/math")
mathPlugin.mapFunction("sqrt", "sqrt")
mathPlugin.mapConstant("PI", "PI")

# Load plugin
initRuntime()
loadPlugin(mathPlugin, runtimeEnv)
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
- Add `{.gcsafe.}` pragma
- Handle argument validation (check `args.len`, `args[i].kind`)
- Return appropriate `Value` using constructors

### 2. Error Handling
- Check argument counts and types
- Return `valNil()` for errors (or custom error handling)
- Use runtime safety checks

### 3. Plugin Development
- Register runtime functions with `registerFunc()`
- Add codegen mappings with `mapFunction()`, `mapConstant()`
- Include necessary imports with `addNimImport()`

### 4. Multi-Language Features
- Use frontends for parsing different languages
- Use backends for generating different outputs
- AST is language-independent

### 5. Performance Optimization
- Use codegen/transpilation for production
- Runtime is for dynamic/interactive scenarios
- Plugin system allows extending both runtime and codegen

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
- **AUTOPRAGMA.md** - Auto-registration guide
- **examples/autopragma_example.nim** - Auto-registration example
- **examples/codegen_example.nim** - Code generation example
- **examples/plugin_example.nim** - Plugin system example

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
2. **GC safety**: Add `{.gcsafe.}` pragma to native functions
3. **Value access**: Always check `val.kind` before accessing fields like `val.i`, `val.s`
4. **Import paths**: The main module is `nimini`, submodules are `nimini/[module]`
5. **Frontend/Backend registration**: Must register frontends/backends before use

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
