## Quick test for multiline const with blank lines

import ../nimini/parser
import ../nimini/tokenizer
import ../nimini/ast

let code = """
const
  MaxBuildings = 100

  screenWidth = 800
  screenHeight = 450
"""

try:
  let tokens = tokenizeDsl(code)
  let prog = parseDsl(tokens)
  
  echo "Success! Parsed ", prog.stmts.len, " statements"
  for i, stmt in prog.stmts:
    if stmt.kind == skConst:
      echo "  const[", i, "]: ", stmt.constName
except Exception as e:
  echo "Error: ", e.msg
