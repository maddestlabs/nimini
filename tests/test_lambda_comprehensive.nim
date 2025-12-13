## Comprehensive Lambda and Do Notation Tests for Nimini

import ../nimini
import std/strutils

echo "=" .repeat(70)
echo "NIMINI LAMBDA & DO NOTATION COMPREHENSIVE TESTS"
echo "=" .repeat(70)
echo ""

# Test 1: Basic Lambda Assignment and Call
echo "Test 1: Basic Lambda Assignment"
echo "-" .repeat(70)
let test1 = """
var square = proc(x: int):
  return x * x

echo($square(5))
echo($square(10))
"""
try:
  initRuntime()
  execProgram(parseDsl(tokenizeDsl(test1)), runtimeEnv)
  echo "✓ PASS"
except:
  echo "✗ FAIL: ", getCurrentExceptionMsg()
echo ""

# Test 2: Lambda with String Concatenation
echo "Test 2: Lambda with String Operations"
echo "-" .repeat(70)
let test2 = """
var makeGreeting = proc(name: string):
  return "Hello, " & name & "!"

var msg = makeGreeting("Alice")
echo(msg)
"""
try:
  initRuntime()
  execProgram(parseDsl(tokenizeDsl(test2)), runtimeEnv)
  echo "✓ PASS"
except:
  echo "✗ FAIL: ", getCurrentExceptionMsg()
echo ""

# Test 3: Lambda with Multiple Statements
echo "Test 3: Lambda with Multiple Statements"
echo "-" .repeat(70)
let test3 = """
var compute = proc(a: int, b: int):
  var sum = a + b
  var product = a * b
  echo("Sum: " & $sum)
  echo("Product: " & $product)
  return product

var result = compute(3, 4)
echo("Result: " & $result)
"""
try:
  initRuntime()
  execProgram(parseDsl(tokenizeDsl(test3)), runtimeEnv)
  echo "✓ PASS"
except:
  echo "✗ FAIL: ", getCurrentExceptionMsg()
echo ""

# Test 4: Do Notation - Basic
echo "Test 4: Do Notation (Basic)"
echo "-" .repeat(70)
let test4 = """
proc executeBlock(action: int):
  echo("Starting...")
  action()
  echo("Done!")

executeBlock():
  echo("Executing action!")
"""
try:
  initRuntime()
  execProgram(parseDsl(tokenizeDsl(test4)), runtimeEnv)
  echo "✓ PASS"
except:
  echo "✗ FAIL: ", getCurrentExceptionMsg()
echo ""

# Test 5: Do Notation - Multiple Statements in Block
echo "Test 5: Do Notation with Multi-Statement Block"
echo "-" .repeat(70)
let test5 = """
proc withContext(callback: int):
  echo("--- Begin Context ---")
  callback()
  echo("--- End Context ---")

withContext():
  echo("Statement 1")
  echo("Statement 2")
  echo("Statement 3")
"""
try:
  initRuntime()
  execProgram(parseDsl(tokenizeDsl(test5)), runtimeEnv)
  echo "✓ PASS"
except:
  echo "✗ FAIL: ", getCurrentExceptionMsg()
echo ""

# Test 6: Lambda Assigned to Variable Then Passed
echo "Test 6: Lambda Variable Passed as Argument"
echo "-" .repeat(70)
let test6 = """
proc runTwice(fn: int):
  fn()
  fn()

var sayHello = proc():
  echo("Hello!")

runTwice(sayHello)
"""
try:
  initRuntime()
  execProgram(parseDsl(tokenizeDsl(test6)), runtimeEnv)
  echo "✓ PASS"
except:
  echo "✗ FAIL: ", getCurrentExceptionMsg()
echo ""

# Test 7: Lambda with Conditional Logic
echo "Test 7: Lambda with Conditional Logic"
echo "-" .repeat(70)
let test7 = """
var checkEven = proc(n: int):
  if n % 2 == 0:
    echo($n & " is even")
  else:
    echo($n & " is odd")

checkEven(4)
checkEven(7)
"""
try:
  initRuntime()
  execProgram(parseDsl(tokenizeDsl(test7)), runtimeEnv)
  echo "✓ PASS"
except:
  echo "✗ FAIL: ", getCurrentExceptionMsg()
echo ""

# Test 8: Lambda with Loops
echo "Test 8: Lambda with Loops"
echo "-" .repeat(70)
let test8 = """
var countDown = proc(n: int):
  var i = n
  while i > 0:
    echo($i)
    i = i - 1
  echo("Blast off!")

countDown(3)
"""
try:
  initRuntime()
  execProgram(parseDsl(tokenizeDsl(test8)), runtimeEnv)
  echo "✓ PASS"
except:
  echo "✗ FAIL: ", getCurrentExceptionMsg()
echo ""

# Test 9: Do Notation with Variables in Scope
echo "Test 9: Do Notation Accessing Outer Scope"
echo "-" .repeat(70)
let test9 = """
var name = "World"

proc greetWith(action: int):
  action()

greetWith():
  echo("Hello, " & name & "!")
"""
try:
  initRuntime()
  execProgram(parseDsl(tokenizeDsl(test9)), runtimeEnv)
  echo "✓ PASS"
except:
  echo "✗ FAIL: ", getCurrentExceptionMsg()
echo ""

# Test 10: Nested Lambda Calls
echo "Test 10: Nested Function Calls with Lambdas"
echo "-" .repeat(70)
let test10 = """
var add = proc(a: int, b: int): return a + b
var multiply = proc(x: int, y: int): return x * y

var result = multiply(add(2, 3), add(4, 1))
echo($result)
"""
try:
  initRuntime()
  execProgram(parseDsl(tokenizeDsl(test10)), runtimeEnv)
  echo "✓ PASS"
except:
  echo "✗ FAIL: ", getCurrentExceptionMsg()
echo ""

echo "=" .repeat(70)
echo "ALL LAMBDA TESTS COMPLETED!"
echo "=" .repeat(70)
