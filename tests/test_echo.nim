import ../nimini

initRuntime()
let code = """
echo("Hello from Nimini!")
"""
let prog = parseDsl(tokenizeDsl(code))
execProgram(prog, runtimeEnv)
