## Test backward compatibility of Nim code generation
## Ensures that existing Nim codegen still works after backend refactoring

import ../src/nimini
import std/strutils

proc testBasicCodegen() =
  echo "Testing basic Nim codegen..."
  let dslSource = """
var x = 10
var y = 20
var sum = x + y
"""
  let tokens = tokenizeDsl(dslSource)
  let program = parseDsl(tokens)
  let nimCode = generateNimCode(program)
  
  # Verify it generates valid Nim code
  assert "var x = 10" in nimCode
  assert "var y = 20" in nimCode
  assert "var sum = (x + y)" in nimCode
  echo "✓ Basic codegen works"

proc testIfStatements() =
  echo "Testing if statement codegen..."
  let dslSource = """
if x > 5:
  echo(x)
elif x > 3:
  echo("medium")
else:
  echo("small")
"""
  let tokens = tokenizeDsl(dslSource)
  let program = parseDsl(tokens)
  let nimCode = generateNimCode(program)
  
  assert "if (x > 5):" in nimCode
  assert "elif (x > 3):" in nimCode
  assert "else:" in nimCode
  echo "✓ If statement codegen works"

proc testLoops() =
  echo "Testing loop codegen..."
  let dslSource = """
for i in 1..10:
  echo(i)

while x > 0:
  x = x - 1
"""
  let tokens = tokenizeDsl(dslSource)
  let program = parseDsl(tokens)
  let nimCode = generateNimCode(program)
  
  assert "for i in" in nimCode
  assert "while (x > 0):" in nimCode
  echo "✓ Loop codegen works"

proc testProcedures() =
  echo "Testing procedure codegen..."
  let dslSource = """
proc add(a: int, b: int):
  return a + b
"""
  let tokens = tokenizeDsl(dslSource)
  let program = parseDsl(tokens)
  let nimCode = generateNimCode(program)
  
  assert "proc add" in nimCode
  assert "return (a + b)" in nimCode
  echo "✓ Procedure codegen works"

proc testExpressions() =
  echo "Testing expression codegen..."
  let dslSource = """
var a = 5 + 3
var b = 10 - 2
var c = 4 * 5
var d = 20 / 4
var e = not true
var f = true and false
var g = true or false
"""
  let tokens = tokenizeDsl(dslSource)
  let program = parseDsl(tokens)
  let nimCode = generateNimCode(program)
  
  assert "var a = (5 + 3)" in nimCode
  assert "var b = (10 - 2)" in nimCode
  assert "var c = (4 * 5)" in nimCode
  assert "var d = (20 / 4)" in nimCode
  assert "not" in nimCode
  assert "and" in nimCode
  assert "or" in nimCode
  echo "✓ Expression codegen works"

proc testBackwardCompatibleAPI() =
  echo "Testing backward compatible API..."
  let dslSource = "var x = 42"
  let tokens = tokenizeDsl(dslSource)
  let program = parseDsl(tokens)
  
  # Test that the old API still works
  let code1 = generateNimCode(program)
  assert "var x = 42" in code1
  
  # Test with nil context (should create default Nim backend)
  let code2 = generateNimCode(program, nil)
  assert "var x = 42" in code2
  
  echo "✓ Backward compatible API works"

proc testNewBackendAPI() =
  echo "Testing new multi-backend API..."
  let dslSource = "var x = 42"
  let tokens = tokenizeDsl(dslSource)
  let program = parseDsl(tokens)
  
  # Test Nim backend
  let nimBackend = newNimBackend()
  let nimCode = generateCode(program, nimBackend)
  assert "var x = 42" in nimCode
  
  # Test Python backend
  let pythonBackend = newPythonBackend()
  let pythonCode = generateCode(program, pythonBackend)
  assert "x = 42" in pythonCode
  
  # Test JavaScript backend
  let jsBackend = newJavaScriptBackend()
  let jsCode = generateCode(program, jsBackend)
  assert "let x = 42;" in jsCode
  
  echo "✓ New multi-backend API works"

when isMainModule:
  echo "=" .repeat(70)
  echo "Backward Compatibility Tests"
  echo "=" .repeat(70)
  echo ""
  
  testBasicCodegen()
  testIfStatements()
  testLoops()
  testProcedures()
  testExpressions()
  testBackwardCompatibleAPI()
  testNewBackendAPI()
  
  echo ""
  echo "=" .repeat(70)
  echo "✓ All backward compatibility tests passed!"
  echo "=" .repeat(70)
