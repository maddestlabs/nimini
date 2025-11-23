## Nimini Codegen Example

import std/math
import ../src/nimini/[runtime, tokenizer, plugin, parser, codegen]

# Create a simple math plugin with runtime + codegen support
proc createMathPlugin(): Plugin =
  let p = newPlugin(
    name        = "math",
    author      = "Nimini Team",
    version     = "1.0.0",
    description = "Math functions with runtime + codegen support"
  )

  # Native runtime functions --------------------------

  proc sqrtFunc(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
    if args.len != 1:
      return valNil()
    return valFloat(sqrt(args[0].f))

  proc powFunc(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
    if args.len != 2:
      return valNil()
    return valFloat(pow(args[0].f, args[1].f))

  # Register runtime functions
  p.registerFunc("sqrt", sqrtFunc)
  p.registerFunc("pow", powFunc)
  p.registerConstantFloat("PI", 3.14159265359)
  p.registerConstantFloat("E", 2.71828182846)

  # Codegen mappings -------------------------------

  # Codegen imports
  p.addNimImport("std/math")

  # DSL → Nim function mappings
  p.mapFunction("sqrt", "sqrt")
  p.mapFunction("pow", "pow")

  # Constant mappings
  p.mapConstant("PI", "PI")
  p.mapConstant("E", "E")

  return p


# ------------------------------------------------------
# Main example
# ------------------------------------------------------

proc main() =
  echo "=== Nimini Codegen Example ==="
  echo ""

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

  # ------------------------------------------------------
  # Parse the DSL
  # ------------------------------------------------------
  let tokens  = tokenizeDsl(dslCode)
  let program = parseDsl(tokens)

  # ------------------------------------------------------
  # Initialize runtime + plugin
  # ------------------------------------------------------
  initRuntime()

  let mathPlugin = createMathPlugin()
  registerPlugin(mathPlugin)
  loadPlugin(mathPlugin, runtimeEnv)

  # ------------------------------------------------------
  # Execute in DSL runtime
  # ------------------------------------------------------
  echo "Running in DSL runtime (interpreted):"
  execProgram(program, runtimeEnv)
  let runtimeResult = getVar(runtimeEnv, "result")
  echo "result = ", runtimeResult
  echo ""

  # ------------------------------------------------------
  # Codegen transpilation
  # ------------------------------------------------------
  echo "Generated Nim code (transpiled):"
  echo "---"

  let ctx = newCodegenContext()
  loadPluginsCodegen(ctx)
  let nimCode = generateNimCode(program, ctx)

  echo nimCode
  echo "---"
  echo ""

  echo "You can compile the generated Nim code with:"
  echo "  nim c <file>.nim"


when isMainModule:
  main()
