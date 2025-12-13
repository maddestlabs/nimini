# Nim Backend for Code Generation
# Generates native Nim code from Nimini AST

import ../backend
import ../ast
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
  of "$":
    result = "$(" & operand & ")"
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

method generateBreak*(backend: NimBackend; label: string; indent: string): string =
  if label.len > 0:
    result = indent & "break " & label
  else:
    result = indent & "break"

method generateContinue*(backend: NimBackend; label: string; indent: string): string =
  if label.len > 0:
    result = indent & "continue " & label
  else:
    result = indent & "continue"

# ------------------------------------------------------------------------------
# Function/Procedure Generation
# ------------------------------------------------------------------------------

method generateProcDecl*(backend: NimBackend; name: string; params: seq[ProcParam]; indent: string): string =
  var paramStrs: seq[string] = @[]
  for param in params:
    var paramStr = ""
    if param.isVar:
      paramStr = param.name & ": var " & param.paramType
    elif param.paramType.len > 0:
      paramStr = param.name & ": " & param.paramType
    else:
      # No type specified - Nim will infer or use auto
      paramStr = param.name
    paramStrs.add(paramStr)
  
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
# Type Generation
# ------------------------------------------------------------------------------

method generateEnumType*(backend: NimBackend; name: string; values: seq[tuple[name: string, value: int]]; indent: string): string =
  ## Generate Nim enum type definition
  result = indent & "type " & name & " = enum"
  if values.len > 0:
    for i, enumVal in values:
      result &= "\n" & indent & "  " & enumVal.name
      # Show explicit ordinal value if it's not sequential
      let expectedOrdinal = if i == 0: 0 else: values[i-1].value + 1
      if enumVal.value != expectedOrdinal:
        result &= " = " & $enumVal.value

# ------------------------------------------------------------------------------
# Program Structure
# ------------------------------------------------------------------------------

method generateProgramHeader*(backend: NimBackend): string =
  result = ""  # Nim doesn't need a header

method generateProgramFooter*(backend: NimBackend): string =
  result = ""  # Nim doesn't need a footer
