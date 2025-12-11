## Type Suffix Example
## Demonstrates support for type suffixes on numeric literals

import ../src/nimini
import ../src/nimini/backends/python_backend
import ../src/nimini/backends/javascript_backend

proc main() =
  echo "=== Type Suffix Support Example ==="
  echo ""

  let dslCode = """
var smallInt = 127'i8
var normalInt = 1000
var bigInt = 999999999'i64
var unsignedInt = 255'u8

var singleFloat = 3.14'f32
var doubleFloat = 3.14159265359'f64
var normalFloat = 2.718

var digitSize = 100
var halfDigit = digitSize / 2'f32

var radius = 5'i32
var area = radius * radius

echo("Small int: " & $smallInt)
echo("Normal int: " & $normalInt)
echo("Big int: " & $bigInt)
echo("Unsigned: " & $unsignedInt)
echo("Single float: " & $singleFloat)
echo("Double float: " & $doubleFloat)
echo("Half digit: " & $halfDigit)
echo("Area: " & $area)
"""

  echo "DSL Code:"
  echo "=========="
  echo dslCode
  echo "=========="
  echo ""

  # Parse and execute
  let tokens = tokenizeDsl(dslCode)
  let program = parseDsl(tokens)

  echo "Execution Results:"
  echo "==================="
  initRuntime()
  execProgram(program, runtimeEnv)
  echo ""

  # Show generated code for all backends
  echo "Generated Nim Code:"
  echo "==================="
  let ctx = newCodegenContext()
  let nimCode = generateNimCode(program, ctx)
  echo nimCode
  echo ""
  
  echo "Generated Python Code:"
  echo "======================"
  let pyBackend = newPythonBackend()
  let pyCode = generateCode(program, pyBackend)
  echo pyCode
  echo ""
  
  echo "Generated JavaScript Code:"
  echo "============================"
  let jsBackend = newJavaScriptBackend()
  let jsCode = generateCode(program, jsBackend)
  echo jsCode
  echo ""

main()
