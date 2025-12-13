## Direct test
import ../nimini
import std/strutils

let code = """const
  a = 1
  b = 2

echo("a = ", a)
echo("b = ", b)
"""

echo "=== Code ==="
echo code
echo ""

try:
  let tokens = tokenizeDsl(code)
  echo "Tokens: ", tokens.len
  
  let prog = parseDsl(tokens)
  echo "Statements: ", prog.stmts.len
  
  for i, s in prog.stmts:
    echo "  ", i, ": ", s.kind
  
  initRuntime()
  initStdlib()
  echo "\nExecuting..."
  execProgram(prog, runtimeEnv)
  echo "Done!"
except Exception as e:
  echo "ERROR: ", e.msg
