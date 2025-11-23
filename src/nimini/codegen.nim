# Code Generation for Nimini DSL
# Transpiles Nimini AST to native Nim code for compilation

import std/[strutils, tables, sets]
import ast
import plugin

# ------------------------------------------------------------------------------
# Codegen Context
# ------------------------------------------------------------------------------

type
  CodegenContext* = ref object
    ## Context for code generation tracking imports, mappings, etc.
    indent: int
    imports: HashSet[string]
    functionMappings: Table[string, string]  # DSL func name -> Nim code
    constantMappings: Table[string, string]  # DSL const name -> Nim code
    tempVarCounter: int
    inProc: bool  # Track if we're inside a proc definition

proc newCodegenContext*(): CodegenContext =
  ## Create a new codegen context
  result = CodegenContext(
    indent: 0,
    imports: initHashSet[string](),
    functionMappings: initTable[string, string](),
    constantMappings: initTable[string, string](),
    tempVarCounter: 0,
    inProc: false
  )

proc addImport*(ctx: CodegenContext; module: string) =
  ## Add an import to the generated code
  ctx.imports.incl(module)

proc addFunctionMapping*(ctx: CodegenContext; dslName, nimCode: string) =
  ## Map a DSL function name to its Nim implementation
  ctx.functionMappings[dslName] = nimCode

proc addConstantMapping*(ctx: CodegenContext; dslName, nimCode: string) =
  ## Map a DSL constant name to its Nim value
  ctx.constantMappings[dslName] = nimCode

proc hasImport*(ctx: CodegenContext; module: string): bool =
  ## Check if an import has been added
  result = module in ctx.imports

proc hasFunction*(ctx: CodegenContext; dslName: string): bool =
  ## Check if a function mapping exists
  result = dslName in ctx.functionMappings

proc getFunctionMapping*(ctx: CodegenContext; dslName: string): string =
  ## Get the Nim code for a mapped function
  result = ctx.functionMappings[dslName]

proc hasConstant*(ctx: CodegenContext; dslName: string): bool =
  ## Check if a constant mapping exists
  result = dslName in ctx.constantMappings

proc getConstantMapping*(ctx: CodegenContext; dslName: string): string =
  ## Get the Nim value for a mapped constant
  result = ctx.constantMappings[dslName]

proc getIndent(ctx: CodegenContext): string =
  ## Get current indentation string
  result = spaces(ctx.indent * 2)

proc withIndent(ctx: CodegenContext; code: string): string =
  ## Add indentation to a line of code
  result = ctx.getIndent() & code

# ------------------------------------------------------------------------------
# Expression Code Generation
# ------------------------------------------------------------------------------

proc genExpr*(e: Expr; ctx: CodegenContext): string

proc genExpr*(e: Expr; ctx: CodegenContext): string =
  ## Generate Nim code for an expression
  case e.kind
  of ekInt:
    result = $e.intVal

  of ekFloat:
    result = $e.floatVal

  of ekString:
    result = "\"" & e.strVal.replace("\\", "\\\\").replace("\"", "\\\"") & "\""

  of ekBool:
    result = if e.boolVal: "true" else: "false"

  of ekIdent:
    # Check if this is a mapped constant
    if e.ident in ctx.constantMappings:
      result = ctx.constantMappings[e.ident]
    else:
      result = e.ident

  of ekUnaryOp:
    let operand = genExpr(e.unaryExpr, ctx)
    case e.unaryOp
    of "-":
      result = "-(" & operand & ")"
    of "not":
      result = "not (" & operand & ")"
    else:
      result = e.unaryOp & "(" & operand & ")"

  of ekBinOp:
    let left = genExpr(e.left, ctx)
    let right = genExpr(e.right, ctx)

    case e.op
    of "+", "-", "*", "/", "%":
      result = "(" & left & " " & e.op & " " & right & ")"
    of "==", "!=", "<", "<=", ">", ">=":
      result = "(" & left & " " & e.op & " " & right & ")"
    of "and":
      result = "(" & left & " and " & right & ")"
    of "or":
      result = "(" & left & " or " & right & ")"
    else:
      result = "(" & left & " " & e.op & " " & right & ")"

  of ekCall:
    # Check if this function has a custom mapping
    var funcCode: string
    if e.funcName in ctx.functionMappings:
      funcCode = ctx.functionMappings[e.funcName]
    else:
      funcCode = e.funcName

    # Generate arguments
    var argStrs: seq[string] = @[]
    for arg in e.args:
      argStrs.add(genExpr(arg, ctx))

    result = funcCode & "(" & argStrs.join(", ") & ")"

# ------------------------------------------------------------------------------
# Statement Code Generation
# ------------------------------------------------------------------------------

proc genStmt*(s: Stmt; ctx: CodegenContext): string
proc genBlock*(stmts: seq[Stmt]; ctx: CodegenContext): string

proc genStmt*(s: Stmt; ctx: CodegenContext): string =
  ## Generate Nim code for a statement
  case s.kind
  of skExpr:
    result = ctx.withIndent(genExpr(s.expr, ctx))

  of skVar:
    let value = genExpr(s.varValue, ctx)
    result = ctx.withIndent("var " & s.varName & " = " & value)

  of skLet:
    let value = genExpr(s.letValue, ctx)
    result = ctx.withIndent("let " & s.letName & " = " & value)

  of skAssign:
    let value = genExpr(s.assignValue, ctx)
    result = ctx.withIndent(s.target & " = " & value)

  of skIf:
    var lines: seq[string] = @[]

    # If branch
    let ifCond = genExpr(s.ifBranch.cond, ctx)
    lines.add(ctx.withIndent("if " & ifCond & ":"))
    ctx.indent += 1
    for stmt in s.ifBranch.stmts:
      lines.add(genStmt(stmt, ctx))
    ctx.indent -= 1

    # Elif branches
    for elifBranch in s.elifBranches:
      let elifCond = genExpr(elifBranch.cond, ctx)
      lines.add(ctx.withIndent("elif " & elifCond & ":"))
      ctx.indent += 1
      for stmt in elifBranch.stmts:
        lines.add(genStmt(stmt, ctx))
      ctx.indent -= 1

    # Else branch
    if s.elseStmts.len > 0:
      lines.add(ctx.withIndent("else:"))
      ctx.indent += 1
      for stmt in s.elseStmts:
        lines.add(genStmt(stmt, ctx))
      ctx.indent -= 1

    result = lines.join("\n")

  of skFor:
    var lines: seq[string] = @[]
    let startExpr = genExpr(s.forStart, ctx)
    let endExpr = genExpr(s.forEnd, ctx)

    # Nimini uses Python-style range (start ..< end)
    lines.add(ctx.withIndent("for " & s.forVar & " in " & startExpr & " ..< " & endExpr & ":"))
    ctx.indent += 1
    for stmt in s.forBody:
      lines.add(genStmt(stmt, ctx))
    ctx.indent -= 1

    result = lines.join("\n")

  of skProc:
    var lines: seq[string] = @[]

    # Build parameter list
    var paramStrs: seq[string] = @[]
    for (name, typ) in s.params:
      if typ.len > 0:
        paramStrs.add(name & ": " & typ)
      else:
        # No type specified - use auto type in Nim
        paramStrs.add(name)

    let paramList = paramStrs.join("; ")
    lines.add(ctx.withIndent("proc " & s.procName & "(" & paramList & ") ="))

    # Generate body
    ctx.indent += 1
    ctx.inProc = true
    for stmt in s.body:
      lines.add(genStmt(stmt, ctx))
    ctx.inProc = false
    ctx.indent -= 1

    result = lines.join("\n")

  of skReturn:
    let value = genExpr(s.returnVal, ctx)
    result = ctx.withIndent("return " & value)

  of skBlock:
    var lines: seq[string] = @[]
    lines.add(ctx.withIndent("block:"))
    ctx.indent += 1
    for stmt in s.stmts:
      lines.add(genStmt(stmt, ctx))
    ctx.indent -= 1
    result = lines.join("\n")

proc genBlock*(stmts: seq[Stmt]; ctx: CodegenContext): string =
  ## Generate code for a sequence of statements
  var lines: seq[string] = @[]
  for stmt in stmts:
    lines.add(genStmt(stmt, ctx))
  result = lines.join("\n")

# ------------------------------------------------------------------------------
# Program Code Generation
# ------------------------------------------------------------------------------

proc genProgram*(prog: Program; ctx: CodegenContext): string =
  ## Generate complete Nim program from Nimini AST
  var sections: seq[string] = @[]

  # Generate imports
  if ctx.imports.len > 0:
    var importLines: seq[string] = @[]
    for imp in ctx.imports:
      importLines.add("import " & imp)
    sections.add(importLines.join("\n"))
    sections.add("")  # Blank line after imports

  # Generate main code
  sections.add(genBlock(prog.stmts, ctx))

  result = sections.join("\n")

proc generateNimCode*(prog: Program; ctx: CodegenContext = nil): string =
  ## High-level API: Generate Nim code from a Nimini program
  var genCtx = ctx
  if genCtx.isNil:
    genCtx = newCodegenContext()

  result = genProgram(prog, genCtx)

# ------------------------------------------------------------------------------
# Plugin Integration
# ------------------------------------------------------------------------------

proc applyPluginCodegen*(plugin: Plugin; ctx: CodegenContext) =
  ## Apply plugin codegen metadata to a codegen context
  # Add imports
  for imp in plugin.codegen.nimImports:
    ctx.addImport(imp)

  # Add function mappings
  for dslName, nimCode in plugin.codegen.functionMappings:
    ctx.addFunctionMapping(dslName, nimCode)

  # Add constant mappings
  for dslName, nimValue in plugin.codegen.constantMappings:
    ctx.addConstantMapping(dslName, nimValue)

proc loadPluginsCodegen*(ctx: CodegenContext; registry: PluginRegistry) =
  ## Load codegen metadata from all plugins in a registry
  for name in registry.loadOrder:
    let plugin = registry.plugins[name]
    if plugin.enabled:
      applyPluginCodegen(plugin, ctx)

proc loadPluginsCodegen*(ctx: CodegenContext) =
  ## Load codegen metadata from global plugin registry
  if plugin.globalRegistry.isNil:
    return
  loadPluginsCodegen(ctx, plugin.globalRegistry)
