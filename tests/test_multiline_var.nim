## Test multiline var and let blocks

import unittest
import ../nimini/parser
import ../nimini/tokenizer
import ../nimini/ast

suite "Multiline Var and Let Tests":

  test "multiline var block":
    let code = """
var
  x = 1
  y = 2
  z = 3
"""
    let tokens = tokenizeDsl(code)
    let prog = parseDsl(tokens)
    
    assert prog.stmts.len == 3
    assert prog.stmts[0].kind == skVar
    assert prog.stmts[0].varName == "x"
    assert prog.stmts[0].varValue.intVal == 1
    
    assert prog.stmts[1].kind == skVar
    assert prog.stmts[1].varName == "y"
    assert prog.stmts[1].varValue.intVal == 2
    
    assert prog.stmts[2].kind == skVar
    assert prog.stmts[2].varName == "z"
    assert prog.stmts[2].varValue.intVal == 3

  test "multiline let block":
    let code = """
let
  a = 10
  b = 20
  c = 30
"""
    let tokens = tokenizeDsl(code)
    let prog = parseDsl(tokens)
    
    assert prog.stmts.len == 3
    assert prog.stmts[0].kind == skLet
    assert prog.stmts[0].letName == "a"
    assert prog.stmts[0].letValue.intVal == 10
    
    assert prog.stmts[1].kind == skLet
    assert prog.stmts[1].letName == "b"
    
    assert prog.stmts[2].kind == skLet
    assert prog.stmts[2].letName == "c"

  test "multiline var with blank lines and type annotations":
    let code = """
var
  l1: float = 15.0
  
  m1: float = 0.2
  
  count = 5
"""
    let tokens = tokenizeDsl(code)
    let prog = parseDsl(tokens)
    
    assert prog.stmts.len == 3
    assert prog.stmts[0].kind == skVar
    assert prog.stmts[0].varName == "l1"
    
    assert prog.stmts[1].kind == skVar
    assert prog.stmts[1].varName == "m1"
    
    assert prog.stmts[2].kind == skVar
    assert prog.stmts[2].varName == "count"

  test "multiline var with type suffixes":
    let code = """
var
  l1 = 15'f32
  m1 = 0.2'f32
  count = 100'i32
"""
    let tokens = tokenizeDsl(code)
    let prog = parseDsl(tokens)
    
    assert prog.stmts.len == 3
    assert prog.stmts[0].kind == skVar
    assert prog.stmts[0].varName == "l1"
    assert prog.stmts[0].varValue.kind == ekFloat
    assert prog.stmts[0].varValue.floatTypeSuffix == "f32"
    
    assert prog.stmts[1].kind == skVar
    assert prog.stmts[1].varName == "m1"
    
    assert prog.stmts[2].kind == skVar
    assert prog.stmts[2].varName == "count"

echo "\nAll multiline var and let tests passed!"
