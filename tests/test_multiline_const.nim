## Test multiline const and type definitions

import unittest
import ../nimini/parser
import ../nimini/tokenizer
import ../nimini/ast

suite "Multiline Const and Type Tests":

  test "multiline const block":
    let code = """
const
  a = 1
  b = 2
  c = 3
"""
    let tokens = tokenizeDsl(code)
    let prog = parseDsl(tokens)
    
    assert prog.stmts.len == 3
    assert prog.stmts[0].kind == skConst
    assert prog.stmts[0].constName == "a"
    assert prog.stmts[0].constValue.intVal == 1
    
    assert prog.stmts[1].kind == skConst
    assert prog.stmts[1].constName == "b"
    assert prog.stmts[1].constValue.intVal == 2
    
    assert prog.stmts[2].kind == skConst
    assert prog.stmts[2].constName == "c"
    assert prog.stmts[2].constValue.intVal == 3

  test "multiline type block":
    let code = """
type
  MyInt = int
  MyFloat = float
  MyString = string
"""
    let tokens = tokenizeDsl(code)
    let prog = parseDsl(tokens)
    
    assert prog.stmts.len == 3
    assert prog.stmts[0].kind == skType
    assert prog.stmts[0].typeName == "MyInt"
    
    assert prog.stmts[1].kind == skType
    assert prog.stmts[1].typeName == "MyFloat"
    
    assert prog.stmts[2].kind == skType
    assert prog.stmts[2].typeName == "MyString"

  test "mixed multiline const with type annotations":
    let code = """
const
  width: int = 800
  height: int = 600
  title = "My Window"
"""
    let tokens = tokenizeDsl(code)
    let prog = parseDsl(tokens)
    
    assert prog.stmts.len == 3
    assert prog.stmts[0].kind == skConst
    assert prog.stmts[0].constName == "width"
    assert prog.stmts[0].constValue.intVal == 800
    
    assert prog.stmts[1].kind == skConst
    assert prog.stmts[1].constName == "height"
    assert prog.stmts[1].constValue.intVal == 600
    
    assert prog.stmts[2].kind == skConst
    assert prog.stmts[2].constName == "title"
    assert prog.stmts[2].constValue.strVal == "My Window"

echo "\nAll multiline const and type tests defined!"
