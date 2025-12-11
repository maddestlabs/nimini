# Test code generation for break/continue across all backends

import nimini

let testCode = """
# Test break and continue
var sum = 0

# Test while with break
var i = 0
while i < 100:
  i = i + 1
  if i > 5:
    break
  sum = sum + i

# Test for with continue
for j in 1..10:
  if j % 2 == 0:
    continue
  sum = sum + j
"""

echo "=== Nim Backend ==="
let tokens1 = tokenizeDsl(testCode)
let prog1 = parseDsl(tokens1)
let nimBackend = newNimBackend()
echo generateCode(prog1, nimBackend)

echo "\n=== Python Backend ==="
let tokens2 = tokenizeDsl(testCode)
let prog2 = parseDsl(tokens2)
let pythonBackend = newPythonBackend()
echo generateCode(prog2, pythonBackend)

echo "\n=== JavaScript Backend ==="
let tokens3 = tokenizeDsl(testCode)
let prog3 = parseDsl(tokens3)
let jsBackend = newJavaScriptBackend()
echo generateCode(prog3, jsBackend)
