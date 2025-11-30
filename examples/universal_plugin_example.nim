## Multi-Backend Plugin Example
## Demonstrates how to create a plugin that supports multiple code generation backends

import ../src/nimini
import std/[math, strutils]

# Create a universal math plugin that works with multiple backends
proc createUniversalMathPlugin(): Plugin =
  result = newPlugin("universal_math", "Nimini Team", "1.0.0", 
                     "Universal math plugin supporting multiple backends")

  # ============================================================================
  # Runtime implementations (language-agnostic)
  # ============================================================================
  
  proc sqrtFunc(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
    if args.len != 1:
      quit "sqrt expects 1 argument"
    return valFloat(sqrt(args[0].f))

  proc powFunc(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
    if args.len != 2:
      quit "pow expects 2 arguments"
    return valFloat(pow(args[0].f, args[1].f))

  proc absFunc(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
    if args.len != 1:
      quit "abs expects 1 argument"
    return valFloat(abs(args[0].f))

  # Register runtime functions
  result.registerFunc("sqrt", sqrtFunc)
  result.registerFunc("pow", powFunc)
  result.registerFunc("abs", absFunc)
  result.registerConstantFloat("PI", PI)
  result.registerConstantFloat("E", E)

  # ============================================================================
  # Nim backend mappings
  # ============================================================================
  
  result.addImportForBackend("Nim", "std/math")
  result.mapFunctionForBackend("Nim", "sqrt", "sqrt")
  result.mapFunctionForBackend("Nim", "pow", "pow")
  result.mapFunctionForBackend("Nim", "abs", "abs")
  result.mapConstantForBackend("Nim", "PI", "PI")
  result.mapConstantForBackend("Nim", "E", "E")

  # ============================================================================
  # Python backend mappings
  # ============================================================================
  
  result.addImportForBackend("Python", "math")
  result.mapFunctionForBackend("Python", "sqrt", "math.sqrt")
  result.mapFunctionForBackend("Python", "pow", "math.pow")
  result.mapFunctionForBackend("Python", "abs", "abs")  # Built-in
  result.mapConstantForBackend("Python", "PI", "math.pi")
  result.mapConstantForBackend("Python", "E", "math.e")

  # ============================================================================
  # JavaScript backend mappings
  # ============================================================================
  
  # JavaScript has Math built-in, no imports needed
  result.mapFunctionForBackend("JavaScript", "sqrt", "Math.sqrt")
  result.mapFunctionForBackend("JavaScript", "pow", "Math.pow")
  result.mapFunctionForBackend("JavaScript", "abs", "Math.abs")
  result.mapConstantForBackend("JavaScript", "PI", "Math.PI")
  result.mapConstantForBackend("JavaScript", "E", "Math.E")

# Main demo
when isMainModule:
  echo "=" .repeat(70)
  echo "Multi-Backend Plugin Demo"
  echo "=" .repeat(70)
  echo ""

  # Create and register plugin
  let mathPlugin = createUniversalMathPlugin()
  registerPlugin(mathPlugin)

  # Define DSL code using plugin functions
  let dslSource = """
var radius = 5.0
var area = PI * pow(radius, 2.0)
var circumference = 2.0 * PI * radius

echo(area)
echo(circumference)

var x = -42.5
var absValue = abs(x)
var sqrtValue = sqrt(absValue)

echo(absValue)
echo(sqrtValue)
"""

  # Parse the DSL
  let tokens = tokenizeDsl(dslSource)
  let program = parseDsl(tokens)

  # Generate code for each backend with plugin support
  echo "=== NIM OUTPUT (with plugin mappings) ==="
  echo "-" .repeat(70)
  let nimBackend = newNimBackend()
  var nimCtx = newCodegenContext(nimBackend)
  applyPluginCodegen(mathPlugin, nimCtx)
  let nimCode = generateCode(program, nimBackend, nimCtx)
  echo nimCode
  echo ""

  echo "=== PYTHON OUTPUT (with plugin mappings) ==="
  echo "-" .repeat(70)
  let pythonBackend = newPythonBackend()
  var pythonCtx = newCodegenContext(pythonBackend)
  applyPluginCodegen(mathPlugin, pythonCtx)
  let pythonCode = generateCode(program, pythonBackend, pythonCtx)
  echo pythonCode
  echo ""

  echo "=== JAVASCRIPT OUTPUT (with plugin mappings) ==="
  echo "-" .repeat(70)
  let jsBackend = newJavaScriptBackend()
  var jsCtx = newCodegenContext(jsBackend)
  applyPluginCodegen(mathPlugin, jsCtx)
  let jsCode = generateCode(program, jsBackend, jsCtx)
  echo jsCode
  echo ""

  echo "=" .repeat(70)
  echo "✓ Universal plugin successfully generated code for 3 languages!"
  echo "=" .repeat(70)
