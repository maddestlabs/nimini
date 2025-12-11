## Simple demonstration of case statements in Nimini

import ../src/nimini

echo "=== Nimini Case Statement Demo ==="
echo ""

let code = """
# Function to describe a day
proc describeDay(dayNum: int):
  case dayNum
  of 1: 
    return "Monday - Start of work week"
  of 2:
    return "Tuesday - Getting into the groove"
  of 3:
    return "Wednesday - Halfway there!"
  of 4:
    return "Thursday - Almost weekend"
  of 5:
    return "Friday - Weekend is here!"
  of 6, 7:
    return "Weekend - Relax and enjoy!"
  else:
    return "Invalid day number"

# Test the function
echo(describeDay(1))
echo(describeDay(3))
echo(describeDay(6))
echo(describeDay(99))

# String matching example
var status = "running"
case status
of "idle":
  echo("System is idle")
of "running", "active":
  echo("System is running")
of "paused":
  echo("System is paused")
else:
  echo("Unknown status")
"""

initRuntime()
let prog = parseDsl(tokenizeDsl(code))
execProgram(prog, runtimeEnv)

echo ""
echo "✓ Case statements working perfectly!"
