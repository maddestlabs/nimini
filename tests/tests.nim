# tests/tests.nim

import unittest
import sequtils
import ../src/nimini

suite "Tokenizer Tests":
  test "tokenize simple variable":
    let tokens = tokenizeDsl("var x = 10")
    assert tokens.len > 0
    assert tokens[0].kind == tkIdent
    assert tokens[0].lexeme == "var"

  test "tokenize string":
    let tokens = tokenizeDsl("var s = \"hello\"")
    assert tokens.anyIt(it.kind == tkString)

  test "tokenize indented block":
    let code = """
if true:
  var x = 1
"""
    let tokens = tokenizeDsl(code)
    assert tokens.anyIt(it.kind == tkIndent)
    assert tokens.anyIt(it.kind == tkDedent)

suite "Parser Tests":
  test "parse variable declaration":
    let code = "var x = 10"
    let tokens = tokenizeDsl(code)
    let prog = parseDsl(tokens)
    assert prog.stmts.len == 1
    assert prog.stmts[0].kind == skVar

  test "parse function definition":
    let code = """
proc add(a:int, b:int):
  return a + b
"""
    let tokens = tokenizeDsl(code)
    let prog = parseDsl(tokens)
    assert prog.stmts.len == 1
    assert prog.stmts[0].kind == skProc
    assert prog.stmts[0].procName == "add"

  test "parse if statement":
    let code = """
if x > 5:
  var y = 10
"""
    let tokens = tokenizeDsl(code)
    let prog = parseDsl(tokens)
    assert prog.stmts.len == 1
    assert prog.stmts[0].kind == skIf

  test "parse for loop":
    let code = """
for i in range(0, 5):
  var x = i
"""
    let tokens = tokenizeDsl(code)
    let prog = parseDsl(tokens)
    assert prog.stmts.len == 1
    assert prog.stmts[0].kind == skFor

suite "Runtime Tests":
  test "execute variable assignment":
    initRuntime()
    let code = "var x = 42"
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let v = getVar(runtimeEnv, "x")
    assert v.i == 42

  test "execute arithmetic":
    initRuntime()
    let code = """
var x = 10
var y = 20
var z = x + y
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let z = getVar(runtimeEnv, "z")
    assert z.f == 30.0

  test "execute function call":
    initRuntime()
    let code = """
proc double(n:int):
  return n * 2
var result = double(5)
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let result = getVar(runtimeEnv, "result")
    assert result.f == 10.0

  test "execute if statement":
    initRuntime()
    let code = """
var x = 10
if x > 5:
  var y = "big"
else:
  var y = "small"
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let y = getVar(runtimeEnv, "y")
    assert y.s == "big"

  test "execute for loop":
    initRuntime()
    let code = """
var sum = 0
for i in range(0, 5):
  sum = sum + i
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let sum = getVar(runtimeEnv, "sum")
    assert sum.f == 10.0  # 0+1+2+3+4

  test "register native function":
    initRuntime()
    
    proc testFunc(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
      if args.len > 0 and args[0].kind == vkInt:
        return valInt(args[0].i * 2)
      return valNil()
    
    registerNative("double", testFunc)
    let code = "var x = double(5)"
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let x = getVar(runtimeEnv, "x")
    assert x.i == 10