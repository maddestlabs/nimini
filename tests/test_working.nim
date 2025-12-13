# Simple nimini script - should work
var x = 10
var y = 20
var sum = x + y
echo("Sum: " & $sum)

# Test math functions
var angle = 3.14159
var sineVal = sin(angle)
echo("sin(pi) = " & $sineVal)

# Test object types
type Point = object
  x: float
  y: float

var p = Point(x: 3.0, y: 4.0)
echo("Point: (" & $p.x & ", " & $p.y & ")")

# Test arrays
var arr = [1, 2, 3, 4, 5]
var total = 0
for i in 0..<5:
  total = total + arr[i]
echo("Array sum: " & $total)

# Test lambda
var double = proc(n: int):
  return n * 2

echo("Double 5: " & $double(5))
