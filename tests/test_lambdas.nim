## Test lambda and do notation support

import src/nimini

echo "=== Test 1: Simple Lambda Creation ==="
let code1 = """
var add = proc(a: int, b: int):
  return a + b

echo($add(3, 4))
"""
echo "Code:"
echo code1
try:
  initRuntime()
  execProgram(parseDsl(tokenizeDsl(code1)), runtimeEnv)
except:
  echo "Error: ", getCurrentExceptionMsg()
echo ""

echo "=== Test 2: Do Notation with Callback ==="
let code2 = """
proc withBlock(callback: int):
  echo("Before callback")
  callback()
  echo("After callback")

withBlock():
  echo("Inside the do block!")
"""
echo "Code:"
echo code2
try:
  initRuntime()
  execProgram(parseDsl(tokenizeDsl(code2)), runtimeEnv)
except:
  echo "Error: ", getCurrentExceptionMsg()
echo ""

echo "=== Test 3: Simple Lambda Variable ==="
let code3 = """
var greet = proc(name: string):
  echo("Hello, " & name & "!")

greet("World")
"""
echo "Code:"
echo code3
try:
  initRuntime()
  execProgram(parseDsl(tokenizeDsl(code3)), runtimeEnv)
except:
  echo "Error: ", getCurrentExceptionMsg()
echo ""

echo "=== Test 4: Lambda with Return Value ==="
let code4 = """
var multiply = proc(x: int, y: int): return x * y

var result = multiply(6, 7)
echo($result)
"""
echo "Code:"
echo code4
try:
  initRuntime()
  execProgram(parseDsl(tokenizeDsl(code4)), runtimeEnv)
except:
  echo "Error: ", getCurrentExceptionMsg()
echo ""

echo "All lambda tests completed!"
