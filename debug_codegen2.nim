import src/nimini
import std/strutils

echo "Starting debug..."

let code = """
block outer:
  for i in 0..<5:
    if i == 3:
      break outer
"""

echo "Code to parse:"
echo code

try:
  echo "Tokenizing..."
  let tokens = tokenizeDsl(code)
  echo "Token count: ", tokens.len
  
  echo "Parsing..."
  let prog = parseDsl(tokens)
  echo "Statement count: ", prog.stmts.len
  
  echo "Generating code..."
  let ctx = newCodegenContext()
  let nimCode = generateNimCode(prog, ctx)
  
  echo "Generated code:"
  echo nimCode
  echo ""
  echo "Looking for: 'block outer:'"
  echo "Found: ", ("block outer:" in nimCode)
except Exception as e:
  echo "Error: ", e.msg
