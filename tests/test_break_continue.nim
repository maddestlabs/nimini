import std/[unittest, strutils]
import ../src/nimini/[tokenizer, parser, runtime]

suite "Break and Continue Statements":
  setup:
    initRuntime()
    
  test "break in while loop":
    let code = """
var i = 0
while i < 10:
  if i == 5:
    break
  i = i + 1
"""
    let tokens = tokenizeDsl(code)
    let prog = parseDsl(tokens)
    execProgram(prog, runtimeEnv)
    let i = getVar(runtimeEnv, "i")
    check i.i == 5

  test "continue in while loop":
    let code = """
var i = 0
var sum = 0
while i < 10:
  i = i + 1
  if i % 2 == 0:
    continue
  sum = sum + i
"""
    let tokens = tokenizeDsl(code)
    let prog = parseDsl(tokens)
    execProgram(prog, runtimeEnv)
    let sum = getVar(runtimeEnv, "sum")
    # Should sum odd numbers 1,3,5,7,9 = 25
    check sum.i == 25

  test "break in for loop":
    let code = """
var found = 0
for i in 1..10:
  if i == 7:
    found = i
    break
"""
    let tokens = tokenizeDsl(code)
    let prog = parseDsl(tokens)
    execProgram(prog, runtimeEnv)
    let found = getVar(runtimeEnv, "found")
    check found.i == 7

  test "continue in for loop":
    let code = """
var sum = 0
for i in 1..10:
  if i % 3 == 0:
    continue
  sum = sum + i
"""
    let tokens = tokenizeDsl(code)
    let prog = parseDsl(tokens)
    execProgram(prog, runtimeEnv)
    let sum = getVar(runtimeEnv, "sum")
    # Should sum all except 3,6,9: 1+2+4+5+7+8+10 = 37
    check sum.i == 37

  test "nested loops with break":
    let code = """
var found = false
for i in 1..5:
  for j in 1..5:
    if i * j == 12:
      found = true
      break
  if found:
    break
"""
    let tokens = tokenizeDsl(code)
    let prog = parseDsl(tokens)
    execProgram(prog, runtimeEnv)
    let found = getVar(runtimeEnv, "found")
    check found.b == true

  test "nested loops with continue":
    let code = """
var count = 0
for i in 1..3:
  for j in 1..3:
    if j == 2:
      continue
    count = count + 1
"""
    let tokens = tokenizeDsl(code)
    let prog = parseDsl(tokens)
    execProgram(prog, runtimeEnv)
    let count = getVar(runtimeEnv, "count")
    # Should count 2 iterations per outer loop (skip j==2) = 6
    check count.i == 6

  test "break with early exit":
    let code = """
var x = 0
for i in 1..100:
  x = i
  if i >= 3:
    break
"""
    let tokens = tokenizeDsl(code)
    let prog = parseDsl(tokens)
    execProgram(prog, runtimeEnv)
    let x = getVar(runtimeEnv, "x")
    check x.i == 3

  test "multiple continue in loop":
    let code = """
var result = 0
for i in 0..10:
  if i < 3:
    continue
  if i > 7:
    continue
  result = result + i
"""
    let tokens = tokenizeDsl(code)
    let prog = parseDsl(tokens)
    execProgram(prog, runtimeEnv)
    let result = getVar(runtimeEnv, "result")
    # Should sum 3,4,5,6,7 = 25
    check result.i == 25
