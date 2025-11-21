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
var y = ""
if x > 5:
  y = "big"
else:
  y = "small"
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

suite "Boolean Literal Tests":
  test "tokenize boolean literals":
    let tokens = tokenizeDsl("true false")
    assert tokens[0].kind == tkIdent
    assert tokens[0].lexeme == "true"
    assert tokens[1].kind == tkIdent
    assert tokens[1].lexeme == "false"

  test "parse boolean literals":
    let code = """
var t = true
var f = false
"""
    let prog = parseDsl(tokenizeDsl(code))
    assert prog.stmts.len == 2
    assert prog.stmts[0].kind == skVar
    assert prog.stmts[0].varValue.kind == ekBool
    assert prog.stmts[0].varValue.boolVal == true
    assert prog.stmts[1].kind == skVar
    assert prog.stmts[1].varValue.kind == ekBool
    assert prog.stmts[1].varValue.boolVal == false

  test "execute boolean literals":
    initRuntime()
    let code = """
var t = true
var f = false
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let t = getVar(runtimeEnv, "t")
    let f = getVar(runtimeEnv, "f")
    assert t.kind == vkBool
    assert t.b == true
    assert f.kind == vkBool
    assert f.b == false

  test "boolean expressions in conditions":
    initRuntime()
    let code = """
var result = "unknown"
if true:
  result = "yes"
else:
  result = "no"
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let result = getVar(runtimeEnv, "result")
    assert result.s == "yes"

suite "Logical Operator Tests":
  test "parse and operator":
    let code = "var x = true and false"
    let prog = parseDsl(tokenizeDsl(code))
    assert prog.stmts[0].kind == skVar
    assert prog.stmts[0].varValue.kind == ekBinOp
    assert prog.stmts[0].varValue.op == "and"

  test "parse or operator":
    let code = "var x = true or false"
    let prog = parseDsl(tokenizeDsl(code))
    assert prog.stmts[0].kind == skVar
    assert prog.stmts[0].varValue.kind == ekBinOp
    assert prog.stmts[0].varValue.op == "or"

  test "execute and operator":
    initRuntime()
    let code = """
var a = true and true
var b = true and false
var c = false and true
var d = false and false
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    assert getVar(runtimeEnv, "a").b == true
    assert getVar(runtimeEnv, "b").b == false
    assert getVar(runtimeEnv, "c").b == false
    assert getVar(runtimeEnv, "d").b == false

  test "execute or operator":
    initRuntime()
    let code = """
var a = true or true
var b = true or false
var c = false or true
var d = false or false
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    assert getVar(runtimeEnv, "a").b == true
    assert getVar(runtimeEnv, "b").b == true
    assert getVar(runtimeEnv, "c").b == true
    assert getVar(runtimeEnv, "d").b == false

  test "logical operator precedence":
    initRuntime()
    let code = """
var x = true or false and false
var y = false and false or true
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    # 'and' has higher precedence than 'or'
    # x = true or (false and false) = true or false = true
    # y = (false and false) or true = false or true = true
    assert getVar(runtimeEnv, "x").b == true
    assert getVar(runtimeEnv, "y").b == true

  test "short-circuit evaluation for and":
    initRuntime()
    let code = """
var called = false
proc sideEffect():
  called = true
  return true
var result = false and sideEffect()
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    # sideEffect() should NOT be called because first operand is false
    let called = getVar(runtimeEnv, "called")
    assert called.b == false

  test "short-circuit evaluation for or":
    initRuntime()
    let code = """
var called = false
proc sideEffect():
  called = true
  return false
var result = true or sideEffect()
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    # sideEffect() should NOT be called because first operand is true
    let called = getVar(runtimeEnv, "called")
    assert called.b == false

  test "logical operators with comparisons":
    initRuntime()
    let code = """
var x = 5
var y = 10
var result1 = x > 0 and y > 0
var result2 = x > 10 or y > 5
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    assert getVar(runtimeEnv, "result1").b == true
    assert getVar(runtimeEnv, "result2").b == true

suite "For Loop Tests":
  test "parse for loop with range":
    let code = """
for i in range(0, 5):
  var x = i
"""
    let prog = parseDsl(tokenizeDsl(code))
    assert prog.stmts[0].kind == skFor
    assert prog.stmts[0].forVar == "i"

  test "execute for loop with simple range":
    initRuntime()
    let code = """
var count = 0
for i in range(0, 5):
  count = count + 1
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let count = getVar(runtimeEnv, "count")
    assert count.i == 5

  test "execute for loop with accumulation":
    initRuntime()
    let code = """
var sum = 0
for i in range(1, 6):
  sum = sum + i
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let sum = getVar(runtimeEnv, "sum")
    assert sum.i == 15  # 1+2+3+4+5

  test "execute for loop with product":
    initRuntime()
    let code = """
var product = 1
for i in range(2, 5):
  product = product * i
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let product = getVar(runtimeEnv, "product")
    assert product.i == 24  # 2*3*4

  test "nested for loops":
    initRuntime()
    let code = """
var sum = 0
for i in range(0, 3):
  for j in range(0, 3):
    sum = sum + 1
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let sum = getVar(runtimeEnv, "sum")
    assert sum.i == 9  # 3*3

  test "for loop with conditional":
    initRuntime()
    let code = """
var evenSum = 0
for i in range(0, 10):
  var remainder = i % 2
  if remainder == 0:
    evenSum = evenSum + i
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let evenSum = getVar(runtimeEnv, "evenSum")
    assert evenSum.i == 20  # 0+2+4+6+8

  test "for loop variable scope":
    initRuntime()
    let code = """
var last = 0
for i in range(5, 10):
  last = i
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    # Loop variable 'i' is scoped to the loop and not accessible after
    # But 'last' was declared outside and updated inside, so it's accessible
    let last = getVar(runtimeEnv, "last")
    assert last.i == 9  # Last value of loop variable

suite "Scope Chain Tests":
  test "if block scope isolation":
    initRuntime()
    let code = """
var outer = 10
if true:
  var inner = 20
  outer = outer + inner
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let outer = getVar(runtimeEnv, "outer")
    assert outer.i == 30  # Outer variable was modified
    # 'inner' should not be accessible here (would cause runtime error)

  test "for loop scope isolation":
    initRuntime()
    let code = """
var sum = 0
for i in range(0, 5):
  var temp = i * 2
  sum = sum + temp
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let sum = getVar(runtimeEnv, "sum")
    assert sum.i == 20  # 0+2+4+6+8
    # 'i' and 'temp' should not be accessible here

  test "nested scope resolution":
    initRuntime()
    let code = """
var x = 1
if true:
  var y = 2
  if true:
    var z = 3
    x = x + y + z
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let x = getVar(runtimeEnv, "x")
    assert x.i == 6  # 1+2+3

  test "shadowing in nested scopes":
    initRuntime()
    let code = """
var x = 10
if true:
  var x = 20
  if true:
    var x = 30
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let x = getVar(runtimeEnv, "x")
    assert x.i == 10  # Outer x unchanged by inner declarations

  test "explicit block scope":
    initRuntime()
    let code = """
var outer = 1
block:
  var inner = 2
  outer = outer + inner
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let outer = getVar(runtimeEnv, "outer")
    assert outer.i == 3

  test "function parameter scope":
    initRuntime()
    let code = """
var x = 100
proc setX(val: int):
  x = val
setX(50)
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let x = getVar(runtimeEnv, "x")
    assert x.i == 50  # Function can modify outer scope variables

  test "loop variable shadowing":
    initRuntime()
    let code = """
var i = 999
for i in range(0, 3):
  var x = i
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let i = getVar(runtimeEnv, "i")
    assert i.i == 999  # Outer 'i' unchanged by loop variable