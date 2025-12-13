## Test new features: string interpolation, var params, do notation

import ../nimini

echo "Starting tests..."
echo ""

echo "=== Test 1: String Interpolation ($) ==="
let code1 = """
var x = 42
var message = "Hello"
echo($x)
echo($message)
"""
echo "Code:"
echo code1
try:
  initRuntime()
  execProgram(parseDsl(tokenizeDsl(code1)), runtimeEnv)
except:
  echo "Error: ", getCurrentExceptionMsg()
echo ""

echo "=== Test 2: Var Parameters ==="
let code2 = """
proc increment(var x: int):
  x = x + 1

var counter = 10
echo($counter)
increment(counter)
echo($counter)
"""
echo "Code:"
echo code2
try:
  initRuntime()
  execProgram(parseDsl(tokenizeDsl(code2)), runtimeEnv)
except:
  echo "Error: ", getCurrentExceptionMsg()
echo ""

echo "=== Test 3: Do Notation (Basic) ==="
let code3 = """
proc withBlock(callback: int):
  echo("Inside withBlock - before callback")
  callback()
  echo("Inside withBlock - after callback")

withBlock():
  echo("Inside the do block!")
"""
echo "Code:"
echo code3
try:
  initRuntime()
  execProgram(parseDsl(tokenizeDsl(code3)), runtimeEnv)
except:
  echo "Error: ", getCurrentExceptionMsg()
echo ""

echo "All tests completed!"
