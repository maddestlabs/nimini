# Abstract Syntax Tree for the Nimini, the mini-Nim DSL

# ------------------------------------------------------------------------------
# Type Annotations
# ------------------------------------------------------------------------------

type
  TypeKind* = enum
    tkSimple,      # int, float, string, etc.
    tkPointer,     # ptr T
    tkGeneric,     # UncheckedArray[T], seq[T]
    tkProc         # proc type

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

# ------------------------------------------------------------------------------
# Expression AST
# ------------------------------------------------------------------------------

type
  ExprKind* = enum
    ekInt, ekFloat, ekString, ekBool,
    ekIdent,
    ekBinOp, ekUnaryOp,
    ekCall,
    ekArray,
    ekIndex,
    ekCast,        # cast[Type](expr)
    ekAddr,        # addr expr
    ekDeref        # expr[]

  Expr* = ref object
    line*: int
    col*: int

    case kind*: ExprKind
    of ekInt:
      intVal*: int
    of ekFloat:
      floatVal*: float
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

# ------------------------------------------------------------------------------
# Statement AST
# ------------------------------------------------------------------------------

type
  StmtKind* = enum
    skExpr,
    skVar,
    skLet,
    skConst,       # const declaration
    skAssign,
    skIf,
    skFor,
    skWhile,
    skProc,
    skReturn,
    skBlock,
    skDefer,       # defer statement
    skType         # type definition

  IfBranch* = object
    cond*: Expr
    stmts*: seq[Stmt]

  Stmt* = ref object
    line*: int
    col*: int

    case kind*: StmtKind
    of skExpr:
      expr*: Expr

    of skVar:
      varName*: string
      varType*: TypeNode  # optional type annotation
      varValue*: Expr

    of skLet:
      letName*: string
      letType*: TypeNode  # optional type annotation
      letValue*: Expr

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

    of skFor:
      forVar*: string
      forIterable*: Expr  # The expression to iterate over (e.g., 1..5, range(1,10), etc.)
      forBody*: seq[Stmt]

    of skWhile:
      whileCond*: Expr
      whileBody*: seq[Stmt]

    of skProc:
      procName*: string
      params*: seq[(string, string)]
      procReturnType*: TypeNode  # optional return type
      procPragmas*: seq[string]  # pragmas like {.cdecl.}
      body*: seq[Stmt]

    of skReturn:
      returnVal*: Expr

    of skBlock:
      stmts*: seq[Stmt]

    of skDefer:
      deferStmt*: Stmt

    of skType:
      typeName*: string
      typeValue*: TypeNode

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

proc newInt*(v: int; line=0; col=0): Expr =
  Expr(kind: ekInt, intVal: v, line: line, col: col)

proc newFloat*(v: float; line=0; col=0): Expr =
  Expr(kind: ekFloat, floatVal: v, line: line, col: col)

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

proc newIndex*(target: Expr; index: Expr; line=0; col=0): Expr =
  Expr(kind: ekIndex, indexTarget: target, indexExpr: index, line: line, col: col)

proc newCast*(t: TypeNode; e: Expr; line=0; col=0): Expr =
  Expr(kind: ekCast, castType: t, castExpr: e, line: line, col: col)

proc newAddr*(e: Expr; line=0; col=0): Expr =
  Expr(kind: ekAddr, addrExpr: e, line: line, col: col)

proc newDeref*(e: Expr; line=0; col=0): Expr =
  Expr(kind: ekDeref, derefExpr: e, line: line, col: col)

# --- Type Nodes ---------------------------------------------------------------

proc newSimpleType*(name: string): TypeNode =
  TypeNode(kind: tkSimple, typeName: name)

proc newPointerType*(t: TypeNode): TypeNode =
  TypeNode(kind: tkPointer, ptrType: t)

proc newGenericType*(name: string; params: seq[TypeNode]): TypeNode =
  TypeNode(kind: tkGeneric, genericName: name, genericParams: params)

proc newProcType*(params: seq[TypeNode]; returnType: TypeNode): TypeNode =
  TypeNode(kind: tkProc, procParams: params, procReturn: returnType)

# --- Statements ---------------------------------------------------------------

proc newExprStmt*(e: Expr; line=0; col=0): Stmt =
  Stmt(kind: skExpr, expr: e, line: line, col: col)

proc newVar*(name: string; val: Expr; typ: TypeNode = nil; line=0; col=0): Stmt =
  Stmt(kind: skVar, varName: name, varType: typ, varValue: val, line: line, col: col)

proc newLet*(name: string; val: Expr; typ: TypeNode = nil; line=0; col=0): Stmt =
  Stmt(kind: skLet, letName: name, letType: typ, letValue: val, line: line, col: col)

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

proc newFor*(varName: string; iterable: Expr; body: seq[Stmt]; line=0; col=0): Stmt =
  Stmt(kind: skFor,
       forVar: varName,
       forIterable: iterable,
       forBody: body,
       line: line, col: col)

proc newWhile*(cond: Expr; body: seq[Stmt]; line=0; col=0): Stmt =
  Stmt(kind: skWhile,
       whileCond: cond,
       whileBody: body,
       line: line, col: col)

proc newProc*(name: string; params: seq[(string,string)]; body: seq[Stmt]; 
              returnType: TypeNode = nil; pragmas: seq[string] = @[]; line=0; col=0): Stmt =
  Stmt(kind: skProc, procName: name, params: params, procReturnType: returnType,
       procPragmas: pragmas, body: body, line: line, col: col)

proc newReturn*(val: Expr; line=0; col=0): Stmt =
  Stmt(kind: skReturn, returnVal: val, line: line, col: col)

proc newDefer*(s: Stmt; line=0; col=0): Stmt =
  Stmt(kind: skDefer, deferStmt: s, line: line, col: col)

proc newType*(name: string; value: TypeNode; line=0; col=0): Stmt =
  Stmt(kind: skType, typeName: name, typeValue: value, line: line, col: col)

proc newBlock*(stmts: seq[Stmt]; line=0; col=0): Stmt =
  Stmt(kind: skBlock, stmts: stmts, line: line, col: col)
