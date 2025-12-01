# Clean, strict, Nim compatible runtime for Nimini

import std/[tables, math, strutils]
import ast

# ------------------------------------------------------------------------------
# Value Types
# ------------------------------------------------------------------------------

type
  ValueKind* = enum
    vkNil,
    vkInt,
    vkFloat,
    vkBool,
    vkString,
    vkFunction,
    vkMap,
    vkArray

  NativeFunc* = proc(env: ref Env; args: seq[Value]): Value

  FunctionVal* = ref object
    isNative*: bool
    native*: NativeFunc
    params*: seq[string]
    stmts*: seq[Stmt]

  Value* = ref object
    kind*: ValueKind
    i*: int
    f*: float
    b*: bool
    s*: string
    fnVal*: FunctionVal
    map*: Table[string, Value]
    arr*: seq[Value]

  Env* = object
    vars*: Table[string, Value]
    parent*: ref Env

proc `$`*(v: Value): string =
  case v.kind
  of vkNil: result = "nil"
  of vkInt: result = $v.i
  of vkFloat: result = $v.f
  of vkBool: result = $v.b
  of vkString: result = v.s
  of vkFunction: result = "<function>"
  of vkArray:
    result = "["
    for i, elem in v.arr:
      if i > 0: result.add(", ")
      result.add($elem)
    result.add("]")
  of vkMap:
    result = "{"
    var first = true
    for k, val in v.map:
      if not first: result.add(", ")
      result.add(k & ": " & $val)
      first = false
    result.add("}")

# ------------------------------------------------------------------------------
# Value Constructors
# ------------------------------------------------------------------------------

proc valNil*(): Value =
  Value(kind: vkNil, i: 0, f: 0.0, b: false, s: "", fnVal: nil)

# Keep i and f in sync so z.f works even for integer results
proc valInt*(i: int): Value =
  Value(kind: vkInt, i: i, f: float(i), b: false, s: "", fnVal: nil)

proc valFloat*(f: float): Value =
  Value(kind: vkFloat, i: int(f), f: f, b: false, s: "", fnVal: nil)

proc valBool*(b: bool): Value =
  Value(
    kind: vkBool,
    i: (if b: 1 else: 0),
    f: (if b: 1.0 else: 0.0),
    b: b,
    s: "",
    fnVal: nil
  )

proc valString*(s: string): Value =
  Value(
    kind: vkString,
    i: 0,
    f: 0.0,
    b: (s.len > 0),
    s: s,
    fnVal: nil
  )

proc valNativeFunc*(fn: NativeFunc): Value =
  Value(kind: vkFunction, fnVal: FunctionVal(
    isNative: true,
    native: fn,
    params: @[],
    stmts: @[]
  ))

proc valUserFunc*(params: seq[string]; stmts: seq[Stmt]): Value =
  Value(kind: vkFunction, fnVal: FunctionVal(
    isNative: false,
    native: nil,
    params: params,
    stmts: stmts
  ))

proc valMap*(initialMap: Table[string, Value] = initTable[string, Value]()): Value =
  Value(kind: vkMap, map: initialMap)

# Alias for compatibility with plugin code
proc newMapValue*(): Value =
  valMap()

# Map access operators
proc `[]`*(v: Value; key: string): Value =
  if v.kind != vkMap:
    quit "Runtime Error: Cannot index non-map value"
  if key in v.map:
    return v.map[key]
  return valNil()

proc `[]=`*(v: Value; key: string; val: Value) =
  if v.kind != vkMap:
    quit "Runtime Error: Cannot set key on non-map value"
  v.map[key] = val

proc getByKey*(v: Value; key: string): Value =
  ## Get a value from a map by key. Returns valNil() if key not found.
  if v.kind != vkMap:
    quit "Runtime Error: getByKey called on non-map value"
  if key in v.map:
    return v.map[key]
  return valNil()

# ------------------------------------------------------------------------------
# Environment
# ------------------------------------------------------------------------------

proc newEnv*(parent: ref Env = nil): ref Env =
  new(result)
  result.vars = initTable[string, Value]()
  result.parent = parent

proc defineVar*(env: ref Env; name: string; v: Value) =
  env.vars[name] = v

proc setVar*(env: ref Env; name: string; v: Value) =
  var e = env
  while e != nil:
    if name in e.vars:
      e.vars[name] = v
      return
    e = e.parent
  env.vars[name] = v

proc getVar*(env: ref Env; name: string): Value =
  var e = env
  while e != nil:
    if name in e.vars:
      return e.vars[name]
    e = e.parent
  quit "Runtime Error: Undefined variable '" & name & "'"

# ------------------------------------------------------------------------------
# Conversion Helpers
# ------------------------------------------------------------------------------

proc toBool(v: Value): bool =
  case v.kind
  of vkNil: false
  of vkBool: v.b
  of vkInt: v.i != 0
  of vkFloat: v.f != 0.0
  of vkString: v.s.len > 0
  of vkFunction: true
  of vkMap: v.map.len > 0
  of vkArray: v.arr.len > 0

proc toFloat(v: Value): float =
  case v.kind
  of vkInt: float(v.i)
  of vkFloat: v.f
  of vkString:
    try:
      parseFloat(v.s)
    except:
      quit "Runtime Error: Cannot convert string '" & v.s & "' to float"
  of vkArray:
    quit "Runtime Error: Cannot convert array to float"
  else:
    quit "Runtime Error: Expected numeric value, got " & $v.kind & " (value: " & $v & ")"

proc toInt(v: Value): int =
  case v.kind
  of vkInt: v.i
  of vkFloat: int(v.f)
  of vkString:
    try:
      parseInt(v.s)
    except:
      quit "Runtime Error: Cannot convert string '" & v.s & "' to int"
  of vkArray:
    quit "Runtime Error: Cannot convert array to int"
  else:
    quit "Runtime Error: Expected numeric value, got " & $v.kind & " (value: " & $v & ")"

# ------------------------------------------------------------------------------
# Return Propagation
# ------------------------------------------------------------------------------

type
  ExecResult = object
    hasReturn: bool
    value: Value

proc noReturn(): ExecResult =
  ExecResult(hasReturn: false, value: valNil())

proc withReturn(v: Value): ExecResult =
  ExecResult(hasReturn: true, value: v)

# ------------------------------------------------------------------------------
# Expression Evaluation
# ------------------------------------------------------------------------------

proc evalExpr(e: Expr; env: ref Env): Value
proc execStmt*(s: Stmt; env: ref Env): ExecResult
proc execBlock(sts: seq[Stmt]; env: ref Env): ExecResult

# Function call --------------------------------------------------------

proc evalCall(name: string; args: seq[Expr]; env: ref Env): Value =
  let val = getVar(env, name)
  if val.kind != vkFunction:
    quit "Runtime Error: '" & name & "' is not callable"

  let fn = val.fnVal

  if fn.isNative:
    var argVals: seq[Value] = @[]
    for a in args:
      argVals.add evalExpr(a, env)
    return fn.native(env, argVals)
  else:
    # User-defined function
    let callEnv = newEnv(env)
    var argVals: seq[Value] = @[]
    for a in args:
      argVals.add evalExpr(a, env)

    # Bind parameters
    for i, pname in fn.params:
      if i < argVals.len:
        defineVar(callEnv, pname, argVals[i])
      else:
        defineVar(callEnv, pname, valNil())

    # Execute body, propagate return
    for st in fn.stmts:
      let res = execStmt(st, callEnv)
      if res.hasReturn:
        return res.value

    valNil()

# Main evalExpr --------------------------------------------------------

proc evalExpr(e: Expr; env: ref Env): Value =
  case e.kind
  of ekInt:    valInt(e.intVal)
  of ekFloat:  valFloat(e.floatVal)
  of ekString: valString(e.strVal)
  of ekBool:   valBool(e.boolVal)
  of ekIdent:  getVar(env, e.ident)

  of ekUnaryOp:
    let v = evalExpr(e.unaryExpr, env)
    case e.unaryOp
    of "-":
      if v.kind == vkFloat:
        valFloat(-v.f)
      else:
        valInt(-toInt(v))
    of "not":
      valBool(not toBool(v))
    of "$":
      valString($v)
    else:
      quit "Unknown unary op: " & e.unaryOp

  of ekBinOp:
    # Handle logical operators with short-circuit evaluation
    if e.op == "and":
      let l = evalExpr(e.left, env)
      if not toBool(l):
        return valBool(false)
      let r = evalExpr(e.right, env)
      return valBool(toBool(r))
    elif e.op == "or":
      let l = evalExpr(e.left, env)
      if toBool(l):
        return valBool(true)
      let r = evalExpr(e.right, env)
      return valBool(toBool(r))

    # Evaluate both sides for other operators
    let l = evalExpr(e.left, env)
    let r = evalExpr(e.right, env)

    case e.op
    of "&":
      # String concatenation - handle first to avoid converting to float
      valString($l & $r)
    of "+", "-", "*", "/", "%", "==", "!=", "<", "<=", ">", ">=":
      # Arithmetic and comparison operators need numeric conversion
      let bothInts = (l.kind == vkInt and r.kind == vkInt)
      let lf = toFloat(l)
      let rf = toFloat(r)

      case e.op
      of "+":
        if bothInts: valInt(l.i + r.i)
        else: valFloat(lf + rf)
      of "-":
        if bothInts: valInt(l.i - r.i)
        else: valFloat(lf - rf)
      of "*":
        if bothInts: valInt(l.i * r.i)
        else: valFloat(lf * rf)
      of "/":
        if bothInts: valInt(l.i div r.i)
        else: valFloat(lf / rf)
      of "%":
        if bothInts: valInt(l.i mod r.i)
        else: valFloat(lf mod rf)
      of "==": valBool(lf == rf)
      of "!=": valBool(lf != rf)
      of "<":  valBool(lf <  rf)
      of "<=": valBool(lf <= rf)
      of ">":  valBool(lf >  rf)
      of ">=": valBool(lf >= rf)
      else: valNil()  # Should never reach here
    
    # Range operators - return a special range value for for-loop iteration
    of "..", "..<":
      # For runtime, we'll create a custom value type that represents a range
      # For simplicity, we'll store it as a map with "start" and "end" keys
      let rangeMap = initTable[string, Value]()
      var rangeVal = valMap()
      rangeVal.map["start"] = valInt(toInt(l))
      if e.op == "..":
        rangeVal.map["end"] = valInt(toInt(r))  # Inclusive
      else:  # ..<
        rangeVal.map["end"] = valInt(toInt(r) - 1)  # Exclusive, so subtract 1
      rangeVal.map["is_range"] = valBool(true)
      rangeVal
    
    else:
      quit "Unknown binary op: " & e.op

  of ekCall:
    evalCall(e.funcName, e.args, env)

  of ekArray:
    var elements: seq[Value] = @[]
    for elem in e.elements:
      elements.add(evalExpr(elem, env))
    Value(kind: vkArray, arr: elements)

  of ekIndex:
    let target = evalExpr(e.indexTarget, env)
    let index = evalExpr(e.indexExpr, env)
    if target.kind != vkArray:
      quit "Cannot index non-array value"
    let idx = toInt(index)
    if idx < 0 or idx >= target.arr.len:
      quit "Index out of bounds: " & $idx & " (array length: " & $target.arr.len & ")"
    target.arr[idx]

# ------------------------------------------------------------------------------
# Statement Execution
# ------------------------------------------------------------------------------

proc execBlock(sts: seq[Stmt]; env: ref Env): ExecResult =
  var res = noReturn()
  for st in sts:
    res = execStmt(st, env)
    if res.hasReturn:
      return res
  res

proc execStmt*(s: Stmt; env: ref Env): ExecResult =
  case s.kind
  of skExpr:
    discard evalExpr(s.expr, env)
    noReturn()

  of skVar:
    defineVar(env, s.varName, evalExpr(s.varValue, env))
    noReturn()

  of skLet:
    defineVar(env, s.letName, evalExpr(s.letValue, env))
    noReturn()

  of skAssign:
    setVar(env, s.target, evalExpr(s.assignValue, env))
    noReturn()

  of skIf:
    # Each branch gets its own scope
    if toBool(evalExpr(s.ifBranch.cond, env)):
      let childEnv = newEnv(env)
      return execBlock(s.ifBranch.stmts, childEnv)

    for br in s.elifBranches:
      if toBool(evalExpr(br.cond, env)):
        let childEnv = newEnv(env)
        return execBlock(br.stmts, childEnv)

    if s.elseStmts.len > 0:
      let childEnv = newEnv(env)
      return execBlock(s.elseStmts, childEnv)

    noReturn()

  of skFor:
    # Evaluate the iterable expression
    let iterableVal = evalExpr(s.forIterable, env)
    
    # Handle different iterable types
    if iterableVal.kind == vkMap and "is_range" in iterableVal.map and iterableVal.map["is_range"].b:
      # Range value created by .. or ..< operators
      let startVal = toInt(iterableVal.map["start"])
      let endVal = toInt(iterableVal.map["end"])
      for i in startVal .. endVal:
        let loopEnv = newEnv(env)
        defineVar(loopEnv, s.forVar, valInt(i))
        let res = execBlock(s.forBody, loopEnv)
        if res.hasReturn:
          return res
    elif iterableVal.kind == vkInt:
      # Simple case: iterate from 0 to value-1 (backward compatibility)
      for i in 0 ..< iterableVal.i:
        let loopEnv = newEnv(env)
        defineVar(loopEnv, s.forVar, valInt(i))
        let res = execBlock(s.forBody, loopEnv)
        if res.hasReturn:
          return res
    else:
      # For other cases, we could extend this to handle custom iterables
      quit "Runtime Error: Cannot iterate over value in for loop (not a range or integer)"

    noReturn()

  of skWhile:
    # Execute while loop
    while true:
      # Evaluate condition
      let condVal = evalExpr(s.whileCond, env)
      if not toBool(condVal):
        break
      
      # Execute body
      let res = execBlock(s.whileBody, env)
      
      # If body returns, propagate the return
      if res.hasReturn:
        return res
    
    noReturn()

  of skProc:
    var pnames: seq[string] = @[]
    for (n, _) in s.params:
      pnames.add(n)
    defineVar(env, s.procName, valUserFunc(pnames, s.body))
    noReturn()

  of skReturn:
    withReturn(evalExpr(s.returnVal, env))

  of skBlock:
    # Explicit blocks create their own scope
    let blockEnv = newEnv(env)
    return execBlock(s.stmts, blockEnv)

# ------------------------------------------------------------------------------
# Program Execution
# ------------------------------------------------------------------------------

var runtimeEnv*: ref Env

proc initRuntime*() =
  runtimeEnv = newEnv(nil)
  # Note: Plugin system is initialized on-demand in plugin.nim

proc execProgram*(prog: Program; env: ref Env) =
  discard execBlock(prog.stmts, env)

# ------------------------------------------------------------------------------
# Native Function Registration / Globals
# ------------------------------------------------------------------------------

proc registerNative*(name: string; fn: NativeFunc) =
  defineVar(runtimeEnv, name, valNativeFunc(fn))

proc setGlobal*(name: string; v: Value) =
  defineVar(runtimeEnv, name, v)

proc setGlobalInt*(name: string; i: int) =
  setGlobal(name, valInt(i))

proc setGlobalFloat*(name: string; f: float) =
  setGlobal(name, valFloat(f))

proc setGlobalBool*(name: string; b: bool) =
  setGlobal(name, valBool(b))

proc setGlobalString*(name: string; s: string) =
  setGlobal(name, valString(s))
