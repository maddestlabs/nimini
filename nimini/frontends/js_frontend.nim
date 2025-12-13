# JavaScript Frontend - Parse JavaScript syntax into Nimini AST
# Supports ES6+ subset for library interop

import ../frontend
import ../tokenizer
import ../parser
import ../ast
import std/[strutils, tables]

export frontend

type
  JsTokenKind = enum
    jsInt, jsFloat, jsString, jsIdent,
    jsLBrace, jsRBrace, jsLParen, jsRParen, jsLBracket, jsRBracket,
    jsSemicolon, jsComma, jsColon, jsOp, jsEOF

  JsToken = object
    kind: JsTokenKind
    lexeme: string
    line: int
    col: int

  JavaScriptFrontend* = ref object of Frontend

proc newJavaScriptFrontend*(): JavaScriptFrontend =
  result = JavaScriptFrontend(
    name: "JavaScript",
    fileExtensions: @[".js", ".mjs"],
    supportsTypeAnnotations: false  # Plain JS (TypeScript would be separate)
  )

# JavaScript tokenizer
proc tokenizeJavaScript(src: string): seq[Token] =
  var res: seq[Token] = @[]
  var i = 0
  var line = 1
  var col = 1

  proc addToken(k: TokenKind; lex: string; ln, cl: int) =
    res.add Token(kind: k, lexeme: lex, line: ln, col: cl)

  proc isIdentStart(c: char): bool =
    c.isAlphaAscii() or c == '_' or c == '$'

  proc isIdentChar(c: char): bool =
    c.isAlphaAscii() or c.isDigit or c == '_' or c == '$'

  while i < src.len:
    let c = src[i]

    # Handle newline
    if c == '\n':
      addToken(tkNewline, "\n", line, col)
      inc line
      col = 1
      inc i
      continue

    # Skip spaces and tabs
    if c == ' ' or c == '\t':
      if c == ' ': inc col else: col += 4
      inc i
      continue

    # Comments
    if c == '/' and i+1 < src.len:
      if src[i+1] == '/':
        # Single-line comment
        while i < src.len and src[i] != '\n':
          inc i
        continue
      elif src[i+1] == '*':
        # Multi-line comment
        inc i, 2
        col += 2
        while i+1 < src.len:
          if src[i] == '*' and src[i+1] == '/':
            inc i, 2
            col += 2
            break
          if src[i] == '\n':
            inc line
            col = 1
          else:
            inc col
          inc i
        continue

    # Braces and punctuation
    case c
    of '{':
      addToken(tkIndent, "{", line, col)  # Map to indent
      inc col; inc i
      continue
    of '}':
      addToken(tkDedent, "}", line, col)  # Map to dedent
      inc col; inc i
      continue
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
    of ';':
      addToken(tkNewline, ";", line, col)  # Semicolon ends statement
      inc col; inc i
      continue
    else:
      discard

    # Strings
    if c == '"' or c == '\'' or (c == '`'):
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
          of '`': s.add '`'
          else: s.add src[i]
          inc i; inc col
        else:
          if src[i] == '\n':
            inc line
            col = 1
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
        elif src[i] == '.' and not sawDot and i+1 < src.len and src[i+1].isDigit():
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

    if i+2 < src.len:
      let three = src[i .. i+2]
      case three
      of "===", "!==":
        addToken(tkOp, three, line, startCol)
        inc i, 3
        col += 3
        continue
      else:
        discard

    if i+1 < src.len:
      let two = src[i] & src[i+1]
      case two
      of "==", "!=", "<=", ">=", "&&", "||", "=>", "++", "--", "**":
        addToken(tkOp, two, line, startCol)
        inc i, 2
        col += 2
        continue
      else:
        discard

    case c
    of '+', '-', '*', '/', '%', '=', '<', '>', '&', '|', '!', '.':
      addToken(tkOp, $c, line, startCol)
      inc i; inc col
      continue
    else:
      quit "Unexpected character '" & $c & "' at " & $line & ":" & $col

  addToken(tkEOF, "", line, col)
  return res

# JavaScript parser - converts JS tokens to Nimini AST
proc parseJavaScript(tokens: seq[Token]): Program =
  # JavaScript-to-Nim keyword/operator mappings
  let keywordMap = {
    "function": "proc",
    "const": "let",
    "let": "var",
    "var": "var",
    "true": "true",
    "false": "false",
    "null": "nil",
    "undefined": "nil",
    "return": "return",
    "if": "if",
    "else": "else",
    "for": "for",
    "while": "while",
    "of": "in"
  }.toTable

  # Convert JavaScript tokens to Nim-compatible tokens
  var nimTokens: seq[Token] = @[]
  var skipUntil = -1  # Track when to skip tokens
  
  for i, tok in tokens:
    # Skip tokens if we're in a skip region
    if i < skipUntil:
      continue
    
    # Handle else if -> elif conversion
    if tok.kind == tkIdent and tok.lexeme == "else" and i+1 < tokens.len:
      # Look ahead to see if next meaningful token is "if"
      # Skip over newlines, braces (tkIndent/tkDedent)
      var nextIdx = i + 1
      while nextIdx < tokens.len and tokens[nextIdx].kind in [tkNewline, tkIndent, tkDedent]:
        inc nextIdx
      if nextIdx < tokens.len and tokens[nextIdx].kind == tkIdent and tokens[nextIdx].lexeme == "if":
        # Convert else if to elif
        nimTokens.add Token(kind: tkIdent, lexeme: "elif", line: tok.line, col: tok.col)
        # Now handle the if's condition parentheses
        var ifIdx = nextIdx + 1
        if ifIdx < tokens.len and tokens[ifIdx].kind == tkLParen:
          var parenDepth = 1
          inc ifIdx
          # Copy condition contents without the parens
          while ifIdx < tokens.len and parenDepth > 0:
            if tokens[ifIdx].kind == tkLParen:
              inc parenDepth
              nimTokens.add tokens[ifIdx]
            elif tokens[ifIdx].kind == tkRParen:
              dec parenDepth
              if parenDepth > 0:
                nimTokens.add tokens[ifIdx]
              # else: skip the closing paren
            else:
              nimTokens.add tokens[ifIdx]
            inc ifIdx
          skipUntil = ifIdx  # Skip past all processed tokens
        else:
          skipUntil = nextIdx + 1  # Just skip the "if" token
        continue
      else:
        # Plain else (not followed by if) - add it and continue
        nimTokens.add Token(kind: tkIdent, lexeme: "else", line: tok.line, col: tok.col)
        continue
    # Map operators
    elif tok.kind == tkOp:
      case tok.lexeme
      of "&&": 
        nimTokens.add Token(kind: tkIdent, lexeme: "and", line: tok.line, col: tok.col)
      of "||":
        nimTokens.add Token(kind: tkIdent, lexeme: "or", line: tok.line, col: tok.col)
      of "!":
        nimTokens.add Token(kind: tkIdent, lexeme: "not", line: tok.line, col: tok.col)
      of "===":
        nimTokens.add Token(kind: tkOp, lexeme: "==", line: tok.line, col: tok.col)
      of "!==":
        nimTokens.add Token(kind: tkOp, lexeme: "!=", line: tok.line, col: tok.col)
      else:
        nimTokens.add tok
      continue
    # Map keywords
    elif tok.kind == tkIdent and tok.lexeme in keywordMap:
      nimTokens.add Token(kind: tok.kind, lexeme: keywordMap[tok.lexeme], line: tok.line, col: tok.col)
      
      # If this is if/while/for, skip the condition parentheses
      if tok.lexeme in ["if", "while", "for"]:
        # Add the keyword first (already done above)
        # Now skip the opening paren if present
        if i+1 < tokens.len and tokens[i+1].kind == tkLParen:
          var parenDepth = 1
          var j = i + 2
          # Copy condition contents without the parens
          while j < tokens.len and parenDepth > 0:
            if tokens[j].kind == tkLParen:
              inc parenDepth
              nimTokens.add tokens[j]
            elif tokens[j].kind == tkRParen:
              dec parenDepth
              if parenDepth > 0:
                nimTokens.add tokens[j]
              # else: skip the closing paren
            else:
              nimTokens.add tokens[j]
            inc j
          skipUntil = j  # Skip past all the tokens we just processed
        continue
    # Convert console.log to echo
    elif tok.kind == tkIdent and tok.lexeme == "console" and i+2 < tokens.len and
         tokens[i+1].kind == tkOp and tokens[i+1].lexeme == "." and
         tokens[i+2].kind == tkIdent and tokens[i+2].lexeme == "log":
      nimTokens.add Token(kind: tkIdent, lexeme: "echo", line: tok.line, col: tok.col)
      skipUntil = i + 3  # Skip console, ., and log
      continue
    # Map operators
    elif tok.kind == tkOp:
      case tok.lexeme
      of "&&":
        nimTokens.add Token(kind: tkIdent, lexeme: "and", line: tok.line, col: tok.col)
      of "||":
        nimTokens.add Token(kind: tkIdent, lexeme: "or", line: tok.line, col: tok.col)
      of "!":
        nimTokens.add Token(kind: tkIdent, lexeme: "not", line: tok.line, col: tok.col)
      of "===", "==":
        nimTokens.add Token(kind: tkOp, lexeme: "==", line: tok.line, col: tok.col)
      of "!==", "!=":
        nimTokens.add Token(kind: tkOp, lexeme: "!=", line: tok.line, col: tok.col)
      of ".":
        # Skip dots that aren't part of console.log (we don't support method chaining yet)
        continue
      else:
        nimTokens.add tok
    # Handle braces - { becomes indent, } becomes dedent
    elif tok.kind == tkIndent:  # {
      # Need colon before brace for Nim
      if nimTokens.len > 0 and nimTokens[^1].kind != tkColon:
        nimTokens.add Token(kind: tkColon, lexeme: ":", line: tok.line, col: tok.col)
      nimTokens.add Token(kind: tkNewline, lexeme: "\n", line: tok.line, col: tok.col)
      nimTokens.add Token(kind: tkIndent, lexeme: "", line: tok.line, col: tok.col)
    elif tok.kind == tkDedent:  # }
      # Add newline before dedent if needed
      if nimTokens.len > 0 and nimTokens[^1].kind != tkNewline:
        nimTokens.add Token(kind: tkNewline, lexeme: "\n", line: tok.line, col: tok.col)
      nimTokens.add Token(kind: tkDedent, lexeme: "", line: tok.line, col: tok.col)
    else:
      nimTokens.add tok
    
    # Add type annotations for function parameters
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

  # Debug: print converted tokens
  when false:  # Set to true for debugging
    echo "=== Converted Nim Tokens ==="
    for i, t in nimTokens:
      echo i, ": ", t.kind, " '", t.lexeme, "'"
  
  # Use existing Nim parser on converted tokens
  return parseDsl(nimTokens)

method tokenize*(frontend: JavaScriptFrontend; source: string): seq[Token] =
  return tokenizeJavaScript(source)

method parse*(frontend: JavaScriptFrontend; tokens: seq[Token]): Program =
  return parseJavaScript(tokens)

# Auto-register this frontend
var javaScriptFrontendInstance: JavaScriptFrontend = nil

proc getJavaScriptFrontend*(): JavaScriptFrontend =
  if javaScriptFrontendInstance.isNil:
    javaScriptFrontendInstance = newJavaScriptFrontend()
    registerFrontend(javaScriptFrontendInstance)
  return javaScriptFrontendInstance

# Auto-register on module load
discard getJavaScriptFrontend()
