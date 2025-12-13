# Simple string operations demo using Nimini DSL
# This demonstrates the $ operator, string slicing, and string methods

import ../nimini
import ../nimini/backends/[nim_backend, python_backend, javascript_backend]

proc main() =
  echo "=== Testing String Operations in Nimini ==="
  echo ""
  
  # Test 1: $ operator for stringification
  echo "Test 1: $ Stringify Operator"
  let code1 = """
var num = 42
var str = $num
echo(str)
"""
  
  echo "Nim Backend:"
  let ast1 = parseAndRun(code1)
  let nimCode1 = transpileTo(ast1, newNimBackend())
  echo nimCode1
  echo ""
  
  echo "Python Backend:"
  let pyCode1 = transpileTo(ast1, newPythonBackend())
  echo pyCode1
  echo ""
  
  echo "JavaScript Backend:"
  let jsCode1 = transpileTo(ast1, newJavaScriptBackend())
  echo jsCode1
  echo ""
  echo "---"
  echo ""
  
  # Test 2: String slicing (inclusive)
  echo "Test 2: String Slicing (Inclusive)"
  let code2 = """
var text = "Hello, World!"
var hello = text[0..4]
echo(hello)
"""
  
  let ast2 = parseAndRun(code2)
  echo "Nim Backend:"
  echo transpileTo(ast2, newNimBackend())
  echo ""
  echo "Python Backend:"
  echo transpileTo(ast2, newPythonBackend())
  echo ""
  echo "JavaScript Backend:"
  echo transpileTo(ast2, newJavaScriptBackend())
  echo ""
  echo "---"
  echo ""
  
  # Test 3: String slicing (exclusive)
  echo "Test 3: String Slicing (Exclusive)"
  let code3 = """
var text = "Programming"
var prog = text[0..<4]
echo(prog)
"""
  
  let ast3 = parseAndRun(code3)
  echo "Nim Backend:"
  echo transpileTo(ast3, newNimBackend())
  echo ""
  echo "Python Backend:"
  echo transpileTo(ast3, newPythonBackend())
  echo ""
  echo "JavaScript Backend:"
  echo transpileTo(ast3, newJavaScriptBackend())
  echo ""
  echo "---"
  echo ""
  
  # Test 4: String length property
  echo "Test 4: String Length"
  let code4 = """
var name = "Nimini"
var length = name.len
echo($length)
"""
  
  let ast4 = parseAndRun(code4)
  echo "Nim Backend:"
  echo transpileTo(ast4, newNimBackend())
  echo ""
  echo "Python Backend:"
  echo transpileTo(ast4, newPythonBackend())
  echo ""
  echo "JavaScript Backend:"
  echo transpileTo(ast4, newJavaScriptBackend())
  echo ""
  echo "---"
  echo ""
  
  echo "All tests completed!"

main()
