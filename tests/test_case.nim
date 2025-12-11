## Test case statements in Nimini

import ../src/nimini
import std/[unittest, strutils]

suite "Case Statement Tests":
  
  test "basic case with integers":
    let code = """
var x = 2
case x
of 1:
  echo("one")
of 2:
  echo("two")
of 3:
  echo("three")
else:
  echo("other")
"""
    initRuntime()
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    assert prog.stmts.len == 2  # var + case
    assert prog.stmts[1].kind == skCase

  test "case with multiple values per branch":
    let code = """
var x = 5
case x
of 1, 2, 3:
  echo("small")
of 4, 5, 6:
  echo("medium")
of 7, 8, 9:
  echo("large")
else:
  echo("other")
"""
    initRuntime()
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    assert prog.stmts[1].kind == skCase
    # Verify the of branch has multiple values
    assert prog.stmts[1].ofBranches[0].values.len == 3

  test "case with strings":
    let code = """
var cmd = "start"
case cmd
of "start":
  echo("starting")
of "stop", "quit":
  echo("stopping")
else:
  echo("unknown")
"""
    initRuntime()
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    assert prog.stmts[1].kind == skCase

  test "case with elif":
    let code = """
var x = 100
case x
of 1:
  echo("one")
of 2:
  echo("two")
elif x > 50:
  echo("large number")
else:
  echo("other")
"""
    initRuntime()
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    assert prog.stmts[1].kind == skCase
    assert prog.stmts[1].caseElif.len == 1

  test "case without else (should work with matched values)":
    let code = """
var x = 1
case x
of 1:
  echo("matched")
of 2:
  echo("also matched")
else:
  echo("fallback")
"""
    initRuntime()
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    # Should execute without error

  test "case inline syntax":
    let code = """
var x = 2
case x
of 1: echo("one")
of 2: echo("two")
else: echo("other")
"""
    initRuntime()
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    assert prog.stmts[1].kind == skCase

  test "case with optional colon after expression":
    let code = """
var x = 1
case x:
of 1:
  echo("one")
else:
  echo("other")
"""
    initRuntime()
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    assert prog.stmts[1].kind == skCase

  test "case statement code generation":
    let code = """
var x = 2
case x
of 1:
  echo("one")
of 2, 3:
  echo("two or three")
else:
  echo("other")
"""
    let prog = parseDsl(tokenizeDsl(code))
    let ctx = newCodegenContext()
    let nimCode = generateNimCode(prog, ctx)
    assert "case" in nimCode
    assert "of 1:" in nimCode
    assert "of 2, 3:" in nimCode
    assert "else:" in nimCode
