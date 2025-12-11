# Comprehensive Tuple Demo for Nimini
# Demonstrates all tuple features with executable examples

echo "=== Nimini Tuple Examples ==="
echo ""

# Example 1: Basic unnamed tuple
echo "1. Basic Unnamed Tuple:"
let coordinates = (10, 20, 30)
echo "  coordinates = (10, 20, 30)"
echo ""

# Example 2: Named tuple (like a lightweight struct)
echo "2. Named Tuple:"
let person = (name: "Alice", age: 25, city: "NYC")
echo "  person = (name: \"Alice\", age: 25, city: \"NYC\")"
echo ""

# Example 3: Tuple unpacking
echo "3. Tuple Unpacking:"
let (x, y, z) = coordinates
echo "  let (x, y, z) = coordinates"
echo "  x = ", x, ", y = ", y, ", z = ", z
echo ""

# Example 4: Empty tuple
echo "4. Empty Tuple:"
let empty = ()
echo "  empty = ()"
echo ""

# Example 5: Single element tuple (requires trailing comma)
echo "5. Single Element Tuple:"
let single = (42,)
echo "  single = (42,)"
echo ""

# Example 6: Nested tuples
echo "6. Nested Tuples:"
let matrix = ((1, 2), (3, 4), (5, 6))
echo "  matrix = ((1, 2), (3, 4), (5, 6))"
echo ""

# Example 7: Tuple with mixed types
echo "7. Mixed Type Tuple:"
let mixed = (1, "hello", true, 3.14)
echo "  mixed = (1, \"hello\", true, 3.14)"
echo ""

# Example 8: Named tuple with computed values
echo "8. Named Tuple with Expressions:"
let point = (x: 10 + 5, y: 20 * 2, z: 100 - 50)
echo "  point = (x: 10 + 5, y: 20 * 2, z: 100 - 50)"
echo ""

# Example 9: Multiple return values simulation
echo "9. Simulating Multiple Return Values:"
proc getDimensions(): (int, int) =
  return (1920, 1080)

let (width, height) = getDimensions()
echo "  proc getDimensions(): (int, int) = return (1920, 1080)"
echo "  let (width, height) = getDimensions()"
echo "  width = ", width, ", height = ", height
echo ""

# Example 10: Swapping values using tuples
echo "10. Swapping Values with Tuples:"
var a = 5
var b = 10
echo "  Before: a = ", a, ", b = ", b
var temp = (b, a)
var (aNew, bNew) = temp
a = aNew
b = bNew
echo "  After:  a = ", a, ", b = ", b
echo ""

# Example 11: Tuple with trailing comma (allowed)
echo "11. Tuple with Trailing Comma:"
let numbers = (1, 2, 3,)
echo "  numbers = (1, 2, 3,)"
echo ""

echo "=== All Examples Completed ==="
