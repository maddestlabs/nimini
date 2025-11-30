## Multi-Backend Code Generation Example
## Demonstrates how to generate code for multiple target languages from the same Nimini DSL

import ../src/nimini
import std/strutils

# Define a simple Nimini DSL program
let dslSource = """
# Simple program demonstrating various features
var x = 10
var y = 20

proc add(a: int, b: int):
  return a + b

var result = add(x, y)

for i in 1..5:
  var squared = i * i
  echo(squared)

if result > 25:
  echo(result)
elif result > 15:
  echo("Medium")
else:
  echo("Small")

while x > 0:
  x = x - 1
"""

echo "=" .repeat(70)
echo "Multi-Backend Code Generation Demo"
echo "=" .repeat(70)
echo ""

# Parse the DSL once
let tokens = tokenizeDsl(dslSource)
let program = parseDsl(tokens)

# Generate Nim code
echo "=== NIM OUTPUT ==="
echo "-" .repeat(70)
let nimBackend = newNimBackend()
let nimCode = generateCode(program, nimBackend)
echo nimCode
echo ""

# Generate Python code
echo "=== PYTHON OUTPUT ==="
echo "-" .repeat(70)
let pythonBackend = newPythonBackend()
let pythonCode = generateCode(program, pythonBackend)
echo pythonCode
echo ""

# Generate JavaScript code
echo "=== JAVASCRIPT OUTPUT ==="
echo "-" .repeat(70)
let jsBackend = newJavaScriptBackend()
let jsCode = generateCode(program, jsBackend)
echo jsCode
echo ""

echo "=" .repeat(70)
echo "✓ Successfully generated code for 3 different languages!"
echo "=" .repeat(70)

# You could also save the outputs to files:
# writeFile("output.nim", nimCode)
# writeFile("output.py", pythonCode)
# writeFile("output.js", jsCode)
