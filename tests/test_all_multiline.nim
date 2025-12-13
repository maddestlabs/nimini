## Test all multiline blocks together
import ../nimini

let code = """
const
  Width = 800
  Height = 600

type
  Id = int
  Name = string

var
  id1: Id = 1
  id2: Id = 2

let
  name1: Name = "Alice"
  name2: Name = "Bob"

echo("Size: ", Width, "x", Height)
echo("Player 1: ", id1, " - ", name1)
echo("Player 2: ", id2, " - ", name2)
"""

try:
  let tokens = tokenizeDsl(code)
  let prog = parseDsl(tokens)
  
  echo "Parsed ", prog.stmts.len, " statements:"
  var constCount, typeCount, varCount, letCount, exprCount = 0
  for s in prog.stmts:
    case s.kind
    of skConst: inc constCount
    of skType: inc typeCount
    of skVar: inc varCount
    of skLet: inc letCount
    of skExpr: inc exprCount
    else: discard
  
  echo "  const: ", constCount
  echo "  type: ", typeCount
  echo "  var: ", varCount
  echo "  let: ", letCount
  echo "  expr: ", exprCount
  echo ""
  
  initRuntime()
  initStdlib()
  execProgram(prog, runtimeEnv)
  
  echo "\n✓ All multiline blocks work correctly!"
except Exception as e:
  echo "ERROR: ", e.msg
