# Python Backend for Code Generation
# Generates Python code from Nimini AST

import ../backend
import std/strutils

type
  PythonBackend* = ref object of CodegenBackend

proc newPythonBackend*(): PythonBackend =
  ## Create a new Python backend
  result = PythonBackend(
    name: "Python",
    fileExtension: ".py",
    usesIndentation: true,
    indentSize: 4
  )

# ------------------------------------------------------------------------------
# Primitive Value Generation
# ------------------------------------------------------------------------------

method generateInt*(backend: PythonBackend; value: int): string =
  result = $value

method generateFloat*(backend: PythonBackend; value: float): string =
  result = $value

method generateString*(backend: PythonBackend; value: string): string =
  # Escape special characters
  let escaped = value
    .replace("\\", "\\\\")
    .replace("\"", "\\\"")
    .replace("\n", "\\n")
    .replace("\r", "\\r")
    .replace("\t", "\\t")
  result = "\"" & escaped & "\""

method generateBool*(backend: PythonBackend; value: bool): string =
  result = if value: "True" else: "False"

method generateIdent*(backend: PythonBackend; name: string): string =
  result = name

# ------------------------------------------------------------------------------
# Expression Generation
# ------------------------------------------------------------------------------

method generateBinOp*(backend: PythonBackend; left, op, right: string): string =
  # Map operators to Python syntax
  let pythonOp = case op
    of "and": "and"
    of "or": "or"
    of "%": "%"  # Modulo is the same
    else: op
  
  result = "(" & left & " " & pythonOp & " " & right & ")"

method generateUnaryOp*(backend: PythonBackend; op, operand: string): string =
  case op
  of "-":
    result = "-(" & operand & ")"
  of "not":
    result = "not (" & operand & ")"
  else:
    result = op & "(" & operand & ")"

method generateCall*(backend: PythonBackend; funcName: string; args: seq[string]): string =
  result = funcName & "(" & args.join(", ") & ")"

method generateArray*(backend: PythonBackend; elements: seq[string]): string =
  result = "[" & elements.join(", ") & "]"

method generateIndex*(backend: PythonBackend; target, index: string): string =
  result = target & "[" & index & "]"

# ------------------------------------------------------------------------------
# Statement Generation
# ------------------------------------------------------------------------------

method generateVarDecl*(backend: PythonBackend; name, value: string; indent: string): string =
  # Python doesn't distinguish var/let - both are just assignments
  result = indent & name & " = " & value

method generateLetDecl*(backend: PythonBackend; name, value: string; indent: string): string =
  # Python doesn't have const at statement level
  result = indent & name & " = " & value

method generateAssignment*(backend: PythonBackend; target, value: string; indent: string): string =
  result = indent & target & " = " & value

# ------------------------------------------------------------------------------
# Control Flow Generation
# ------------------------------------------------------------------------------

method generateIfStmt*(backend: PythonBackend; condition: string; indent: string): string =
  result = indent & "if " & condition & ":"

method generateElifStmt*(backend: PythonBackend; condition: string; indent: string): string =
  result = indent & "elif " & condition & ":"

method generateElseStmt*(backend: PythonBackend; indent: string): string =
  result = indent & "else:"

method generateForLoop*(backend: PythonBackend; varName, iterable: string; indent: string): string =
  result = indent & "for " & varName & " in " & iterable & ":"

method generateWhileLoop*(backend: PythonBackend; condition: string; indent: string): string =
  result = indent & "while " & condition & ":"

# ------------------------------------------------------------------------------
# Function/Procedure Generation
# ------------------------------------------------------------------------------

method generateProcDecl*(backend: PythonBackend; name: string; params: seq[(string, string)]; indent: string): string =
  var paramStrs: seq[string] = @[]
  for (pname, ptype) in params:
    # Python doesn't require type annotations (though they can be added)
    # For now, just use parameter names
    paramStrs.add(pname)
  
  let paramList = paramStrs.join(", ")
  result = indent & "def " & name & "(" & paramList & "):"

method generateReturn*(backend: PythonBackend; value: string; indent: string): string =
  result = indent & "return " & value

# ------------------------------------------------------------------------------
# Module/Import Generation
# ------------------------------------------------------------------------------

method generateImport*(backend: PythonBackend; module: string): string =
  result = "import " & module

method generateComment*(backend: PythonBackend; text: string; indent: string = ""): string =
  result = indent & "# " & text

# ------------------------------------------------------------------------------
# Program Structure
# ------------------------------------------------------------------------------

method generateProgramHeader*(backend: PythonBackend): string =
  result = "#!/usr/bin/env python3"

method generateProgramFooter*(backend: PythonBackend): string =
  result = ""  # Python doesn't need a footer
