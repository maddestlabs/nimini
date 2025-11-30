# Abstract Syntax Tree for the Nimini, the mini-Nim DSL

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
    ekIndex

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

# ------------------------------------------------------------------------------
# Statement AST
# ------------------------------------------------------------------------------

type
  StmtKind* = enum
    skExpr,
    skVar,
    skLet,
    skAssign,
    skIf,
    skFor,
    skWhile,
    skProc,
    skReturn,
    skBlock

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
      varValue*: Expr

    of skLet:
      letName*: string
      letValue*: Expr

    of skAssign:
      target*: string
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
      body*: seq[Stmt]

    of skReturn:
      returnVal*: Expr

    of skBlock:
      stmts*: seq[Stmt]

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

# --- Statements ---------------------------------------------------------------

proc newExprStmt*(e: Expr; line=0; col=0): Stmt =
  Stmt(kind: skExpr, expr: e, line: line, col: col)

proc newVar*(name: string; val: Expr; line=0; col=0): Stmt =
  Stmt(kind: skVar, varName: name, varValue: val, line: line, col: col)

proc newLet*(name: string; val: Expr; line=0; col=0): Stmt =
  Stmt(kind: skLet, letName: name, letValue: val, line: line, col: col)

proc newAssign*(target: string; val: Expr; line=0; col=0): Stmt =
  Stmt(kind: skAssign, target: target, assignValue: val, line: line, col: col)

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

proc newProc*(name: string; params: seq[(string,string)]; body: seq[Stmt]; line=0; col=0): Stmt =
  Stmt(kind: skProc, procName: name, params: params, body: body, line: line, col: col)

proc newReturn*(val: Expr; line=0; col=0): Stmt =
  Stmt(kind: skReturn, returnVal: val, line: line, col: col)

proc newBlock*(stmts: seq[Stmt]; line=0; col=0): Stmt =
  Stmt(kind: skBlock, stmts: stmts, line: line, col: col)
