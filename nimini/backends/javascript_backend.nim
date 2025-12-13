# JavaScript Backend for Code Generation
# Generates JavaScript (ES6+) code from Nimini AST

import ../backend
import ../ast
import std/strutils

type
  JavaScriptBackend* = ref object of CodegenBackend

proc newJavaScriptBackend*(): JavaScriptBackend =
  ## Create a new JavaScript backend
  result = JavaScriptBackend(
    name: "JavaScript",
    fileExtension: ".js",
    usesIndentation: false,  # Uses braces
    indentSize: 2
  )

# ------------------------------------------------------------------------------
# Primitive Value Generation
# ------------------------------------------------------------------------------

method generateInt*(backend: JavaScriptBackend; value: int): string =
  result = $value

method generateFloat*(backend: JavaScriptBackend; value: float): string =
  result = $value

method generateString*(backend: JavaScriptBackend; value: string): string =
  # Escape special characters
  let escaped = value
    .replace("\\", "\\\\")
    .replace("\"", "\\\"")
    .replace("\n", "\\n")
    .replace("\r", "\\r")
    .replace("\t", "\\t")
  result = "\"" & escaped & "\""

method generateBool*(backend: JavaScriptBackend; value: bool): string =
  result = if value: "true" else: "false"

method generateIdent*(backend: JavaScriptBackend; name: string): string =
  result = name

# ------------------------------------------------------------------------------
# Expression Generation
# ------------------------------------------------------------------------------

method generateBinOp*(backend: JavaScriptBackend; left, op, right: string): string =
  # Map operators to JavaScript syntax
  let jsOp = case op
    of "and": "&&"
    of "or": "||"
    of "%": "%"  # Modulo is the same
    of "&": "+"  # String concatenation
    else: op
  
  result = "(" & left & " " & jsOp & " " & right & ")"

method generateUnaryOp*(backend: JavaScriptBackend; op, operand: string): string =
  case op
  of "-":
    result = "-(" & operand & ")"
  of "not":
    result = "!(" & operand & ")"
  of "$":
    result = "String(" & operand & ")"
  else:
    result = op & "(" & operand & ")"

method generateCall*(backend: JavaScriptBackend; funcName: string; args: seq[string]): string =
  result = funcName & "(" & args.join(", ") & ")"

method generateArray*(backend: JavaScriptBackend; elements: seq[string]): string =
  result = "[" & elements.join(", ") & "]"

method generateIndex*(backend: JavaScriptBackend; target, index: string): string =
  result = target & "[" & index & "]"

# ------------------------------------------------------------------------------
# Statement Generation
# ------------------------------------------------------------------------------

method generateVarDecl*(backend: JavaScriptBackend; name, value: string; indent: string): string =
  result = indent & "let " & name & " = " & value & ";"

method generateLetDecl*(backend: JavaScriptBackend; name, value: string; indent: string): string =
  result = indent & "const " & name & " = " & value & ";"

method generateAssignment*(backend: JavaScriptBackend; target, value: string; indent: string): string =
  result = indent & target & " = " & value & ";"

# ------------------------------------------------------------------------------
# Control Flow Generation
# ------------------------------------------------------------------------------

method generateIfStmt*(backend: JavaScriptBackend; condition: string; indent: string): string =
  result = indent & "if (" & condition & ") {"

method generateElifStmt*(backend: JavaScriptBackend; condition: string; indent: string): string =
  result = indent & "} else if (" & condition & ") {"

method generateElseStmt*(backend: JavaScriptBackend; indent: string): string =
  result = indent & "} else {"

method generateBlockEnd*(backend: JavaScriptBackend; indent: string): string =
  result = indent & "}"

method generateForLoop*(backend: JavaScriptBackend; varName, iterable: string; indent: string): string =
  # Use for...of for iteration
  result = indent & "for (const " & varName & " of " & iterable & ") {"

method generateWhileLoop*(backend: JavaScriptBackend; condition: string; indent: string): string =
  result = indent & "while (" & condition & ") {"

method generateBreak*(backend: JavaScriptBackend; label: string; indent: string): string =
  if label.len > 0:
    result = indent & "break " & label & ";"
  else:
    result = indent & "break;"

method generateContinue*(backend: JavaScriptBackend; label: string; indent: string): string =
  if label.len > 0:
    result = indent & "continue " & label & ";"
  else:
    result = indent & "continue;"

# ------------------------------------------------------------------------------
# Function/Procedure Generation
# ------------------------------------------------------------------------------

method generateProcDecl*(backend: JavaScriptBackend; name: string; params: seq[ProcParam]; indent: string): string =
  var paramStrs: seq[string] = @[]
  for param in params:
    # JavaScript doesn't require type annotations
    # JavaScript passes objects by reference, so var params work naturally
    paramStrs.add(param.name)
  
  let paramList = paramStrs.join(", ")
  result = indent & "function " & name & "(" & paramList & ") {"

method generateReturn*(backend: JavaScriptBackend; value: string; indent: string): string =
  result = indent & "return " & value & ";"

# ------------------------------------------------------------------------------
# Module/Import Generation
# ------------------------------------------------------------------------------

method generateImport*(backend: JavaScriptBackend; module: string): string =
  # ES6 import syntax
  result = "import * as " & module & " from '" & module & "';"

method generateComment*(backend: JavaScriptBackend; text: string; indent: string = ""): string =
  result = indent & "// " & text

# ------------------------------------------------------------------------------
# Type Generation
# ------------------------------------------------------------------------------

method generateEnumType*(backend: JavaScriptBackend; name: string; values: seq[tuple[name: string, value: int]]; indent: string): string =
  ## Generate JavaScript enum using frozen object pattern
  result = indent & "const " & name & " = Object.freeze({"
  if values.len > 0:
    for i, enumVal in values:
      if i > 0:
        result &= ","
      result &= "\n" & indent & "  " & enumVal.name & ": " & $enumVal.value
    result &= "\n" & indent & "});"
  else:
    result &= "});"

# ------------------------------------------------------------------------------
# Program Structure
# ------------------------------------------------------------------------------

method generateProgramHeader*(backend: JavaScriptBackend): string =
  result = "\"use strict\";\n"

method generateProgramFooter*(backend: JavaScriptBackend): string =
  result = ""  # JavaScript doesn't need a footer
