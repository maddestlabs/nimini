## Example demonstrating Nimini codegen functionality
## This shows how to transpile Nimini DSL to native Nim code

import ../src/nimini

# Create a simple math plugin with codegen support
proc createMathPlugin(): Plugin =
  result = newPlugin(
    name: "math",
    author: "Nimini Team",
    version: "1.0.0",
    description: "Math functions with codegen support"
  )

  # Define native functions (for runtime execution)
  proc sqrtFunc(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
    if args.len < 1:
      return valNil()
    return valFloat(sqrt(args[0].f))

  proc powFunc(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
    if args.len < 2:
      return valNil()
    return valFloat(pow(args[0].f, args[1].f))

  # Register runtime functions
  result.registerFunc("sqrt", sqrtFunc)
  result.registerFunc("pow", powFunc)
  result.registerConstantFloat("PI", 3.14159265359)
  result.registerConstantFloat("E", 2.71828182846)

  # Register codegen mappings
  result.addNimImport("std/math")
  result.mapFunction("sqrt", "sqrt")     # Maps to Nim's sqrt
  result.mapFunction("pow", "pow")       # Maps to Nim's pow
  result.mapConstant("PI", "PI")         # Maps to Nim's PI
  result.mapConstant("E", "E")           # Maps to Nim's E

proc main() =
  echo "=== Nimini Codegen Example ==="
  echo ""

  # Define a simple Nimini program
  let dslCode = """
var radius = 5.0
var area = PI * pow(radius, 2.0)
var side = sqrt(area)
var result = side * E
"""

  echo "DSL Code:"
  echo "---"
  echo dslCode
  echo "---"
  echo ""

  # Parse the DSL
  let tokens = tokenizeDsl(dslCode)
  let program = parseDsl(tokens)

  # Initialize runtime and plugin
  initRuntime()
  let mathPlugin = createMathPlugin()
  registerPlugin(mathPlugin)
  loadPlugin(mathPlugin, runtimeEnv)

  # Execute in DSL runtime (interpreted)
  echo "Running in DSL runtime (interpreted):"
  execProgram(program, runtimeEnv)
  let runtimeResult = getVar(runtimeEnv, "result")
  echo "result = ", runtimeResult
  echo ""

  # Generate Nim code (transpiled)
  echo "Generated Nim code (for compilation):"
  echo "---"
  let ctx = newCodegenContext()
  loadPluginsCodegen(ctx)  # Load codegen metadata from plugins
  let nimCode = generateNimCode(program, ctx)
  echo nimCode
  echo "---"
  echo ""

  echo "The generated Nim code can be compiled with: nim c <file>.nim"
  echo "This provides native performance while maintaining the same semantics."

when isMainModule:
  main()
