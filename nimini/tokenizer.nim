# dsl_tokenizer.nim
# Clean, strict-mode-safe tokenizer for the Mini-Nim DSL

import std/[strutils]
import ast

# ------------------------------------------------------------------------------
# Token Types
# ------------------------------------------------------------------------------

type
  TokenKind* = enum
    tkInt, tkFloat, tkString,
    tkIdent, tkOp,
    tkLParen, tkRParen,
    tkLBracket, tkRBracket,
    tkLBrace, tkRBrace,          # { }
    tkComma, tkColon, tkDot,     # , : .
    tkNewline,
    tkIndent, tkDedent,
    tkEOF

  Token* = object
    kind*: TokenKind
    lexeme*: string
    line*: int
    col*: int

proc `$`*(t: Token): string =
  result = $t.kind & "('" & t.lexeme & "') at " & $t.line & ":" & $t.col

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------

proc isIdentStart(c: char): bool =
  c.isAlphaAscii() or c == '_'

proc isIdentChar(c: char): bool =
  c.isAlphaAscii() or c.isDigit or c == '_'

proc isDigit(c: char): bool =
  c >= '0' and c <= '9'

proc addToken(res: var seq[Token];
              k: TokenKind;
              lex: string;
              line, col: int) =
  res.add Token(kind: k, lexeme: lex, line: line, col: col)

# ------------------------------------------------------------------------------
# Tokenizer
# ------------------------------------------------------------------------------

proc tokenizeDsl*(src: string): seq[Token] =
  var res: seq[Token] = @[]
  var i = 0
  var line = 1
  var col = 1

  # indentation stack
  var indentStack = @[0]
  var atLineStart = true

  # local utility to compute current indent
  proc countIndent(start: int): tuple[len, newI: int] =
    var j = start
    var n = 0
    while j < src.len:
      case src[j]
      of ' ':
        inc n; inc j
      of '\t':
        inc n, 4   # treat tabs as 4 spaces
        inc j
      else:
        break
    (n, j)

  # ----------------------------------------------------------------------------

  while i < src.len:
    let c = src[i]

    # ------------------------------
    # Handle newline
    # ------------------------------
    if c == '\n':
      addToken(res, tkNewline, "\n", line, col)
      inc line
      col = 1
      atLineStart = true
      inc i
      continue

    # If at start of line, count indentation
    if atLineStart:
      if c == ' ' or c == '\t':
        let (nIndent, newI) = countIndent(i)
        let prev = indentStack[^1]

        if nIndent > prev:
          indentStack.add nIndent
          addToken(res, tkIndent, "", line, col)
        elif nIndent < prev:
          while indentStack.len > 0 and indentStack[^1] > nIndent:
            discard indentStack.pop()
            addToken(res, tkDedent, "", line, col)

        i = newI
        col += (newI - i)
        atLineStart = false
        continue
      else:
        # no indent
        let prev = indentStack[^1]
        if prev != 0:
          while indentStack.len > 1:
            discard indentStack.pop()
            addToken(res, tkDedent, "", line, col)
        atLineStart = false

    # ------------------------------
    # Skip spaces inside line
    # ------------------------------
    if c == ' ':
      inc col; inc i
      continue

    if c == '\t':
      col += 4; inc i
      continue

    # ------------------------------
    # Comments
    # ------------------------------
    if c == '#':
      # skip until newline
      while i < src.len and src[i] != '\n':
        inc i
      continue

    # ------------------------------
    # Parens / Commas / Colon
    # ------------------------------
    case c
    of '(':
      addToken(res, tkLParen, "(", line, col)
      inc col; inc i
      continue
    of ')':
      addToken(res, tkRParen, ")", line, col)
      inc col; inc i
      continue
    of '[':
      addToken(res, tkLBracket, "[", line, col)
      inc col; inc i
      continue
    of ']':
      addToken(res, tkRBracket, "]", line, col)
      inc col; inc i
      continue
    of ',':
      addToken(res, tkComma, ",", line, col)
      inc col; inc i
      continue
    of ':':
      addToken(res, tkColon, ":", line, col)
      inc col; inc i
      continue
    else:
      # Not punctuation, fall through so other tokenizer rules handle it
      discard
    
    # ------------------------------
    # Strings: "..." or '...'
    # ------------------------------
    if c == '"' or c == '\'':
      let startCol = col
      let quote = c
      inc i; inc col

      var s = ""
      while i < src.len and src[i] != quote:
        s.add src[i]
        inc i; inc col

      if i >= src.len:
        var err = newException(NiminiTokenizeError, "Unterminated string at line " & $line)
        err.line = line
        err.col = startCol
        raise err

      # skip closing quote
      inc i; inc col

      addToken(res, tkString, s, line, startCol)
      continue

    # ------------------------------
    # Numbers: int or float
    # ------------------------------
    if c.isDigit():
      let start = i
      let startCol = col
      var sawDot = false

      inc i; inc col
      while i < src.len:
        if src[i].isDigit():
          inc i; inc col
        elif src[i] == '.' and not sawDot:
          # Check if this is a range operator (..) instead of decimal point
          if i+1 < src.len and src[i+1] == '.':
            # This is the start of a .. operator, stop parsing number
            break
          sawDot = true
          inc i; inc col
        else:
          break

      # Check for type suffix (e.g., 123'i32, 3.14'f32)
      var typeSuffix = ""
      if i < src.len and src[i] == '\'':
        inc i; inc col  # Skip the apostrophe
        let suffixStart = i
        # Read the type suffix (e.g., i32, f64, u8)
        while i < src.len and src[i].isIdentChar():
          inc i; inc col
        typeSuffix = src[suffixStart ..< i]

      let numPart = src[start ..< (if typeSuffix.len > 0: i - typeSuffix.len - 1 else: i)]
      let lexeme = if typeSuffix.len > 0: numPart & "'" & typeSuffix else: numPart
      
      if sawDot:
        addToken(res, tkFloat, lexeme, line, startCol)
      else:
        addToken(res, tkInt, lexeme, line, startCol)
      continue

    # ------------------------------
    # Identifiers / keywords
    # ------------------------------
    if c.isIdentStart():
      let start = i
      let startCol = col

      inc i; inc col
      while i < src.len and src[i].isIdentChar():
        inc i; inc col

      let lex = src[start ..< i]
      addToken(res, tkIdent, lex, line, startCol)
      continue

    # ------------------------------
    # Operators
    # ------------------------------
    let startCol = col

    # Note: "and" and "or" are tokenized as identifiers (above) and handled
    # as keyword operators by the parser, not as operator tokens here

    # multi-char ops
    if i+1 < src.len:
      let two = src[i] & src[i+1]
      case two
      of "==", "!=", "<=", ">=":
        addToken(res, tkOp, two, line, startCol)
        inc i, 2
        col += 2
        continue
      of "+=", "-=", "*=", "/=", "%=":
        # Compound assignment operators
        addToken(res, tkOp, two, line, startCol)
        inc i, 2
        col += 2
        continue
      of "..":
        # Check for ..< (three-char operator)
        if i+2 < src.len and src[i+2] == '<':
          addToken(res, tkOp, "..<", line, startCol)
          inc i, 3
          col += 3
        else:
          # Just .. operator
          addToken(res, tkOp, "..", line, startCol)
          inc i, 2
          col += 2
        continue

    # single-char ops
    case c
    of '+', '-', '*', '/', '%', '=', '<', '>', '&', '$', '@', '!':
      addToken(res, tkOp, $c, line, startCol)
      inc i; inc col
      continue
    of '.':
      addToken(res, tkDot, $c, line, startCol)
      inc i; inc col
      continue
    of '{':
      addToken(res, tkLBrace, $c, line, startCol)
      inc i; inc col
      continue
    of '}':
      addToken(res, tkRBrace, $c, line, startCol)
      inc i; inc col
      continue
    else:
      var err = newException(NiminiTokenizeError, "Unexpected character '" & $c & "' at " & $line & ":" & $col)
      err.line = line
      err.col = col
      raise err

  # End of input: emit any remaining dedents
  while indentStack.len > 1:
    discard indentStack.pop()
    addToken(res, tkDedent, "", line, col)

  addToken(res, tkEOF, "", line, col)
  return res
