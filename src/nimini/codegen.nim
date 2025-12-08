# Code Generation for Nimini DSL
# Transpiles Nimini AST to multiple target languages using pluggable backends

import std/[strutils, tables, sets]
import ast
import plugin
import backend
import backends/nim_backend

export backend
export nim_backend

# ------------------------------------------------------------------------------
# Type Helpers
# ------------------------------------------------------------------------------

proc typeToString*(t: TypeNode): string =
  ## Convert a type node to its string representation
  if t.isNil:
    return ""
  
  case t.kind
  of tkSimple:
    return t.typeName
  of tkPointer:
    return "ptr " & typeToString(t.ptrType)
  of tkGeneric:
    result = t.genericName & "["
    for i, param in t.genericParams:
      if i > 0: result.add(", ")
      result.add(typeToString(param))
    result.add("]")
  of tkProc:
    result = "proc("
    for i, param in t.procParams:
      if i > 0: result.add(", ")
      result.add(typeToString(param))
    result.add(")")
    if not t.procReturn.isNil:
      result.add(": " & typeToString(t.procReturn))

# ------------------------------------------------------------------------------
# Codegen Context
# ------------------------------------------------------------------------------

type
  CodegenContext* = ref object
    ## Context for code generation tracking imports, mappings, etc.
    backend*: CodegenBackend
    indent: int
    imports: HashSet[string]
    functionMappings: Table[string, string]  # DSL func name -> target code
    constantMappings: Table[string, string]  # DSL const name -> target value
    tempVarCounter: int
    inProc: bool  # Track if we're inside a proc definition

proc newCodegenContext*(backend: CodegenBackend = nil): CodegenContext =
  ## Create a new codegen context with optional backend
  ## If no backend is provided, defaults to Nim backend
  var backendImpl = backend
  if backendImpl.isNil:
    backendImpl = newNimBackend()
  
  result = CodegenContext(
    backend: backendImpl,
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
  result = spaces(ctx.indent * ctx.backend.indentSize)

proc withIndent(ctx: CodegenContext; code: string): string =
  ## Add indentation to a line of code
  result = ctx.getIndent() & code

# ------------------------------------------------------------------------------
# Expression Code Generation
# ------------------------------------------------------------------------------

proc genExpr*(e: Expr; ctx: CodegenContext): string

proc genExpr*(e: Expr; ctx: CodegenContext): string =
  ## Generate code for an expression using the configured backend
  case e.kind
  of ekInt:
    result = ctx.backend.generateInt(e.intVal)

  of ekFloat:
    result = ctx.backend.generateFloat(e.floatVal)

  of ekString:
    result = ctx.backend.generateString(e.strVal)

  of ekBool:
    result = ctx.backend.generateBool(e.boolVal)

  of ekIdent:
    # Check if this is a mapped constant
    if e.ident in ctx.constantMappings:
      result = ctx.constantMappings[e.ident]
    else:
      result = ctx.backend.generateIdent(e.ident)

  of ekUnaryOp:
    let operand = genExpr(e.unaryExpr, ctx)
    result = ctx.backend.generateUnaryOp(e.unaryOp, operand)

  of ekBinOp:
    let left = genExpr(e.left, ctx)
    let right = genExpr(e.right, ctx)
    result = ctx.backend.generateBinOp(left, e.op, right)

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

    result = ctx.backend.generateCall(funcCode, argStrs)

  of ekArray:
    # Generate array literal
    var elemStrs: seq[string] = @[]
    for elem in e.elements:
      elemStrs.add(genExpr(elem, ctx))
    result = ctx.backend.generateArray(elemStrs)

  of ekIndex:
    # Generate array indexing
    let target = genExpr(e.indexTarget, ctx)
    let index = genExpr(e.indexExpr, ctx)
    result = ctx.backend.generateIndex(target, index)

  of ekCast:
    # Generate cast[Type](expr)
    let typeName = typeToString(e.castType)
    let expr = genExpr(e.castExpr, ctx)
    result = "cast[" & typeName & "](" & expr & ")"

  of ekAddr:
    # Generate addr expr
    let expr = genExpr(e.addrExpr, ctx)
    result = "addr " & expr

  of ekDeref:
    # Generate expr[]
    let expr = genExpr(e.derefExpr, ctx)
    result = expr & "[]"

# ------------------------------------------------------------------------------
# Statement Code Generation
# ------------------------------------------------------------------------------

proc genStmt*(s: Stmt; ctx: CodegenContext): string
proc genBlock*(stmts: seq[Stmt]; ctx: CodegenContext): string

proc genStmt*(s: Stmt; ctx: CodegenContext): string =
  ## Generate code for a statement using the configured backend
  case s.kind
  of skExpr:
    result = ctx.withIndent(genExpr(s.expr, ctx))

  of skVar:
    let value = genExpr(s.varValue, ctx)
    let typeStr = if s.varType.isNil: "" else: typeToString(s.varType)
    result = ctx.backend.generateVarDecl(s.varName, value, ctx.getIndent())
    if typeStr.len > 0:
      # Add type annotation if present
      result = ctx.getIndent() & "var " & s.varName & ": " & typeStr & " = " & value

  of skLet:
    let value = genExpr(s.letValue, ctx)
    let typeStr = if s.letType.isNil: "" else: typeToString(s.letType)
    result = ctx.backend.generateLetDecl(s.letName, value, ctx.getIndent())
    if typeStr.len > 0:
      # Add type annotation if present
      result = ctx.getIndent() & "let " & s.letName & ": " & typeStr & " = " & value

  of skConst:
    let value = genExpr(s.constValue, ctx)
    let typeStr = if s.constType.isNil: "" else: ": " & typeToString(s.constType)
    result = ctx.getIndent() & "const " & s.constName & typeStr & " = " & value

  of skAssign:
    let value = genExpr(s.assignValue, ctx)
    let target = genExpr(s.assignTarget, ctx)
    result = ctx.backend.generateAssignment(target, value, ctx.getIndent())

  of skIf:
    var lines: seq[string] = @[]

    # If branch
    let ifCond = genExpr(s.ifBranch.cond, ctx)
    lines.add(ctx.backend.generateIfStmt(ifCond, ctx.getIndent()))
    ctx.indent += 1
    for stmt in s.ifBranch.stmts:
      lines.add(genStmt(stmt, ctx))
    ctx.indent -= 1
    
    # Add block end for brace-based languages
    if not ctx.backend.usesIndentation and (s.elifBranches.len > 0 or s.elseStmts.len > 0):
      discard  # Don't close yet, elif/else will handle it

    # Elif branches
    for elifBranch in s.elifBranches:
      let elifCond = genExpr(elifBranch.cond, ctx)
      lines.add(ctx.backend.generateElifStmt(elifCond, ctx.getIndent()))
      ctx.indent += 1
      for stmt in elifBranch.stmts:
        lines.add(genStmt(stmt, ctx))
      ctx.indent -= 1

    # Else branch
    if s.elseStmts.len > 0:
      lines.add(ctx.backend.generateElseStmt(ctx.getIndent()))
      ctx.indent += 1
      for stmt in s.elseStmts:
        lines.add(genStmt(stmt, ctx))
      ctx.indent -= 1
    
    # Close final block for brace-based languages
    if not ctx.backend.usesIndentation:
      lines.add(ctx.backend.generateBlockEnd(ctx.getIndent()))

    result = lines.join("\n")

  of skFor:
    var lines: seq[string] = @[]
    let iterableExpr = genExpr(s.forIterable, ctx)

    # Generate for loop
    lines.add(ctx.backend.generateForLoop(s.forVar, iterableExpr, ctx.getIndent()))
    ctx.indent += 1
    for stmt in s.forBody:
      lines.add(genStmt(stmt, ctx))
    ctx.indent -= 1
    
    # Close block for brace-based languages
    if not ctx.backend.usesIndentation:
      lines.add(ctx.backend.generateBlockEnd(ctx.getIndent()))

    result = lines.join("\n")

  of skWhile:
    var lines: seq[string] = @[]
    let condExpr = genExpr(s.whileCond, ctx)

    # Generate while loop
    lines.add(ctx.backend.generateWhileLoop(condExpr, ctx.getIndent()))
    ctx.indent += 1
    for stmt in s.whileBody:
      lines.add(genStmt(stmt, ctx))
    ctx.indent -= 1
    
    # Close block for brace-based languages
    if not ctx.backend.usesIndentation:
      lines.add(ctx.backend.generateBlockEnd(ctx.getIndent()))

    result = lines.join("\n")

  of skProc:
    var lines: seq[string] = @[]

    # Generate procedure declaration
    lines.add(ctx.backend.generateProcDecl(s.procName, s.params, ctx.getIndent()))

    # Generate body
    ctx.indent += 1
    ctx.inProc = true
    for stmt in s.body:
      lines.add(genStmt(stmt, ctx))
    ctx.inProc = false
    ctx.indent -= 1
    
    # Close block for brace-based languages
    if not ctx.backend.usesIndentation:
      lines.add(ctx.backend.generateBlockEnd(ctx.getIndent()))

    result = lines.join("\n")

  of skReturn:
    let value = genExpr(s.returnVal, ctx)
    result = ctx.backend.generateReturn(value, ctx.getIndent())

  of skBlock:
    var lines: seq[string] = @[]
    # Note: Block is a Nim-specific construct, may need special handling per backend
    if ctx.backend.usesIndentation:
      lines.add(ctx.withIndent("block:"))
    else:
      lines.add(ctx.withIndent("{"))
    ctx.indent += 1
    for stmt in s.stmts:
      lines.add(genStmt(stmt, ctx))
    ctx.indent -= 1
    if not ctx.backend.usesIndentation:
      lines.add(ctx.withIndent("}"))
    result = lines.join("\n")

  of skDefer:
    # Generate defer statement
    result = ctx.withIndent("defer:")
    ctx.indent += 1
    result.add("\n" & genStmt(s.deferStmt, ctx))
    ctx.indent -= 1

  of skType:
    # Generate type definition
    let typeStr = typeToString(s.typeValue)
    result = ctx.withIndent("type " & s.typeName & " = " & typeStr)

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
  ## Generate complete program from Nimini AST using configured backend
  var sections: seq[string] = @[]

  # Generate program header if needed
  let header = ctx.backend.generateProgramHeader()
  if header.len > 0:
    sections.add(header)

  # Generate imports
  if ctx.imports.len > 0:
    var importLines: seq[string] = @[]
    for imp in ctx.imports:
      importLines.add(ctx.backend.generateImport(imp))
    sections.add(importLines.join("\n"))
    sections.add("")  # Blank line after imports

  # Generate main code
  sections.add(genBlock(prog.stmts, ctx))

  # Generate program footer if needed
  let footer = ctx.backend.generateProgramFooter()
  if footer.len > 0:
    sections.add(footer)

  result = sections.join("\n")

proc generateCode*(prog: Program; backend: CodegenBackend; ctx: CodegenContext = nil): string =
  ## High-level API: Generate code for any backend
  var genCtx = ctx
  if genCtx.isNil:
    genCtx = newCodegenContext(backend)
  else:
    genCtx.backend = backend

  result = genProgram(prog, genCtx)

proc generateNimCode*(prog: Program; ctx: CodegenContext = nil): string =
  ## High-level API: Generate Nim code from a Nimini program (backward compatible)
  var genCtx = ctx
  if genCtx.isNil:
    genCtx = newCodegenContext(newNimBackend())
  elif genCtx.backend.isNil:
    genCtx.backend = newNimBackend()

  result = genProgram(prog, genCtx)

# ------------------------------------------------------------------------------
# Plugin Integration
# ------------------------------------------------------------------------------

proc applyPluginCodegen*(plugin: Plugin; ctx: CodegenContext) =
  ## Apply plugin codegen metadata to a codegen context
  let backendName = ctx.backend.name
  
  # Try to use backend-specific mappings first
  if backendName in plugin.codegen.backends:
    let mapping = plugin.codegen.backends[backendName]
    
    # Add backend-specific imports
    for imp in mapping.imports:
      ctx.addImport(imp)
    
    # Add backend-specific function mappings
    for dslName, targetCode in mapping.functionMappings:
      ctx.addFunctionMapping(dslName, targetCode)
    
    # Add backend-specific constant mappings
    for dslName, targetValue in mapping.constantMappings:
      ctx.addConstantMapping(dslName, targetValue)
  
  # Fallback to legacy Nim mappings for backward compatibility
  elif backendName == "Nim":
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
