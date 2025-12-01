## Frontend Abstraction Layer Example
## Demonstrates the new multi-language frontend system

import ../src/nimini
import std/strutils

echo "=" .repeat(70)
echo "Nimini Frontend Abstraction Layer Demo"
echo "=" .repeat(70)
echo ""

# Example 1: Backward Compatible - Using existing functions
echo "=== Example 1: Backward Compatible (existing API) ==="
echo "-" .repeat(70)
let nimCode1 = """
var x = 10
var y = 20
var sum = x + y
echo(sum)
"""

let tokens = tokenizeDsl(nimCode1)
let program1 = parseDsl(tokens)
echo "✓ Old API still works: ", program1.stmts.len, " statements parsed"
echo ""

# Example 2: Using the Nim Frontend explicitly
echo "=== Example 2: Using Nim Frontend Explicitly ==="
echo "-" .repeat(70)
let nimCode2 = """
proc add(a: int, b: int):
  return a + b

var result = add(5, 10)
"""

let nimFrontend = getNimFrontend()
let program2 = nimFrontend.compile(nimCode2)
echo "✓ Frontend: ", nimFrontend.name
echo "✓ Extensions: ", nimFrontend.fileExtensions.join(", ")
echo "✓ Type annotations: ", nimFrontend.supportsTypeAnnotations
echo "✓ Parsed: ", program2.stmts.len, " statements"
echo ""

# Example 3: Auto-detection (currently only Nim is registered)
echo "=== Example 3: Auto-Detection ==="
echo "-" .repeat(70)
let nimCode3 = """
for i in 1..5:
  var squared = i * i
  echo(squared)
"""

# Auto-detect and compile
let program3 = compileSource(nimCode3)
echo "✓ Auto-detected and compiled: ", program3.stmts.len, " statements"
echo ""

# Example 4: Detection by file extension
echo "=== Example 4: Detection by File Extension ==="
echo "-" .repeat(70)
let nimCode4 = """
let pi = 3.14159
var radius = 5.0
var area = pi * radius * radius
"""

let program4 = compileSource(nimCode4, filename="script.nim")
echo "✓ Detected by .nim extension: ", program4.stmts.len, " statements"
echo ""

# Example 5: Generate code to multiple backends from single source
echo "=== Example 5: Multi-Backend Output ==="
echo "-" .repeat(70)
let sourceCode = """
proc factorial(n: int):
  if n <= 1:
    return 1
  else:
    return n * factorial(n - 1)

var result = factorial(5)
echo(result)
"""

let program5 = compileSource(sourceCode)

echo "--- Nim Output ---"
let nimOutput = generateCode(program5, newNimBackend())
echo nimOutput
echo ""

echo "--- Python Output ---"
let pythonOutput = generateCode(program5, newPythonBackend())
echo pythonOutput
echo ""

echo "--- JavaScript Output ---"
let jsOutput = generateCode(program5, newJavaScriptBackend())
echo jsOutput
echo ""

# Example 6: Frontend information
echo "=== Example 6: Frontend Registry ==="
echo "-" .repeat(70)
let frontend = getNimFrontend()
echo "Registered frontend: ", frontend.name
echo "Supported extensions: ", frontend.fileExtensions
echo "Primary extension: ", frontend.getFileExtension()
echo "Supports .nim? ", frontend.supportsExtension(".nim")
echo "Supports .py? ", frontend.supportsExtension(".py")
echo ""

echo "=" .repeat(70)
echo "✓ Frontend abstraction layer working correctly!"
echo "✓ Ready for JavaScript and Python frontends to be added"
echo "=" .repeat(70)
