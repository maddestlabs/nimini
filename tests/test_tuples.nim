# Test tuples in Nimini
import ../src/nimini

# Test 1: Simple unnamed tuple literal
echo "Test 1: Unnamed tuple literal"
let code1 = """
let myTuple = (1, "hello", true)
"""
let tokens1 = tokenizeDsl(code1)
let prog1 = parseDsl(tokens1)
let ctx1 = newCodegenContext()
let output1 = genProgram(prog1, ctx1)
echo output1
echo ""

# Test 2: Named tuple literal
echo "Test 2: Named tuple literal"
let code2 = """
let person = (name: "Bob", age: 30)
"""
let tokens2 = tokenizeDsl(code2)
let prog2 = parseDsl(tokens2)
let ctx2 = newCodegenContext()
let output2 = genProgram(prog2, ctx2)
echo output2
echo ""

# Test 3: Tuple unpacking
echo "Test 3: Tuple unpacking"
let code3 = """
let (x, y) = (10, 20)
"""
let tokens3 = tokenizeDsl(code3)
let prog3 = parseDsl(tokens3)
let ctx3 = newCodegenContext()
let output3 = genProgram(prog3, ctx3)
echo output3
echo ""

# Test 4: Tuple from function call (simulated with identifier)
echo "Test 4: Tuple unpacking from function"
let code4 = """
let (a, b, c) = getTuple()
"""
let tokens4 = tokenizeDsl(code4)
let prog4 = parseDsl(tokens4)
let ctx4 = newCodegenContext()
let output4 = genProgram(prog4, ctx4)
echo output4
echo ""

# Test 5: Empty tuple
echo "Test 5: Empty tuple"
let code5 = """
let empty = ()
"""
let tokens5 = tokenizeDsl(code5)
let prog5 = parseDsl(tokens5)
let ctx5 = newCodegenContext()
let output5 = genProgram(prog5, ctx5)
echo output5
echo ""

# Test 6: Single element tuple with trailing comma
echo "Test 6: Single element tuple"
let code6 = """
let single = (42,)
"""
let tokens6 = tokenizeDsl(code6)
let prog6 = parseDsl(tokens6)
let ctx6 = newCodegenContext()
let output6 = genProgram(prog6, ctx6)
echo output6
echo ""

# Test 7: Nested tuples
echo "Test 7: Nested tuples"
let code7 = """
let nested = ((1, 2), (3, 4))
"""
let tokens7 = tokenizeDsl(code7)
let prog7 = parseDsl(tokens7)
let ctx7 = newCodegenContext()
let output7 = genProgram(prog7, ctx7)
echo output7
echo ""

# Test 8: Named tuple with expressions
echo "Test 8: Named tuple with expressions"
let code8 = """
let point = (x: 10 + 5, y: 20 * 2)
"""
let tokens8 = tokenizeDsl(code8)
let prog8 = parseDsl(tokens8)
let ctx8 = newCodegenContext()
let output8 = genProgram(prog8, ctx8)
echo output8
echo ""

# Test 9: Tuple with trailing comma
echo "Test 9: Tuple with trailing comma"
let code9 = """
let trailing = (1, 2, 3,)
"""
let tokens9 = tokenizeDsl(code9)
let prog9 = parseDsl(tokens9)
let ctx9 = newCodegenContext()
let output9 = genProgram(prog9, ctx9)
echo output9
echo ""

# Test 10: var unpacking
echo "Test 10: var unpacking"
let code10 = """
var (x, y, z) = (1, 2, 3)
"""
let tokens10 = tokenizeDsl(code10)
let prog10 = parseDsl(tokens10)
let ctx10 = newCodegenContext()
let output10 = genProgram(prog10, ctx10)
echo output10
echo ""

echo "All tests completed!"
