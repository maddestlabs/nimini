# Code Generation for Nimini DSL
# Transpiles Nimini AST to multiple target languages using pluggable backends

import std/[strutils, tables, sets]
import ast
import codegen_ext
import backend
import backends/nim_backend

export backend
export nim_backend
export codegen_ext

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
  of tkObject:
    result = "object"
    # Field details handled in statement generation
  of tkEnum:
    result = "enum"
    # Enum values handled in statement generation

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

# Forward declarations for mutually recursive procs
proc genExpr*(e: Expr; ctx: CodegenContext): string
proc genStmt*(s: Stmt; ctx: CodegenContext): string

proc genExpr*(e: Expr; ctx: CodegenContext): string =
  ## Generate code for an expression using the configured backend
  case e.kind
  of ekInt:
    result = ctx.backend.generateInt(e.intVal)
    # Add type suffix if present (only for Nim backend)
    if e.intTypeSuffix.len > 0 and ctx.backend.name == "Nim":
      result = result & "'" & e.intTypeSuffix

  of ekFloat:
    result = ctx.backend.generateFloat(e.floatVal)
    # Add type suffix if present (only for Nim backend)
    if e.floatTypeSuffix.len > 0 and ctx.backend.name == "Nim":
      result = result & "'" & e.floatTypeSuffix

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

    # Check if this is a method call (first arg is the object)
    # Detect common string/collection methods
    if argStrs.len > 0 and funcCode in ["toUpper", "toLower", "strip", "trim", "split", "join", "replace", "contains", "startsWith", "endsWith"]:
      let target = argStrs[0]
      let methodArgs = argStrs[1..^1]
      
      case funcCode
      of "toUpper":
        case ctx.backend.name
        of "Nim":
          result = target & ".toUpper()"
        of "Python":
          result = target & ".upper()"
        of "JavaScript":
          result = target & ".toUpperCase()"
        else:
          result = target & ".toUpper()"
      
      of "toLower":
        case ctx.backend.name
        of "Nim":
          result = target & ".toLower()"
        of "Python":
          result = target & ".lower()"
        of "JavaScript":
          result = target & ".toLowerCase()"
        else:
          result = target & ".toLower()"
      
      of "strip", "trim":
        case ctx.backend.name
        of "Nim":
          result = target & ".strip()"
        of "Python":
          result = target & ".strip()"
        of "JavaScript":
          result = target & ".trim()"
        else:
          result = target & ".strip()"
      
      of "split":
        if methodArgs.len > 0:
          case ctx.backend.name
          of "Nim", "Python", "JavaScript":
            result = target & ".split(" & methodArgs.join(", ") & ")"
          else:
            result = target & ".split(" & methodArgs.join(", ") & ")"
        else:
          result = target & ".split()"
      
      of "join":
        if methodArgs.len > 0:
          case ctx.backend.name
          of "Nim", "Python", "JavaScript":
            result = target & ".join(" & methodArgs.join(", ") & ")"
          else:
            result = target & ".join(" & methodArgs.join(", ") & ")"
        else:
          result = target & ".join()"
      
      of "replace":
        if methodArgs.len >= 2:
          case ctx.backend.name
          of "Nim", "Python", "JavaScript":
            result = target & ".replace(" & methodArgs.join(", ") & ")"
          else:
            result = target & ".replace(" & methodArgs.join(", ") & ")"
        else:
          result = ctx.backend.generateCall(funcCode, argStrs)
      
      of "contains":
        if methodArgs.len > 0:
          case ctx.backend.name
          of "Nim":
            result = target & ".contains(" & methodArgs[0] & ")"
          of "Python":
            result = methodArgs[0] & " in " & target
          of "JavaScript":
            result = target & ".includes(" & methodArgs[0] & ")"
          else:
            result = target & ".contains(" & methodArgs[0] & ")"
        else:
          result = ctx.backend.generateCall(funcCode, argStrs)
      
      of "startsWith":
        if methodArgs.len > 0:
          case ctx.backend.name
          of "Nim":
            result = target & ".startsWith(" & methodArgs[0] & ")"
          of "Python":
            result = target & ".startswith(" & methodArgs[0] & ")"
          of "JavaScript":
            result = target & ".startsWith(" & methodArgs[0] & ")"
          else:
            result = target & ".startsWith(" & methodArgs[0] & ")"
        else:
          result = ctx.backend.generateCall(funcCode, argStrs)
      
      of "endsWith":
        if methodArgs.len > 0:
          case ctx.backend.name
          of "Nim":
            result = target & ".endsWith(" & methodArgs[0] & ")"
          of "Python":
            result = target & ".endswith(" & methodArgs[0] & ")"
          of "JavaScript":
            result = target & ".endsWith(" & methodArgs[0] & ")"
          else:
            result = target & ".endsWith(" & methodArgs[0] & ")"
        else:
          result = ctx.backend.generateCall(funcCode, argStrs)
      
      else:
        result = ctx.backend.generateCall(funcCode, argStrs)
    else:
      result = ctx.backend.generateCall(funcCode, argStrs)

  of ekArray:
    # Generate array literal
    var elemStrs: seq[string] = @[]
    for elem in e.elements:
      elemStrs.add(genExpr(elem, ctx))
    result = ctx.backend.generateArray(elemStrs)

  of ekMap:
    # Generate map literal as Nim table
    result = "{" 
    var pairs: seq[string] = @[]
    for pair in e.mapPairs:
      let key = ctx.backend.generateString(pair.key)
      let value = genExpr(pair.value, ctx)
      pairs.add(key & ": " & value)
    result &= pairs.join(", ")
    result &= "}.toTable"

  of ekIndex:
    # Generate array indexing or slicing
    let target = genExpr(e.indexTarget, ctx)
    
    # Check if this is a slice operation (index is a range operation)
    if e.indexExpr.kind == ekBinOp and (e.indexExpr.op == ".." or e.indexExpr.op == "..<"):
      let startIdx = genExpr(e.indexExpr.left, ctx)
      let endIdx = genExpr(e.indexExpr.right, ctx)
      let isInclusive = e.indexExpr.op == ".."
      
      # Generate backend-specific slice syntax
      case ctx.backend.name
      of "Nim":
        if isInclusive:
          result = target & "[" & startIdx & ".." & endIdx & "]"
        else:
          result = target & "[" & startIdx & "..<" & endIdx & "]"
      of "Python":
        if isInclusive:
          result = target & "[" & startIdx & ":" & endIdx & "+1]"
        else:
          result = target & "[" & startIdx & ":" & endIdx & "]"
      of "JavaScript":
        if isInclusive:
          result = target & ".slice(" & startIdx & ", " & endIdx & "+1)"
        else:
          result = target & ".slice(" & startIdx & ", " & endIdx & ")"
      else:
        # Default fallback
        result = target & "[" & startIdx & ".." & endIdx & "]"
    else:
      # Regular indexing
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

  of ekObjConstr:
    # Generate object construction Type(field: value, ...)
    result = e.objType & "("
    var fieldStrs: seq[string] = @[]
    for field in e.objFields:
      let fieldValue = genExpr(field.value, ctx)
      fieldStrs.add(field.name & ": " & fieldValue)
    result &= fieldStrs.join(", ")
    result &= ")"

  of ekDot:
    # Generate field access obj.field or method calls
    let target = genExpr(e.dotTarget, ctx)
    
    # Check if this is a common string/collection method
    case e.dotField
    of "len":
      # String/array length - map to backend-specific syntax
      case ctx.backend.name
      of "Nim":
        result = target & ".len"
      of "Python":
        result = "len(" & target & ")"
      of "JavaScript":
        result = target & ".length"
      else:
        result = target & ".len"
    
    of "toUpper":
      # Convert to uppercase
      case ctx.backend.name
      of "Nim":
        result = target & ".toUpper()"
      of "Python":
        result = target & ".upper()"
      of "JavaScript":
        result = target & ".toUpperCase()"
      else:
        result = target & ".toUpper()"
    
    of "toLower":
      # Convert to lowercase
      case ctx.backend.name
      of "Nim":
        result = target & ".toLower()"
      of "Python":
        result = target & ".lower()"
      of "JavaScript":
        result = target & ".toLowerCase()"
      else:
        result = target & ".toLower()"
    
    of "strip", "trim":
      # Remove leading/trailing whitespace
      case ctx.backend.name
      of "Nim":
        result = target & ".strip()"
      of "Python":
        result = target & ".strip()"
      of "JavaScript":
        result = target & ".trim()"
      else:
        result = target & ".strip()"
    
    of "split":
      # String split - needs special handling for arguments
      # For now, just generate the method name
      case ctx.backend.name
      of "Nim", "Python", "JavaScript":
        result = target & ".split"
      else:
        result = target & ".split"
    
    of "join":
      # String join
      case ctx.backend.name
      of "Nim", "Python", "JavaScript":
        result = target & ".join"
      else:
        result = target & ".join"
    
    of "replace":
      # String replace
      case ctx.backend.name
      of "Nim", "Python", "JavaScript":
        result = target & ".replace"
      else:
        result = target & ".replace"
    
    of "contains":
      # String/array contains check
      case ctx.backend.name
      of "Nim":
        result = target & ".contains"
      of "Python":
        # In Python, use 'in' operator, but for method call syntax we need a wrapper
        result = target & ".__contains__"
      of "JavaScript":
        result = target & ".includes"
      else:
        result = target & ".contains"
    
    of "startsWith":
      # String starts with
      case ctx.backend.name
      of "Nim":
        result = target & ".startsWith"
      of "Python":
        result = target & ".startswith"
      of "JavaScript":
        result = target & ".startsWith"
      else:
        result = target & ".startsWith"
    
    of "endsWith":
      # String ends with
      case ctx.backend.name
      of "Nim":
        result = target & ".endsWith"
      of "Python":
        result = target & ".endswith"
      of "JavaScript":
        result = target & ".endsWith"
      else:
        result = target & ".endsWith"
    
    else:
      # Regular field access
      result = target & "." & e.dotField

  of ekTuple:
    # Generate tuple literal
    if e.isNamedTuple:
      # Named tuple: (name: "Bob", age: 30)
      result = "("
      var fieldStrs: seq[string] = @[]
      for field in e.tupleFields:
        let fieldValue = genExpr(field.value, ctx)
        fieldStrs.add(field.name & ": " & fieldValue)
      result &= fieldStrs.join(", ")
      result &= ")"
    else:
      # Unnamed tuple: (1, "hello", true)
      result = "("
      var elemStrs: seq[string] = @[]
      for elem in e.tupleElements:
        elemStrs.add(genExpr(elem, ctx))
      result &= elemStrs.join(", ")
      result &= ")"
  
  of ekLambda:
    # Generate lambda/anonymous proc
    case ctx.backend.name
    of "Nim":
      # Nim: proc(params): body
      result = "proc("
      var paramStrs: seq[string] = @[]
      for param in e.lambdaParams:
        if param.isVar:
          paramStrs.add(param.name & ": var " & param.paramType)
        elif param.paramType.len > 0:
          paramStrs.add(param.name & ": " & param.paramType)
        else:
          paramStrs.add(param.name)
      result &= paramStrs.join(", ")
      result &= ") =\n"
      
      # Generate lambda body
      ctx.indent += 1
      for stmt in e.lambdaBody:
        result &= genStmt(stmt, ctx) & "\n"
      ctx.indent -= 1
    
    of "Python":
      # Python: lambda params: body (but lambdas are limited, may need to use def)
      # For multi-line bodies, we'll generate an inline function definition
      if e.lambdaBody.len == 1:
        # Try to use lambda for simple cases
        result = "lambda "
        var paramStrs: seq[string] = @[]
        for param in e.lambdaParams:
          paramStrs.add(param.name)
        result &= paramStrs.join(", ")
        result &= ": "
        result &= genStmt(e.lambdaBody[0], ctx).strip()
      else:
        # Multi-line: need to define a function
        # This is tricky in an expression context - for now, use a simple lambda that calls nothing
        result = "lambda: None  # TODO: multi-statement lambda"
    
    of "JavaScript":
      # JavaScript: (params) => { body }
      result = "("
      var paramStrs: seq[string] = @[]
      for param in e.lambdaParams:
        paramStrs.add(param.name)
      result &= paramStrs.join(", ")
      result &= ") => {\n"
      
      # Generate lambda body
      ctx.indent += 1
      for stmt in e.lambdaBody:
        result &= genStmt(stmt, ctx) & "\n"
      ctx.indent -= 1
      result &= ctx.getIndent() & "}"
    
    else:
      result = "/* lambda not implemented for " & ctx.backend.name & " */"

# ------------------------------------------------------------------------------
# Statement Code Generation
# ------------------------------------------------------------------------------

proc genBlock*(stmts: seq[Stmt]; ctx: CodegenContext): string

# genStmt is already forward declared above with genExpr

proc genStmt*(s: Stmt; ctx: CodegenContext): string =
  ## Generate code for a statement using the configured backend
  case s.kind
  of skExpr:
    result = ctx.withIndent(genExpr(s.expr, ctx))

  of skVar:
    if s.isVarUnpack:
      # Tuple unpacking: var (x, y) = getTuple()
      let value = genExpr(s.varValue, ctx)
      let names = "(" & s.varNames.join(", ") & ")"
      result = ctx.getIndent() & "var " & names & " = " & value
    else:
      let value = genExpr(s.varValue, ctx)
      let typeStr = if s.varType.isNil: "" else: typeToString(s.varType)
      result = ctx.backend.generateVarDecl(s.varName, value, ctx.getIndent())
      if typeStr.len > 0:
        # Add type annotation if present
        result = ctx.getIndent() & "var " & s.varName & ": " & typeStr & " = " & value

  of skLet:
    if s.isLetUnpack:
      # Tuple unpacking: let (x, y) = getTuple()
      let value = genExpr(s.letValue, ctx)
      let names = "(" & s.letNames.join(", ") & ")"
      result = ctx.getIndent() & "let " & names & " = " & value
    else:
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

  of skCase:
    var lines: seq[string] = @[]
    let caseExpr = genExpr(s.caseExpr, ctx)
    
    # Generate case statement header
    lines.add(ctx.withIndent("case " & caseExpr))
    
    # Generate 'of' branches
    for branch in s.ofBranches:
      # Combine multiple values with commas
      var valuesStr = ""
      for i, valueExpr in branch.values:
        if i > 0:
          valuesStr.add(", ")
        valuesStr.add(genExpr(valueExpr, ctx))
      
      lines.add(ctx.withIndent("of " & valuesStr & ":"))
      ctx.indent += 1
      for stmt in branch.stmts:
        lines.add(genStmt(stmt, ctx))
      ctx.indent -= 1
    
    # Generate 'elif' branches (treated as part of case in Nim)
    for elifBranch in s.caseElif:
      let elifCond = genExpr(elifBranch.cond, ctx)
      lines.add(ctx.withIndent("elif " & elifCond & ":"))
      ctx.indent += 1
      for stmt in elifBranch.stmts:
        lines.add(genStmt(stmt, ctx))
      ctx.indent -= 1
    
    # Generate 'else' branch
    if s.caseElse.len > 0:
      lines.add(ctx.withIndent("else:"))
      ctx.indent += 1
      for stmt in s.caseElse:
        lines.add(genStmt(stmt, ctx))
      ctx.indent -= 1
    
    result = lines.join("\n")

  of skFor:
    var lines: seq[string] = @[]
    let iterableExpr = genExpr(s.forIterable, ctx)

    # Handle labeled loops
    if s.forLabel.len > 0:
      lines.add(ctx.getIndent() & "block " & s.forLabel & ":")
      ctx.indent += 1
    
    # Generate for loop with multiple variables if needed
    let forVarList = if s.forVars.len > 1: s.forVars.join(", ") else: s.forVar
    lines.add(ctx.backend.generateForLoop(forVarList, iterableExpr, ctx.getIndent()))
    ctx.indent += 1
    for stmt in s.forBody:
      lines.add(genStmt(stmt, ctx))
    ctx.indent -= 1
    
    # Close block for brace-based languages
    if not ctx.backend.usesIndentation:
      lines.add(ctx.backend.generateBlockEnd(ctx.getIndent()))
    
    # Close labeled block
    if s.forLabel.len > 0:
      ctx.indent -= 1

    result = lines.join("\n")

  of skWhile:
    var lines: seq[string] = @[]
    let condExpr = genExpr(s.whileCond, ctx)

    # Handle labeled loops
    if s.whileLabel.len > 0:
      lines.add(ctx.getIndent() & "block " & s.whileLabel & ":")
      ctx.indent += 1
    
    # Generate while loop
    lines.add(ctx.backend.generateWhileLoop(condExpr, ctx.getIndent()))
    ctx.indent += 1
    for stmt in s.whileBody:
      lines.add(genStmt(stmt, ctx))
    ctx.indent -= 1
    
    # Close block for brace-based languages
    if not ctx.backend.usesIndentation:
      lines.add(ctx.backend.generateBlockEnd(ctx.getIndent()))
    
    # Close labeled block
    if s.whileLabel.len > 0:
      ctx.indent -= 1

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
      if s.blockLabel.len > 0:
        lines.add(ctx.withIndent("block " & s.blockLabel & ":"))
      else:
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
    case s.typeValue.kind
    of tkObject:
      result = ctx.withIndent("type " & s.typeName & " = object")
      if s.typeValue.objectFields.len > 0:
        ctx.indent += 1
        for field in s.typeValue.objectFields:
          let fieldTypeStr = typeToString(field.fieldType)
          result &= "\n" & ctx.withIndent(field.name & ": " & fieldTypeStr)
        ctx.indent -= 1
    
    of tkEnum:
      # Use backend-specific enum generation
      result = ctx.backend.generateEnumType(s.typeName, s.typeValue.enumValues, ctx.getIndent())
      # For Python backend, add Enum import if needed (full statement)
      if ctx.backend.name == "Python" and s.typeValue.enumValues.len > 0:
        ctx.imports.incl("from enum import Enum")
    
    else:
      result = ctx.withIndent("type " & s.typeName & " = ")
      let typeStr = typeToString(s.typeValue)
      result &= typeStr

  of skBreak:
    result = ctx.backend.generateBreak(s.breakLabel, ctx.getIndent())

  of skContinue:
    result = ctx.backend.generateContinue(s.continueLabel, ctx.getIndent())

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

  # Generate main code FIRST (this may add imports)
  let mainCode = genBlock(prog.stmts, ctx)

  # Generate imports (after main code generation, which may have added imports)
  if ctx.imports.len > 0:
    var importLines: seq[string] = @[]
    for imp in ctx.imports:
      # Check if it's a full import statement (starts with "from" or "import")
      if imp.startsWith("from ") or imp.startsWith("import "):
        importLines.add(imp)
      else:
        importLines.add(ctx.backend.generateImport(imp))
    sections.add(importLines.join("\n"))
    sections.add("")  # Blank line after imports

  # Add the main code
  sections.add(mainCode)

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
# Extension Integration
# ------------------------------------------------------------------------------

proc applyExtensionCodegen*(ext: CodegenExtension; ctx: CodegenContext) =
  ## Apply extension codegen metadata to a codegen context
  let backendName = ctx.backend.name
  
  # Use backend-specific mappings
  if backendName in ext.backends:
    let mapping = ext.backends[backendName]
    
    # Add backend-specific imports
    for imp in mapping.imports:
      ctx.addImport(imp)
    
    # Add backend-specific function mappings
    for dslName, targetCode in mapping.functionMappings:
      ctx.addFunctionMapping(dslName, targetCode)
    
    # Add backend-specific constant mappings
    for dslName, targetValue in mapping.constantMappings:
      ctx.addConstantMapping(dslName, targetValue)

proc loadExtensionsCodegen*(ctx: CodegenContext; registry: ExtensionRegistry) =
  ## Load codegen metadata from all extensions in a registry
  for name in registry.loadOrder:
    let ext = registry.extensions[name]
    applyExtensionCodegen(ext, ctx)

proc loadExtensionsCodegen*(ctx: CodegenContext) =
  ## Load codegen metadata from global extension registry
  if codegen_ext.globalExtRegistry.isNil:
    return
  loadExtensionsCodegen(ctx, codegen_ext.globalExtRegistry)
