# Tests for Frontend Abstraction Layer

import ../src/nimini
import std/[unittest, strutils]

suite "Frontend Abstraction Layer":
  
  test "Nim frontend creation":
    let frontend = newNimFrontend()
    check frontend.name == "Nim"
    check frontend.fileExtensions.len > 0
    check ".nim" in frontend.fileExtensions
    check frontend.supportsTypeAnnotations == true
  
  test "Nim frontend singleton":
    let fe1 = getNimFrontend()
    let fe2 = getNimFrontend()
    check fe1 == fe2  # Should be same instance
  
  test "Tokenization through frontend":
    let frontend = getNimFrontend()
    let source = "var x = 10"
    let tokens = frontend.tokenize(source)
    check tokens.len > 0
  
  test "Parsing through frontend":
    let frontend = getNimFrontend()
    let source = """
var x = 10
var y = 20
"""
    let tokens = frontend.tokenize(source)
    let program = frontend.parse(tokens)
    check program.stmts.len == 2
  
  test "Compile convenience method":
    let frontend = getNimFrontend()
    let source = "var x = 10"
    let program = frontend.compile(source)
    check program.stmts.len == 1
  
  test "Extension detection":
    let frontend = getNimFrontend()
    check frontend.supportsExtension(".nim") == true
    check frontend.supportsExtension("nim") == true
    check frontend.supportsExtension(".nims") == true
    check frontend.supportsExtension(".py") == false
  
  test "Auto-detection by content (Nim)":
    let source = """
proc test():
  echo("hello")
"""
    let program = compileSource(source)
    check program.stmts.len == 1
  
  test "Detection by filename":
    let source = "var x = 10"
    let program = compileSource(source, filename="test.nim")
    check program.stmts.len == 1
  
  test "Explicit frontend usage":
    let source = "var x = 10"
    let frontend = getNimFrontend()
    let program = compileSource(source, frontend)
    check program.stmts.len == 1
  
  test "Backward compatibility - tokenizeDsl":
    let source = "var x = 10"
    let tokens = tokenizeDsl(source)
    check tokens.len > 0
  
  test "Backward compatibility - parseDsl":
    let source = "var x = 10"
    let tokens = tokenizeDsl(source)
    let program = parseDsl(tokens)
    check program.stmts.len == 1
  
  test "Complex program through frontend":
    let source = """
proc add(a: int, b: int):
  return a + b

var x = 10
var y = 20
var result = add(x, y)

if result > 25:
  echo(result)

for i in 1..5:
  echo(i)
"""
    let frontend = getNimFrontend()
    let program = frontend.compile(source)
    check program.stmts.len == 6
  
  test "Multi-backend output from frontend":
    let source = """
var x = 10
var y = 20
"""
    let program = compileSource(source)
    
    # Generate to different backends
    let nimCode = generateCode(program, newNimBackend())
    let pyCode = generateCode(program, newPythonBackend())
    let jsCode = generateCode(program, newJavaScriptBackend())
    
    check nimCode.len > 0
    check pyCode.len > 0
    check jsCode.len > 0
    check nimCode.contains("var")
    check pyCode.contains("=")
    check jsCode.contains("let")

when isMainModule:
  echo "Running Frontend Abstraction Layer Tests..."
