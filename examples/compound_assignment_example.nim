## Compound Assignment Operators Example
## Demonstrates support for +=, -=, *=, /=, %= operators

import ../nimini
import ../nimini/backends/[python_backend, javascript_backend]

proc main() =
  echo "=== Compound Assignment Operators ==="
  echo ""

  let dslCode = """
# Basic compound assignments
var counter = 0
counter += 1
counter += 1
counter += 1
echo("Counter: " & $counter)

var score = 100
score -= 15
score -= 10
echo("Score: " & $score)

var multiplier = 2
multiplier *= 3
multiplier *= 2
echo("Multiplier: " & $multiplier)

var total = 100
total /= 4
echo("Total: " & $total)

var remainder = 17
remainder %= 5
echo("Remainder: " & $remainder)

# Compound assignments with expressions
var x = 10
x += 5 * 2
echo("x after += 5 * 2: " & $x)

# Compound assignments with field access
type Point = object
  x: int
  y: int

var p = Point(x: 100, y: 200)
p.x += 50
p.y -= 25
echo("Point: (" & $p.x & ", " & $p.y & ")")

# Compound assignments in loops
var sum = 0
for i in 1..5:
  sum += i
echo("Sum 1-5: " & $sum)
"""

  echo "DSL Code:"
  echo dslCode
  echo ""

  # Parse and execute
  let tokens = tokenizeDsl(dslCode)
  let program = parseDsl(tokens)
  
  echo "=== Runtime Execution ==="
  initRuntime()
  execProgram(program, runtimeEnv)
  echo ""
  
  # Generate code for different backends
  echo "=== Generated Nim Code ==="
  let nimBackend = newNimBackend()
  echo generateCode(program, nimBackend)
  echo ""
  
  echo "=== Generated Python Code ==="
  let pythonBackend = newPythonBackend()
  echo generateCode(program, pythonBackend)
  echo ""
  
  echo "=== Generated JavaScript Code ==="
  let jsBackend = newJavaScriptBackend()
  echo generateCode(program, jsBackend)

main()
