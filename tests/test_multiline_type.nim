## Test multiline type blocks
import ../nimini

let code = """
type
  MyInt = int
  MyFloat = float
  MyString = string

var x: MyInt = 42
var y: MyFloat = 3.14
var z: MyString = "hello"

echo("x = ", x)
echo("y = ", y)
echo("z = ", z)
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
