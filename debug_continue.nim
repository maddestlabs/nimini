import src/nimini

initRuntime()
let code = """
var count = 0
block outer:
  for i in 0..<3:
    for j in 0..<3:
      if j == 1:
        continue outer
      count = count + 1
"""
echo "Testing continue with label"
let prog = parseDsl(tokenizeDsl(code))
execProgram(prog, runtimeEnv)
let count = getVar(runtimeEnv, "count")
echo "count.i = ", count.i
echo "Expected: 3"
