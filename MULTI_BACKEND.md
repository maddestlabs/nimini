# Multi-Backend Code Generation

Nimini now supports generating code for multiple target languages from the same DSL source. This makes it truly language-agnostic while maintaining your vision of a unified scripting solution.

## Overview

The multi-backend system allows you to:

1. **Write once, deploy anywhere**: Write your logic in Nimini DSL and generate native code for Nim, Python, JavaScript, or any future backend
2. **Create universal plugins**: Plugins can define mappings for all supported backends
3. **Maintain backward compatibility**: Existing Nim-only code continues to work unchanged
4. **Easy extensibility**: Adding new language backends requires only implementing a simple interface

## Supported Backends

| Backend | Status | File Extension | Features |
|---------|--------|----------------|----------|
| **Nim** | ✅ Fully supported | `.nim` | Original target, full feature support |
| **Python** | ✅ Fully supported | `.py` | Python 3+ with proper indentation |
| **JavaScript** | ✅ Fully supported | `.js` | ES6+ with modern syntax |

## Basic Usage

### Simple Multi-Backend Generation

```nim
import nimini

# Parse DSL once
let dslSource = """
var x = 10
var y = 20
var sum = x + y
echo(sum)
"""

let tokens = tokenizeDsl(dslSource)
let program = parseDsl(tokens)

# Generate for different backends
let nimCode = generateCode(program, newNimBackend())
let pythonCode = generateCode(program, newPythonBackend())
let jsCode = generateCode(program, newJavaScriptBackend())
```

### Backward Compatible API

Existing code continues to work:

```nim
let nimCode = generateNimCode(program)  # Still works!
```

## Universal Plugins

Create plugins that work across all backends:

```nim
proc createMathPlugin(): Plugin =
  result = newPlugin("math", "Author", "1.0.0", "Universal math plugin")

  # Runtime implementation (for interpreted execution)
  proc sqrtFunc(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
    return valFloat(sqrt(args[0].f))
  
  result.registerFunc("sqrt", sqrtFunc)
  result.registerConstantFloat("PI", PI)

  # Nim backend mappings
  result.addImportForBackend("Nim", "std/math")
  result.mapFunctionForBackend("Nim", "sqrt", "sqrt")
  result.mapConstantForBackend("Nim", "PI", "PI")

  # Python backend mappings
  result.addImportForBackend("Python", "math")
  result.mapFunctionForBackend("Python", "sqrt", "math.sqrt")
  result.mapConstantForBackend("Python", "PI", "math.pi")

  # JavaScript backend mappings
  result.mapFunctionForBackend("JavaScript", "sqrt", "Math.sqrt")
  result.mapConstantForBackend("JavaScript", "PI", "Math.PI")
```

## Backend API

Each backend implements these key methods:

```nim
type CodegenBackend = ref object of RootObj
  name: string
  fileExtension: string
  usesIndentation: bool

# Primitive values
method generateInt(backend: CodegenBackend; value: int): string
method generateFloat(backend: CodegenBackend; value: float): string
method generateString(backend: CodegenBackend; value: string): string
method generateBool(backend: CodegenBackend; value: bool): string

# Expressions
method generateBinOp(backend: CodegenBackend; left, op, right: string): string
method generateCall(backend: CodegenBackend; funcName: string; args: seq[string]): string

# Statements
method generateVarDecl(backend: CodegenBackend; name, value: string; indent: string): string
method generateIfStmt(backend: CodegenBackend; condition: string; indent: string): string
method generateForLoop(backend: CodegenBackend; varName, iterable: string; indent: string): string

# And more...
```

## Creating a New Backend

To add support for a new language:

1. Create `src/nimini/backends/my_backend.nim`
2. Implement `CodegenBackend` interface
3. Export from `src/nimini.nim`

Example skeleton:

```nim
import ../backend

type
  MyBackend* = ref object of CodegenBackend

proc newMyBackend*(): MyBackend =
  result = MyBackend(
    name: "MyLanguage",
    fileExtension: ".my",
    usesIndentation: true,  # or false for brace-based
    indentSize: 2
  )

method generateInt*(backend: MyBackend; value: int): string =
  result = $value

method generateVarDecl*(backend: MyBackend; name, value: string; indent: string): string =
  result = indent & "var " & name & " = " & value

# Implement all required methods...
```

## Language-Specific Features

### Nim
- Indentation-based syntax (`:`)
- Distinguishes `var` (mutable) and `let` (immutable)
- Native Nim operators and functions

### Python
- Python 3+ syntax with proper indentation
- Converts `var`/`let` to simple assignments (Python doesn't distinguish)
- Boolean values: `True`/`False`
- Function definitions use `def`

### JavaScript
- ES6+ with `let`/`const` distinction
- Brace-based blocks: `{ }`
- Boolean operators: `&&`, `||`, `!`
- Function definitions use `function`

## Complete Examples

### Example 1: Multi-Backend Generation

See `examples/multi_backend_example.nim` for a demonstration of generating code for all three backends from the same DSL source.

```bash
nim c -r examples/multi_backend_example.nim
```

### Example 2: Universal Plugin

See `examples/universal_plugin_example.nim` for a complete plugin that supports all backends.

```bash
nim c -r examples/universal_plugin_example.nim
```

## Migration Guide

### From Nim-Only to Multi-Backend

**Before:**
```nim
let nimCode = generateNimCode(program)
```

**After (backward compatible):**
```nim
# Still works!
let nimCode = generateNimCode(program)

# Or explicitly specify backend
let nimCode = generateCode(program, newNimBackend())
```

### Plugin Migration

**Before (Nim-only):**
```nim
plugin.addNimImport("std/math")
plugin.mapFunction("sqrt", "sqrt")
plugin.mapConstant("PI", "PI")
```

**After (backward compatible + multi-backend):**
```nim
# Old API still works for Nim backend
plugin.addNimImport("std/math")
plugin.mapFunction("sqrt", "sqrt")
plugin.mapConstant("PI", "PI")

# Add support for other backends
plugin.addImportForBackend("Python", "math")
plugin.mapFunctionForBackend("Python", "sqrt", "math.sqrt")
plugin.mapConstantForBackend("Python", "PI", "math.pi")
```

## Benefits

1. **Unified Logic**: Write your application logic once in Nimini DSL
2. **Language Freedom**: Deploy to any supported language without rewriting
3. **Plugin Portability**: Plugins work across all backends automatically
4. **Performance Paths**: 
   - Develop with interpreted runtime
   - Deploy as compiled Nim for max performance
   - Deploy as Python for integration with ML/data science
   - Deploy as JavaScript for web/Node.js deployment
5. **No Vendor Lock-in**: Not tied to a single language ecosystem

## Architecture

```
┌─────────────────┐
│   Nimini DSL    │
└────────┬────────┘
         │
    ┌────▼────┐
    │ Tokenizer│
    └────┬────┘
         │
    ┌────▼────┐
    │ Parser  │
    └────┬────┘
         │
    ┌────▼────┐
    │   AST   │  ◄── Language-agnostic
    └────┬────┘
         │
    ┌────▼──────────────┐
    │ Backend Interface │
    └────┬──────────────┘
         │
    ┌────▼────────────────────────┐
    │   Multiple Backends         │
    ├─────────┬──────────┬────────┤
    │   Nim   │  Python  │   JS   │
    └─────────┴──────────┴────────┘
         │         │         │
    ┌────▼────┬────▼────┬────▼────┐
    │.nim file│.py file │.js file │
    └─────────┴─────────┴─────────┘
```

## Future Backends

Potential future backends to consider:

- **C**: Maximum portability and performance
- **Lua**: Game engine integration
- **Go**: Microservices and cloud deployments
- **Rust**: Systems programming with safety
- **TypeScript**: Type-safe JavaScript
- **Ruby**: Scripting and web development

## Testing

Run the backward compatibility tests:

```bash
nim c -r tests/test_backend_compat.nim
```

This verifies that:
- Existing Nim codegen still works
- All backends generate valid code
- API changes are backward compatible

## API Reference

See the individual backend modules for detailed API documentation:
- `src/nimini/backend.nim` - Abstract backend interface
- `src/nimini/backends/nim_backend.nim` - Nim code generation
- `src/nimini/backends/python_backend.nim` - Python code generation
- `src/nimini/backends/javascript_backend.nim` - JavaScript code generation
