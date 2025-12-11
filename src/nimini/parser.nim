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
  
  # Check for object type definition: object
  # Note: This is for inline object types in type declarations
  # The full object parsing is done in parseObjectType
  if typeName == "object":
    # Simple placeholder - full parsing done elsewhere
    return newObjectType(@[])
  
  # Check for enum type definition: enum
  if typeName == "enum":
    # Simple placeholder - full parsing done elsewhere
    return newEnumType(@[])
  
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

proc parseObjectType(p: var Parser): TypeNode =
  ## Parse object type definition with fields
  ## Expects: object <newline> <indent> field1: Type1 <newline> field2: Type2 ...
  discard expect(p, tkIdent, "Expected 'object'")  # Already consumed 'object'
  
  var fields: seq[tuple[name: string, fieldType: TypeNode]] = @[]
  
  # Expect newline then indent
  discard expect(p, tkNewline, "Expected newline after 'object'")
  if not match(p, tkIndent):
    # Empty object
    return newObjectType(fields)
  
  # Parse fields
  while not p.atEnd():
    if match(p, tkDedent):
      break
    if p.cur().kind == tkNewline:
      discard p.advance()
      continue
    
    # Parse field: name: Type
    let fieldName = expect(p, tkIdent, "Expected field name").lexeme
    discard expect(p, tkColon, "Expected ':' after field name")
    let fieldType = parseType(p)
    fields.add((fieldName, fieldType))
    discard match(p, tkNewline)
  
  return newObjectType(fields)

proc parseEnumType(p: var Parser): TypeNode =
  ## Parse enum type definition with values
  ## Expects: enum <newline> <indent> Value1 <newline> Value2 = 10 ...
  discard expect(p, tkIdent, "Expected 'enum'")  # Already consumed 'enum'
  
  var enumValues: seq[tuple[name: string, value: int]] = @[]
  var nextOrdinal = 0
  
  # Expect newline then indent
  discard expect(p, tkNewline, "Expected newline after 'enum'")
  if not match(p, tkIndent):
    # Empty enum
    return newEnumType(enumValues)
  
  # Parse enum values
  while not p.atEnd():
    if match(p, tkDedent):
      break
    if p.cur().kind == tkNewline:
      discard p.advance()
      continue
    
    # Parse value: Name or Name = ordinal
    let valueName = expect(p, tkIdent, "Expected enum value name").lexeme
    var ordinal = nextOrdinal
    
    if p.cur().kind == tkOp and p.cur().lexeme == "=":
      discard p.advance()
      if p.cur().kind != tkInt:
        quit "Expected integer ordinal value for enum at line " & $p.cur().line
      ordinal = parseInt(p.cur().lexeme)
      discard p.advance()
    
    enumValues.add((valueName, ordinal))
    nextOrdinal = ordinal + 1
    discard match(p, tkNewline)
  
  return newEnumType(enumValues)

proc parsePrefix(p: var Parser): Expr =
  let t = p.cur()

  case t.kind
  of tkInt:
    discard p.advance()
    # Extract type suffix if present (e.g., "123'i32" -> value=123, suffix=i32)
    let lexeme = t.lexeme
    var typeSuffix = ""
    var numPart = lexeme
    
    let apostrophePos = lexeme.find('\'')
    if apostrophePos >= 0:
      numPart = lexeme[0..<apostrophePos]
      typeSuffix = lexeme[apostrophePos+1..^1]
    
    newInt(parseInt(numPart), t.line, t.col, typeSuffix)

  of tkFloat:
    discard p.advance()
    # Extract type suffix if present (e.g., "3.14'f32" -> value=3.14, suffix=f32)
    let lexeme = t.lexeme
    var typeSuffix = ""
    var numPart = lexeme
    
    let apostrophePos = lexeme.find('\'')
    if apostrophePos >= 0:
      numPart = lexeme[0..<apostrophePos]
      typeSuffix = lexeme[apostrophePos+1..^1]
    
    newFloat(parseFloat(numPart), t.line, t.col, typeSuffix)

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
    elif t.lexeme == "proc":
      # Parse anonymous proc (lambda expression)
      discard p.advance()
      discard expect(p, tkLParen, "Expected '(' after proc")
      
      var params: seq[ProcParam] = @[]
      if p.cur().kind != tkRParen:
        while true:
          # Check for 'var' modifier
          var isVar = false
          if p.cur().kind == tkIdent and p.cur().lexeme == "var":
            isVar = true
            discard p.advance()
          
          let pname = expect(p, tkIdent, "Expected parameter name").lexeme
          discard expect(p, tkColon, "Expected ':'")
          let ptype = expect(p, tkIdent, "Expected parameter type").lexeme
          params.add(ProcParam(name: pname, paramType: ptype, isVar: isVar))
          if not match(p, tkComma):
            break
      
      discard expect(p, tkRParen, "Expected ')'")
      
      # Optional return type - check if there's a colon followed by a type (not a statement)
      var returnType: TypeNode = nil
      var hasBodyColon = false
      if p.cur().kind == tkColon:
        # Save position to potentially backtrack
        let colonPos = p.pos
        discard p.advance()
        # Check if it looks like a return type (an identifier that's not a statement keyword)
        if p.cur().kind == tkIdent and p.cur().lexeme notin ["defer", "if", "for", "while", "return", "var", "let", "const", "block", "case", "break", "continue"]:
          # This is a return type
          returnType = parseType(p)
          # After the return type, expect another colon for the body
          discard expect(p, tkColon, "Expected ':' before proc body")
          hasBodyColon = true
        else:
          # It's the body colon - the statement after it will be parsed as body
          # The colon is already consumed
          hasBodyColon = true
      
      if not hasBodyColon:
        # No colon yet, expect one for the body
        discard expect(p, tkColon, "Expected ':' before proc body")
      
      # Parse body - could be inline or block
      var body: seq[Stmt] = @[]
      if p.cur().kind == tkNewline:
        # Multi-line block body
        discard p.advance()
        body = parseBlock(p)
      else:
        # Inline single statement
        body.add(parseStmt(p))
      
      return newLambda(params, body, returnType, t.line, t.col)
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
      
      # Skip newlines and indents after opening paren
      while p.cur().kind in {tkNewline, tkIndent}:
        discard p.advance()
      
      var args: seq[Expr] = @[]
      var objFields: seq[tuple[name: string, value: Expr]] = @[]
      var isObjConstr = false
      
      if p.cur().kind != tkRParen:
        # Peek ahead to see if this is object construction (field: value) or function call
        # Save position for potential backtrack
        let savedPos = p.pos
        
        # Skip any leading whitespace for lookahead
        while p.cur().kind in {tkNewline, tkIndent}:
          discard p.advance()
        
        # Check if first argument looks like named field (ident followed by colon)
        if p.cur().kind == tkIdent:
          let possibleField = p.cur().lexeme
          discard p.advance()
          # Skip whitespace between ident and potential colon
          while p.cur().kind in {tkNewline, tkIndent}:
            discard p.advance()
          if p.cur().kind == tkColon:
            # This is object construction!
            isObjConstr = true
            p.pos = savedPos  # Reset to parse properly
            # Skip whitespace again after reset
            while p.cur().kind in {tkNewline, tkIndent}:
              discard p.advance()
          else:
            # Not object construction, reset and parse as call
            p.pos = savedPos
        
        if isObjConstr:
          # Parse as object construction Type(field: value, ...)
          let fieldName = expect(p, tkIdent, "Expected field name").lexeme
          discard expect(p, tkColon, "Expected ':' after field name")
          # Skip newlines/indents after colon
          while p.cur().kind in {tkNewline, tkIndent}:
            discard p.advance()
          let fieldValue = parseExpr(p)
          objFields.add((fieldName, fieldValue))
          
          # Skip trailing whitespace after field value
          while p.cur().kind in {tkNewline, tkIndent, tkDedent}:
            discard p.advance()
          
          while match(p, tkComma):
            # Skip newlines/indents after comma
            while p.cur().kind in {tkNewline, tkIndent}:
              discard p.advance()
            # Check for closing paren (trailing comma case)
            if p.cur().kind in {tkRParen, tkDedent}:
              # Skip any dedents before the closing paren
              while p.cur().kind == tkDedent:
                discard p.advance()
              break
            let fname = expect(p, tkIdent, "Expected field name").lexeme
            discard expect(p, tkColon, "Expected ':' after field name")
            # Skip newlines/indents after colon
            while p.cur().kind in {tkNewline, tkIndent}:
              discard p.advance()
            let fvalue = parseExpr(p)
            objFields.add((fname, fvalue))
            # Skip trailing whitespace after field value
            while p.cur().kind in {tkNewline, tkIndent, tkDedent}:
              discard p.advance()
        else:
          # Parse as regular function call
          args.add(parseExpr(p))
          while match(p, tkComma):
            args.add(parseExpr(p))
      
      # Skip newlines/dedents before closing paren
      while p.cur().kind in {tkNewline, tkDedent}:
        discard p.advance()
      
      discard expect(p, tkRParen, "Expected ')'")
      
      # Check for do notation: functionCall(): followed by block
      var callExpr: Expr
      if isObjConstr:
        callExpr = newObjConstr(t.lexeme, objFields, t.line, t.col)
      else:
        callExpr = newCall(t.lexeme, args, t.line, t.col)
      
      # Check if this is do notation: call followed by : and block
      if p.cur().kind == tkColon:
        discard p.advance()  # consume ':'
        if p.cur().kind == tkNewline:
          discard p.advance()  # consume newline
          # This is do notation! Parse the block as a lambda body
          let lambdaBody = parseBlock(p)
          # Create a lambda with no parameters
          let lambda = newLambda(@[], lambdaBody, nil, t.line, t.col)
          # Add the lambda as the last argument to the call
          if callExpr.kind == ekCall:
            callExpr.args.add(lambda)
          return callExpr
      
      return callExpr
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
    # Parse tuple literal or parenthesized expression
    discard p.advance()
    let startLine = t.line
    let startCol = t.col
    
    # Empty tuple: ()
    if p.cur().kind == tkRParen:
      discard p.advance()
      return newTuple(@[], startLine, startCol)
    
    # Check if this is a named tuple by looking ahead
    var isNamedTuple = false
    if p.cur().kind == tkIdent:
      let savedPos = p.pos
      discard p.advance()
      if p.cur().kind == tkColon:
        isNamedTuple = true
      p.pos = savedPos
    
    if isNamedTuple:
      # Parse named tuple: (name: "Bob", age: 30)
      var fields: seq[tuple[name: string, value: Expr]] = @[]
      
      let fieldName = expect(p, tkIdent, "Expected field name").lexeme
      discard expect(p, tkColon, "Expected ':' after field name")
      let fieldValue = parseExpr(p)
      fields.add((fieldName, fieldValue))
      
      while match(p, tkComma):
        if p.cur().kind == tkRParen:
          break  # Allow trailing comma
        let fname = expect(p, tkIdent, "Expected field name").lexeme
        discard expect(p, tkColon, "Expected ':' after field name")
        let fvalue = parseExpr(p)
        fields.add((fname, fvalue))
      
      discard expect(p, tkRParen, "Expected ')'")
      return newNamedTuple(fields, startLine, startCol)
    else:
      # Parse unnamed tuple or parenthesized expression
      var elements: seq[Expr] = @[]
      elements.add(parseExpr(p))
      
      # Check if there's a comma (making it a tuple)
      if match(p, tkComma):
        # This is a tuple
        if p.cur().kind != tkRParen:
          elements.add(parseExpr(p))
          while match(p, tkComma):
            if p.cur().kind == tkRParen:
              break  # Allow trailing comma
            elements.add(parseExpr(p))
        discard expect(p, tkRParen, "Expected ')'")
        return newTuple(elements, startLine, startCol)
      else:
        # Single expression in parentheses
        discard expect(p, tkRParen, "Expected ')'")
        return elements[0]

  of tkLBracket:
    discard p.advance()
    var elements: seq[Expr] = @[]
    if p.cur().kind != tkRBracket:
      elements.add(parseExpr(p))
      while match(p, tkComma):
        elements.add(parseExpr(p))
    discard expect(p, tkRBracket, "Expected ']'")
    newArray(elements, t.line, t.col)

  of tkLBrace:
    # Parse map literal {key: value, key2: value2, ...}
    discard p.advance()
    var pairs: seq[tuple[key: string, value: Expr]] = @[]
    if p.cur().kind != tkRBrace:
      # Parse first key-value pair
      if p.cur().kind != tkIdent and p.cur().kind != tkString:
        quit "Map literal keys must be identifiers or strings at line " & $t.line
      let key = p.cur().lexeme
      discard p.advance()
      discard expect(p, tkColon, "Expected ':' after map key")
      let value = parseExpr(p)
      pairs.add((key, value))
      
      # Parse remaining pairs
      while match(p, tkComma):
        if p.cur().kind == tkRBrace:
          break  # Allow trailing comma
        if p.cur().kind != tkIdent and p.cur().kind != tkString:
          quit "Map literal keys must be identifiers or strings at line " & $p.cur().line
        let pairKey = p.cur().lexeme
        discard p.advance()
        discard expect(p, tkColon, "Expected ':' after map key")
        let pairValue = parseExpr(p)
        pairs.add((pairKey, pairValue))
    
    discard expect(p, tkRBrace, "Expected '}'")
    newMap(pairs, t.line, t.col)

  else:
    quit "Unexpected token in expression at line" & $t.line

# Pratt led -------------------------------------------------------------

proc parseExpr(p: var Parser; prec=0): Expr =
  var left = parsePrefix(p)
  while true:
    let cur = p.cur()
    
    # Handle dot notation for field access or method calls
    if cur.kind == tkDot:
      discard p.advance()
      let fieldName = expect(p, tkIdent, "Expected field name after '.'").lexeme
      
      # Check if this is a method call (followed by parentheses)
      if p.cur().kind == tkLParen:
        discard p.advance()
        
        # Parse method arguments
        var args: seq[Expr] = @[]
        if p.cur().kind != tkRParen:
          args.add(parseExpr(p))
          while match(p, tkComma):
            args.add(parseExpr(p))
        
        discard expect(p, tkRParen, "Expected ')'")
        
        # Create a method call node (represented as a call with the object as first argument)
        # For backend generation, we'll handle this specially
        args.insert(left, 0)  # Insert object as first argument
        left = newCall(fieldName, args, cur.line, cur.col)
      else:
        # Regular field access
        left = newDot(left, fieldName, cur.line, cur.col)
      continue
    
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
  
  # Check if this is tuple unpacking: let (x, y) = ...
  if p.cur().kind == tkLParen:
    if isConst:
      quit "Tuple unpacking not supported for const at line " & $kw.line
    
    discard p.advance()
    var names: seq[string] = @[]
    names.add(expect(p, tkIdent, "Expected identifier").lexeme)
    
    while match(p, tkComma):
      names.add(expect(p, tkIdent, "Expected identifier").lexeme)
    
    discard expect(p, tkRParen, "Expected ')'")
    
    # Optional type annotation
    var typeAnnotation: TypeNode = nil
    if p.cur().kind == tkColon:
      discard p.advance()
      typeAnnotation = parseType(p)
    
    discard expect(p, tkOp, "Expected '='")
    let val = parseExpr(p)
    
    if isLet:
      return newLetUnpack(names, val, typeAnnotation, kw.line, kw.col)
    else:
      return newVarUnpack(names, val, typeAnnotation, kw.line, kw.col)
  
  # Regular variable declaration
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
  
  # Check for multiple loop variables: for i, item in ...
  var varNames: seq[string] = @[]
  let firstVarTok = expect(p, tkIdent, "Expected loop variable name")
  varNames.add(firstVarTok.lexeme)
  
  # Check if there are more variables (comma-separated)
  while p.cur().kind == tkComma:
    discard p.advance()
    let varTok = expect(p, tkIdent, "Expected loop variable name")
    varNames.add(varTok.lexeme)
  
  # Expect "in" keyword
  if p.cur().kind != tkIdent or p.cur().lexeme != "in":
    quit "Parse Error: Expected 'in' after for variable at line " & $p.cur().line
  discard p.advance()

  # Parse the iterable expression (e.g., 1..5, range(1,10), someArray, etc.)
  let iterableExpr = parseExpr(p)

  discard expect(p, tkColon, "Expected ':'")
  discard expect(p, tkNewline, "Expected newline")

  let body = parseBlock(p)
  
  if varNames.len == 1:
    newFor(varNames[0], iterableExpr, body, "", tok.line, tok.col)
  else:
    newForMulti(varNames, iterableExpr, body, "", tok.line, tok.col)

proc parseWhile(p: var Parser): Stmt =
  let tok = advance(p)
  let cond = parseExpr(p)
  discard expect(p, tkColon, "Expected ':'")
  discard expect(p, tkNewline, "Expected newline")
  let body = parseBlock(p)
  newWhile(cond, body, "", tok.line, tok.col)

proc parseProc(p: var Parser): Stmt =
  let tok = advance(p)
  let nameTok = expect(p, tkIdent, "Expected proc name")
  discard expect(p, tkLParen, "Expected '('")

  var params: seq[ProcParam] = @[]
  if p.cur().kind != tkRParen:
    while true:
      # Check for 'var' modifier
      var isVar = false
      if p.cur().kind == tkIdent and p.cur().lexeme == "var":
        isVar = true
        discard p.advance()
      
      let pname = expect(p, tkIdent, "Expected parameter name").lexeme
      discard expect(p, tkColon, "Expected ':'")
      let ptype = expect(p, tkIdent, "Expected parameter type").lexeme
      params.add(ProcParam(name: pname, paramType: ptype, isVar: isVar))
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

proc parseCase(p: var Parser): Stmt =
  let tok = advance(p)  # consume 'case'
  let expr = parseExpr(p)
  
  # Optional colon after the expression (both syntaxes are allowed)
  if p.cur().kind == tkColon:
    discard p.advance()
  
  discard expect(p, tkNewline, "Expected newline after case expression")
  
  var caseStmt = newCase(expr, tok.line, tok.col)
  
  # Skip newlines before first branch
  while p.cur().kind == tkNewline:
    discard p.advance()
  
  # Parse 'of' branches
  while p.cur().kind == tkIdent and p.cur().lexeme == "of":
    discard p.advance()  # consume 'of'
    
    # Parse comma-separated values for this branch
    var values: seq[Expr] = @[]
    values.add(parseExpr(p))
    
    while p.cur().kind == tkComma:
      discard p.advance()  # consume comma
      values.add(parseExpr(p))
    
    discard expect(p, tkColon, "Expected ':' after of values")
    
    # Check if the body is inline or on next lines
    var branchBody: seq[Stmt] = @[]
    if p.cur().kind != tkNewline:
      # Inline statement (e.g., of "x": echo "hi")
      branchBody.add(parseStmt(p))
    else:
      # Block of statements
      discard expect(p, tkNewline, "Expected newline")
      branchBody = parseBlock(p)
    
    caseStmt.addOfBranch(values, branchBody)
    
    # Skip newlines between branches
    while p.cur().kind == tkNewline:
      discard p.advance()
  
  # Parse optional 'elif' branches (treated like else: if)
  while p.cur().kind == tkIdent and p.cur().lexeme == "elif":
    discard p.advance()  # consume 'elif'
    let cond = parseExpr(p)
    discard expect(p, tkColon, "Expected ':' after elif condition")
    
    var elifBody: seq[Stmt] = @[]
    if p.cur().kind != tkNewline:
      elifBody.add(parseStmt(p))
    else:
      discard expect(p, tkNewline, "Expected newline")
      elifBody = parseBlock(p)
    
    caseStmt.addCaseElif(cond, elifBody)
    
    # Skip newlines
    while p.cur().kind == tkNewline:
      discard p.advance()
  
  # Parse optional 'else' branch
  if p.cur().kind == tkIdent and p.cur().lexeme == "else":
    discard p.advance()  # consume 'else'
    discard expect(p, tkColon, "Expected ':' after else")
    
    var elseBody: seq[Stmt] = @[]
    if p.cur().kind != tkNewline:
      elseBody.add(parseStmt(p))
    else:
      discard expect(p, tkNewline, "Expected newline")
      elseBody = parseBlock(p)
    
    caseStmt.addCaseElse(elseBody)
  
  caseStmt

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
      
      # Check if this is an object or enum type
      let typeValue = 
        if p.cur().kind == tkIdent and p.cur().lexeme == "object":
          parseObjectType(p)
        elif p.cur().kind == tkIdent and p.cur().lexeme == "enum":
          parseEnumType(p)
        else:
          parseType(p)
      
      return newType(typeName, typeValue, t.line, t.col)
    of "if": return parseIf(p)
    of "case": return parseCase(p)
    of "for": return parseFor(p)
    of "while": return parseWhile(p)
    of "proc": return parseProc(p)
    of "return": return parseReturn(p)
    of "block":
      # Check for labeled block with for/while
      let blockTok = p.advance()
      
      # Check if there's a label
      var label = ""
      if p.cur().kind == tkIdent:
        let savedPos = p.pos
        let potentialLabel = p.advance()
        
        # Check if followed by colon
        if p.cur().kind == tkColon:
          label = potentialLabel.lexeme
          discard p.advance()  # consume colon
          
          # Check if this is a labeled loop
          if p.cur().kind == tkNewline:
            discard p.advance()
          
          if p.cur().kind == tkIdent:
            case p.cur().lexeme
            of "for":
              var forStmt = parseFor(p)
              forStmt.forLabel = label
              return forStmt
            of "while":
              var whileStmt = parseWhile(p)
              whileStmt.whileLabel = label
              return whileStmt
            else:
              # Regular labeled block
              let body = parseBlock(p)
              return newBlock(body, label, blockTok.line, blockTok.col)
          else:
            # Regular labeled block
            if p.cur().kind == tkNewline:
              discard p.advance()
            let body = parseBlock(p)
            return newBlock(body, label, blockTok.line, blockTok.col)
        else:
          # Not a label, restore and parse as regular block
          p.pos = savedPos
      
      # Regular block without label
      discard expect(p, tkColon, "Expected ':'")
      discard expect(p, tkNewline, "Expected newline")
      let body = parseBlock(p)
      return newBlock(body, "", blockTok.line, blockTok.col)
    of "break":
      discard p.advance()
      # Check if there's a label (identifier) after break
      var label = ""
      if p.cur().kind == tkIdent:
        label = p.cur().lexeme
        discard p.advance()
      return newBreak(label, t.line, t.col)
    of "continue":
      discard p.advance()
      # Check if there's a label (identifier) after continue
      var label = ""
      if p.cur().kind == tkIdent:
        label = p.cur().lexeme
        discard p.advance()
      return newContinue(label, t.line, t.col)
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
