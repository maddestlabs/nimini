# Integration test: Nimini -> Nim code generation for tuples
import ../nimini

echo "=== Testing Nimini Tuple Code Generation ==="
echo ""

# Test 1: Generate Nim code from Nimini tuple code
let niminiCode = """
# Tuple example in Nimini
let point = (x: 10, y: 20)
let (a, b) = (1, 2)
let mixed = (42, "hello", true)
"""

echo "Nimini Source Code:"
echo niminiCode
echo ""

# Parse and generate Nim code
let tokens = tokenizeDsl(niminiCode)
let prog = parseDsl(tokens)
let ctx = newCodegenContext()
let nimCode = genProgram(prog, ctx)

echo "Generated Nim Code:"
echo nimCode
echo ""

echo "=== Code Generation Test Passed ==="
