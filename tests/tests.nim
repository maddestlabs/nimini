# tests/tests.nim

import unittest
import sequtils
import std/[tables, strutils]
import ../src/nimini

suite "Tokenizer Tests":
  test "tokenize simple variable":
    let tokens = tokenizeDsl("var x = 10")
    assert tokens.len > 0
    assert tokens[0].kind == tkIdent
    assert tokens[0].lexeme == "var"

  test "tokenize string":
    let tokens = tokenizeDsl("var s = \"hello\"")
    assert tokens.anyIt(it.kind == tkString)

  test "tokenize indented block":
    let code = """
if true:
  var x = 1
"""
    let tokens = tokenizeDsl(code)
    assert tokens.anyIt(it.kind == tkIndent)
    assert tokens.anyIt(it.kind == tkDedent)

suite "Parser Tests":
  test "parse variable declaration":
    let code = "var x = 10"
    let tokens = tokenizeDsl(code)
    let prog = parseDsl(tokens)
    assert prog.stmts.len == 1
    assert prog.stmts[0].kind == skVar

  test "parse function definition":
    let code = """
proc add(a:int, b:int):
  return a + b
"""
    let tokens = tokenizeDsl(code)
    let prog = parseDsl(tokens)
    assert prog.stmts.len == 1
    assert prog.stmts[0].kind == skProc
    assert prog.stmts[0].procName == "add"

  test "parse if statement":
    let code = """
if x > 5:
  var y = 10
"""
    let tokens = tokenizeDsl(code)
    let prog = parseDsl(tokens)
    assert prog.stmts.len == 1
    assert prog.stmts[0].kind == skIf

  test "parse for loop":
    let code = """
for i in 0..5:
  var x = i
"""
    let tokens = tokenizeDsl(code)
    let prog = parseDsl(tokens)
    assert prog.stmts.len == 1
    assert prog.stmts[0].kind == skFor

suite "Runtime Tests":
  test "execute variable assignment":
    initRuntime()
    let code = "var x = 42"
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let v = getVar(runtimeEnv, "x")
    assert v.i == 42

  test "execute arithmetic":
    initRuntime()
    let code = """
var x = 10
var y = 20
var z = x + y
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let z = getVar(runtimeEnv, "z")
    assert z.f == 30.0

  test "execute function call":
    initRuntime()
    let code = """
proc double(n:int):
  return n * 2
var result = double(5)
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let result = getVar(runtimeEnv, "result")
    assert result.f == 10.0

  test "execute if statement":
    initRuntime()
    let code = """
var x = 10
var y = ""
if x > 5:
  y = "big"
else:
  y = "small"
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let y = getVar(runtimeEnv, "y")
    assert y.s == "big"

  test "execute for loop":
    initRuntime()
    let code = """
var sum = 0
for i in 0..<5:
  sum = sum + i
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let sum = getVar(runtimeEnv, "sum")
    assert sum.f == 10.0  # 0+1+2+3+4

  test "register native function":
    initRuntime()

    proc testFunc(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
      if args.len > 0 and args[0].kind == vkInt:
        return valInt(args[0].i * 2)
      return valNil()

    registerNative("double", testFunc)
    let code = "var x = double(5)"
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let x = getVar(runtimeEnv, "x")
    assert x.i == 10

suite "Boolean Literal Tests":
  test "tokenize boolean literals":
    let tokens = tokenizeDsl("true false")
    assert tokens[0].kind == tkIdent
    assert tokens[0].lexeme == "true"
    assert tokens[1].kind == tkIdent
    assert tokens[1].lexeme == "false"

  test "parse boolean literals":
    let code = """
var t = true
var f = false
"""
    let prog = parseDsl(tokenizeDsl(code))
    assert prog.stmts.len == 2
    assert prog.stmts[0].kind == skVar
    assert prog.stmts[0].varValue.kind == ekBool
    assert prog.stmts[0].varValue.boolVal == true
    assert prog.stmts[1].kind == skVar
    assert prog.stmts[1].varValue.kind == ekBool
    assert prog.stmts[1].varValue.boolVal == false

  test "execute boolean literals":
    initRuntime()
    let code = """
var t = true
var f = false
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let t = getVar(runtimeEnv, "t")
    let f = getVar(runtimeEnv, "f")
    assert t.kind == vkBool
    assert t.b == true
    assert f.kind == vkBool
    assert f.b == false

  test "boolean expressions in conditions":
    initRuntime()
    let code = """
var result = "unknown"
if true:
  result = "yes"
else:
  result = "no"
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let result = getVar(runtimeEnv, "result")
    assert result.s == "yes"

suite "Logical Operator Tests":
  test "parse and operator":
    let code = "var x = true and false"
    let prog = parseDsl(tokenizeDsl(code))
    assert prog.stmts[0].kind == skVar
    assert prog.stmts[0].varValue.kind == ekBinOp
    assert prog.stmts[0].varValue.op == "and"

  test "parse or operator":
    let code = "var x = true or false"
    let prog = parseDsl(tokenizeDsl(code))
    assert prog.stmts[0].kind == skVar
    assert prog.stmts[0].varValue.kind == ekBinOp
    assert prog.stmts[0].varValue.op == "or"

  test "execute and operator":
    initRuntime()
    let code = """
var a = true and true
var b = true and false
var c = false and true
var d = false and false
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    assert getVar(runtimeEnv, "a").b == true
    assert getVar(runtimeEnv, "b").b == false
    assert getVar(runtimeEnv, "c").b == false
    assert getVar(runtimeEnv, "d").b == false

  test "execute or operator":
    initRuntime()
    let code = """
var a = true or true
var b = true or false
var c = false or true
var d = false or false
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    assert getVar(runtimeEnv, "a").b == true
    assert getVar(runtimeEnv, "b").b == true
    assert getVar(runtimeEnv, "c").b == true
    assert getVar(runtimeEnv, "d").b == false

  test "logical operator precedence":
    initRuntime()
    let code = """
var x = true or false and false
var y = false and false or true
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    # 'and' has higher precedence than 'or'
    # x = true or (false and false) = true or false = true
    # y = (false and false) or true = false or true = true
    assert getVar(runtimeEnv, "x").b == true
    assert getVar(runtimeEnv, "y").b == true

  test "short-circuit evaluation for and":
    initRuntime()
    let code = """
var called = false
proc sideEffect():
  called = true
  return true
var result = false and sideEffect()
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    # sideEffect() should NOT be called because first operand is false
    let called = getVar(runtimeEnv, "called")
    assert called.b == false

  test "short-circuit evaluation for or":
    initRuntime()
    let code = """
var called = false
proc sideEffect():
  called = true
  return false
var result = true or sideEffect()
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    # sideEffect() should NOT be called because first operand is true
    let called = getVar(runtimeEnv, "called")
    assert called.b == false

  test "logical operators with comparisons":
    initRuntime()
    let code = """
var x = 5
var y = 10
var result1 = x > 0 and y > 0
var result2 = x > 10 or y > 5
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    assert getVar(runtimeEnv, "result1").b == true
    assert getVar(runtimeEnv, "result2").b == true

suite "For Loop Tests":
  test "parse for loop with range":
    let code = """
for i in 0..<5:
  var x = i
"""
    let prog = parseDsl(tokenizeDsl(code))
    assert prog.stmts[0].kind == skFor
    assert prog.stmts[0].forVar == "i"

  test "execute for loop with simple range":
    initRuntime()
    let code = """
var count = 0
for i in 0..<5:
  count = count + 1
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let count = getVar(runtimeEnv, "count")
    assert count.i == 5

  test "execute for loop with accumulation":
    initRuntime()
    let code = """
var sum = 0
for i in 1..5:
  sum = sum + i
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let sum = getVar(runtimeEnv, "sum")
    assert sum.i == 15  # 1+2+3+4+5

  test "execute for loop with product":
    initRuntime()
    let code = """
var product = 1
for i in 2..4:
  product = product * i
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let product = getVar(runtimeEnv, "product")
    assert product.i == 24  # 2*3*4

  test "nested for loops":
    initRuntime()
    let code = """
var sum = 0
for i in 0..<3:
  for j in 0..<3:
    sum = sum + 1
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let sum = getVar(runtimeEnv, "sum")
    assert sum.i == 9  # 3*3

  test "for loop with conditional":
    initRuntime()
    let code = """
var evenSum = 0
for i in 0..<10:
  var remainder = i % 2
  if remainder == 0:
    evenSum = evenSum + i
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let evenSum = getVar(runtimeEnv, "evenSum")
    assert evenSum.i == 20  # 0+2+4+6+8

  test "for loop variable scope":
    initRuntime()
    let code = """
var last = 0
for i in 5..9:
  last = i
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    # Loop variable 'i' is scoped to the loop and not accessible after
    # But 'last' was declared outside and updated inside, so it's accessible
    let last = getVar(runtimeEnv, "last")
    assert last.i == 9  # Last value of loop variable

suite "Scope Chain Tests":
  test "if block scope isolation":
    initRuntime()
    let code = """
var outer = 10
if true:
  var inner = 20
  outer = outer + inner
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let outer = getVar(runtimeEnv, "outer")
    assert outer.i == 30  # Outer variable was modified
    # 'inner' should not be accessible here (would cause runtime error)

  test "for loop scope isolation":
    initRuntime()
    let code = """
var sum = 0
for i in 0..<5:
  var temp = i * 2
  sum = sum + temp
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let sum = getVar(runtimeEnv, "sum")
    assert sum.i == 20  # 0+2+4+6+8
    # 'i' and 'temp' should not be accessible here

  test "nested scope resolution":
    initRuntime()
    let code = """
var x = 1
if true:
  var y = 2
  if true:
    var z = 3
    x = x + y + z
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let x = getVar(runtimeEnv, "x")
    assert x.i == 6  # 1+2+3

  test "shadowing in nested scopes":
    initRuntime()
    let code = """
var x = 10
if true:
  var x = 20
  if true:
    var x = 30
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let x = getVar(runtimeEnv, "x")
    assert x.i == 10  # Outer x unchanged by inner declarations

  test "explicit block scope":
    initRuntime()
    let code = """
var outer = 1
block:
  var inner = 2
  outer = outer + inner
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let outer = getVar(runtimeEnv, "outer")
    assert outer.i == 3

  test "function parameter scope":
    initRuntime()
    let code = """
var x = 100
proc setX(val: int):
  x = val
setX(50)
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let x = getVar(runtimeEnv, "x")
    assert x.i == 50  # Function can modify outer scope variables

  test "loop variable shadowing":
    initRuntime()
    let code = """
var i = 999
for i in 0..<3:
  var x = i
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let i = getVar(runtimeEnv, "i")
    assert i.i == 999  # Outer 'i' unchanged by loop variable

suite "Plugin System Tests":
  test "create plugin with metadata":
    let plugin = newPlugin("test", "TestAuthor", "1.0.0", "A test plugin")
    assert plugin.info.name == "test"
    assert plugin.info.author == "TestAuthor"
    assert plugin.info.version == "1.0.0"
    assert plugin.info.description == "A test plugin"
    assert plugin.enabled == true

  test "register function with plugin":
    let plugin = newPlugin("test", "TestAuthor", "1.0.0", "Test")

    proc testFunc(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
      return valInt(42)

    plugin.registerFunc("testFunc", testFunc)
    assert "testFunc" in plugin.functions
    assert plugin.functions["testFunc"] != nil

  test "register constants with plugin":
    let plugin = newPlugin("test", "TestAuthor", "1.0.0", "Test")

    plugin.registerConstantInt("MAX_VALUE", 100)
    plugin.registerConstantFloat("PI", 3.14159)
    plugin.registerConstantString("GREETING", "Hello")
    plugin.registerConstantBool("DEBUG", true)

    assert "MAX_VALUE" in plugin.constants
    assert plugin.constants["MAX_VALUE"].i == 100
    assert "PI" in plugin.constants
    assert plugin.constants["PI"].f == 3.14159
    assert "GREETING" in plugin.constants
    assert plugin.constants["GREETING"].s == "Hello"
    assert "DEBUG" in plugin.constants
    assert plugin.constants["DEBUG"].b == true

  test "register node definitions":
    let plugin = newPlugin("test", "TestAuthor", "1.0.0", "Test")
    plugin.registerNode("CustomNode", "A custom AST node")

    assert plugin.nodes.len == 1
    assert plugin.nodes[0].name == "CustomNode"
    assert plugin.nodes[0].description == "A custom AST node"

  test "plugin lifecycle hooks":
    var loadCalled = false
    var unloadCalled = false

    let plugin = newPlugin("test", "TestAuthor", "1.0.0", "Test")

    plugin.setOnLoad(proc(ctx: PluginContext): void =
      loadCalled = true
    )

    plugin.setOnUnload(proc(ctx: PluginContext): void =
      unloadCalled = true
    )

    initRuntime()
    let ctx = newPluginContext(runtimeEnv)

    # Test onLoad hook
    if plugin.hooks.onLoad != nil:
      plugin.hooks.onLoad(ctx)
    assert loadCalled == true

    # Test onUnload hook
    if plugin.hooks.onUnload != nil:
      plugin.hooks.onUnload(ctx)
    assert unloadCalled == true

  test "register plugin in registry":
    let registry = newPluginRegistry()
    let plugin = newPlugin("test", "TestAuthor", "1.0.0", "Test")

    registry.registerPlugin(plugin)

    assert registry.hasPlugin("test")
    assert registry.listPlugins().len == 1
    assert registry.listPlugins()[0] == "test"

  test "load plugin into runtime":
    initRuntime()

    var hookCalled = false
    let plugin = newPlugin("testPlugin", "TestAuthor", "1.0.0", "Test")

    proc addFunc(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
      if args.len >= 2:
        return valInt(args[0].i + args[1].i)
      return valNil()

    plugin.registerFunc("add", addFunc)
    plugin.registerConstantInt("MAGIC_NUMBER", 42)

    plugin.setOnLoad(proc(ctx: PluginContext): void =
      hookCalled = true
    )

    let registry = newPluginRegistry()
    registry.registerPlugin(plugin)
    registry.loadPlugin(plugin, runtimeEnv)

    # Check that hook was called
    assert hookCalled == true

    # Check that function is available in runtime
    let code = "var result = add(10, 20)"
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)
    let result = getVar(runtimeEnv, "result")
    assert result.i == 30

    # Check that constant is available
    let constVal = getVar(runtimeEnv, "MAGIC_NUMBER")
    assert constVal.i == 42

  test "plugin with multiple functions":
    initRuntime()

    let plugin = newPlugin("math", "TestAuthor", "1.0.0", "Math utilities")

    proc multiplyFunc(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
      if args.len >= 2:
        return valInt(args[0].i * args[1].i)
      return valNil()

    proc squareFunc(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
      if args.len >= 1:
        return valInt(args[0].i * args[0].i)
      return valNil()

    plugin.registerFunc("multiply", multiplyFunc)
    plugin.registerFunc("square", squareFunc)

    let registry = newPluginRegistry()
    registry.registerPlugin(plugin)
    registry.loadPlugin(plugin, runtimeEnv)

    let code = """
var a = multiply(3, 4)
var b = square(5)
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)

    let a = getVar(runtimeEnv, "a")
    let b = getVar(runtimeEnv, "b")
    assert a.i == 12
    assert b.i == 25

  test "global plugin registry":
    initPluginSystem()

    let plugin = newPlugin("global", "TestAuthor", "1.0.0", "Global test")
    registerPlugin(plugin)

    assert hasPlugin("global")
    assert listPlugins().len >= 1

    let retrieved = getPlugin("global")
    assert retrieved.info.name == "global"

  test "load all plugins":
    initRuntime()
    let registry = newPluginRegistry()

    let plugin1 = newPlugin("plugin1", "Author", "1.0.0", "First")
    let plugin2 = newPlugin("plugin2", "Author", "1.0.0", "Second")

    proc func1(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
      return valInt(1)

    proc func2(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
      return valInt(2)

    plugin1.registerFunc("func1", func1)
    plugin2.registerFunc("func2", func2)

    registry.registerPlugin(plugin1)
    registry.registerPlugin(plugin2)
    registry.loadAllPlugins(runtimeEnv)

    # Both functions should be available
    let code = """
var a = func1()
var b = func2()
"""
    let prog = parseDsl(tokenizeDsl(code))
    execProgram(prog, runtimeEnv)

    let a = getVar(runtimeEnv, "a")
    let b = getVar(runtimeEnv, "b")
    assert a.i == 1
    assert b.i == 2

  test "plugin string representation":
    let plugin = newPlugin("myPlugin", "John Doe", "2.5.0", "My awesome plugin")
    let str = $plugin
    assert "myPlugin" in str
    assert "2.5.0" in str

  test "plugin info string representation":
    let info = PluginInfo(
      name: "testInfo",
      author: "Jane Doe",
      version: "1.2.3",
      description: "Test plugin info"
    )
    let str = $info
    assert "testInfo" in str
    assert "1.2.3" in str
    assert "Jane Doe" in str

suite "Codegen Tests":
  test "generate code for simple variable":
    let code = "var x = 42"
    let prog = parseDsl(tokenizeDsl(code))
    let ctx = newCodegenContext()
    let nimCode = generateNimCode(prog, ctx)
    assert "var x = 42" in nimCode

  test "generate code for arithmetic":
    let code = "var result = 10 + 20"
    let prog = parseDsl(tokenizeDsl(code))
    let ctx = newCodegenContext()
    let nimCode = generateNimCode(prog, ctx)
    assert "var result = (10 + 20)" in nimCode

  test "generate code for if statement":
    let code = """
if x > 5:
  var y = 10
else:
  var y = 20
"""
    let prog = parseDsl(tokenizeDsl(code))
    let ctx = newCodegenContext()
    let nimCode = generateNimCode(prog, ctx)
    assert "if" in nimCode
    assert "else:" in nimCode

  test "generate code for for loop":
    let code = """
for i in 0..<5:
  var x = i
"""
    let prog = parseDsl(tokenizeDsl(code))
    let ctx = newCodegenContext()
    let nimCode = generateNimCode(prog, ctx)
    assert "for i in" in nimCode
    assert "..<" in nimCode

  test "generate code for function call":
    let code = "var result = myFunc(10, 20)"
    let prog = parseDsl(tokenizeDsl(code))
    let ctx = newCodegenContext()
    let nimCode = generateNimCode(prog, ctx)
    assert "myFunc(10, 20)" in nimCode

  test "generate code with function mapping":
    let code = "var result = sqrt(16.0)"
    let prog = parseDsl(tokenizeDsl(code))
    let ctx = newCodegenContext()
    ctx.addFunctionMapping("sqrt", "math.sqrt")
    let nimCode = generateNimCode(prog, ctx)
    assert "math.sqrt(16.0)" in nimCode

  test "generate code with constant mapping":
    let code = "var area = PI * 2.0"
    let prog = parseDsl(tokenizeDsl(code))
    let ctx = newCodegenContext()
    ctx.addConstantMapping("PI", "math.PI")
    let nimCode = generateNimCode(prog, ctx)
    assert "math.PI" in nimCode

  test "generate code with imports":
    let code = "var x = 42"
    let prog = parseDsl(tokenizeDsl(code))
    let ctx = newCodegenContext()
    ctx.addImport("std/math")
    ctx.addImport("std/strutils")
    let nimCode = generateNimCode(prog, ctx)
    assert "import std/math" in nimCode
    assert "import std/strutils" in nimCode

  test "plugin codegen integration":
    let plugin = newPlugin("math", "TestAuthor", "1.0.0", "Math plugin")

    proc sqrtFunc(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
      return valNil()

    plugin.registerFunc("sqrt", sqrtFunc)
    plugin.registerConstantFloat("PI", 3.14159)

    # Add codegen mappings
    plugin.addNimImport("std/math")
    plugin.mapFunction("sqrt", "sqrt")
    plugin.mapConstant("PI", "PI")

    # Check that codegen metadata was stored
    assert plugin.codegen.nimImports.len == 1
    assert plugin.codegen.nimImports[0] == "std/math"
    assert "sqrt" in plugin.codegen.functionMappings
    assert "PI" in plugin.codegen.constantMappings

  test "apply plugin codegen to context":
    let plugin = newPlugin("math", "TestAuthor", "1.0.0", "Math")
    plugin.addNimImport("std/math")
    plugin.mapFunction("pow", "math.pow")
    plugin.mapConstant("E", "math.E")

    let ctx = newCodegenContext()
    applyPluginCodegen(plugin, ctx)

    # Check that mappings were applied
    assert ctx.hasImport("std/math")
    assert ctx.hasFunction("pow")
    assert ctx.getFunctionMapping("pow") == "math.pow"
    assert ctx.hasConstant("E")
    assert ctx.getConstantMapping("E") == "math.E"

  test "generate code for proc definition":
    let code = """
proc double(x: int):
  return x * 2
"""
    let prog = parseDsl(tokenizeDsl(code))
    let ctx = newCodegenContext()
    let nimCode = generateNimCode(prog, ctx)
    assert "proc double" in nimCode
    assert "return" in nimCode

  test "generate code with boolean expressions":
    let code = """
var a = true
var b = false
var c = a and b
var d = a or b
"""
    let prog = parseDsl(tokenizeDsl(code))
    let ctx = newCodegenContext()
    let nimCode = generateNimCode(prog, ctx)
    assert "true" in nimCode
    assert "false" in nimCode
    assert "and" in nimCode
    assert "or" in nimCode

  test "generate code for nested expressions":
    let code = "var result = (a + b) * (c - d)"
    let prog = parseDsl(tokenizeDsl(code))
    let ctx = newCodegenContext()
    let nimCode = generateNimCode(prog, ctx)
    # Check that parentheses are preserved in generated code
    assert "*" in nimCode
    assert "+" in nimCode
    assert "-" in nimCode