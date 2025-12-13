## Nimini Codegen Example - Using CodegenExtension

import ../nimini

# Avoid naming conflict by importing with except
import std/math except sqrt, pow

proc sqrt(env: ref Env; args: seq[Value]): Value {.nimini, gcsafe.} =
  if args.len != 1:
    return valNil()
  return valFloat(math.sqrt(args[0].f))

proc pow(env: ref Env; args: seq[Value]): Value {.nimini, gcsafe.} =
  if args.len != 2:
    return valNil()
  return valFloat(math.pow(args[0].f, args[1].f))

# Create a codegen extension for transpilation support
proc createMathExtension(): CodegenExtension =
  let ext = newCodegenExtension("math")
  
  # Nim backend mappings
  ext.addNimImport("std/math")
  ext.mapNimFunction("sqrt", "sqrt")
  ext.mapNimFunction("pow", "pow")
  ext.mapNimConstant("PI", "PI")
  ext.mapNimConstant("E", "E")
  
  # Could add Python/JS mappings here too:
  # ext.addImport("Python", "math")
  # ext.mapFunction("Python", "sqrt", "math.sqrt")
  # ext.mapFunction("Python", "pow", "math.pow")
  
  return ext


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
  # Initialize runtime (use autopragma for registration)
  # ------------------------------------------------------
  initRuntime()
  exportNiminiProcs(sqrt, pow)
  
  # Register constants manually
  defineVar(runtimeEnv, "PI", valFloat(PI))
  defineVar(runtimeEnv, "E", valFloat(E))
  
  # Register codegen extension
  let mathExt = createMathExtension()
  registerExtension(mathExt)

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
  loadExtensionsCodegen(ctx)
  let nimCode = generateNimCode(program, ctx)

  echo nimCode
  echo "---"
  echo ""

  echo "You can compile the generated Nim code with:"
  echo "  nim c <file>.nim"


when isMainModule:
  main()
