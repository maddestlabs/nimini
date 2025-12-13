## Comprehensive String Operations Example
## Shows practical usage of all string features

import ../nimini
import ../nimini/backends/python_backend
import ../nimini/backends/javascript_backend

proc main() =
  echo "=== Comprehensive String Operations Example ==="
  echo ""

  let dslCode = """
var title = "  NIMINI DSL  "
var version = 1
var minor = 0

var cleanTitle = title.strip()
var versionStr = $version & "." & $minor
var fullTitle = cleanTitle & " v" & versionStr

var greeting = "Hello, Nimini User!"
var hello = greeting[0..4]
var user = greeting[7..<12]

var data = "temperature:25:humidity:60"
var firstPart = data[0..14]
var temp = data[12..13]

var filename = "example.nim"
var ext = filename[8..10]
var name = filename[0..<7]

var sentence = "The quick brown fox"
var wordLen = sentence.len

echo("Full Title: " & fullTitle)
echo("Greeting Parts: " & hello & " and " & user)
echo("First Part: " & firstPart)
echo("Temperature: " & temp)
echo("Filename: " & name & " Extension: " & ext)
echo("Sentence Length: " & $wordLen)
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
