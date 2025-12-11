## Test enum types, enum values, and enum comparisons

import ../src/nimini
import std/[unittest, strutils]

suite "Enum Type Tests":
  
  test "basic enum type definition":
    let code = """
type Color = enum
  red
  green
  blue
"""
    let prog = parseDsl(tokenizeDsl(code))
    assert prog.stmts.len == 1
    assert prog.stmts[0].kind == skType
    assert prog.stmts[0].typeName == "Color"
    assert prog.stmts[0].typeValue.kind == tkEnum
    assert prog.stmts[0].typeValue.enumValues.len == 3
    assert prog.stmts[0].typeValue.enumValues[0].name == "red"
    assert prog.stmts[0].typeValue.enumValues[0].value == 0
    assert prog.stmts[0].typeValue.enumValues[1].name == "green"
    assert prog.stmts[0].typeValue.enumValues[1].value == 1
    assert prog.stmts[0].typeValue.enumValues[2].name == "blue"
    assert prog.stmts[0].typeValue.enumValues[2].value == 2

  test "enum with explicit ordinal values":
    let code = """
type HttpStatus = enum
  ok = 200
  notFound = 404
  serverError = 500
"""
    let prog = parseDsl(tokenizeDsl(code))
    assert prog.stmts.len == 1
    assert prog.stmts[0].typeValue.enumValues.len == 3
    assert prog.stmts[0].typeValue.enumValues[0].name == "ok"
    assert prog.stmts[0].typeValue.enumValues[0].value == 200
    assert prog.stmts[0].typeValue.enumValues[1].name == "notFound"
    assert prog.stmts[0].typeValue.enumValues[1].value == 404
    assert prog.stmts[0].typeValue.enumValues[2].name == "serverError"
    assert prog.stmts[0].typeValue.enumValues[2].value == 500

  test "enum with mixed ordinal values":
    let code = """
type Priority = enum
  low
  medium
  high = 10
  critical
"""
    let prog = parseDsl(tokenizeDsl(code))
    assert prog.stmts.len == 1
    assert prog.stmts[0].typeValue.enumValues.len == 4
    assert prog.stmts[0].typeValue.enumValues[0].value == 0  # low
    assert prog.stmts[0].typeValue.enumValues[1].value == 1  # medium
    assert prog.stmts[0].typeValue.enumValues[2].value == 10 # high (explicit)
    assert prog.stmts[0].typeValue.enumValues[3].value == 11 # critical (auto-increment)

  test "using enum values as identifiers":
    let code = """
type Color = enum
  red
  green
  blue

var c = red
"""
    let prog = parseDsl(tokenizeDsl(code))
    assert prog.stmts.len == 2
    assert prog.stmts[1].kind == skVar
    assert prog.stmts[1].varValue.kind == ekIdent
    assert prog.stmts[1].varValue.ident == "red"

  test "enum in case statement":
    let code = """
type Color = enum
  red
  green
  blue

var c = red
case c
of red:
  echo("It's red")
of green:
  echo("It's green")
of blue:
  echo("It's blue")
"""
    let prog = parseDsl(tokenizeDsl(code))
    assert prog.stmts.len == 3
    assert prog.stmts[2].kind == skCase
    assert prog.stmts[2].ofBranches.len == 3
    assert prog.stmts[2].ofBranches[0].values[0].kind == ekIdent
    assert prog.stmts[2].ofBranches[0].values[0].ident == "red"

  test "code generation for Nim backend":
    let code = """
type Color = enum
  red
  green
  blue

var c = red
"""
    let prog = parseDsl(tokenizeDsl(code))
    let nimCode = generateCode(prog, newNimBackend())
    # Should contain the enum definition
    assert "type Color = enum" in nimCode
    assert "red" in nimCode
    assert "green" in nimCode
    assert "blue" in nimCode
    assert "var c = red" in nimCode

  test "code generation for Nim backend with explicit values":
    let code = """
type HttpStatus = enum
  ok = 200
  notFound = 404
"""
    let prog = parseDsl(tokenizeDsl(code))
    let nimCode = generateCode(prog, newNimBackend())
    assert "type HttpStatus = enum" in nimCode
    assert "ok = 200" in nimCode
    assert "notFound = 404" in nimCode

  test "code generation for Python backend":
    let code = """
type Color = enum
  red
  green
  blue
"""
    let prog = parseDsl(tokenizeDsl(code))
    let pyCode = generateCode(prog, newPythonBackend())
    # Python uses Enum class
    assert "class Color(Enum):" in pyCode
    assert "red = 0" in pyCode
    assert "green = 1" in pyCode
    assert "blue = 2" in pyCode
    # Should import Enum
    assert "from enum import Enum" in pyCode

  test "code generation for JavaScript backend":
    let code = """
type Color = enum
  red
  green
  blue
"""
    let prog = parseDsl(tokenizeDsl(code))
    let jsCode = generateCode(prog, newJavaScriptBackend())
    # JavaScript uses frozen object
    assert "const Color = Object.freeze({" in jsCode
    assert "red: 0" in jsCode
    assert "green: 1" in jsCode
    assert "blue: 2" in jsCode

  test "enum comparison in expressions":
    let code = """
type Color = enum
  red
  green
  blue

var c = red
if c == red:
  echo("Red color")
"""
    let prog = parseDsl(tokenizeDsl(code))
    assert prog.stmts.len == 3
    let ifStmt = prog.stmts[2]
    assert ifStmt.kind == skIf
    assert ifStmt.ifBranch.cond.kind == ekBinOp
    assert ifStmt.ifBranch.cond.op == "=="

  test "empty enum type":
    let code = """
type EmptyEnum = enum
"""
    let prog = parseDsl(tokenizeDsl(code))
    assert prog.stmts.len == 1
    assert prog.stmts[0].typeValue.enumValues.len == 0

  test "enum with type annotation":
    let code = """
type Color = enum
  red
  green
  blue

var c: Color = red
"""
    let prog = parseDsl(tokenizeDsl(code))
    assert prog.stmts.len == 2
    assert prog.stmts[1].varType != nil
    assert prog.stmts[1].varType.kind == tkSimple
    assert prog.stmts[1].varType.typeName == "Color"

  test "multiple enum types":
    let code = """
type Color = enum
  red
  green
  blue

type Size = enum
  small
  medium
  large
"""
    let prog = parseDsl(tokenizeDsl(code))
    assert prog.stmts.len == 2
    assert prog.stmts[0].typeName == "Color"
    assert prog.stmts[1].typeName == "Size"
    assert prog.stmts[0].typeValue.enumValues.len == 3
    assert prog.stmts[1].typeValue.enumValues.len == 3
