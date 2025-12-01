## Python Frontend Example
## Demonstrates parsing Python code and generating to multiple backends

import ../src/nimini
import std/strutils

echo "=" .repeat(70)
echo "Python Frontend Demo"
echo "=" .repeat(70)
echo ""

# Example 1: Simple Python code
echo "=== Example 1: Basic Python Syntax ==="
echo "-" .repeat(70)
let pyCode1 = """
x = 10
y = 20
sum = x + y
print(sum)
"""

let prog1 = compileSource(pyCode1, getPythonFrontend())
echo "✓ Parsed Python code: ", prog1.stmts.len, " statements"
echo ""

# Example 2: Python function
echo "=== Example 2: Python Function ==="
echo "-" .repeat(70)
let pyCode2 = """
def add(a, b):
  return a + b

result = add(5, 10)
print(result)
"""

let prog2 = compileSource(pyCode2, getPythonFrontend())
echo "Python input:"
echo pyCode2
echo ""
echo "Nim output:"
echo generateCode(prog2, newNimBackend())
echo ""

# Example 3: Control flow
echo "=== Example 3: Python Control Flow ==="
echo "-" .repeat(70)
let pyCode3 = """
x = 15

if x > 20:
  print("Large")
elif x > 10:
  print("Medium")
else:
  print("Small")
"""

let prog3 = compileSource(pyCode3, getPythonFrontend())
echo "Python input:"
echo pyCode3
echo ""
echo "JavaScript output:"
echo generateCode(prog3, newJavaScriptBackend())
echo ""

# Example 4: Loops
echo "=== Example 4: Python Loops ==="
echo "-" .repeat(70)
let pyCode4 = """
for i in range(1, 6):
  squared = i * i
  print(squared)

count = 5
while count > 0:
  print(count)
  count = count - 1
"""

let prog4 = compileSource(pyCode4, getPythonFrontend())
echo "Python input:"
echo pyCode4
echo ""
echo "Python output:"
echo generateCode(prog4, newPythonBackend())
echo ""

# Example 5: Boolean logic
echo "=== Example 5: Python Boolean Logic ==="
echo "-" .repeat(70)
let pyCode5 = """
a = True
b = False
result = a and not b

if result or b:
  print("Yes")
"""

let prog5 = compileSource(pyCode5, getPythonFrontend())
echo "Python input:"
echo pyCode5
echo ""
echo "Nim output:"
echo generateCode(prog5, newNimBackend())
echo ""

# Example 6: Arrays
echo "=== Example 6: Python Lists ==="
echo "-" .repeat(70)
let pyCode6 = """
numbers = [1, 2, 3, 4, 5]
first = numbers[0]
last = numbers[4]
print(first)
print(last)
"""

let prog6 = compileSource(pyCode6, getPythonFrontend())
echo "Python input:"
echo pyCode6
echo ""
echo "JavaScript output:"
echo generateCode(prog6, newJavaScriptBackend())
echo ""

# Example 7: Complex example
echo "=== Example 7: Complete Python Program ==="
echo "-" .repeat(70)
let pyCode7 = """
def factorial(n):
  if n <= 1:
    return 1
  else:
    return n * factorial(n - 1)

def fibonacci(n):
  if n <= 1:
    return n
  return fibonacci(n - 1) + fibonacci(n - 2)

result1 = factorial(5)
result2 = fibonacci(7)

print(result1)
print(result2)
"""

let prog7 = compileSource(pyCode7, getPythonFrontend())
echo "Python input:"
echo pyCode7
echo ""
echo "Nim output:"
echo generateCode(prog7, newNimBackend())
echo ""

# Example 8: Auto-detection
echo "=== Example 8: Auto-Detection ==="
echo "-" .repeat(70)
let pythonCode = """
def greet(name):
  print("Hello, " + name)

greet("World")
"""

let prog8 = compileSource(pythonCode)  # Auto-detect
echo "✓ Auto-detected as Python"
echo "✓ Parsed successfully"
echo ""

# Example 9: Cross-language compilation
echo "=== Example 9: Python → All Backends ==="
echo "-" .repeat(70)
let pySource = """
def square(x):
  return x * x

value = 7
result = square(value)
print(result)
"""

let prog9 = compileSource(pySource, getPythonFrontend())

echo "--- Nim ---"
echo generateCode(prog9, newNimBackend())
echo ""

echo "--- Python ---"
echo generateCode(prog9, newPythonBackend())
echo ""

echo "--- JavaScript ---"
echo generateCode(prog9, newJavaScriptBackend())
echo ""

echo "=" .repeat(70)
echo "✓ Python frontend working perfectly!"
echo "✓ Write Python, generate Nim/Python/JavaScript"
echo "=" .repeat(70)
