## Complete Lambda Example - Demonstrating All Features

import ../nimini
import std/strutils

echo "=" .repeat(70)
echo "COMPLETE LAMBDA SHOWCASE"
echo "=" .repeat(70)
echo ""

let showcaseCode = """
# 1. Simple lambda with return value
var add = proc(a: int, b: int):
  return a + b

echo("add(3, 4) = " & $add(3, 4))

# 2. Lambda with multi-line body
var greetAndCompute = proc(name: string, x: int):
  echo("Hello, " & name & "!")
  var squared = x * x
  echo("Your number squared is: " & $squared)
  return squared

var result = greetAndCompute("Alice", 5)
echo("Result: " & $result)

# 3. Lambda stored and reused
var sayHello = proc():
  echo("  > Hello from lambda!")

echo("Calling sayHello twice:")
sayHello()
sayHello()

# 4. Lambda with conditional logic
var checkPositive = proc(n: int):
  if n > 0:
    echo($n & " is positive")
  elif n < 0:
    echo($n & " is negative")
  else:
    echo($n & " is zero")

checkPositive(5)
checkPositive(-3)
checkPositive(0)

# 5. Lambda with loop
var printRange = proc(start: int, end: int):
  var i = start
  while i <= end:
    echo("  " & $i)
    i = i + 1

echo("Range from 1 to 3:")
printRange(1, 3)

# 6. Passing lambda to function
proc applyOperation(fn: int, a: int, b: int):
  echo("Applying operation...")
  var res = fn(a, b)
  echo("Result: " & $res)

applyOperation(proc(x: int, y: int): return x * y, 6, 7)

# 7. Do notation - basic
proc withContext(action: int):
  echo("=== Begin Context ===")
  action()
  echo("=== End Context ===")

withContext():
  echo("Inside the context!")
  echo("This is do notation!")

# 8. Do notation with closure (accessing outer scope)
var userName = "Bob"
var age = 25

proc displayInfo(display: int):
  echo("Displaying user info:")
  display()

displayInfo():
  echo("  Name: " & userName)
  echo("  Age: " & $age)

# 9. Nested lambda calls
var multiply = proc(x: int, y: int): return x * y
var subtract = proc(a: int, b: int): return a - b

var complex = multiply(add(2, 3), subtract(10, 5))
echo("Complex calculation: " & $complex)

# 10. Lambda with string operations
var makeGreeting = proc(name: string):
  var upper = name.toUpper()
  var greeting = "HELLO, " & upper & "!"
  return greeting

var msg = makeGreeting("world")
echo(msg)

echo("All lambda features demonstrated!")
"""

echo "Running showcase code:"
echo "-" .repeat(70)
echo ""

try:
  initRuntime()
  let tokens = tokenizeDsl(showcaseCode)
  let program = parseDsl(tokens)
  execProgram(program, runtimeEnv)
  echo ""
  echo "=" .repeat(70)
  echo "✓ SHOWCASE COMPLETED SUCCESSFULLY!"
  echo "=" .repeat(70)
except:
  echo "✗ Error: ", getCurrentExceptionMsg()
