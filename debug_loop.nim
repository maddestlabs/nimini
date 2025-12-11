import src/nimini

initRuntime()
let code = """
var count = 0
for i in 0..<5:
  count = count + 1
"""
let prog = parseDsl(tokenizeDsl(code))
execProgram(prog, runtimeEnv)
let count = getVar(runtimeEnv, "count")
echo "count.kind = ", count.kind
echo "count.i = ", count.i
echo "count.f = ", count.f
echo "Expected: 5"
