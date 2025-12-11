# Test Type Suffixes
# Tests type suffix support on numeric literals

import ../src/nimini

proc main() =
  echo "=== Testing Type Suffix Support ==="
  echo ""

  # Test 1: Basic integer type suffixes
  echo "Test 1: Integer Type Suffixes"
  let code1 = """
var i8val = 127'i8
var i16val = 32767'i16
var i32val = 999999'i32
var i64val = 9999999999'i64

echo("i8: " & $i8val)
echo("i16: " & $i16val)
echo("i32: " & $i32val)
echo("i64: " & $i64val)
"""
  
  let tokens1 = tokenizeDsl(code1)
  let prog1 = parseDsl(tokens1)
  initRuntime()
  execProgram(prog1, runtimeEnv)
  echo ""
  
  # Test 2: Unsigned integer type suffixes
  echo "Test 2: Unsigned Integer Type Suffixes"
  let code2 = """
var u8val = 255'u8
var u16val = 65535'u16
var u32val = 4294967295'u32

echo("u8: " & $u8val)
echo("u16: " & $u16val)
echo("u32: " & $u32val)
"""
  
  let tokens2 = tokenizeDsl(code2)
  let prog2 = parseDsl(tokens2)
  initRuntime()
  execProgram(prog2, runtimeEnv)
  echo ""
  
  # Test 3: Float type suffixes
  echo "Test 3: Float Type Suffixes"
  let code3 = """
var f32val = 3.14'f32
var f64val = 3.14159265359'f64

echo("f32: " & $f32val)
echo("f64: " & $f64val)
"""
  
  let tokens3 = tokenizeDsl(code3)
  let prog3 = parseDsl(tokens3)
  initRuntime()
  execProgram(prog3, runtimeEnv)
  echo ""
  
  # Test 4: Type suffixes in expressions
  echo "Test 4: Type Suffixes in Expressions"
  let code4 = """
var size = 100
var half = size / 2'f32
var doubled = size * 2'i32

echo("Half: " & $half)
echo("Doubled: " & $doubled)
"""
  
  let tokens4 = tokenizeDsl(code4)
  let prog4 = parseDsl(tokens4)
  initRuntime()
  execProgram(prog4, runtimeEnv)
  echo ""
  
  # Test 5: Codegen verification
  echo "Test 5: Nim Codegen Output"
  let codeGen = """
var radius = 5'i32
var pi = 3.14159'f32
var area = radius * radius
"""
  
  let tokensGen = tokenizeDsl(codeGen)
  let progGen = parseDsl(tokensGen)
  let ctx = newCodegenContext()
  let nimCode = generateNimCode(progGen, ctx)
  echo nimCode
  echo ""
  
  echo "All type suffix tests passed!"

main()
