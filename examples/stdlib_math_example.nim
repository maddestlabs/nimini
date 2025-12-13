## Example demonstrating nimini's math stdlib functions
## Shows how all math operations work in both runtime and codegen modes

import ../nimini

proc main() =
  echo "=== Nimini Math Stdlib Example ==="
  echo ""
  
  # Initialize runtime with stdlib
  initRuntime()
  initStdlib()
  
  let code = """
# Trigonometric functions
var angle = 45.0
var radians = degToRad(angle)
echo("Angle: " & $angle & " degrees = " & $radians & " radians")
echo("sin(" & $angle & "°) = " & $sin(radians))
echo("cos(" & $angle & "°) = " & $cos(radians))
echo("tan(" & $angle & "°) = " & $tan(radians))
echo("")

# Exponential and logarithmic
var x = 2.0
var y = 3.0
echo("sqrt(" & $x & ") = " & $sqrt(x))
echo("pow(" & $x & ", " & $y & ") = " & $pow(x, y))
echo("exp(1) = " & $exp(1.0))
echo("ln(E) = " & $ln(E))
echo("")

# Rounding functions
var num = 3.7
echo("Number: " & $num)
echo("floor(" & $num & ") = " & $floor(num))
echo("ceil(" & $num & ") = " & $ceil(num))
echo("round(" & $num & ") = " & $round(num))
echo("")

# Absolute value
var neg = -5.5
echo("abs(" & $neg & ") = " & $abs(neg))
echo("")

# Min/Max
var a = 10.0
var b = 20.0
echo("min(" & $a & ", " & $b & ") = " & $min(a, b))
echo("max(" & $a & ", " & $b & ") = " & $max(a, b))
echo("")

# Type conversions
var floatVal = 3.14
var intVal = 42
echo("int(" & $floatVal & ") = " & $int(floatVal))
echo("float(" & $intVal & ") = " & $float(intVal))
echo("")

# Using PI constant
var radius = 5.0
var area = PI * pow(radius, 2.0)
var circumference = 2.0 * PI * radius
echo("Circle with radius " & $radius & ":")
echo("  Area = " & $area)
echo("  Circumference = " & $circumference)
"""

  echo "DSL Code:"
  echo "---"
  echo code
  echo "---"
  echo ""
  
  echo "Execution Output:"
  echo "---"
  let program = parseDsl(tokenizeDsl(code))
  execProgram(program, runtimeEnv)
  echo "---"

when isMainModule:
  main()
