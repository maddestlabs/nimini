import ../nimini

let code = readFile("examples/multiline_all_blocks.nim")

echo "Code length: ", code.len

try:
  let tokens = tokenizeDsl(code)
  echo "Tokens: ", tokens.len
  
  let prog = parseDsl(tokens)
  echo "Statements: ", prog.stmts.len
  
  for i, s in prog.stmts:
    echo "  ", i, ": ", s.kind
  
  initRuntime()
  initStdlib()
  execProgram(prog, runtimeEnv)
except Exception as e:
  echo "ERROR: ", e.msg
  echo "  ", e.name
