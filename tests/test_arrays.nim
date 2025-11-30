# Test array and indexing support in Nimini

import ../src/nimini

let code = """
let nums = [1, 2, 3, 4, 5]
let first = nums[0]
let last = nums[4]

var data = [10, 20, 30]
let doubled = data[1] * 2

let matrix = [[1, 2], [3, 4]]
let value = matrix[0][1]
"""

# Test parsing
echo "=== Testing Array Support ==="
echo "Parsing code..."
let tokens = tokenizeDsl(code)
let prog = parseDsl(tokens)
echo "✓ Parsing successful"

# Test Nim backend
echo "\n=== Nim Backend ==="
let nimBackend = newNimBackend()
let nimCode = generateCode(prog, nimBackend)
echo nimCode

# Test Python backend  
echo "\n=== Python Backend ==="
let pythonBackend = newPythonBackend()
let pythonCode = generateCode(prog, pythonBackend)
echo pythonCode

# Test JavaScript backend
echo "\n=== JavaScript Backend ==="
let jsBackend = newJavaScriptBackend()
let jsCode = generateCode(prog, jsBackend)
echo jsCode

# Test runtime execution
echo "\n=== Runtime Execution ==="
initRuntime()
execProgram(prog, runtimeEnv)
echo "first = ", getVar(runtimeEnv, "first")
echo "last = ", getVar(runtimeEnv, "last")
echo "doubled = ", getVar(runtimeEnv, "doubled")
echo "value = ", getVar(runtimeEnv, "value")
