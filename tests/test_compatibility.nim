# Example Nim code to test compatibility

# This will be flagged as unsupported
import std/math
import std/strutils

# Template - not supported
template myTemplate(x: int): int =
  x * 2

# Macro - not supported  
macro myMacro(x: int): int =
  result = x

# Try/except - not supported
proc riskyFunc(): int =
  try:
    return 10 / 0
  except DivByZeroDefect:
    return 0

# Supported features
type Point = object
  x: float
  y: float

proc distance(p1: Point, p2: Point): float =
  let dx = p2.x - p1.x
  let dy = p2.y - p1.y
  return sqrt(dx * dx + dy * dy)  # sqrt from stdlib

var p1 = Point(x: 0.0, y: 0.0)
var p2 = Point(x: 3.0, y: 4.0)

# This function call is not in nimini stdlib (needs to be exposed)
var dist = distance(p1, p2)

echo("Distance: " & $dist)

# Lambda (supported in nimini!)
var multiply = proc(a: int, b: int): int =
  return a * b

echo($multiply(5, 6))
