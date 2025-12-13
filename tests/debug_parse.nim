## Debug parse with simple const

import ../nimini/parser
import ../nimini/tokenizer
import ../nimini/ast

let code = """const
  MaxBuildings = 100

  screenWidth = 800
  screenHeight = 450

proc main =
  echo(screenWidth)

main()
"""

try:
  echo "Tokenizing..."
  let tokens = tokenizeDsl(code)
  echo "Got ", tokens.len, " tokens"
  
  echo "\nFirst 25 tokens:"
  for i in 0..<min(25, tokens.len):
    echo "  [", i, "] ", tokens[i].kind, ": '", tokens[i].lexeme, "' line=", tokens[i].line
  
  echo "\nParsing..."
  let prog = parseDsl(tokens)
  
  echo "\nSuccess! Parsed ", prog.stmts.len, " statements:"
  for i, stmt in prog.stmts:
    echo "  [", i, "] ", stmt.kind
except Exception as e:
  echo "\nError: ", e.msg
  echo "Type: ", $e.name
