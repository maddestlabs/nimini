## Example demonstrating Object Types and Object Construction in Nimini

import ../src/nimini

let exampleCode = """
# Define a Vector2 type for 2D positions
type Vector2 = object
  x: float
  y: float

# Define a Color type
type Color = object
  r: int
  g: int
  b: int

# Define a ClockHand type (from raylib example)
type ClockHand = object
  value: int
  angle: float
  length: int
  color: Color

# Create some objects
var pos = Vector2(x: 100.0, y: 200.0)
var red = Color(r: 255, g: 0, b: 0)
var blue = Color(r: 0, g: 0, b: 255)

var hourHand = ClockHand(value: 3, angle: 90.0, length: 80, color: red)

var minuteHand = ClockHand(value: 15, angle: 45.0, length: 100, color: blue)

# Access and modify fields
echo("Position: ")
echo(pos.x)
echo(pos.y)

echo("Hour hand angle: ")
echo(hourHand.angle)

echo("Minute hand color: ")
echo(minuteHand.color.r)
echo(minuteHand.color.g)
echo(minuteHand.color.b)

# Modify fields
pos.x = 150.0
pos.y = 250.0
hourHand.angle = 180.0

echo("Updated position: ")
echo(pos.x)
echo(pos.y)

echo("Updated hour hand angle: ")
echo(hourHand.angle)
"""

echo "Nimini Object Types Example"
echo "=================================================="
echo ""

# Parse the code
let tokens = tokenizeDsl(exampleCode)
let program = parseDsl(tokens)

echo "Parsed successfully!"
echo "Number of statements: ", program.stmts.len
echo ""

# Generate Nim code
let nimCode = generateNimCode(program)

echo "Generated Nim Code:"
echo "--------------------------------------------------"
echo nimCode
echo ""

# Execute the code
echo "Executing the code:"
echo "--------------------------------------------------"
initRuntime()
execProgram(program, runtimeEnv)
