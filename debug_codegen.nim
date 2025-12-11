import src/nimini

let code = """
block outer:
  for i in 0..<5:
    if i == 3:
      break outer
"""
let prog = parseDsl(tokenizeDsl(code))
let ctx = newCodegenContext()
let nimCode = generateNimCode(prog, ctx)
echo "Generated code:"
echo nimCode
echo ""
echo "Looking for: 'block outer:'"
echo "Found: ", ("block outer:" in nimCode)
