## Quick Python Frontend Demo
## Write Python, generate Nim/Python/JavaScript

import src/nimini
import std/strutils

# Python code
let pythonSource = """
def fibonacci(n):
  if n <= 1:
    return n
  return fibonacci(n - 1) + fibonacci(n - 2)

# Calculate fibonacci numbers
for i in range(1, 10):
  result = fibonacci(i)
  print(result)
"""

echo "Python Source Code:"
echo "=" .repeat(60)
echo pythonSource
echo ""

# Parse Python code
let program = compileSource(pythonSource, getPythonFrontend())

# Generate to all backends
echo "Generated Nim Code:"
echo "=" .repeat(60)
echo generateCode(program, newNimBackend())
echo ""

echo "Generated Python Code:"
echo "=" .repeat(60)
echo generateCode(program, newPythonBackend())
echo ""

echo "Generated JavaScript Code:"
echo "=" .repeat(60)
echo generateCode(program, newJavaScriptBackend())
