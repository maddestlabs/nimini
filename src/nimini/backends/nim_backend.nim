# Nim Backend for Code Generation
# Generates native Nim code from Nimini AST

import ../backend
import std/strutils

type
  NimBackend* = ref object of CodegenBackend

proc newNimBackend*(): NimBackend =
  ## Create a new Nim backend
  result = NimBackend(
    name: "Nim",
    fileExtension: ".nim",
    usesIndentation: true,
    indentSize: 2
  )

# ------------------------------------------------------------------------------
# Primitive Value Generation
# ------------------------------------------------------------------------------

method generateInt*(backend: NimBackend; value: int): string =
  result = $value

method generateFloat*(backend: NimBackend; value: float): string =
  result = $value

method generateString*(backend: NimBackend; value: string): string =
  # Escape special characters
  let escaped = value
    .replace("\\", "\\\\")
    .replace("\"", "\\\"")
    .replace("\n", "\\n")
    .replace("\r", "\\r")
    .replace("\t", "\\t")
  result = "\"" & escaped & "\""

method generateBool*(backend: NimBackend; value: bool): string =
  result = if value: "true" else: "false"

method generateIdent*(backend: NimBackend; name: string): string =
  result = name

# ------------------------------------------------------------------------------
# Expression Generation
# ------------------------------------------------------------------------------

method generateBinOp*(backend: NimBackend; left, op, right: string): string =
  # Map operators to Nim syntax
  let nimOp = case op
    of "and": "and"
    of "or": "or"
    else: op
  
  result = "(" & left & " " & nimOp & " " & right & ")"

method generateUnaryOp*(backend: NimBackend; op, operand: string): string =
  case op
  of "-":
    result = "-(" & operand & ")"
  of "not":
    result = "not (" & operand & ")"
  else:
    result = op & "(" & operand & ")"

method generateCall*(backend: NimBackend; funcName: string; args: seq[string]): string =
  result = funcName & "(" & args.join(", ") & ")"

method generateArray*(backend: NimBackend; elements: seq[string]): string =
  result = "@[" & elements.join(", ") & "]"

method generateIndex*(backend: NimBackend; target, index: string): string =
  result = target & "[" & index & "]"

# ------------------------------------------------------------------------------
# Statement Generation
# ------------------------------------------------------------------------------

method generateVarDecl*(backend: NimBackend; name, value: string; indent: string): string =
  result = indent & "var " & name & " = " & value

method generateLetDecl*(backend: NimBackend; name, value: string; indent: string): string =
  result = indent & "let " & name & " = " & value

method generateAssignment*(backend: NimBackend; target, value: string; indent: string): string =
  result = indent & target & " = " & value

# ------------------------------------------------------------------------------
# Control Flow Generation
# ------------------------------------------------------------------------------

method generateIfStmt*(backend: NimBackend; condition: string; indent: string): string =
  result = indent & "if " & condition & ":"

method generateElifStmt*(backend: NimBackend; condition: string; indent: string): string =
  result = indent & "elif " & condition & ":"

method generateElseStmt*(backend: NimBackend; indent: string): string =
  result = indent & "else:"

method generateForLoop*(backend: NimBackend; varName, iterable: string; indent: string): string =
  result = indent & "for " & varName & " in " & iterable & ":"

method generateWhileLoop*(backend: NimBackend; condition: string; indent: string): string =
  result = indent & "while " & condition & ":"

# ------------------------------------------------------------------------------
# Function/Procedure Generation
# ------------------------------------------------------------------------------

method generateProcDecl*(backend: NimBackend; name: string; params: seq[(string, string)]; indent: string): string =
  var paramStrs: seq[string] = @[]
  for (pname, ptype) in params:
    if ptype.len > 0:
      paramStrs.add(pname & ": " & ptype)
    else:
      # No type specified - Nim will infer or use auto
      paramStrs.add(pname)
  
  let paramList = paramStrs.join("; ")
  result = indent & "proc " & name & "(" & paramList & ") ="

method generateReturn*(backend: NimBackend; value: string; indent: string): string =
  result = indent & "return " & value

# ------------------------------------------------------------------------------
# Module/Import Generation
# ------------------------------------------------------------------------------

method generateImport*(backend: NimBackend; module: string): string =
  result = "import " & module

method generateComment*(backend: NimBackend; text: string; indent: string = ""): string =
  result = indent & "# " & text

# ------------------------------------------------------------------------------
# Program Structure
# ------------------------------------------------------------------------------

method generateProgramHeader*(backend: NimBackend): string =
  result = ""  # Nim doesn't need a header

method generateProgramFooter*(backend: NimBackend): string =
  result = ""  # Nim doesn't need a footer
