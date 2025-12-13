## Test multiline var
import ../nimini

let code = """
var
  l1 = 15'f32
  m1 = 0.2'f32
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
    echo "  ", i, ": ", s.kind, " - ", s.varName
  
  initRuntime()
  initStdlib()
  echo "\nExecuting..."
  execProgram(prog, runtimeEnv)
  
  let l1 = getVar(runtimeEnv, "l1")
  let m1 = getVar(runtimeEnv, "m1")
  echo "l1 = ", l1.f
  echo "m1 = ", m1.f
  echo "Done!"
except Exception as e:
  echo "ERROR: ", e.msg
