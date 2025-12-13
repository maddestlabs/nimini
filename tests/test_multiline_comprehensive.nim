## Comprehensive test of multiline const and type blocks
import unittest
import ../nimini/parser
import ../nimini/tokenizer
import ../nimini/ast
import ../nimini/runtime

suite "Comprehensive Multiline Blocks":

  test "const block with blank lines and comments":
    let code = """
const
  # Configuration
  Width = 800
  
  Height = 600
  
  # Title
  Title = "Test"
"""
    let tokens = tokenizeDsl(code)
    let prog = parseDsl(tokens)
    
    assert prog.stmts.len == 3
    assert prog.stmts[0].constName == "Width"
    assert prog.stmts[1].constName == "Height"
    assert prog.stmts[2].constName == "Title"

  test "type block with mixed types":
    let code = """
type
  Int32 = int
  
  Point = object
    x: float
    y: float
  
  Color = enum
    Red
    Green
"""
    let tokens = tokenizeDsl(code)
    let prog = parseDsl(tokens)
    
    assert prog.stmts.len == 3
    assert prog.stmts[0].kind == skType
    assert prog.stmts[1].kind == skType
    assert prog.stmts[2].kind == skType

  test "execution with multiline const":
    let code = """
const
  a = 10
  b = 20
  c = 30

var sum = a + b + c
"""
    let tokens = tokenizeDsl(code)
    let prog = parseDsl(tokens)
    
    initRuntime()
    execProgram(prog, runtimeEnv)
    
    let sum = getVar(runtimeEnv, "sum")
    assert sum.i == 60

  test "execution with type aliases":
    let code = """
type
  Score = int
  Name = string

var playerScore: Score = 100
var playerName: Name = "Alice"
"""
    let tokens = tokenizeDsl(code)
    let prog = parseDsl(tokens)
    
    initRuntime()
    execProgram(prog, runtimeEnv)
    
    let score = getVar(runtimeEnv, "playerScore")
    let name = getVar(runtimeEnv, "playerName")
    assert score.i == 100
    assert name.s == "Alice"

echo "\nAll comprehensive multiline tests passed!"
