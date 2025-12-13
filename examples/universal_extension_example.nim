## Multi-Backend Extension Example
## Demonstrates how to create a codegen extension that supports multiple backends

import ../nimini
import std/[strutils, math]

proc sqrt(env: ref Env; args: seq[Value]): Value {.nimini, gcsafe.} =
  if args.len != 1:
    quit "sqrt expects 1 argument"
  return valFloat(sqrt(args[0].f))

proc pow(env: ref Env; args: seq[Value]): Value {.nimini, gcsafe.} =
  if args.len != 2:
    quit "pow expects 2 arguments"
  return valFloat(pow(args[0].f, args[1].f))

proc absFunc(env: ref Env; args: seq[Value]): Value {.nimini, gcsafe.} =
  if args.len != 1:
    quit "abs expects 1 argument"
  if args[0].kind == vkInt:
    return valInt(abs(args[0].i))
  else:
    return valFloat(abs(args[0].f))

# Create a universal codegen extension for multi-backend support
proc createUniversalMathExtension(): CodegenExtension =
  let ext = newCodegenExtension("universal_math")

  # ============================================================================
  # Nim backend mappings
  # ============================================================================
  
  ext.addImport("Nim", "std/math")
  ext.mapFunction("Nim", "sqrt", "sqrt")
  ext.mapFunction("Nim", "pow", "pow")
  ext.mapFunction("Nim", "absFunc", "abs")
  ext.mapConstant("Nim", "PI", "PI")
  ext.mapConstant("Nim", "E", "E")

  # ============================================================================
  # Python backend mappings
  # ============================================================================
  
  ext.addImport("Python", "math")
  ext.mapFunction("Python", "sqrt", "math.sqrt")
  ext.mapFunction("Python", "pow", "math.pow")
  ext.mapFunction("Python", "absFunc", "abs")  # Built-in
  ext.mapConstant("Python", "PI", "math.pi")
  ext.mapConstant("Python", "E", "math.e")

  # ============================================================================
  # JavaScript backend mappings
  # ============================================================================
  
  # JavaScript has Math built-in, no imports needed
  ext.mapFunction("JavaScript", "sqrt", "Math.sqrt")
  ext.mapFunction("JavaScript", "pow", "Math.pow")
  ext.mapFunction("JavaScript", "absFunc", "Math.abs")
  ext.mapConstant("JavaScript", "PI", "Math.PI")
  ext.mapConstant("JavaScript", "E", "Math.E")
  
  return ext

# Main demo
when isMainModule:
  echo "=" .repeat(70)
  echo "Multi-Backend Extension Demo"
  echo "=" .repeat(70)
  echo ""

  # Initialize runtime and register functions
  initRuntime()
  exportNiminiProcs(sqrt, pow, absFunc)
  
  # Register constants
  defineVar(runtimeEnv, "PI", valFloat(PI))
  defineVar(runtimeEnv, "E", valFloat(E))
  
  # Create and register codegen extension
  let mathExt = createUniversalMathExtension()
  registerExtension(mathExt)

  # Define DSL code using math functions
  let dslSource = """
var radius = 5.0
var area = PI * pow(radius, 2.0)
var circumference = 2.0 * PI * radius

echo(area)
echo(circumference)

var x = -42.5
var absValue = absFunc(x)
var sqrtValue = sqrt(absValue)

echo(absValue)
echo(sqrtValue)
"""

  # Parse the DSL
  let tokens = tokenizeDsl(dslSource)
  let program = parseDsl(tokens)

  # Generate code for each backend with extension support
  echo "=== NIM OUTPUT (with extension mappings) ==="
  echo "-" .repeat(70)
  let nimBackend = newNimBackend()
  var nimCtx = newCodegenContext(nimBackend)
  applyExtensionCodegen(mathExt, nimCtx)
  let nimCode = generateCode(program, nimBackend, nimCtx)
  echo nimCode
  echo ""

  echo "=== PYTHON OUTPUT (with extension mappings) ==="
  echo "-" .repeat(70)
  let pythonBackend = newPythonBackend()
  var pythonCtx = newCodegenContext(pythonBackend)
  applyExtensionCodegen(mathExt, pythonCtx)
  let pythonCode = generateCode(program, pythonBackend, pythonCtx)
  echo pythonCode
  echo ""

  echo "=== JAVASCRIPT OUTPUT (with extension mappings) ==="
  echo "-" .repeat(70)
  let jsBackend = newJavaScriptBackend()
  var jsCtx = newCodegenContext(jsBackend)
  applyExtensionCodegen(mathExt, jsCtx)
  let jsCode = generateCode(program, jsBackend, jsCtx)
  echo jsCode
  echo ""

  echo "=" .repeat(70)
  echo "✓ Universal extension successfully generated code for 3 languages!"
  echo "=" .repeat(70)
