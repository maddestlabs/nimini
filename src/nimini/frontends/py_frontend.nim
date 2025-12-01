# Python Frontend - Parse Python syntax into Nimini AST
# Supports a subset of Python for library interop

import ../frontend
import ../tokenizer
import ../parser
import ../ast
import std/[strutils, tables]

export frontend

type
  PyTokenKind = enum
    pyInt, pyFloat, pyString, pyIdent,
    pyLParen, pyRParen, pyLBracket, pyRBracket,
    pyComma, pyColon, pyOp, pyNewline,
    pyIndent, pyDedent, pyEOF

  PyToken = object
    kind: PyTokenKind
    lexeme: string
    line: int
    col: int

  PythonFrontend* = ref object of Frontend

proc newPythonFrontend*(): PythonFrontend =
  result = PythonFrontend(
    name: "Python",
    fileExtensions: @[".py"],
    supportsTypeAnnotations: true  # Python 3+ has type hints
  )

# Python tokenizer - similar to Nim but with Python-specific keywords
proc tokenizePython(src: string): seq[Token] =
  var res: seq[Token] = @[]
  var i = 0
  var line = 1
  var col = 1
  var indentStack = @[0]
  var atLineStart = true

  proc countIndent(start: int): tuple[len, newI: int] =
    var j = start
    var n = 0
    while j < src.len:
      case src[j]
      of ' ':
        inc n; inc j
      of '\t':
        inc n, 4
        inc j
      else:
        break
    (n, j)

  proc addToken(k: TokenKind; lex: string; ln, cl: int) =
    res.add Token(kind: k, lexeme: lex, line: ln, col: cl)

  proc isIdentStart(c: char): bool =
    c.isAlphaAscii() or c == '_'

  proc isIdentChar(c: char): bool =
    c.isAlphaAscii() or c.isDigit or c == '_'

  while i < src.len:
    let c = src[i]

    # Handle newline
    if c == '\n':
      addToken(tkNewline, "\n", line, col)
      inc line
      col = 1
      atLineStart = true
      inc i
      continue

    # Handle indentation at line start
    if atLineStart:
      if c == ' ' or c == '\t':
        let (nIndent, newI) = countIndent(i)
        let prev = indentStack[^1]

        if nIndent > prev:
          indentStack.add nIndent
          addToken(tkIndent, "", line, col)
        elif nIndent < prev:
          while indentStack.len > 0 and indentStack[^1] > nIndent:
            discard indentStack.pop()
            addToken(tkDedent, "", line, col)

        i = newI
        col += (newI - i)
        atLineStart = false
        continue
      else:
        let prev = indentStack[^1]
        if prev != 0:
          while indentStack.len > 1:
            discard indentStack.pop()
            addToken(tkDedent, "", line, col)
        atLineStart = false

    # Skip spaces
    if c == ' ' or c == '\t':
      if c == ' ': inc col else: col += 4
      inc i
      continue

    # Comments
    if c == '#':
      while i < src.len and src[i] != '\n':
        inc i
      continue

    # Punctuation
    case c
    of '(':
      addToken(tkLParen, "(", line, col)
      inc col; inc i
      continue
    of ')':
      addToken(tkRParen, ")", line, col)
      inc col; inc i
      continue
    of '[':
      addToken(tkLBracket, "[", line, col)
      inc col; inc i
      continue
    of ']':
      addToken(tkRBracket, "]", line, col)
      inc col; inc i
      continue
    of ',':
      addToken(tkComma, ",", line, col)
      inc col; inc i
      continue
    of ':':
      addToken(tkColon, ":", line, col)
      inc col; inc i
      continue
    else:
      discard

    # Strings
    if c == '"' or c == '\'':
      let startCol = col
      let quote = c
      inc i; inc col

      var s = ""
      while i < src.len and src[i] != quote:
        if src[i] == '\\' and i+1 < src.len:
          inc i; inc col
          case src[i]
          of 'n': s.add '\n'
          of 't': s.add '\t'
          of 'r': s.add '\r'
          of '\\': s.add '\\'
          of '"': s.add '"'
          of '\'': s.add '\''
          else: s.add src[i]
          inc i; inc col
        else:
          s.add src[i]
          inc i; inc col

      if i >= src.len:
        quit "Unterminated string at line " & $line

      inc i; inc col
      addToken(tkString, s, line, startCol)
      continue

    # Numbers
    if c.isDigit():
      let start = i
      let startCol = col
      var sawDot = false

      inc i; inc col
      while i < src.len:
        if src[i].isDigit():
          inc i; inc col
        elif src[i] == '.' and not sawDot:
          if i+1 < src.len and src[i+1] == '.':
            break
          sawDot = true
          inc i; inc col
        else:
          break

      let lex = src[start ..< i]
      if sawDot:
        addToken(tkFloat, lex, line, startCol)
      else:
        addToken(tkInt, lex, line, startCol)
      continue

    # Identifiers and keywords
    if c.isIdentStart():
      let start = i
      let startCol = col

      inc i; inc col
      while i < src.len and src[i].isIdentChar():
        inc i; inc col

      let lex = src[start ..< i]
      addToken(tkIdent, lex, line, startCol)
      continue

    # Operators
    let startCol = col

    if i+1 < src.len:
      let two = src[i] & src[i+1]
      case two
      of "==", "!=", "<=", ">=", "//":
        addToken(tkOp, two, line, startCol)
        inc i, 2
        col += 2
        continue
      of "**":
        addToken(tkOp, "**", line, startCol)
        inc i, 2
        col += 2
        continue
      else:
        discard

    case c
    of '+', '-', '*', '/', '%', '=', '<', '>', '&', '!':
      addToken(tkOp, $c, line, startCol)
      inc i; inc col
      continue
    else:
      quit "Unexpected character '" & $c & "' at " & $line & ":" & $col

  # Emit remaining dedents
  while indentStack.len > 1:
    discard indentStack.pop()
    addToken(tkDedent, "", line, col)

  addToken(tkEOF, "", line, col)
  return res

# Python parser - converts Python AST to Nimini AST
proc parsePython(tokens: seq[Token]): Program =
  # Python-to-Nim keyword mappings
  let keywordMap = {
    "def": "proc",
    "True": "true",
    "False": "false",
    "None": "nil",
    "elif": "elif",
    "and": "and",
    "or": "or",
    "not": "not",
    "in": "in",
    "pass": "discard"
  }.toTable

  # Convert Python tokens to Nim-compatible tokens
  var nimTokens: seq[Token] = @[]
  
  for i, tok in tokens:
    # Map Python keywords to Nim equivalents
    if tok.kind == tkIdent and tok.lexeme in keywordMap:
      nimTokens.add Token(kind: tok.kind, lexeme: keywordMap[tok.lexeme], line: tok.line, col: tok.col)
    # Convert Python's print to echo
    elif tok.kind == tkIdent and tok.lexeme == "print":
      nimTokens.add Token(kind: tok.kind, lexeme: "echo", line: tok.line, col: tok.col)
    # Map Python operators to Nim
    elif tok.kind == tkOp:
      case tok.lexeme
      of "//":
        nimTokens.add Token(kind: tok.kind, lexeme: "div", line: tok.line, col: tok.col)
      of "**":
        nimTokens.add Token(kind: tok.kind, lexeme: "^", line: tok.line, col: tok.col)
      of "!":
        nimTokens.add Token(kind: tok.kind, lexeme: "not", line: tok.line, col: tok.col)
      else:
        nimTokens.add tok
    else:
      nimTokens.add tok
    
    # Add type annotations for function parameters that don't have them
    if i > 0 and i+1 < tokens.len:
      if tok.kind == tkIdent and tokens[i-1].kind in [tkLParen, tkComma] and 
         tokens[i+1].kind in [tkComma, tkRParen]:
        # Check if we're in a proc definition by looking backwards
        var inProc = false
        for j in countdown(nimTokens.len-1, max(0, nimTokens.len-15)):
          if nimTokens[j].kind == tkIdent and nimTokens[j].lexeme == "proc":
            inProc = true
            break
          # Stop if we hit something that means we're not in proc params
          if nimTokens[j].kind in [tkNewline, tkIndent, tkDedent]:
            break
        
        # Only add type if we're in a proc and next token isn't already a colon
        if inProc and tokens[i+1].kind != tkColon:
          nimTokens.add Token(kind: tkColon, lexeme: ":", line: tok.line, col: tok.col)
          nimTokens.add Token(kind: tkIdent, lexeme: "int", line: tok.line, col: tok.col)

  # Use existing Nim parser on converted tokens
  return parseDsl(nimTokens)

method tokenize*(frontend: PythonFrontend; source: string): seq[Token] =
  return tokenizePython(source)

method parse*(frontend: PythonFrontend; tokens: seq[Token]): Program =
  return parsePython(tokens)

# Auto-register this frontend
var pythonFrontendInstance: PythonFrontend = nil

proc getPythonFrontend*(): PythonFrontend =
  if pythonFrontendInstance.isNil:
    pythonFrontendInstance = newPythonFrontend()
    registerFrontend(pythonFrontendInstance)
  return pythonFrontendInstance

# Auto-register on module load
discard getPythonFrontend()
