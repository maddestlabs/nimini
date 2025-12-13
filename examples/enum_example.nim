## Example demonstrating enum types in Nimini
## Shows basic enum definitions, explicit values, and usage in case statements

import ../nimini
import ../nimini/backends/[nim_backend, python_backend, javascript_backend]
import std/strutils

# Example 1: Basic enum type with auto-incremented values
let code1 = """
type Color = enum
  red
  green
  blue
  yellow

var favoriteColor = blue
echo(favoriteColor)
"""

# Example 2: Enum with explicit ordinal values (HTTP status codes)
let code2 = """
type HttpStatus = enum
  ok = 200
  created = 201
  notFound = 404
  serverError = 500

var status = notFound
echo(status)
"""

# Example 3: Enum in case statement
let code3 = """
type TrafficLight = enum
  red
  yellow
  green

var light = red

case light
of red:
  echo("Stop!")
of yellow:
  echo("Slow down")
of green:
  echo("Go!")
"""

# Example 4: Enum with mixed ordinal values
let code4 = """
type Priority = enum
  low
  medium
  high = 10
  critical
  emergency = 99

var taskPriority = high
echo(taskPriority)
"""

# Example 5: Multiple enums and comparisons
let code5 = """
type Direction = enum
  north
  east
  south
  west

type Speed = enum
  stopped
  slow
  medium
  fast

var heading = north
var velocity = fast

if heading == north and velocity == fast:
  echo("Going north fast!")
"""

# Generate code for different backends
echo "=" .repeat(80)
echo "Example 1: Basic Enum"
echo "=" .repeat(80)
echo "\n--- Nim Code ---"
echo generateCode(parseDsl(tokenizeDsl(code1)), newNimBackend())

echo "\n--- Python Code ---"
echo generateCode(parseDsl(tokenizeDsl(code1)), newPythonBackend())

echo "\n--- JavaScript Code ---"
echo generateCode(parseDsl(tokenizeDsl(code1)), newJavaScriptBackend())

echo "\n" & "=" .repeat(80)
echo "Example 2: HTTP Status Codes"
echo "=" .repeat(80)
echo "\n--- Nim Code ---"
echo generateCode(parseDsl(tokenizeDsl(code2)), newNimBackend())

echo "\n--- Python Code ---"
echo generateCode(parseDsl(tokenizeDsl(code2)), newPythonBackend())

echo "\n" & "=" .repeat(80)
echo "Example 3: Enum in Case Statement"
echo "=" .repeat(80)
echo "\n--- Nim Code ---"
echo generateCode(parseDsl(tokenizeDsl(code3)), newNimBackend())

echo "\n--- Python Code ---"
echo generateCode(parseDsl(tokenizeDsl(code3)), newPythonBackend())

echo "\n" & "=" .repeat(80)
echo "Example 4: Mixed Ordinal Values"
echo "=" .repeat(80)
echo "\n--- Nim Code ---"
echo generateCode(parseDsl(tokenizeDsl(code4)), newNimBackend())

echo "\n" & "=" .repeat(80)
echo "Example 5: Multiple Enums"
echo "=" .repeat(80)
echo "\n--- Nim Code ---"
echo generateCode(parseDsl(tokenizeDsl(code5)), newNimBackend())
