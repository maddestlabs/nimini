import ../src/nimini

echo "Testing basic runtime..."
initRuntime()
let code = """
var x = 42
"""
let prog = parseDsl(tokenizeDsl(code))
execProgram(prog, runtimeEnv)
let x = getVar(runtimeEnv, "x")
echo "x = ", x.i
echo "Success!"
