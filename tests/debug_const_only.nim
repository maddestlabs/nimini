## Test just const parsing

import ../nimini/parser
import ../nimini/tokenizer
import ../nimini/ast

let code = """const
  MaxBuildings = 100

  screenWidth = 800
  screenHeight = 450
"""

try:
  echo "Tokenizing..."
  let tokens = tokenizeDsl(code)
  echo "Got ", tokens.len, " tokens"
  
  echo "\nParsing..."
  let prog = parseDsl(tokens)
  
  echo "\nSuccess! Parsed ", prog.stmts.len, " statements:"
  for i, stmt in prog.stmts:
    if stmt.kind == skConst:
      echo "  [", i, "] const ", stmt.constName, " = ", stmt.constValue.intVal
except Exception as e:
  echo "\nError: ", e.msg
