## Test the exact raylib-style example from TODO_RAYLIB.md

import ../nimini
import std/strutils

let exactExample = """
type Vector2 = object
  x: float
  y: float

type Color = object
  r: int
  g: int
  b: int

type ClockHand = object
  angle: float
  length: int
  thickness: int
  color: Color
  value: int
  origin: Vector2

type Clock = object
  mode: int
  second: ClockHand

var myClock = Clock(
  mode: 0,
  second: ClockHand(
    angle: 45,
    length: 140,
    thickness: 3,
    color: Color(r: 245, g: 245, b: 220),
    value: 0,
    origin: Vector2(x: 0, y: 0)
  )
)

echo("Clock created successfully!")
echo("Mode: ")
echo(myClock.mode)
echo("Second hand angle: ")
echo(myClock.second.angle)
echo("Second hand length: ")
echo(myClock.second.length)
echo("Second hand color (beige): ")
echo(myClock.second.color.r)
echo(myClock.second.color.g)
echo(myClock.second.color.b)
echo("Second hand origin: ")
echo(myClock.second.origin.x)
echo(myClock.second.origin.y)
"""

echo "Testing Exact Raylib-Style Multi-line Object Construction"
echo "=========================================================="
echo ""

# Parse the code
let tokens = tokenizeDsl(exactExample)
let program = parseDsl(tokens)

echo "✓ Parsed successfully!"
echo "  Number of statements: ", program.stmts.len
echo ""

# Generate Nim code
let nimCode = generateNimCode(program)

echo "Generated Nim Code (excerpt):"
echo "------------------------------"
let lines = nimCode.split("\n")
for i, line in lines:
  if i < 30:  # Show first 30 lines
    echo line
if lines.len > 30:
  echo "... (", lines.len - 30, " more lines)"
echo ""

# Execute the code
echo "Execution Output:"
echo "-----------------"
initRuntime()
execProgram(program, runtimeEnv)
