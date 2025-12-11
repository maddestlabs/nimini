## Test multi-line object construction

import ../src/nimini
import std/[unittest, strutils]

suite "Multi-line Object Construction Tests":
  
  test "simple multi-line object construction":
    let code = """
type Vector2 = object
  x: float
  y: float

var pos = Vector2(
  x: 10.0,
  y: 20.0
)
"""
    let prog = parseDsl(tokenizeDsl(code))
    assert prog.stmts.len == 2
    assert prog.stmts[1].kind == skVar
    assert prog.stmts[1].varValue.kind == ekObjConstr
    assert prog.stmts[1].varValue.objFields.len == 2

  test "nested multi-line object construction":
    let code = """
type Vector2 = object
  x: float
  y: float

type Color = object
  r: int
  g: int
  b: int

type ClockHand = object
  angle: float
  length: int
  thickness: int
  color: Color
  value: int
  origin: Vector2

type Clock = object
  mode: int
  second: ClockHand

var myClock = Clock(
  mode: 0,
  second: ClockHand(
    angle: 45,
    length: 140,
    thickness: 3,
    color: Color(r: 245, g: 245, b: 220),
    value: 0,
    origin: Vector2(x: 0, y: 0)
  )
)
"""
    let prog = parseDsl(tokenizeDsl(code))
    # Should parse without errors
    assert prog.stmts.len == 5  # 4 type defs + 1 var
    
    let varStmt = prog.stmts[4]
    assert varStmt.kind == skVar
    assert varStmt.varName == "myClock"
    assert varStmt.varValue.kind == ekObjConstr
    assert varStmt.varValue.objType == "Clock"
    assert varStmt.varValue.objFields.len == 2
    
    # Check the nested ClockHand construction
    let secondField = varStmt.varValue.objFields[1]
    assert secondField.name == "second"
    assert secondField.value.kind == ekObjConstr
    assert secondField.value.objType == "ClockHand"
    assert secondField.value.objFields.len == 6

  test "multi-line with trailing comma":
    let code = """
type Vector2 = object
  x: float
  y: float

var pos = Vector2(
  x: 10.0,
  y: 20.0,
)
"""
    let prog = parseDsl(tokenizeDsl(code))
    assert prog.stmts.len == 2
    assert prog.stmts[1].varValue.objFields.len == 2

  test "code generation preserves structure":
    let code = """
type Vector2 = object
  x: float
  y: float

var pos = Vector2(
  x: 10.0,
  y: 20.0
)
"""
    let prog = parseDsl(tokenizeDsl(code))
    let nimCode = generateNimCode(prog)
    
    # Generated code should be valid
    assert "Vector2(x: 10.0, y: 20.0)" in nimCode

echo "\nAll multi-line object construction tests defined!"
echo "Run with: nim c -r tests/test_multiline_objects.nim"
