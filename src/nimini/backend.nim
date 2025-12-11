# Abstract Backend Interface for Multi-Language Code Generation
# Defines the contract that all language backends must implement

import ast

type
  CodegenBackend* = ref object of RootObj
    ## Abstract backend for code generation
    name*: string
    fileExtension*: string
    usesIndentation*: bool  # True for Python/Nim, false for C/JS with braces
    indentSize*: int

# ------------------------------------------------------------------------------
# Primitive Value Generation
# ------------------------------------------------------------------------------

method generateInt*(backend: CodegenBackend; value: int): string {.base.} =
  ## Generate code for an integer literal
  quit "generateInt not implemented for backend: " & backend.name

method generateFloat*(backend: CodegenBackend; value: float): string {.base.} =
  ## Generate code for a float literal
  quit "generateFloat not implemented for backend: " & backend.name

method generateString*(backend: CodegenBackend; value: string): string {.base.} =
  ## Generate code for a string literal
  quit "generateString not implemented for backend: " & backend.name

method generateBool*(backend: CodegenBackend; value: bool): string {.base.} =
  ## Generate code for a boolean literal
  quit "generateBool not implemented for backend: " & backend.name

method generateIdent*(backend: CodegenBackend; name: string): string {.base.} =
  ## Generate code for an identifier
  quit "generateIdent not implemented for backend: " & backend.name

# ------------------------------------------------------------------------------
# Expression Generation
# ------------------------------------------------------------------------------

method generateBinOp*(backend: CodegenBackend; left, op, right: string): string {.base.} =
  ## Generate code for a binary operation
  quit "generateBinOp not implemented for backend: " & backend.name

method generateUnaryOp*(backend: CodegenBackend; op, operand: string): string {.base.} =
  ## Generate code for a unary operation
  quit "generateUnaryOp not implemented for backend: " & backend.name

method generateCall*(backend: CodegenBackend; funcName: string; args: seq[string]): string {.base.} =
  ## Generate code for a function call
  quit "generateCall not implemented for backend: " & backend.name

method generateArray*(backend: CodegenBackend; elements: seq[string]): string {.base.} =
  ## Generate code for an array literal
  quit "generateArray not implemented for backend: " & backend.name

method generateIndex*(backend: CodegenBackend; target, index: string): string {.base.} =
  ## Generate code for array indexing
  quit "generateIndex not implemented for backend: " & backend.name

# ------------------------------------------------------------------------------
# Statement Generation
# ------------------------------------------------------------------------------

method generateVarDecl*(backend: CodegenBackend; name, value: string; indent: string): string {.base.} =
  ## Generate code for a mutable variable declaration
  quit "generateVarDecl not implemented for backend: " & backend.name

method generateLetDecl*(backend: CodegenBackend; name, value: string; indent: string): string {.base.} =
  ## Generate code for an immutable variable declaration
  quit "generateLetDecl not implemented for backend: " & backend.name

method generateAssignment*(backend: CodegenBackend; target, value: string; indent: string): string {.base.} =
  ## Generate code for an assignment statement
  quit "generateAssignment not implemented for backend: " & backend.name

# ------------------------------------------------------------------------------
# Control Flow Generation
# ------------------------------------------------------------------------------

method generateIfStmt*(backend: CodegenBackend; condition: string; indent: string): string {.base.} =
  ## Generate code for the start of an if statement
  quit "generateIfStmt not implemented for backend: " & backend.name

method generateElifStmt*(backend: CodegenBackend; condition: string; indent: string): string {.base.} =
  ## Generate code for an elif/else-if statement
  quit "generateElifStmt not implemented for backend: " & backend.name

method generateElseStmt*(backend: CodegenBackend; indent: string): string {.base.} =
  ## Generate code for an else statement
  quit "generateElseStmt not implemented for backend: " & backend.name

method generateBlockEnd*(backend: CodegenBackend; indent: string): string {.base.} =
  ## Generate code for the end of a block (e.g., closing brace for C/JS)
  ## Returns empty string for indentation-based languages
  result = ""

method generateForLoop*(backend: CodegenBackend; varName, iterable: string; indent: string): string {.base.} =
  ## Generate code for a for loop
  quit "generateForLoop not implemented for backend: " & backend.name

method generateWhileLoop*(backend: CodegenBackend; condition: string; indent: string): string {.base.} =
  ## Generate code for a while loop
  quit "generateWhileLoop not implemented for backend: " & backend.name

method generateBreak*(backend: CodegenBackend; label: string; indent: string): string {.base.} =
  ## Generate code for a break statement
  quit "generateBreak not implemented for backend: " & backend.name

method generateContinue*(backend: CodegenBackend; label: string; indent: string): string {.base.} =
  ## Generate code for a continue statement
  quit "generateContinue not implemented for backend: " & backend.name

# ------------------------------------------------------------------------------
# Function/Procedure Generation
# ------------------------------------------------------------------------------

method generateProcDecl*(backend: CodegenBackend; name: string; params: seq[ProcParam]; indent: string): string {.base.} =
  ## Generate code for a procedure/function declaration
  quit "generateProcDecl not implemented for backend: " & backend.name

method generateReturn*(backend: CodegenBackend; value: string; indent: string): string {.base.} =
  ## Generate code for a return statement
  quit "generateReturn not implemented for backend: " & backend.name

# ------------------------------------------------------------------------------
# Module/Import Generation
# ------------------------------------------------------------------------------

method generateImport*(backend: CodegenBackend; module: string): string {.base.} =
  ## Generate code for importing a module
  quit "generateImport not implemented for backend: " & backend.name

method generateComment*(backend: CodegenBackend; text: string; indent: string = ""): string {.base.} =
  ## Generate code for a comment
  quit "generateComment not implemented for backend: " & backend.name

# ------------------------------------------------------------------------------
# Type Generation
# ------------------------------------------------------------------------------

method generateEnumType*(backend: CodegenBackend; name: string; values: seq[tuple[name: string, value: int]]; indent: string): string {.base.} =
  ## Generate code for an enum type definition
  quit "generateEnumType not implemented for backend: " & backend.name

# ------------------------------------------------------------------------------
# Program Structure
# ------------------------------------------------------------------------------

method generateProgramHeader*(backend: CodegenBackend): string {.base.} =
  ## Generate any header code needed at the start of a program
  ## (e.g., shebang for Python, strict mode for JS)
  result = ""

method generateProgramFooter*(backend: CodegenBackend): string {.base.} =
  ## Generate any footer code needed at the end of a program
  result = ""
