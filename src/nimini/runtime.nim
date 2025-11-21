# Clean, strict, Nim compatible runtime for Nimini

import std/[tables, strutils, math]
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
    vkFunction

  NativeFunc* = proc(env: ref Env; args: seq[Value]): Value {.gcsafe.}

  FunctionVal* = ref object
    isNative*: bool
    native*: NativeFunc
    params*: seq[string]
    stmts*: seq[Stmt]

  Value* = ref object
    case kind*: ValueKind
    of vkNil:
      discard
    of vkInt:
      i*: int
    of vkFloat:
      f*: float
    of vkBool:
      b*: bool
    of vkString:
      s*: string
    of vkFunction:
      fnVal*: FunctionVal

  Env* = object
    vars*: Table[string, Value]
    parent*: ref Env

proc `$`*(v: Value): string =
  case v.kind
  of vkNil: "nil"
  of vkInt: $v.i
  of vkFloat: $v.f
  of vkBool: $v.b
  of vkString: v.s
  of vkFunction: "<function>"

# ------------------------------------------------------------------------------
# Constructors
# ------------------------------------------------------------------------------

proc valNil*(): Value = Value(kind: vkNil)
proc valInt*(i: int): Value = Value(kind: vkInt, i: i)
proc valFloat*(f: float): Value = Value(kind: vkFloat, f: f)
proc valBool*(b: bool): Value = Value(kind: vkBool, b: b)
proc valString*(s: string): Value = Value(kind: vkString, s: s)

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

# ------------------------------------------------------------------------------
# Environment Handling
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

proc toFloat(v: Value): float =
  case v.kind
  of vkInt: float(v.i)
  of vkFloat: v.f
  else:
    quit "Expected numeric value, got " & $v.kind

proc toInt(v: Value): int =
  case v.kind
  of vkInt: v.i
  of vkFloat: int(v.f)
  else:
    quit "Expected numeric value, got " & $v.kind

# ------------------------------------------------------------------------------
# Return Propagation
# ------------------------------------------------------------------------------

type
  ExecResult = object
    hasReturn: bool
    value: Value

proc noReturn(): ExecResult = ExecResult(hasReturn: false, value: valNil())
proc withReturn(v: Value): ExecResult = ExecResult(hasReturn: true, value: v)

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

  # Evaluate argument list
  var argVals: seq[Value] = @[]
  for a in args:
    argVals.add(evalExpr(a, env))

  # Native function?
  if fn.isNative:
    return fn.native(env, argVals)

  # User-defined
  let child = newEnv(env)
  for i, pname in fn.params:
    if i < argVals.len:
      defineVar(child, pname, argVals[i])
    else:
      defineVar(child, pname, valNil())

  var res = noReturn()
  for st in fn.stmts:
    res = execStmt(st, child)
    if res.hasReturn:
      return res.value

  return valNil()

# Arithmetic ------------------------------------------------------------

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
      if v.kind == vkFloat: valFloat(-v.f)
      else:                 valInt(-toInt(v))
    of "not":
      valBool(not toBool(v))
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

    # Check if both operands are integers for arithmetic ops
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

    else: quit "Unknown binary op: " & e.op

  of ekCall:
    evalCall(e.funcName, e.args, env)

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
    # Evaluate range bounds in parent scope
    let startVal = evalExpr(s.forStart, env)
    let endVal = evalExpr(s.forEnd, env)
    let startInt = toInt(startVal)
    let endInt = toInt(endVal)

    # Loop from start to end-1 (like Python's range)
    for i in startInt ..< endInt:
      # Create a new scope for each iteration with the loop variable
      let loopEnv = newEnv(env)
      defineVar(loopEnv, s.forVar, valInt(i))
      # Execute body in loop scope
      let res = execBlock(s.forBody, loopEnv)
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

proc execProgram*(prog: Program; env: ref Env) =
  discard execBlock(prog.stmts, env)

# ------------------------------------------------------------------------------
# Global Runtime & Events
# ------------------------------------------------------------------------------

var runtimeEnv*: ref Env
var events*: Table[string, Program] = initTable[string, Program]()

proc initRuntime*() =
  runtimeEnv = newEnv()

proc registerNative*(name: string; fn: NativeFunc) =
  defineVar(runtimeEnv, name, valNativeFunc(fn))

proc registerEvent*(name: string; prog: Program) =
  events[name] = prog

proc triggerEvent*(name: string) =
  if name in events:
    execProgram(events[name], runtimeEnv)

# Convenience setters --------------------------------------------------

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
