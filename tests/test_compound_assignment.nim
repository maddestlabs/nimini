# Test compound assignment operators in Nimini
# Tests +=, -=, *=, /=, %= operators

import ../nimini
import std/strutils

proc testBasicCompoundAssignment() =
  echo "=== Testing Basic Compound Assignment ==="
  
  let code = """
var x = 10
x += 5
echo($x)

var y = 20
y -= 3
echo($y)

var z = 4
z *= 3
echo($z)

var w = 100
w /= 4
echo($w)

var m = 17
m %= 5
echo($m)
"""
  
  echo "Code:"
  echo code
  echo ""
  
  echo "Parsing..."
  let tokens = tokenizeDsl(code)
  let prog = parseDsl(tokens)
  echo "✓ Parse successful"
  
  echo "\nExecuting..."
  initRuntime()
  execProgram(prog, runtimeEnv)
  
  # Verify results
  assert getVar(runtimeEnv, "x").i == 15, "x += 5 failed"
  assert getVar(runtimeEnv, "y").i == 17, "y -= 3 failed"
  assert getVar(runtimeEnv, "z").i == 12, "z *= 3 failed"
  assert getVar(runtimeEnv, "w").i == 25, "w /= 4 failed"
  assert getVar(runtimeEnv, "m").i == 2, "m %= 5 failed"
  echo "✓ All compound assignments work correctly"

proc testCompoundWithExpressions() =
  echo "\n=== Testing Compound Assignment with Complex Expressions ==="
  
  let code = """
var counter = 0
counter += 2 * 3
echo($counter)

var total = 100
total -= 10 + 5
echo($total)

var arr = [1, 2, 3, 4, 5]
var sum = 0
sum += arr[0]
sum += arr[1]
sum += arr[2]
echo($sum)
"""
  
  echo "Code:"
  echo code
  echo ""
  
  echo "Parsing..."
  let tokens = tokenizeDsl(code)
  let prog = parseDsl(tokens)
  echo "✓ Parse successful"
  
  echo "\nExecuting..."
  initRuntime()
  execProgram(prog, runtimeEnv)
  
  assert getVar(runtimeEnv, "counter").i == 6, "counter += 2 * 3 failed"
  assert getVar(runtimeEnv, "total").i == 85, "total -= 10 + 5 failed"
  assert getVar(runtimeEnv, "sum").i == 6, "sum with array indexing failed"
  echo "✓ Compound assignments with expressions work correctly"

proc testCompoundWithFieldAccess() =
  echo "\n=== Testing Compound Assignment with Field Access ==="
  
  let code = """
type Point = object
  x: int
  y: int

var p = Point(x: 10, y: 20)
p.x += 5
p.y -= 3
echo($p.x)
echo($p.y)
"""
  
  echo "Code:"
  echo code
  echo ""
  
  echo "Parsing..."
  let tokens = tokenizeDsl(code)
  let prog = parseDsl(tokens)
  echo "✓ Parse successful"
  
  echo "\nExecuting..."
  initRuntime()
  execProgram(prog, runtimeEnv)
  
  let p = getVar(runtimeEnv, "p")
  assert p["x"].i == 15, "p.x += 5 failed"
  assert p["y"].i == 17, "p.y -= 3 failed"
  echo "✓ Compound assignments with field access work correctly"

proc testCodeGeneration() =
  echo "\n=== Testing Code Generation ==="
  
  let code = """
var x = 10
x += 5
x -= 2
x *= 3
"""
  
  let tokens = tokenizeDsl(code)
  let prog = parseDsl(tokens)
  
  echo "Nim Backend:"
  let nimBackend = newNimBackend()
  let nimCode = generateCode(prog, nimBackend)
  echo nimCode
  echo ""
  
  echo "Python Backend:"
  let pyBackend = newPythonBackend()
  let pyCode = generateCode(prog, pyBackend)
  echo pyCode
  echo ""
  
  echo "JavaScript Backend:"
  let jsBackend = newJavaScriptBackend()
  let jsCode = generateCode(prog, jsBackend)
  echo jsCode
  echo ""
  
  echo "✓ Code generation successful for all backends"

# Run all tests
proc main() =
  testBasicCompoundAssignment()
  testCompoundWithExpressions()
  testCompoundWithFieldAccess()
  testCodeGeneration()
  
  echo "\n" & "=".repeat(50)
  echo "✓ ALL COMPOUND ASSIGNMENT TESTS PASSED!"
  echo "=".repeat(50)

main()
