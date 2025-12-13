# Test file for Nimini string operations
# Tests string slicing, $ operator, and common string methods

import ../nimini

# Test 1: $ stringify operator
proc testStringifyOperator() =
  echo "=== Test 1: $ Stringify Operator ==="
  
  # Test with integer
  var num = 42
  var numStr = $num
  echo "Integer to string: " & numStr
  
  # Test with float
  var pi = 3.14159
  var piStr = $pi
  echo "Float to string: " & piStr
  
  # Test with boolean
  var flag = true
  var flagStr = $flag
  echo "Boolean to string: " & flagStr
  
  echo ""

# Test 2: String slicing with inclusive range
proc testStringSlicingInclusive() =
  echo "=== Test 2: String Slicing (Inclusive) ==="
  
  var text = "Hello, World!"
  
  # Get substring from index 0 to 4 (inclusive)
  var hello = text[0..4]
  echo "text[0..4] = " & hello  # Should be "Hello"
  
  # Get substring from index 7 to 11 (inclusive)
  var world = text[7..11]
  echo "text[7..11] = " & world  # Should be "World"
  
  # Single character range
  var firstChar = text[0..0]
  echo "text[0..0] = " & firstChar  # Should be "H"
  
  echo ""

# Test 3: String slicing with exclusive range
proc testStringSlicingExclusive() =
  echo "=== Test 3: String Slicing (Exclusive) ==="
  
  var text = "Hello, World!"
  
  # Get substring from index 0 to 5 (exclusive)
  var hello = text[0..<5]
  echo "text[0..<5] = " & hello  # Should be "Hello"
  
  # Get substring from index 7 to 12 (exclusive)
  var world = text[7..<12]
  echo "text[7..<12] = " & world  # Should be "World"
  
  echo ""

# Test 4: String length
proc testStringLength() =
  echo "=== Test 4: String Length ==="
  
  var empty = ""
  var short = "Hi"
  var long = "This is a longer string"
  
  echo "Length of empty string: " & $empty.len
  echo "Length of 'Hi': " & $short.len
  echo "Length of long string: " & $long.len
  
  echo ""

# Test 5: String case conversion
proc testStringCase() =
  echo "=== Test 5: String Case Conversion ==="
  
  var text = "Hello, World!"
  
  var upper = text.toUpper()
  echo "toUpper: " & upper
  
  var lower = text.toLower()
  echo "toLower: " & lower
  
  var mixed = "MiXeD CaSe"
  echo "Mixed to upper: " & mixed.toUpper()
  echo "Mixed to lower: " & mixed.toLower()
  
  echo ""

# Test 6: String trimming
proc testStringTrim() =
  echo "=== Test 6: String Trimming ==="
  
  var padded = "   Hello, World!   "
  var trimmed = padded.strip()
  echo "Original: '" & padded & "'"
  echo "Trimmed: '" & trimmed & "'"
  
  var tabs = "\t\tTabbed\t\t"
  echo "Trimmed tabs: '" & tabs.strip() & "'"
  
  echo ""

# Test 7: Complex string operations
proc testComplexStringOps() =
  echo "=== Test 7: Complex String Operations ==="
  
  var message = "Temperature is 25 degrees"
  
  # Extract and manipulate parts
  var temp = 25
  var tempStr = $temp
  echo "Temperature as string: " & tempStr
  
  # Use slicing to extract parts
  var prefix = message[0..13]
  echo "Prefix: " & prefix
  
  # Combine operations
  var upperMessage = message.toUpper()
  var messageLen = upperMessage.len
  echo "Uppercase message length: " & $messageLen
  
  echo ""

# Test 8: String operations with arrays
proc testStringArrayOps() =
  echo "=== Test 8: String Array Operations ==="
  
  var fruits = ["apple", "banana", "cherry"]
  
  # Get lengths of strings in array
  echo "First fruit: " & fruits[0]
  echo "First fruit length: " & $fruits[0].len
  
  # Uppercase first fruit
  var firstUpper = fruits[0].toUpper()
  echo "First fruit uppercase: " & firstUpper
  
  # Slice string in array
  var bananaSlice = fruits[1][0..2]
  echo "fruits[1][0..2] = " & bananaSlice  # Should be "ban"
  
  echo ""

# Test 9: Stringify in expressions
proc testStringifyExpressions() =
  echo "=== Test 9: Stringify in Expressions ==="
  
  var x = 10
  var y = 20
  var sum = x + y
  
  # Use $ in string concatenation
  var result = "The sum of " & $x & " and " & $y & " is " & $sum
  echo result
  
  # Nested operations
  var calculation = "Result: " & $(x * 2 + y)
  echo calculation
  
  echo ""

# Main test runner
proc runAllTests() =
  echo "========================================"
  echo "   Nimini String Operations Tests"
  echo "========================================"
  echo ""
  
  testStringifyOperator()
  testStringSlicingInclusive()
  testStringSlicingExclusive()
  testStringLength()
  testStringCase()
  testStringTrim()
  testComplexStringOps()
  testStringArrayOps()
  testStringifyExpressions()
  
  echo "========================================"
  echo "   All Tests Completed!"
  echo "========================================"

# Run all tests
runAllTests()
