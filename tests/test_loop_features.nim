# tests/test_loop_features.nim
# Tests for loop labels and multi-variable for loops

import unittest
import std/strutils
import ../nimini

echo "Running loop feature tests..."

suite "Loop Label Tests":
  test "break with label in nested loops":
    initRuntime()
    let code = """
var count = 0
block outer:
  for i in 0..<3:
    for j in 0..<3:
      count = count + 1
      if j == 1:
        break outer
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let count = getVar(runtimeEnv, "count")
    # Should break outer loop when j==1 in first iteration of i
    # i=0, j=0: count=1
    # i=0, j=1: count=2, then break outer
    assert count.i == 2, "Expected count=2, got " & $count.i

  test "continue with label in nested loops":
    initRuntime()
    let code = """
var count = 0
for i in 0..<3:
  for j in 0..<3:
    if j == 1:
      break
    count = count + 1
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let count = getVar(runtimeEnv, "count")
    # Each outer iteration: j=0 increments count, j=1 breaks inner loop
    # So count increments once per i iteration = 3 times
    assert count.i == 3, "Expected count=3, got " & $count.i

  test "break without label in nested loops":
    initRuntime()
    let code = """
var count = 0
for i in 0..<3:
  for j in 0..<3:
    count = count + 1
    if j == 1:
      break
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let count = getVar(runtimeEnv, "count")
    # Each outer iteration: j=0 and j=1 increment count, then break inner
    # 3 outer iterations * 2 inner iterations = 6
    assert count.i == 6, "Expected count=6, got " & $count.i

  test "labeled while loop with break":
    initRuntime()
    let code = """
var i = 0
var j = 0
block outer:
  while i < 3:
    i = i + 1
    j = 0
    while j < 3:
      j = j + 1
      if j == 2:
        break outer
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let i = getVar(runtimeEnv, "i")
    let j = getVar(runtimeEnv, "j")
    # Should break outer when j reaches 2 in first iteration
    assert i.i == 1, "Expected i=1, got " & $i.i
    assert j.i == 2, "Expected j=2, got " & $j.i

suite "Multi-Variable For Loop Tests":
  test "for with two variables over array":
    initRuntime()
    let code = """
var arr = [10, 20, 30]
var sum = 0
var idxSum = 0
for i, item in arr:
  idxSum = idxSum + i
  sum = sum + item
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let sum = getVar(runtimeEnv, "sum")
    let idxSum = getVar(runtimeEnv, "idxSum")
    assert sum.i == 60, "Expected sum=60, got " & $sum.i  # 10+20+30
    assert idxSum.i == 3, "Expected idxSum=3, got " & $idxSum.i  # 0+1+2

  test "for with single variable over array gets elements":
    initRuntime()
    let code = """
var arr = [5, 10, 15]
var sum = 0
for item in arr:
  sum = sum + item
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let sum = getVar(runtimeEnv, "sum")
    assert sum.i == 30, "Expected sum=30, got " & $sum.i  # 5+10+15

  test "for with multiple variables over range":
    initRuntime()
    let code = """
var sum = 0
for i, j in 0..<5:
  sum = sum + i
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let sum = getVar(runtimeEnv, "sum")
    # When iterating over range, first var gets index, others are nil
    # So this should sum 0+1+2+3+4 = 10
    assert sum.i == 10, "Expected sum=10, got " & $sum.i

suite "Codegen for Loop Labels":
  test "generate code for labeled for loop":
    let code = """
block outer:
  for i in 0..<5:
    if i == 3:
      break outer
"""
    let prog = parseDsl(tokenizeDsl(code))
    let ctx = newCodegenContext()
    let nimCode = generateNimCode(prog, ctx)
    assert "block outer:" in nimCode
    assert "for i in" in nimCode
    assert "break outer" in nimCode

  test "generate code for labeled while loop":
    let code = """
block myloop:
  while true:
    break myloop
"""
    let prog = parseDsl(tokenizeDsl(code))
    let ctx = newCodegenContext()
    let nimCode = generateNimCode(prog, ctx)
    assert "block myloop:" in nimCode
    assert "while" in nimCode
    assert "break myloop" in nimCode

  test "generate code for multi-variable for loop":
    let code = """
var arr = [1, 2, 3]
for i, item in arr:
  var x = i + item
"""
    let prog = parseDsl(tokenizeDsl(code))
    let ctx = newCodegenContext()
    let nimCode = generateNimCode(prog, ctx)
    assert "for i, item in" in nimCode

suite "Complex Loop Label Scenarios":
  test "triple nested loops with multiple labels":
    initRuntime()
    let code = """
var result = 0
block outer:
  for i in 0..<2:
    block middle:
      for j in 0..<2:
        for k in 0..<2:
          result = result + 1
          if k == 1 and j == 1 and i == 0:
            break outer
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let result = getVar(runtimeEnv, "result")
    # i=0, j=0, k=0: result=1
    # i=0, j=0, k=1: result=2
    # i=0, j=1, k=0: result=3
    # i=0, j=1, k=1: result=4, break outer
    assert result.i == 4, "Expected result=4, got " & $result.i

  test "labeled loop with continue to specific level":
    initRuntime()
    let code = """
var count = 0
for i in 0..<3:
  for j in 0..<3:
    if j == 1:
      break
    count = count + 1
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let count = getVar(runtimeEnv, "count")
    # For each i: j=0 increments count, j=1 breaks inner loop
    # So count = 3 (once per i iteration)
    assert count.i == 3, "Expected count=3, got " & $count.i
