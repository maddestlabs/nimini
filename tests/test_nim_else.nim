import ../src/nimini

let nimCode = """
var x = 15
if x > 20:
  echo "big"
else:
  echo "small"
"""

echo "Testing Nim DSL if/else:"
try:
  let prog = compileSource(nimCode)
  echo "✓ Parsed: ", prog.stmts.len, " statements"
except Exception as e:
  echo "✗ Error: ", e.msg
