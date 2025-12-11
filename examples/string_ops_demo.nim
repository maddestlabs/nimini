## Nimini String Operations Example
## Demonstrates $ operator, string slicing, and string methods

import ../src/nimini
import ../src/nimini/backends/python_backend
import ../src/nimini/backends/javascript_backend

proc main() =
  echo "=== Nimini String Operations Example ==="
  echo ""

  # Example DSL code demonstrating string operations
  let dslCode = """
var message = "Hello, World!"
var num = 42
var numStr = $num

var hello = message[0..4]
var world = message[7..11]

var prog = "Programming"
var slice = prog[0..<4]

var name = "Nimini"
var nameLen = name.len
"""

  echo "DSL Code:"
  echo "---"
  echo dslCode
  echo "---"
  echo ""

  # Parse the DSL
  let tokens  = tokenizeDsl(dslCode)
  let program = parseDsl(tokens)

  # Execute in DSL runtime
  echo "Running in DSL runtime (interpreted):"
  initRuntime()
  execProgram(program, runtimeEnv)
  
  echo "numStr = ", getVar(runtimeEnv, "numStr")
  echo "hello = ", getVar(runtimeEnv, "hello")
  echo "world = ", getVar(runtimeEnv, "world")
  echo "slice = ", getVar(runtimeEnv, "slice")
  echo "nameLen = ", getVar(runtimeEnv, "nameLen")
  echo ""

  # Generate code for different backends
  echo "Generated Nim code:"
  echo "---"
  let ctx = newCodegenContext()
  let nimCode = generateNimCode(program, ctx)
  echo nimCode
  echo "---"
  echo ""
  
  echo "Generated Python code:"
  echo "---"
  let pyBackend = newPythonBackend()
  let pyCode = generateCode(program, pyBackend)
  echo pyCode
  echo "---"
  echo ""
  
  echo "Generated JavaScript code:"
  echo "---"
  let jsBackend = newJavaScriptBackend()
  let jsCode = generateCode(program, jsBackend)
  echo jsCode
  echo "---"
  echo ""

main()
