## Test parser robustness with various indentation scenarios

import ../src/nimini/[tokenizer, parser]

proc testCase(name: string; code: string; shouldSucceed: bool = true) =
  echo "Testing: ", name
  try:
    let tokens = tokenizeDsl(code)
    let program = parseDsl(tokens)
    if shouldSucceed:
      echo "  ✓ Success - parsed ", program.stmts.len, " statements"
    else:
      echo "  ✗ Expected to fail but succeeded"
  except:
    if shouldSucceed:
      echo "  ✗ Failed: ", getCurrentExceptionMsg()
    else:
      echo "  ✓ Expected failure: ", getCurrentExceptionMsg()
  echo ""

# Test 1: Correct indentation
testCase("Correct indentation", """
var x = 10
while x > 0:
  echo(x)
  x = x - 1
""")

# Test 2: While with not operator
testCase("While with not operator", """
while not done():
  process()
""")

# Test 3: Nested blocks
testCase("Nested blocks", """
while true:
  if x > 0:
    echo(x)
""")

# Test 4: Multiple statements at same level
testCase("Multiple statements", """
var a = 1
var b = 2
while a < 10:
  a = a + 1
echo(a)
""")

echo "All tests completed!"
