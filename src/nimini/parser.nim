# Recursive descent + Pratt parser for Nimini, the mini-Nim DSL

import std/[strutils]
import tokenizer
import ast

type
  Parser = object
    tokens: seq[Token]
    pos: int

# helpers --------------------------------------------------------------

proc atEnd(p: Parser): bool =
  p.pos >= p.tokens.len or p.tokens[p.pos].kind == tkEOF

proc cur(p: Parser): Token =
  if p.pos < p.tokens.len: p.tokens[p.pos] else: p.tokens[^1]

proc advance(p: var Parser): Token =
  let t = p.cur()
  if not p.atEnd():
    inc p.pos
  t

proc match(p: var Parser; kinds: varargs[TokenKind]): bool =
  if p.atEnd(): return false
  for k in kinds:
    if p.cur().kind == k:
      discard p.advance()
      return true
  false

proc expect(p: var Parser; kind: TokenKind; msg: string): Token =
  if p.cur().kind != kind:
    quit "Parse Error: " & msg & " at line " & $p.cur().line
  advance(p)

# precedence -----------------------------------------------------------

proc precedence(op: string): int =
  case op
  of "or": 1
  of "and": 2
  of "==", "!=", "<", "<=", ">", ">=": 3
  of "..", "..<": 3  # Range operators at same level as comparison
  of "+", "-": 4
  of "*", "/", "%": 5
  of "&": 4  # String concatenation at same level as + and -
  else: 0

# forward decl
proc parseExpr(p: var Parser; prec=0): Expr
proc parseStmt(p: var Parser): Stmt
proc parseBlock(p: var Parser): seq[Stmt]

# prefix parsing --------------------------------------------------------

proc parseType(p: var Parser): TypeNode =
  ## Parse a type annotation
  let t = p.cur()
  
  if t.kind != tkIdent:
    quit "Parse Error: Expected type name at line " & $t.line
  
  let typeName = t.lexeme
  discard p.advance()
  
  # Check for ptr prefix
  if typeName == "ptr":
    let innerType = parseType(p)
    return newPointerType(innerType)
  
  # Check for generic types like UncheckedArray[T] or seq[T]
  if p.cur().kind == tkLBracket:
    discard p.advance()
    var params: seq[TypeNode] = @[]
    params.add(parseType(p))
    while match(p, tkComma):
      params.add(parseType(p))
    discard expect(p, tkRBracket, "Expected ']'")
    return newGenericType(typeName, params)
  
  return newSimpleType(typeName)

proc parsePrefix(p: var Parser): Expr =
  let t = p.cur()

  case t.kind
  of tkInt:
    discard p.advance()
    newInt(parseInt(t.lexeme), t.line, t.col)

  of tkFloat:
    discard p.advance()
    newFloat(parseFloat(t.lexeme), t.line, t.col)

  of tkString:
    discard p.advance()
    newString(t.lexeme, t.line, t.col)

  of tkIdent:
    # Handle boolean literals and keyword operators
    if t.lexeme == "true":
      discard p.advance()
      return newBool(true, t.line, t.col)
    elif t.lexeme == "false":
      discard p.advance()
      return newBool(false, t.line, t.col)
    elif t.lexeme == "not":
      discard p.advance()
      let v = parseExpr(p, 100)
      return newUnaryOp("not", v, t.line, t.col)
    elif t.lexeme == "cast":
      # Parse cast[Type](expr)
      discard p.advance()
      discard expect(p, tkLBracket, "Expected '[' after cast")
      let castType = parseType(p)
      discard expect(p, tkRBracket, "Expected ']'")
      discard expect(p, tkLParen, "Expected '(' after cast type")
      let expr = parseExpr(p)
      discard expect(p, tkRParen, "Expected ')'")
      return newCast(castType, expr, t.line, t.col)
    elif t.lexeme == "addr":
      # Parse addr expr
      discard p.advance()
      let expr = parseExpr(p, 100)
      return newAddr(expr, t.line, t.col)

    discard p.advance()
    if p.cur().kind == tkLParen:
      discard p.advance()
      var args: seq[Expr] = @[]
      if p.cur().kind != tkRParen:
        args.add(parseExpr(p))
        while match(p, tkComma):
          args.add(parseExpr(p))
      discard expect(p, tkRParen, "Expected ')'")
      newCall(t.lexeme, args, t.line, t.col)
    else:
      newIdent(t.lexeme, t.line, t.col)

  of tkOp:
    if t.lexeme in ["-", "$"]:
      discard p.advance()
      let v = parseExpr(p, 100)
      newUnaryOp(t.lexeme, v, t.line, t.col)
    else:
      quit "Unexpected prefix operator at line " & $t.line

  of tkLParen:
    discard p.advance()
    let e = parseExpr(p)
    discard expect(p, tkRParen, "Expected ')'")
    e

  of tkLBracket:
    discard p.advance()
    var elements: seq[Expr] = @[]
    if p.cur().kind != tkRBracket:
      elements.add(parseExpr(p))
      while match(p, tkComma):
        elements.add(parseExpr(p))
    discard expect(p, tkRBracket, "Expected ']'")
    newArray(elements, t.line, t.col)

  else:
    quit "Unexpected token in expression at line " & $t.line

# Pratt led -------------------------------------------------------------

proc parseExpr(p: var Parser; prec=0): Expr =
  var left = parsePrefix(p)
  while true:
    let cur = p.cur()
    
    # Handle array indexing
    if cur.kind == tkLBracket:
      discard p.advance()
      let indexExpr = parseExpr(p)
      discard expect(p, tkRBracket, "Expected ']'")
      left = newIndex(left, indexExpr, cur.line, cur.col)
      continue
    
    var isOp = false
    var opLexeme = ""

    # Check if current token is an operator or keyword operator (and/or)
    if cur.kind == tkOp:
      isOp = true
      opLexeme = cur.lexeme
    elif cur.kind == tkIdent and (cur.lexeme == "and" or cur.lexeme == "or"):
      isOp = true
      opLexeme = cur.lexeme

    if not isOp:
      break

    let thisPrec = precedence(opLexeme)
    if thisPrec <= prec:
      break
    let t = advance(p)    # SAFE (value is used)
    let right = parseExpr(p, thisPrec)
    left = newBinOp(opLexeme, left, right, t.line, t.col)
  left

# statements ------------------------------------------------------------

proc parseVarStmt(p: var Parser; isLet: bool; isConst: bool = false): Stmt =
  let kw = advance(p)
  let nameTok = expect(p, tkIdent, "Expected identifier")
  
  # Optional type annotation
  var typeAnnotation: TypeNode = nil
  if p.cur().kind == tkColon:
    discard p.advance()
    typeAnnotation = parseType(p)
  
  discard expect(p, tkOp, "Expected '='")
  let val = parseExpr(p)
  
  if isConst:
    newConst(nameTok.lexeme, val, typeAnnotation, kw.line, kw.col)
  elif isLet:
    newLet(nameTok.lexeme, val, typeAnnotation, kw.line, kw.col)
  else:
    newVar(nameTok.lexeme, val, typeAnnotation, kw.line, kw.col)

proc parseAssign(p: var Parser; targetExpr: Expr; line, col: int): Stmt =
  # targetExpr is already parsed (e.g., identifier or array index)
  discard expect(p, tkOp, "Expected '='")
  let val = parseExpr(p)
  newAssignExpr(targetExpr, val, line, col)

proc parseIf(p: var Parser): Stmt =
  let tok = advance(p)
  let cond = parseExpr(p)
  discard expect(p, tkColon, "Expected ':'")
  discard expect(p, tkNewline, "Expected newline")
  let body = parseBlock(p)
  var node = newIf(cond, body, tok.line, tok.col)

  # Skip newlines before checking for elif
  while p.cur().kind == tkNewline:
    discard p.advance()
  
  while p.cur().kind == tkIdent and p.cur().lexeme == "elif":
    discard p.advance()
    let c = parseExpr(p)
    discard expect(p, tkColon, "Expected ':'")
    discard expect(p, tkNewline, "Expected newline")
    node.addElif(c, parseBlock(p))
    # Skip newlines before checking for next elif or else
    while p.cur().kind == tkNewline:
      discard p.advance()

  if p.cur().kind == tkIdent and p.cur().lexeme == "else":
    discard p.advance()
    discard expect(p, tkColon, "Expected ':'")
    discard expect(p, tkNewline, "Expected newline")
    node.addElse(parseBlock(p))

  node

proc parseFor(p: var Parser): Stmt =
  let tok = advance(p)
  let varTok = expect(p, tkIdent, "Expected loop variable name")

  # Expect "in" keyword
  if p.cur().kind != tkIdent or p.cur().lexeme != "in":
    quit "Parse Error: Expected 'in' after for variable at line " & $p.cur().line
  discard p.advance()

  # Parse the iterable expression (e.g., 1..5, range(1,10), someArray, etc.)
  let iterableExpr = parseExpr(p)

  discard expect(p, tkColon, "Expected ':'")
  discard expect(p, tkNewline, "Expected newline")

  let body = parseBlock(p)
  newFor(varTok.lexeme, iterableExpr, body, tok.line, tok.col)

proc parseWhile(p: var Parser): Stmt =
  let tok = advance(p)
  let cond = parseExpr(p)
  discard expect(p, tkColon, "Expected ':'")
  discard expect(p, tkNewline, "Expected newline")
  let body = parseBlock(p)
  newWhile(cond, body, tok.line, tok.col)

proc parseProc(p: var Parser): Stmt =
  let tok = advance(p)
  let nameTok = expect(p, tkIdent, "Expected proc name")
  discard expect(p, tkLParen, "Expected '('")

  var params: seq[(string,string)] = @[]
  if p.cur().kind != tkRParen:
    while true:
      let pname = expect(p, tkIdent, "Expected parameter name").lexeme
      discard expect(p, tkColon, "Expected ':'")
      let ptype = expect(p, tkIdent, "Expected parameter type").lexeme
      params.add((pname, ptype))
      if not match(p, tkComma):
        break

  discard expect(p, tkRParen, "Expected ')'")
  
  # Optional return type - look ahead to distinguish from proc body colon
  var returnType: TypeNode = nil
  if p.cur().kind == tkColon:
    # Save position to potentially backtrack
    let colonPos = p.pos
    discard p.advance()
    # If next token is an identifier, it's a return type
    if p.cur().kind == tkIdent and p.cur().lexeme notin ["defer", "if", "for", "while", "return"]:
      returnType = parseType(p)
    else:
      # It was the proc body colon, backtrack
      p.pos = colonPos
  
  # Optional pragmas {.cdecl.}
  var pragmas: seq[string] = @[]
  if p.cur().kind == tkLBrace:
    discard p.advance()
    if p.cur().kind == tkDot:
      discard p.advance()
      if p.cur().kind == tkIdent:
        pragmas.add(p.cur().lexeme)
        discard p.advance()
      if p.cur().kind == tkDot:
        discard p.advance()
      if p.cur().kind == tkRBrace:
        discard p.advance()
  
  discard expect(p, tkColon, "Expected ':'")
  discard expect(p, tkNewline, "Expected newline")

  let body = parseBlock(p)
  newProc(nameTok.lexeme, params, body, returnType, pragmas, tok.line, tok.col)

proc parseReturn(p: var Parser): Stmt =
  let tok = advance(p)
  let v = parseExpr(p)
  newReturn(v, tok.line, tok.col)

proc parseBlockStmt(p: var Parser): Stmt =
  let tok = advance(p)
  discard expect(p, tkColon, "Expected ':'")
  discard expect(p, tkNewline, "Expected newline")
  let body = parseBlock(p)
  newBlock(body, tok.line, tok.col)

proc parseStmt(p: var Parser): Stmt =
  # Skip unexpected indent/dedent tokens to make parser more robust
  while p.cur().kind == tkIndent or p.cur().kind == tkDedent:
    discard p.advance()
    if p.atEnd():
      quit "Unexpected end of input"
  
  let t = p.cur()

  if t.kind == tkIdent:
    case t.lexeme
    of "var": return parseVarStmt(p, false, false)
    of "let": return parseVarStmt(p, true, false)
    of "const": return parseVarStmt(p, false, true)
    of "defer":
      discard p.advance()
      discard expect(p, tkColon, "Expected ':' after defer")
      let deferredStmt = parseStmt(p)
      return newDefer(deferredStmt, t.line, t.col)
    of "type":
      discard p.advance()
      let typeName = expect(p, tkIdent, "Expected type name").lexeme
      discard expect(p, tkOp, "Expected '='")
      let typeValue = parseType(p)
      return newType(typeName, typeValue, t.line, t.col)
    of "if": return parseIf(p)
    of "for": return parseFor(p)
    of "while": return parseWhile(p)
    of "proc": return parseProc(p)
    of "return": return parseReturn(p)
    of "block": return parseBlockStmt(p)
    else:
      # Parse as expression first (could be assignment target or just expression)
      let e = parseExpr(p)
      # Check if this is an assignment
      if p.cur().kind == tkOp and p.cur().lexeme == "=":
        return parseAssign(p, e, t.line, t.col)
      return newExprStmt(e, t.line, t.col)

  let e = parseExpr(p)
  newExprStmt(e, t.line, t.col)

# blocks ---------------------------------------------------------------

proc parseBlock(p: var Parser): seq[Stmt] =
  result = @[]
  if not match(p, tkIndent):
    quit "Expected indent block at line " & $p.cur().line

  while not p.atEnd():
    if match(p, tkDedent):
      break
    if p.cur().kind == tkNewline:
      discard p.advance()
      continue
    result.add(parseStmt(p))
    discard match(p, tkNewline)

# root ---------------------------------------------------------------

proc parseDsl*(tokens: seq[Token]): Program =
  var p = Parser(tokens: tokens, pos: 0)
  var stmts: seq[Stmt] = @[]

  while not p.atEnd():
    if p.cur().kind == tkNewline:
      discard p.advance()
      continue
    # Skip unexpected indent/dedent tokens at top level
    if p.cur().kind == tkIndent or p.cur().kind == tkDedent:
      discard p.advance()
      continue
    stmts.add(parseStmt(p))
    discard match(p, tkNewline)

  Program(stmts: stmts)
