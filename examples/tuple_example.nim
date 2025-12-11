# Tuple Examples for Nimini
# Demonstrates tuple literals, named tuples, and tuple unpacking

# Example 1: Basic unnamed tuple
let coordinates = (10, 20, 30)

# Example 2: Named tuple
let person = (name: "Alice", age: 25, city: "NYC")

# Example 3: Tuple unpacking
let (x, y, z) = coordinates

# Example 4: Named tuple unpacking (assign to a tuple, then access)
let employee = (name: "Bob", id: 12345, department: "Engineering")

# Example 5: Empty tuple
let empty = ()

# Example 6: Single element tuple (requires trailing comma)
let single = (42,)

# Example 7: Nested tuples
let matrix = ((1, 2), (3, 4), (5, 6))

# Example 8: Tuple with mixed types
let mixed = (1, "hello", true, 3.14)

# Example 9: Named tuple with computed values
let point = (x: 10 + 5, y: 20 * 2, z: 100 - 50)

# Example 10: Unpacking from a function (simulated)
proc getTuple(): (int, string, bool) =
  return (42, "answer", true)

let (number, text, flag) = getTuple()

# Example 11: Swapping values using tuples
var a = 5
var b = 10
(a, b) = (b, a)  # Swap values

# Example 12: Multiple return values simulation
proc getDimensions(): (int, int) =
  return (1920, 1080)

let (width, height) = getDimensions()

# Example 13: Tuple in expressions
let sum = coordinates
let result = (x + y + z,)  # Single-element tuple with computation

# Example 14: Named tuple as a simple data structure
let config = (
  host: "localhost",
  port: 8080,
  debug: true
)

# Example 15: Tuple with trailing comma (allowed)
let numbers = (
  1,
  2,
  3,
)
