## Tests for the {.nimini.} autopragma system

import ../src/nimini
import ../src/nimini/autopragma

# Test functions marked with {.nimini.}
proc testAdd(env: ref Env; args: seq[Value]): Value {.nimini.} =
  if args.len < 2:
    return valInt(0)
  return valInt(args[0].i + args[1].i)

proc testMultiply(env: ref Env; args: seq[Value]): Value {.nimini.} =
  if args.len < 2:
    return valInt(1)
  return valInt(args[0].i * args[1].i)

proc testGreet(env: ref Env; args: seq[Value]): Value {.nimini.} =
  if args.len > 0 and args[0].kind == vkString:
    return valString("Hello, " & args[0].s & "!")
  return valString("Hello, world!")

proc testSum(env: ref Env; args: seq[Value]): Value {.nimini.} =
  var sum = 0
  for arg in args:
    sum += arg.i
  return valInt(sum)

when isMainModule:
  echo "Testing autopragma registration..."
  
  # Initialize runtime
  initRuntime()
  
  # Test 1: Register functions using exportNiminiProcs
  echo "\n[Test 1] Registering functions with exportNiminiProcs"
  exportNiminiProcs(testAdd, testMultiply, testGreet, testSum)
  echo "✓ Functions registered"
  
  # Test 2: Call registered functions from script
  echo "\n[Test 2] Calling registered functions from script"
  let script1 = """
    var x = testAdd(5, 3)
    var y = testMultiply(4, 7)
  """
  let tokens1 = tokenizeDsl(script1)
  let program1 = parseDsl(tokens1)
  execProgram(program1, runtimeEnv)
  
  # Verify values in environment
  let x = getVar(runtimeEnv, "x")
  let y = getVar(runtimeEnv, "y")
  assert x.kind == vkInt and x.i == 8, "testAdd(5, 3) should equal 8"
  assert y.kind == vkInt and y.i == 28, "testMultiply(4, 7) should equal 28"
  echo "✓ testAdd(5, 3) = ", x.i
  echo "✓ testMultiply(4, 7) = ", y.i
  
  # Test 3: String return values
  echo "\n[Test 3] Testing string return values"
  let script2 = """
    var greeting = testGreet("Alice")
  """
  let tokens2 = tokenizeDsl(script2)
  let program2 = parseDsl(tokens2)
  execProgram(program2, runtimeEnv)
  
  let greeting = getVar(runtimeEnv, "greeting")
  assert greeting.kind == vkString and greeting.s == "Hello, Alice!", "testGreet should return greeting"
  echo "✓ testGreet(\"Alice\") = \"", greeting.s, "\""
  
  # Test 4: Variable arguments
  echo "\n[Test 4] Testing variable arguments"
  let script3 = """
    var total = testSum(1, 2, 3, 4, 5)
  """
  let tokens3 = tokenizeDsl(script3)
  let program3 = parseDsl(tokens3)
  execProgram(program3, runtimeEnv)
  
  let total = getVar(runtimeEnv, "total")
  assert total.kind == vkInt and total.i == 15, "testSum(1,2,3,4,5) should equal 15"
  echo "✓ testSum(1, 2, 3, 4, 5) = ", total.i
  
  # Test 5: Individual registration with registerNimini
  echo "\n[Test 5] Testing individual registration"
  proc testSquare(env: ref Env; args: seq[Value]): Value {.nimini.} =
    if args.len < 1:
      return valInt(0)
    return valInt(args[0].i * args[0].i)
  
  registerNimini(testSquare)
  
  let script4 = """
    var squared = testSquare(9)
  """
  let tokens4 = tokenizeDsl(script4)
  let program4 = parseDsl(tokens4)
  execProgram(program4, runtimeEnv)
  
  let squared = getVar(runtimeEnv, "squared")
  assert squared.kind == vkInt and squared.i == 81, "testSquare(9) should equal 81"
  echo "✓ testSquare(9) = ", squared.i
  
  echo "\n✅ All autopragma tests passed!"
