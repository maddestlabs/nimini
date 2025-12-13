## Tests for math stdlib functions

import ../nimini
import std/math
import std/unittest

suite "Math Stdlib Functions":
  setup:
    initRuntime()
    initStdlib()
  
  test "sin function":
    let code = """
var result = sin(0.0)
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let result = getVar(runtimeEnv, "result")
    check result.f == 0.0
  
  test "cos function":
    let code = """
var result = cos(0.0)
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let result = getVar(runtimeEnv, "result")
    check result.f == 1.0
  
  test "sqrt function":
    let code = """
var result = sqrt(16.0)
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let result = getVar(runtimeEnv, "result")
    check result.f == 4.0
  
  test "pow function":
    let code = """
var result = pow(2.0, 3.0)
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let result = getVar(runtimeEnv, "result")
    check result.f == 8.0
  
  test "abs function with int":
    let code = """
var result = abs(-5)
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let result = getVar(runtimeEnv, "result")
    check result.i == 5
  
  test "abs function with float":
    let code = """
var result = abs(-3.5)
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let result = getVar(runtimeEnv, "result")
    check result.f == 3.5
  
  test "floor function":
    let code = """
var result = floor(3.7)
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let result = getVar(runtimeEnv, "result")
    check result.f == 3.0
  
  test "ceil function":
    let code = """
var result = ceil(3.2)
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let result = getVar(runtimeEnv, "result")
    check result.f == 4.0
  
  test "min function":
    let code = """
var result = min(5.0, 3.0)
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let result = getVar(runtimeEnv, "result")
    check result.f == 3.0
  
  test "max function":
    let code = """
var result = max(5.0, 3.0)
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let result = getVar(runtimeEnv, "result")
    check result.f == 5.0
  
  test "PI constant":
    let code = """
var result = PI
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let result = getVar(runtimeEnv, "result")
    check abs(result.f - PI) < 0.0001
  
  test "E constant":
    let code = """
var result = E
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let result = getVar(runtimeEnv, "result")
    check abs(result.f - E) < 0.0001
  
  test "degToRad function":
    let code = """
var result = degToRad(180.0)
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let result = getVar(runtimeEnv, "result")
    check abs(result.f - PI) < 0.0001
  
  test "type conversion - int":
    let code = """
var result = int(3.7)
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let result = getVar(runtimeEnv, "result")
    check result.i == 3
  
  test "type conversion - float":
    let code = """
var result = float(5)
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let result = getVar(runtimeEnv, "result")
    check result.f == 5.0
  
  test "type conversion - str":
    let code = """
var result = str(42)
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let result = getVar(runtimeEnv, "result")
    check result.s == "42"
  
  test "combined math operations":
    let code = """
var radius = 5.0
var area = PI * pow(radius, 2.0)
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let area = getVar(runtimeEnv, "area")
    check abs(area.f - (PI * 25.0)) < 0.0001
