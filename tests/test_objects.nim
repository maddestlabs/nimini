## Test object types, object construction, and field access

import ../nimini
import std/[unittest, strutils]

suite "Object Type Tests":
  
  test "basic object type definition":
    let code = """
type Vector2 = object
  x: float
  y: float
"""
    let prog = parseDsl(tokenizeDsl(code))
    assert prog.stmts.len == 1
    assert prog.stmts[0].kind == skType
    assert prog.stmts[0].typeName == "Vector2"
    assert prog.stmts[0].typeValue.kind == tkObject
    assert prog.stmts[0].typeValue.objectFields.len == 2
    assert prog.stmts[0].typeValue.objectFields[0].name == "x"
    assert prog.stmts[0].typeValue.objectFields[1].name == "y"

  test "object construction":
    let code = """
type Vector2 = object
  x: float
  y: float

var pos = Vector2(x: 10.0, y: 20.0)
"""
    let prog = parseDsl(tokenizeDsl(code))
    assert prog.stmts.len == 2
    assert prog.stmts[1].kind == skVar
    assert prog.stmts[1].varName == "pos"
    assert prog.stmts[1].varValue.kind == ekObjConstr
    assert prog.stmts[1].varValue.objType == "Vector2"
    assert prog.stmts[1].varValue.objFields.len == 2

  test "field access (read)":
    let code = """
type Vector2 = object
  x: float
  y: float

var pos = Vector2(x: 10.0, y: 20.0)
var xVal = pos.x
"""
    let prog = parseDsl(tokenizeDsl(code))
    assert prog.stmts.len == 3
    assert prog.stmts[2].kind == skVar
    assert prog.stmts[2].varValue.kind == ekDot
    assert prog.stmts[2].varValue.dotTarget.kind == ekIdent
    assert prog.stmts[2].varValue.dotField == "x"

  test "field access (write)":
    let code = """
type Vector2 = object
  x: float
  y: float

var pos = Vector2(x: 10.0, y: 20.0)
pos.x = 15.0
"""
    let prog = parseDsl(tokenizeDsl(code))
    assert prog.stmts.len == 3
    assert prog.stmts[2].kind == skAssign
    assert prog.stmts[2].assignTarget.kind == ekDot
    assert prog.stmts[2].assignTarget.dotField == "x"

  test "nested field access":
    let code = """
type Vector2 = object
  x: float
  y: float

type Transform = object
  position: Vector2
  scale: Vector2

var t = Transform(position: Vector2(x: 1.0, y: 2.0), scale: Vector2(x: 3.0, y: 4.0))
var val = t.position.x
"""
    let prog = parseDsl(tokenizeDsl(code))
    # Check nested dot access
    let lastStmt = prog.stmts[^1]
    assert lastStmt.kind == skVar
    assert lastStmt.varValue.kind == ekDot
    assert lastStmt.varValue.dotField == "x"
    assert lastStmt.varValue.dotTarget.kind == ekDot
    assert lastStmt.varValue.dotTarget.dotField == "position"

  test "code generation for objects":
    let code = """
type Vector2 = object
  x: float
  y: float

var pos = Vector2(x: 10.0, y: 20.0)
echo(pos.x)
"""
    let prog = parseDsl(tokenizeDsl(code))
    let nimCode = generateNimCode(prog)
    
    # Check that generated code contains object definition
    assert "type Vector2 = object" in nimCode
    assert "x: float" in nimCode
    assert "y: float" in nimCode
    
    # Check object construction
    assert "Vector2(x: 10.0, y: 20.0)" in nimCode
    
    # Check field access
    assert "pos.x" in nimCode

echo "\nAll object type tests defined!"
echo "Run with: nim c -r tests/test_objects.nim"
