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
    vkArray,
    vkPointer     # Raw pointer value


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
    ptrVal*: pointer  # For pointer values

  Env* = object
    vars*: Table[string, Value]
    parent*: ref Env
    deferStack*: seq[Stmt]  # Stack of deferred statements

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
  of vkPointer: result = "<pointer>"

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

proc valPointer*(p: pointer): Value =
  Value(kind: vkPointer, i: 0, f: 0.0, b: (p != nil), s: "", fnVal: nil, ptrVal: p)

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

proc newMapValue*(): Value =
  valMap()

proc valArray*(elements: seq[Value] = @[]): Value =
  Value(kind: vkArray, arr: elements)

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

# Array access operators
proc `[]`*(v: Value; index: int): Value =
  if v.kind != vkArray:
    quit "Runtime Error: Cannot index non-array value"
  if index < 0 or index >= v.arr.len:
    quit "Runtime Error: Array index out of bounds: " & $index & " (length: " & $v.arr.len & ")"
  return v.arr[index]

proc `[]=`*(v: Value; index: int; val: Value) =
  if v.kind != vkArray:
    quit "Runtime Error: Cannot set index on non-array value"
  if index < 0 or index >= v.arr.len:
    quit "Runtime Error: Array index out of bounds: " & $index & " (length: " & $v.arr.len & ")"
  v.arr[index] = val

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

proc valuesEqual*(a, b: Value): bool =
  ## Compare two values for equality (used in case statements)
  if a.kind != b.kind:
    return false
  
  case a.kind
  of vkNil: return true
  of vkInt: return a.i == b.i
  of vkFloat: return a.f == b.f
  of vkBool: return a.b == b.b
  of vkString: return a.s == b.s
  of vkFunction: return false  # Functions are not comparable
  of vkArray: return false     # Arrays need deep comparison (not implemented)
  of vkMap: return false       # Maps need deep comparison (not implemented)
  of vkPointer: return a.ptrVal == b.ptrVal

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
  of vkPointer: v.ptrVal != nil

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

proc toInt*(v: Value): int =
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
  ControlFlow = enum
    cfNone,        # Normal execution
    cfReturn,      # Return from function
    cfBreak,       # Break out of loop
    cfContinue     # Continue to next iteration

  ExecResult = object
    controlFlow: ControlFlow
    value: Value
    label: string  # Optional label for break/continue

proc noReturn(): ExecResult =
  ExecResult(controlFlow: cfNone, value: valNil(), label: "")

proc withReturn(v: Value): ExecResult =
  ExecResult(controlFlow: cfReturn, value: v, label: "")

proc withBreak(label: string = ""): ExecResult =
  ExecResult(controlFlow: cfBreak, value: valNil(), label: label)

proc withContinue(label: string = ""): ExecResult =
  ExecResult(controlFlow: cfContinue, value: valNil(), label: label)

proc hasReturn(r: ExecResult): bool =
  r.controlFlow == cfReturn

proc hasBreak(r: ExecResult): bool =
  r.controlFlow == cfBreak

proc hasContinue(r: ExecResult): bool =
  r.controlFlow == cfContinue

proc hasControlFlow(r: ExecResult): bool =
  r.controlFlow != cfNone

# ------------------------------------------------------------------------------
# Expression Evaluation
# ------------------------------------------------------------------------------

proc evalExpr(e: Expr; env: ref Env): Value
proc execStmt*(s: Stmt; env: ref Env): ExecResult
proc execBlock(sts: seq[Stmt]; env: ref Env): ExecResult

# Function call --------------------------------------------------------

proc evalCall(name: string; args: seq[Expr]; env: ref Env): Value =
  # Handle built-in string methods (when first arg is the target object)
  if args.len > 0 and name in ["toUpper", "toLower", "strip", "trim"]:
    let target = evalExpr(args[0], env)
    
    case name
    of "toUpper":
      if target.kind == vkString:
        return valString(target.s.toUpper())
      else:
        quit "Runtime Error: toUpper() requires a string, got " & $target.kind
    
    of "toLower":
      if target.kind == vkString:
        return valString(target.s.toLower())
      else:
        quit "Runtime Error: toLower() requires a string, got " & $target.kind
    
    of "strip", "trim":
      if target.kind == vkString:
        return valString(target.s.strip())
      else:
        quit "Runtime Error: strip() requires a string, got " & $target.kind
    
    else:
      discard  # Fall through to normal lookup
  
  # Normal function lookup
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
    var returnValue = valNil()
    var hasReturnValue = false
    for st in fn.stmts:
      let res = execStmt(st, callEnv)
      if res.hasReturn():
        returnValue = res.value
        hasReturnValue = true
        break
    
    # Execute deferred statements in reverse order (LIFO)
    for i in countdown(callEnv.deferStack.len - 1, 0):
      discard execStmt(callEnv.deferStack[i], callEnv)
    
    if hasReturnValue:
      return returnValue
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
    of "+":
      # Handle different types for + operator
      if l.kind == vkArray and r.kind == vkArray:
        # Array concatenation
        var result = l.arr
        result.add(r.arr)
        Value(kind: vkArray, arr: result)
      elif l.kind == vkInt and r.kind == vkInt:
        valInt(l.i + r.i)
      else:
        # Numeric addition
        valFloat(toFloat(l) + toFloat(r))
    of "-", "*", "/", "%", "==", "!=", "<", "<=", ">", ">=":
      # Arithmetic and comparison operators need numeric conversion
      let bothInts = (l.kind == vkInt and r.kind == vkInt)
      let lf = toFloat(l)
      let rf = toFloat(r)

      case e.op
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
      rangeVal.map["end"] = valInt(toInt(r))
      rangeVal.map["inclusive"] = valBool(e.op == "..")  # Store whether range is inclusive
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

  of ekMap:
    var mapTable = initTable[string, Value]()
    for pair in e.mapPairs:
      mapTable[pair.key] = evalExpr(pair.value, env)
    Value(kind: vkMap, map: mapTable)

  of ekIndex:
    let target = evalExpr(e.indexTarget, env)
    let index = evalExpr(e.indexExpr, env)
    
    # Check if this is a slice operation (index is a range map)
    if index.kind == vkMap and "is_range" in index.map and toBool(index.map["is_range"]):
      # This is a slice operation
      let startIdx = toInt(index.map["start"])
      let endIdx = toInt(index.map["end"])
      let isInclusive = if "inclusive" in index.map: toBool(index.map["inclusive"]) else: true
      
      case target.kind
      of vkString:
        # String slicing
        let actualEnd = if isInclusive: min(endIdx + 1, target.s.len) else: min(endIdx, target.s.len)
        let actualStart = max(0, startIdx)
        if actualStart >= target.s.len or actualStart >= actualEnd:
          return valString("")
        return valString(target.s[actualStart..<actualEnd])
      
      of vkArray:
        # Array slicing
        let actualEnd = if isInclusive: min(endIdx + 1, target.arr.len) else: min(endIdx, target.arr.len)
        let actualStart = max(0, startIdx)
        if actualStart >= target.arr.len or actualStart >= actualEnd:
          return Value(kind: vkArray, arr: @[])
        var sliced: seq[Value] = @[]
        for i in actualStart..<actualEnd:
          sliced.add(target.arr[i])
        return Value(kind: vkArray, arr: sliced)
      
      else:
        quit "Cannot slice value of type: " & $target.kind
    
    # Regular indexing (single element access)
    case target.kind
    of vkArray:
      let idx = toInt(index)
      if idx < 0 or idx >= target.arr.len:
        quit "Index out of bounds: " & $idx & " (array length: " & $target.arr.len & ")"
      target.arr[idx]
    of vkMap:
      if index.kind != vkString:
        quit "Map keys must be strings, got: " & $index.kind
      if index.s in target.map:
        target.map[index.s]
      else:
        valNil()  # Return nil for missing keys
    of vkString:
      let idx = toInt(index)
      if idx < 0 or idx >= target.s.len:
        quit "String index out of bounds: " & $idx & " (string length: " & $target.s.len & ")"
      valString($target.s[idx])
    else:
      quit "Cannot index value of type: " & $target.kind

  of ekCast:
    # Type casting - for runtime, we'll try to convert the value
    # In a full implementation, this would do proper type checking
    let val = evalExpr(e.castExpr, env)
    # For now, just return the value as-is
    # A real implementation would check the target type and convert
    val

  of ekAddr:
    # Address-of operator - for runtime simulation, return the value
    # In a real implementation with memory management, this would return a pointer
    evalExpr(e.addrExpr, env)

  of ekDeref:
    # Dereference operator - for runtime simulation, just evaluate
    # In a real implementation, this would dereference a pointer
    evalExpr(e.derefExpr, env)

  of ekObjConstr:
    # Object construction - create a map/table with field values
    # In the runtime, we represent objects as maps
    var objMap = initTable[string, Value]()
    for field in e.objFields:
      let fieldValue = evalExpr(field.value, env)
      objMap[field.name] = fieldValue
    # Return as a map value
    valMap(objMap)

  of ekDot:
    # Field access or property access
    let target = evalExpr(e.dotTarget, env)
    
    # Handle built-in properties for strings and arrays
    case e.dotField
    of "len":
      # Get length of string, array, or map
      case target.kind
      of vkString:
        return valInt(target.s.len)
      of vkArray:
        return valInt(target.arr.len)
      of vkMap:
        return valInt(target.map.len)
      else:
        quit "Cannot get length of type: " & $target.kind
    
    else:
      # Regular field access - treat target as a map
      if target.kind == vkMap:
        if e.dotField in target.map:
          return target.map[e.dotField]
        # Field not found - return nil
        valNil()
      else:
        # Not a map/object - return nil
        valNil()

  of ekTuple:
    # Tuple literal - represent as array
    if e.isNamedTuple:
      # Named tuple: (name: "Bob", age: 30) - represent as map
      var tupleMap = initTable[string, Value]()
      for field in e.tupleFields:
        let fieldValue = evalExpr(field.value, env)
        tupleMap[field.name] = fieldValue
      valMap(tupleMap)
    else:
      # Unnamed tuple: (1, 2, 3) - represent as array
      var elements: seq[Value] = @[]
      for elem in e.tupleElements:
        elements.add(evalExpr(elem, env))
      valArray(elements)

# ------------------------------------------------------------------------------
# Statement Execution
# ------------------------------------------------------------------------------

proc execBlock(sts: seq[Stmt]; env: ref Env): ExecResult =
  var res = noReturn()
  for st in sts:
    res = execStmt(st, env)
    if res.hasControlFlow():
      return res
  res

proc execStmt*(s: Stmt; env: ref Env): ExecResult =
  case s.kind
  of skExpr:
    discard evalExpr(s.expr, env)
    noReturn()

  of skVar:
    if s.isVarUnpack:
      # Tuple unpacking: var (x, y, z) = getTuple()
      let value = evalExpr(s.varValue, env)
      if value.kind == vkArray:
        # Unpack array elements to variables
        for i, name in s.varNames:
          if i < value.arr.len:
            defineVar(env, name, value.arr[i])
          else:
            defineVar(env, name, valNil())
      else:
        quit "Cannot unpack non-array value in var unpacking"
    else:
      defineVar(env, s.varName, evalExpr(s.varValue, env))
    noReturn()

  of skLet:
    if s.isLetUnpack:
      # Tuple unpacking: let (x, y, z) = getTuple()
      let value = evalExpr(s.letValue, env)
      if value.kind == vkArray:
        # Unpack array elements to variables
        for i, name in s.letNames:
          if i < value.arr.len:
            defineVar(env, name, value.arr[i])
          else:
            defineVar(env, name, valNil())
      else:
        quit "Cannot unpack non-array value in let unpacking"
    else:
      defineVar(env, s.letName, evalExpr(s.letValue, env))
    noReturn()

  of skConst:
    # Const is treated like let at runtime
    defineVar(env, s.constName, evalExpr(s.constValue, env))
    noReturn()

  of skAssign:
    # Handle assignment to variable or indexed expression
    let value = evalExpr(s.assignValue, env)
    case s.assignTarget.kind
    of ekIdent:
      # Simple variable assignment
      setVar(env, s.assignTarget.ident, value)
    of ekIndex:
      # Array/map index assignment
      let target = evalExpr(s.assignTarget.indexTarget, env)
      let indexVal = evalExpr(s.assignTarget.indexExpr, env)
      case target.kind
      of vkArray:
        let idx = toInt(indexVal)
        if idx < 0 or idx >= target.arr.len:
          quit "Index out of bounds: " & $idx
        target.arr[idx] = value
      of vkMap:
        if indexVal.kind != vkString:
          quit "Map keys must be strings"
        target.map[indexVal.s] = value
      else:
        quit "Cannot index into non-array/map value"
    of ekDot:
      # Field assignment - update the field in the object (map)
      let target = evalExpr(s.assignTarget.dotTarget, env)
      if target.kind == vkMap:
        # Update or add the field
        target.map[s.assignTarget.dotField] = value
      else:
        quit "Cannot assign to field of non-object value"
    else:
      quit "Invalid assignment target"
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

  of skCase:
    # Evaluate the case expression
    let caseVal = evalExpr(s.caseExpr, env)
    
    # Try to match against 'of' branches
    for branch in s.ofBranches:
      for valueExpr in branch.values:
        let branchVal = evalExpr(valueExpr, env)
        # Compare values
        if valuesEqual(caseVal, branchVal):
          let childEnv = newEnv(env)
          return execBlock(branch.stmts, childEnv)
    
    # If no 'of' branch matched, try 'elif' branches
    for elifBranch in s.caseElif:
      if toBool(evalExpr(elifBranch.cond, env)):
        let childEnv = newEnv(env)
        return execBlock(elifBranch.stmts, childEnv)
    
    # If no branch matched, execute else branch if present
    if s.caseElse.len > 0:
      let childEnv = newEnv(env)
      return execBlock(s.caseElse, childEnv)
    
    # If we get here and no else branch exists, that's a runtime error
    # (In Nim, this would be a compile-time error for non-exhaustive cases)
    noReturn()

  of skFor:
    # Evaluate the iterable expression
    let iterableVal = evalExpr(s.forIterable, env)
    
    # Handle different iterable types
    if iterableVal.kind == vkMap and "is_range" in iterableVal.map and iterableVal.map["is_range"].b:
      # Range value created by .. or ..< operators
      let startVal = toInt(iterableVal.map["start"])
      let endVal = toInt(iterableVal.map["end"])
      let isInclusive = toBool(iterableVal.map["inclusive"])
      
      # Use inclusive or exclusive range based on the operator
      if isInclusive:
        for i in startVal .. endVal:
          let loopEnv = newEnv(env)
          # Support multi-variable iteration (e.g., for i, item in pairs(arr))
          if s.forVars.len > 1:
            # For simple ranges, only the index is available
            # First var gets the index, others get nil
            for idx, varName in s.forVars:
              if idx == 0:
                defineVar(loopEnv, varName, valInt(i))
              else:
                defineVar(loopEnv, varName, valNil())
          else:
            defineVar(loopEnv, s.forVar, valInt(i))
          
          let res = execBlock(s.forBody, loopEnv)
          if res.hasReturn():
            return res
          elif res.hasBreak():
            # Check if this break is for this loop (label matches or no label)
            if res.label == "" or res.label == s.forLabel:
              break
            else:
              # Break is for an outer loop, propagate it
              return res
          elif res.hasContinue():
            # Check if this continue is for this loop (label matches or no label)
            if res.label == "" or res.label == s.forLabel:
              continue
            else:
              # Continue is for an outer loop, propagate it
              return res
      else:
        for i in startVal ..< endVal:
          let loopEnv = newEnv(env)
          # Support multi-variable iteration
          if s.forVars.len > 1:
            for idx, varName in s.forVars:
              if idx == 0:
                defineVar(loopEnv, varName, valInt(i))
              else:
                defineVar(loopEnv, varName, valNil())
          else:
            defineVar(loopEnv, s.forVar, valInt(i))
          
          let res = execBlock(s.forBody, loopEnv)
          if res.hasReturn():
            return res
          elif res.hasBreak():
            if res.label == "" or res.label == s.forLabel:
              break
            else:
              return res
          elif res.hasContinue():
            if res.label == "" or res.label == s.forLabel:
              continue
            else:
              return res
    elif iterableVal.kind == vkInt:
      # Simple case: iterate from 0 to value-1 (backward compatibility)
      for i in 0 ..< iterableVal.i:
        let loopEnv = newEnv(env)
        if s.forVars.len > 1:
          for idx, varName in s.forVars:
            if idx == 0:
              defineVar(loopEnv, varName, valInt(i))
            else:
              defineVar(loopEnv, varName, valNil())
        else:
          defineVar(loopEnv, s.forVar, valInt(i))
        let res = execBlock(s.forBody, loopEnv)
        if res.hasReturn():
          return res
        elif res.hasBreak():
          if res.label == "" or res.label == s.forLabel:
            break
          else:
            return res
        elif res.hasContinue():
          if res.label == "" or res.label == s.forLabel:
            continue
          else:
            return res
    elif iterableVal.kind == vkArray:
      # Iterate over array elements
      for i, item in iterableVal.arr:
        let loopEnv = newEnv(env)
        if s.forVars.len > 1:
          # Multi-variable: for idx, elem in array
          for idx, varName in s.forVars:
            if idx == 0:
              defineVar(loopEnv, varName, valInt(i))
            elif idx == 1:
              defineVar(loopEnv, varName, item)
            else:
              defineVar(loopEnv, varName, valNil())
        else:
          # Single variable: for elem in array (just the element)
          defineVar(loopEnv, s.forVar, item)
        let res = execBlock(s.forBody, loopEnv)
        if res.hasReturn():
          return res
        elif res.hasBreak():
          if res.label == "" or res.label == s.forLabel:
            break
          else:
            return res
        elif res.hasContinue():
          if res.label == "" or res.label == s.forLabel:
            continue
          else:
            return res
    else:
      # For other cases, we could extend this to handle custom iterables
      quit "Runtime Error: Cannot iterate over value in for loop (not a range, integer, or array)"

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
      if res.hasReturn():
        return res
      elif res.hasBreak():
        # Check if this break is for this loop (label matches or no label)
        if res.label == "" or res.label == s.whileLabel:
          break
        else:
          # Break is for an outer loop, propagate it
          return res
      elif res.hasContinue():
        # Check if this continue is for this loop (label matches or no label)
        if res.label == "" or res.label == s.whileLabel:
          continue
        else:
          # Continue is for an outer loop, propagate it
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
    let res = execBlock(s.stmts, blockEnv)
    
    # Check if there's a break with a label targeting this block
    if res.hasBreak() and res.label.len > 0:
      # If the label matches this block's label, consume the break
      if res.label == s.blockLabel:
        return noReturn()
      else:
        # Propagate the break to outer blocks
        return res
    
    return res

  of skDefer:
    # Defer statement - push to defer stack for execution at scope exit
    env.deferStack.add(s.deferStmt)
    noReturn()

  of skType:
    # Type definition - for runtime, we just store it as metadata
    # In a real implementation, this would register the type in a type system
    noReturn()

  of skBreak:
    withBreak(s.breakLabel)

  of skContinue:
    withContinue(s.continueLabel)

# ------------------------------------------------------------------------------
# Program Execution
# ------------------------------------------------------------------------------

var runtimeEnv*: ref Env

# ------------------------------------------------------------------------------
# Native Function Registration / Globals
# ------------------------------------------------------------------------------

proc registerNative*(name: string; fn: NativeFunc) =
  defineVar(runtimeEnv, name, valNativeFunc(fn))

proc initRuntime*() =
  runtimeEnv = newEnv(nil)
  # Note: Standard library functions are registered separately via initStdlib()
  
  # Register built-in print/echo functions
  registerNative("echo", proc(env: ref Env; args: seq[Value]): Value =
    for i, arg in args:
      if i > 0: stdout.write(" ")
      stdout.write($arg)
    stdout.write("\n")
    valNil()
  )
  registerNative("print", proc(env: ref Env; args: seq[Value]): Value =
    for i, arg in args:
      if i > 0: stdout.write(" ")
      stdout.write($arg)
    stdout.write("\n")
    valNil()
  )

proc execProgram*(prog: Program; env: ref Env) =
  discard execBlock(prog.stmts, env)

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
