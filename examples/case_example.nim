## Example: Using case statements in Nimini
## This demonstrates the case/of/else syntax with various patterns

import ../src/nimini

# Example 1: Simple case with integers
echo "=== Example 1: Basic integer case ==="
let code1 = """
var score = 85

case score
of 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100:
  echo("Grade: A")
of 80, 81, 82, 83, 84, 85, 86, 87, 88, 89:
  echo("Grade: B")
of 70, 71, 72, 73, 74, 75, 76, 77, 78, 79:
  echo("Grade: C")
else:
  echo("Grade: F")
"""
initRuntime()
execProgram(parseDsl(tokenizeDsl(code1)), runtimeEnv)

# Example 2: Case with strings
echo "\n=== Example 2: String matching ==="
let code2 = """
var command = "help"

case command
of "quit", "exit":
  echo("Exiting program...")
of "help", "?":
  echo("Available commands: start, stop, help, quit")
of "start":
  echo("Starting service...")
of "stop":
  echo("Stopping service...")
else:
  echo("Unknown command. Type 'help' for help.")
"""
initRuntime()
execProgram(parseDsl(tokenizeDsl(code2)), runtimeEnv)

# Example 3: Case with elif for range checking
echo "\n=== Example 3: Case with elif ==="
let code3 = """
var temperature = 75

case temperature
of 32:
  echo("Water freezing point")
of 212:
  echo("Water boiling point")
elif temperature < 32:
  echo("Below freezing")
elif temperature > 100:
  echo("Very hot!")
elif temperature > 80:
  echo("Hot")
elif temperature > 60:
  echo("Pleasant")
else:
  echo("Cool")
"""
initRuntime()
execProgram(parseDsl(tokenizeDsl(code3)), runtimeEnv)

# Example 4: Inline syntax
echo "\n=== Example 4: Inline case syntax ==="
let code4 = """
var dayNum = 3

case dayNum
of 1: echo("Monday")
of 2: echo("Tuesday")
of 3: echo("Wednesday")
of 4: echo("Thursday")
of 5: echo("Friday")
of 6, 7: echo("Weekend!")
else: echo("Invalid day")
"""
initRuntime()
execProgram(parseDsl(tokenizeDsl(code4)), runtimeEnv)

# Example 5: Code generation
echo "\n=== Example 5: Generated Nim code ==="
let code5 = """
var option = 2

case option
of 1:
  echo("Option one")
of 2, 3:
  echo("Option two or three")
else:
  echo("Other option")
"""
let prog = parseDsl(tokenizeDsl(code5))
let ctx = newCodegenContext()
let nimCode = generateNimCode(prog, ctx)
echo "Generated Nim code:"
echo nimCode

echo "\n✓ All case statement examples completed!"
