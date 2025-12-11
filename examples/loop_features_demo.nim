# examples/loop_features_demo.nim
# Demonstrates the new loop features in Nimini:
# - Loop labels with break/continue
# - Multi-variable for loops

import ../src/nimini

echo "=== Nimini Loop Features Demo ==="
echo ""

# Example 1: Basic labeled block with break
echo "Example 1: Labeled block with break"
echo "------------------------------------"
initRuntime()
let code1 = """
var found = false
var result = 0

block search:
  for i in 0..<10:
    for j in 0..<10:
      if i * j == 42:
        result = i * 100 + j
        found = true
        break search
"""
echo "Code:"
echo code1
echo "Executing..."
let prog1 = parseDsl(tokenizeDsl(code1))
execProgram(prog1, runtimeEnv)
let found1 = getVar(runtimeEnv, "found")
let result1 = getVar(runtimeEnv, "result")
echo "Found: ", found1.b
echo "Result: ", result1.i, " (expected: 607 = 6*100 + 7 since 6*7=42)"
echo ""

# Example 2: Multi-variable for loop with array
echo "Example 2: Multi-variable for loop with array"
echo "----------------------------------------------"
initRuntime()
let code2 = """
var fruits = ["apple", "banana", "cherry"]
var count = 0

for idx, fruit in fruits:
  count = count + 1
"""
echo "Code:"
echo code2
echo "Executing..."
let prog2 = parseDsl(tokenizeDsl(code2))
execProgram(prog2, runtimeEnv)
let count2 = getVar(runtimeEnv, "count")
echo "Iterated over ", count2.i, " items"
echo ""

# Example 3: Nested loops with labels
echo "Example 3: Nested loops with labels"
echo "------------------------------------"
initRuntime()
let code3 = """
var iterations = 0

block outer:
  for y in 0..<5:
    for x in 0..<5:
      iterations = iterations + 1
      if x + y > 6:
        break outer
"""
echo "Code:"
echo code3
echo "Executing..."
let prog3 = parseDsl(tokenizeDsl(code3))
execProgram(prog3, runtimeEnv)
let iterations3 = getVar(runtimeEnv, "iterations")
echo "Iterations before breaking: ", iterations3.i
echo ""

# Example 4: Code generation
echo "Example 4: Code generation with loop labels"
echo "--------------------------------------------"
let code4 = """
block findPair:
  for i in 0..<10:
    for j in 0..<10:
      if i + j == 15:
        break findPair
"""
echo "Input code:"
echo code4
let prog4 = parseDsl(tokenizeDsl(code4))
let ctx = newCodegenContext()
let nimCode = generateNimCode(prog4, ctx)
echo "Generated Nim code:"
echo nimCode
echo ""

# Example 5: Multi-variable loop with ranges
echo "Example 5: Multi-variable for with range"
echo "-----------------------------------------"
initRuntime()
let code5 = """
var sum = 0
for i, j in 0..<5:
  sum = sum + i
"""
echo "Code:"
echo code5
echo "Executing..."
let prog5 = parseDsl(tokenizeDsl(code5))
execProgram(prog5, runtimeEnv)
let sum5 = getVar(runtimeEnv, "sum")
echo "Sum of indices: ", sum5.i, " (0+1+2+3+4 = 10)"
echo ""

echo "=== Demo Complete ==="
