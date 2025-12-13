# Abstract Syntax Tree for the Nimini, the mini-Nim DSL

# ------------------------------------------------------------------------------
# Error Types
# ------------------------------------------------------------------------------

type
  NiminiError* = object of CatchableError
    ## Base exception type for all nimini errors
    line*: int
    col*: int
  
  NiminiTokenizeError* = object of NiminiError
    ## Error during tokenization phase
  
  NiminiParseError* = object of NiminiError
    ## Error during parsing phase
  
  NiminiRuntimeError* = object of NiminiError
    ## Error during runtime execution

# ------------------------------------------------------------------------------
# Type Annotations
# ------------------------------------------------------------------------------

type
  ProcParam* = object
    ## Procedure parameter with optional var modifier
    name*: string
    paramType*: string
    isVar*: bool  # true if declared as 'var' parameter

  TypeKind* = enum
    tkSimple,      # int, float, string, etc.
    tkPointer,     # ptr T
    tkGeneric,     # UncheckedArray[T], seq[T]
    tkProc,        # proc type
    tkObject,      # object type with fields
    tkEnum         # enum type

  TypeNode* = ref object
    case kind*: TypeKind
    of tkSimple:
      typeName*: string
    of tkPointer:
      ptrType*: TypeNode
    of tkGeneric:
      genericName*: string
      genericParams*: seq[TypeNode]
    of tkProc:
      procParams*: seq[TypeNode]
      procReturn*: TypeNode
    of tkObject:
      objectFields*: seq[tuple[name: string, fieldType: TypeNode]]
    of tkEnum:
      enumValues*: seq[tuple[name: string, value: int]]  # (name, ordinal value)

# ------------------------------------------------------------------------------
# Expression and Statement AST (must be in same type block due to mutual recursion)
# ------------------------------------------------------------------------------

type
  # Forward declarations for mutually recursive types
  Stmt* = ref StmtObj
  
  ExprKind* = enum
    ekInt, ekFloat, ekString, ekBool,
    ekIdent,
    ekBinOp, ekUnaryOp,
    ekCall,
    ekArray,
    ekMap,         # Map literal {key: value, ...}
    ekIndex,
    ekCast,        # cast[Type](expr)
    ekAddr,        # addr expr
    ekDeref,       # expr[]
    ekObjConstr,   # Object construction Type(field: value, ...)
    ekDot,         # Field access obj.field
    ekTuple,       # Tuple literal (1, 2, 3) or (name: "Bob", age: 30)
    ekLambda       # Lambda/anonymous proc expression

  Expr* = ref object
    line*: int
    col*: int

    case kind*: ExprKind
    of ekInt:
      intVal*: int
      intTypeSuffix*: string  # Optional type suffix like 'i32', 'i64'
    of ekFloat:
      floatVal*: float
      floatTypeSuffix*: string  # Optional type suffix like 'f32', 'f64'
    of ekString:
      strVal*: string
    of ekBool:
      boolVal*: bool
    of ekIdent:
      ident*: string
    of ekBinOp:
      op*: string
      left*, right*: Expr
    of ekUnaryOp:
      unaryOp*: string
      unaryExpr*: Expr
    of ekCall:
      funcName*: string
      args*: seq[Expr]
    of ekArray:
      elements*: seq[Expr]
    of ekMap:
      mapPairs*: seq[tuple[key: string, value: Expr]]
    of ekIndex:
      indexTarget*: Expr
      indexExpr*: Expr
    of ekCast:
      castType*: TypeNode
      castExpr*: Expr
    of ekAddr:
      addrExpr*: Expr
    of ekDeref:
      derefExpr*: Expr
    of ekObjConstr:
      objType*: string
      objFields*: seq[tuple[name: string, value: Expr]]
    of ekDot:
      dotTarget*: Expr
      dotField*: string
    of ekTuple:
      tupleElements*: seq[Expr]                         # For unnamed tuples: (1, 2, 3)
      tupleFields*: seq[tuple[name: string, value: Expr]]  # For named tuples: (x: 1, y: 2)
      isNamedTuple*: bool                                # True if using named fields
    of ekLambda:
      lambdaParams*: seq[ProcParam]  # Parameters for the lambda
      lambdaBody*: seq[Stmt]         # Body statements of the lambda
      lambdaReturnType*: TypeNode    # Optional return type

# Statements (part of the same type block as Expressions)

  StmtKind* = enum
    skExpr,
    skVar,
    skLet,
    skConst,       # const declaration
    skAssign,
    skIf,
    skCase,        # case statement
    skFor,
    skWhile,
    skProc,
    skReturn,
    skBlock,
    skDefer,       # defer statement
    skType,        # type definition
    skBreak,       # break statement
    skContinue     # continue statement

  IfBranch* = object
    cond*: Expr
    stmts*: seq[Stmt]

  OfBranch* = object
    values*: seq[Expr]  # Multiple values for this branch (e.g., of 1, 2, 3:)
    stmts*: seq[Stmt]

  # Stmt is forward declared above with Expression AST
  # Here we complete the StmtObj definition
  StmtObj* = object
    line*: int
    col*: int

    case kind*: StmtKind
    of skExpr:
      expr*: Expr

    of skVar:
      varName*: string
      varNames*: seq[string]      # For tuple unpacking: var (x, y) = ...
      varType*: TypeNode  # optional type annotation
      varValue*: Expr
      isVarUnpack*: bool          # True if this is tuple unpacking

    of skLet:
      letName*: string
      letNames*: seq[string]      # For tuple unpacking: let (x, y) = ...
      letType*: TypeNode  # optional type annotation
      letValue*: Expr
      isLetUnpack*: bool          # True if this is tuple unpacking

    of skConst:
      constName*: string
      constType*: TypeNode  # optional type annotation
      constValue*: Expr

    of skAssign:
      assignTarget*: Expr  # Can be an identifier or indexed expression
      assignValue*: Expr

    of skIf:
      ifBranch*: IfBranch
      elifBranches*: seq[IfBranch]
      elseStmts*: seq[Stmt]

    of skCase:
      caseExpr*: Expr             # The expression being matched
      ofBranches*: seq[OfBranch]  # of value1, value2: stmts
      caseElif*: seq[IfBranch]    # Optional elif branches
      caseElse*: seq[Stmt]        # Optional else branch

    of skFor:
      forLabel*: string           # Optional label for the loop
      forVar*: string
      forVars*: seq[string]       # For multi-variable iteration: for i, item in ...
      forIterable*: Expr  # The expression to iterate over (e.g., 1..5, range(1,10), etc.)
      forBody*: seq[Stmt]

    of skWhile:
      whileLabel*: string         # Optional label for the loop
      whileCond*: Expr
      whileBody*: seq[Stmt]

    of skProc:
      procName*: string
      params*: seq[ProcParam]  # Changed from seq[(string, string)] to support var params
      procReturnType*: TypeNode  # optional return type
      procPragmas*: seq[string]  # pragmas like {.cdecl.}
      body*: seq[Stmt]

    of skReturn:
      returnVal*: Expr

    of skBlock:
      blockLabel*: string         # Optional label for the block
      stmts*: seq[Stmt]

    of skDefer:
      deferStmt*: Stmt

    of skType:
      typeName*: string
      typeValue*: TypeNode

    of skBreak:
      breakLabel*: string  # Optional label for breaking out of labeled blocks

    of skContinue:
      continueLabel*: string  # Optional label for continuing labeled loops

# ------------------------------------------------------------------------------
# Program Root
# ------------------------------------------------------------------------------

type
  Program* = object
    stmts*: seq[Stmt]

# ------------------------------------------------------------------------------
# Constructors
# ------------------------------------------------------------------------------

# --- Expressions --------------------------------------------------------------

proc newInt*(v: int; line=0; col=0; typeSuffix=""): Expr =
  Expr(kind: ekInt, intVal: v, intTypeSuffix: typeSuffix, line: line, col: col)

proc newFloat*(v: float; line=0; col=0; typeSuffix=""): Expr =
  Expr(kind: ekFloat, floatVal: v, floatTypeSuffix: typeSuffix, line: line, col: col)

proc newString*(v: string; line=0; col=0): Expr =
  Expr(kind: ekString, strVal: v, line: line, col: col)

proc newBool*(v: bool; line=0; col=0): Expr =
  Expr(kind: ekBool, boolVal: v, line: line, col: col)

proc newIdent*(v: string; line=0; col=0): Expr =
  Expr(kind: ekIdent, ident: v, line: line, col: col)

proc newBinOp*(op: string; l, r: Expr; line=0; col=0): Expr =
  Expr(kind: ekBinOp, op: op, left: l, right: r, line: line, col: col)

proc newUnaryOp*(op: string; e: Expr; line=0; col=0): Expr =
  Expr(kind: ekUnaryOp, unaryOp: op, unaryExpr: e, line: line, col: col)

proc newCall*(name: string; args: seq[Expr]; line=0; col=0): Expr =
  Expr(kind: ekCall, funcName: name, args: args, line: line, col: col)

proc newArray*(elements: seq[Expr]; line=0; col=0): Expr =
  Expr(kind: ekArray, elements: elements, line: line, col: col)

proc newMap*(pairs: seq[tuple[key: string, value: Expr]]; line=0; col=0): Expr =
  Expr(kind: ekMap, mapPairs: pairs, line: line, col: col)

proc newIndex*(target: Expr; index: Expr; line=0; col=0): Expr =
  Expr(kind: ekIndex, indexTarget: target, indexExpr: index, line: line, col: col)

proc newCast*(t: TypeNode; e: Expr; line=0; col=0): Expr =
  Expr(kind: ekCast, castType: t, castExpr: e, line: line, col: col)

proc newAddr*(e: Expr; line=0; col=0): Expr =
  Expr(kind: ekAddr, addrExpr: e, line: line, col: col)

proc newDeref*(e: Expr; line=0; col=0): Expr =
  Expr(kind: ekDeref, derefExpr: e, line: line, col: col)

proc newObjConstr*(typeName: string; fields: seq[tuple[name: string, value: Expr]]; line=0; col=0): Expr =
  Expr(kind: ekObjConstr, objType: typeName, objFields: fields, line: line, col: col)

proc newDot*(target: Expr; field: string; line=0; col=0): Expr =
  Expr(kind: ekDot, dotTarget: target, dotField: field, line: line, col: col)

proc newTuple*(elements: seq[Expr]; line=0; col=0): Expr =
  Expr(kind: ekTuple, tupleElements: elements, isNamedTuple: false, line: line, col: col)

proc newLambda*(params: seq[ProcParam]; body: seq[Stmt]; returnType: TypeNode = nil; line=0; col=0): Expr =
  Expr(kind: ekLambda, lambdaParams: params, lambdaBody: body, lambdaReturnType: returnType, line: line, col: col)

proc newNamedTuple*(fields: seq[tuple[name: string, value: Expr]]; line=0; col=0): Expr =
  Expr(kind: ekTuple, tupleFields: fields, isNamedTuple: true, line: line, col: col)

# --- Type Nodes ---------------------------------------------------------------

proc newSimpleType*(name: string): TypeNode =
  TypeNode(kind: tkSimple, typeName: name)

proc newPointerType*(t: TypeNode): TypeNode =
  TypeNode(kind: tkPointer, ptrType: t)

proc newGenericType*(name: string; params: seq[TypeNode]): TypeNode =
  TypeNode(kind: tkGeneric, genericName: name, genericParams: params)

proc newProcType*(params: seq[TypeNode]; returnType: TypeNode): TypeNode =
  TypeNode(kind: tkProc, procParams: params, procReturn: returnType)

proc newObjectType*(fields: seq[tuple[name: string, fieldType: TypeNode]]): TypeNode =
  TypeNode(kind: tkObject, objectFields: fields)

proc newEnumType*(values: seq[tuple[name: string, value: int]]): TypeNode =
  TypeNode(kind: tkEnum, enumValues: values)

# --- Statements ---------------------------------------------------------------

proc newExprStmt*(e: Expr; line=0; col=0): Stmt =
  Stmt(kind: skExpr, expr: e, line: line, col: col)

proc newVar*(name: string; val: Expr; typ: TypeNode = nil; line=0; col=0): Stmt =
  Stmt(kind: skVar, varName: name, varType: typ, varValue: val, isVarUnpack: false, line: line, col: col)

proc newVarUnpack*(names: seq[string]; val: Expr; typ: TypeNode = nil; line=0; col=0): Stmt =
  Stmt(kind: skVar, varNames: names, varType: typ, varValue: val, isVarUnpack: true, line: line, col: col)

proc newLet*(name: string; val: Expr; typ: TypeNode = nil; line=0; col=0): Stmt =
  Stmt(kind: skLet, letName: name, letType: typ, letValue: val, isLetUnpack: false, line: line, col: col)

proc newLetUnpack*(names: seq[string]; val: Expr; typ: TypeNode = nil; line=0; col=0): Stmt =
  Stmt(kind: skLet, letNames: names, letType: typ, letValue: val, isLetUnpack: true, line: line, col: col)

proc newConst*(name: string; val: Expr; typ: TypeNode = nil; line=0; col=0): Stmt =
  Stmt(kind: skConst, constName: name, constType: typ, constValue: val, line: line, col: col)

proc newAssign*(targetName: string; val: Expr; line=0; col=0): Stmt =
  # Legacy function for simple variable assignment
  let targetExpr = newIdent(targetName, line, col)
  Stmt(kind: skAssign, assignTarget: targetExpr, assignValue: val, line: line, col: col)

proc newAssignExpr*(target: Expr; val: Expr; line=0; col=0): Stmt =
  # New function for assigning to any expression (variable, array index, etc.)
  Stmt(kind: skAssign, assignTarget: target, assignValue: val, line: line, col: col)

proc newIf*(cond: Expr; body: seq[Stmt]; line=0; col=0): Stmt =
  Stmt(kind: skIf,
       ifBranch: IfBranch(cond: cond, stmts: body),
       elifBranches: @[],
       elseStmts: @[],
       line: line, col: col)

proc addElif*(s: Stmt; cond: Expr; body: seq[Stmt]) =
  s.elifBranches.add IfBranch(cond: cond, stmts: body)

proc addElse*(s: Stmt; body: seq[Stmt]) =
  s.elseStmts = body

proc newCase*(expr: Expr; line=0; col=0): Stmt =
  Stmt(kind: skCase,
       caseExpr: expr,
       ofBranches: @[],
       caseElif: @[],
       caseElse: @[],
       line: line, col: col)

proc addOfBranch*(s: Stmt; values: seq[Expr]; body: seq[Stmt]) =
  s.ofBranches.add OfBranch(values: values, stmts: body)

proc addCaseElif*(s: Stmt; cond: Expr; body: seq[Stmt]) =
  s.caseElif.add IfBranch(cond: cond, stmts: body)

proc addCaseElse*(s: Stmt; body: seq[Stmt]) =
  s.caseElse = body

proc newFor*(varName: string; iterable: Expr; body: seq[Stmt]; label=""; line=0; col=0): Stmt =
  Stmt(kind: skFor,
       forLabel: label,
       forVar: varName,
       forVars: if varName.len > 0: @[varName] else: @[],
       forIterable: iterable,
       forBody: body,
       line: line, col: col)

proc newForMulti*(varNames: seq[string]; iterable: Expr; body: seq[Stmt]; label=""; line=0; col=0): Stmt =
  Stmt(kind: skFor,
       forLabel: label,
       forVar: if varNames.len > 0: varNames[0] else: "",
       forVars: varNames,
       forIterable: iterable,
       forBody: body,
       line: line, col: col)

proc newWhile*(cond: Expr; body: seq[Stmt]; label=""; line=0; col=0): Stmt =
  Stmt(kind: skWhile,
       whileLabel: label,
       whileCond: cond,
       whileBody: body,
       line: line, col: col)

proc newProc*(name: string; params: seq[ProcParam]; body: seq[Stmt]; 
              returnType: TypeNode = nil; pragmas: seq[string] = @[]; line=0; col=0): Stmt =
  Stmt(kind: skProc, procName: name, params: params, procReturnType: returnType,
       procPragmas: pragmas, body: body, line: line, col: col)

proc newReturn*(val: Expr; line=0; col=0): Stmt =
  Stmt(kind: skReturn, returnVal: val, line: line, col: col)

proc newDefer*(s: Stmt; line=0; col=0): Stmt =
  Stmt(kind: skDefer, deferStmt: s, line: line, col: col)

proc newType*(name: string; value: TypeNode; line=0; col=0): Stmt =
  Stmt(kind: skType, typeName: name, typeValue: value, line: line, col: col)

proc newBlock*(stmts: seq[Stmt]; label = ""; line=0; col=0): Stmt =
  Stmt(kind: skBlock, blockLabel: label, stmts: stmts, line: line, col: col)

proc newBreak*(label: string = ""; line=0; col=0): Stmt =
  Stmt(kind: skBreak, breakLabel: label, line: line, col: col)

proc newContinue*(label: string = ""; line=0; col=0): Stmt =
  Stmt(kind: skContinue, continueLabel: label, line: line, col: col)
