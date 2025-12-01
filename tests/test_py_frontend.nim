# Tests for Python Frontend

import ../src/nimini
import std/[unittest, strutils]

suite "Python Frontend":
  
  test "Python frontend creation":
    let frontend = newPythonFrontend()
    check frontend.name == "Python"
    check ".py" in frontend.fileExtensions
    check frontend.supportsTypeAnnotations == true
  
  test "Python frontend singleton":
    let fe1 = getPythonFrontend()
    let fe2 = getPythonFrontend()
    check fe1 == fe2
  
  test "Parse simple Python variable":
    let pyCode = "x = 10"
    let program = compileSource(pyCode, getPythonFrontend())
    check program.stmts.len == 1
  
  test "Parse Python function with def":
    let pyCode = """
def add(a, b):
  return a + b
"""
    let program = compileSource(pyCode, getPythonFrontend())
    check program.stmts.len == 1
  
  test "Parse Python True/False":
    let pyCode = """
a = True
b = False
"""
    let program = compileSource(pyCode, getPythonFrontend())
    check program.stmts.len == 2
  
  test "Parse Python print as echo":
    let pyCode = """
x = 42
print(x)
"""
    let program = compileSource(pyCode, getPythonFrontend())
    check program.stmts.len == 2
  
  test "Parse Python if/elif/else":
    let pyCode = """
x = 15
if x > 20:
  print("big")
elif x > 10:
  print("medium")
else:
  print("small")
"""
    let program = compileSource(pyCode, getPythonFrontend())
    check program.stmts.len == 2
  
  test "Parse Python for loop":
    let pyCode = """
for i in range(1, 10):
  print(i)
"""
    let program = compileSource(pyCode, getPythonFrontend())
    check program.stmts.len == 1
  
  test "Parse Python while loop":
    let pyCode = """
x = 5
while x > 0:
  x = x - 1
"""
    let program = compileSource(pyCode, getPythonFrontend())
    check program.stmts.len == 2
  
  test "Parse Python lists":
    let pyCode = """
numbers = [1, 2, 3, 4, 5]
first = numbers[0]
"""
    let program = compileSource(pyCode, getPythonFrontend())
    check program.stmts.len == 2
  
  test "Parse Python boolean operators":
    let pyCode = """
result = True and False
result2 = True or False
result3 = not True
"""
    let program = compileSource(pyCode, getPythonFrontend())
    check program.stmts.len == 3
  
  test "Python to Nim codegen":
    let pyCode = """
def square(x):
  return x * x
result = square(5)
"""
    let program = compileSource(pyCode, getPythonFrontend())
    let nimCode = generateCode(program, newNimBackend())
    check nimCode.contains("proc")
    check nimCode.contains("square")
  
  test "Python to Python codegen":
    let pyCode = """
x = 10
y = 20
"""
    let program = compileSource(pyCode, getPythonFrontend())
    let pyOutput = generateCode(program, newPythonBackend())
    check pyOutput.contains("=")
  
  test "Python to JavaScript codegen":
    let pyCode = """
x = 10
y = 20
"""
    let program = compileSource(pyCode, getPythonFrontend())
    let jsCode = generateCode(program, newJavaScriptBackend())
    check jsCode.contains("=")
  
  test "Auto-detect Python by content":
    let pyCode = """
def test():
  print("hello")
"""
    let program = compileSource(pyCode)  # Auto-detect
    check program.stmts.len == 1
  
  test "Detect Python by filename":
    let pyCode = "x = 10"
    let program = compileSource(pyCode, filename="script.py")
    check program.stmts.len == 1
  
  test "Complex Python program":
    let pyCode = """
def factorial(n):
  if n <= 1:
    return 1
  else:
    return n * factorial(n - 1)

result = factorial(5)
print(result)
"""
    let program = compileSource(pyCode, getPythonFrontend())
    check program.stmts.len == 3
    
    # Test it generates to all backends
    let nimCode = generateCode(program, newNimBackend())
    let pyOutput = generateCode(program, newPythonBackend())
    let jsCode = generateCode(program, newJavaScriptBackend())
    
    check nimCode.len > 0
    check pyOutput.len > 0
    check jsCode.len > 0
  
  test "Python strings with escapes":
    let pyCode = """
text = "Hello\\nWorld"
"""
    let program = compileSource(pyCode, getPythonFrontend())
    check program.stmts.len == 1
  
  test "Python comments ignored":
    let pyCode = """
# This is a comment
x = 10  # inline comment
# Another comment
y = 20
"""
    let program = compileSource(pyCode, getPythonFrontend())
    check program.stmts.len == 2
  
  test "Python nested functions":
    let pyCode = """
def outer():
  def inner():
    return 42
  return inner()
"""
    let program = compileSource(pyCode, getPythonFrontend())
    check program.stmts.len == 1

when isMainModule:
  echo "Running Python Frontend Tests..."
