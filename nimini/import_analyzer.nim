## Import Analyzer for Nimini Code
## 
## Analyzes Nimini AST to determine required platform bindings
## Used for generating optimized native Nim code with minimal imports

import ../platform/binding_metadata
import ast
import tables, sets, strutils

proc analyzeFunctionCalls*(ast: AstNode): seq[string] =
  ## Walk AST and collect all function call names
  result = @[]
  var visited = initHashSet[string]()
  
  proc visit(node: AstNode) =
    case node.kind
    of Call:
      if node.funcName notin visited:
        result.add(node.funcName)
        visited.incl(node.funcName)
    
    of Block, IfStmt, WhileStmt, ForStmt:
      # Visit children for control structures
      for child in node.children:
        visit(child)
    
    else:
      discard
    
    # Recursively visit all children
    if node.children.len > 0:
      for child in node.children:
        visit(child)
  
  visit(ast)

proc generateImportList*(functionCalls: seq[string], targetLibrary: string): seq[string] =
  ## Generate list of import statements needed for given functions
  let registry = getRegistry()
  let modules = registry.getRequiredModules(functionCalls)
  
  result = @["import storie"]
  
  var addedModules = initHashSet[string]()
  
  for meta in modules:
    if meta.library == targetLibrary:
      let importPath = case targetLibrary
        of "raylib": "import storie/raylib/" & meta.module
        of "sdl3": "import storie/sdl/" & meta.module
        else: ""
      
      if importPath.len > 0 and importPath notin addedModules:
        result.add(importPath)
        addedModules.incl(importPath)

proc estimateBuildSize*(functionCalls: seq[string], targetLibrary: string): int =
  ## Estimate native binary size based on required modules
  let registry = getRegistry()
  let modules = registry.getRequiredModules(functionCalls)
  
  result = 50_000  # Base overhead
  
  for meta in modules:
    if meta.library == targetLibrary:
      result += meta.estimatedSize

proc generateNativeCode*(niminiCode: string, targetLibrary: string, backend: NimBackend): string =
  ## Parse Nimini code and generate native Nim with optimized imports
  
  # Parse code (using your existing Nimini parser)
  let ast = parseDsl(niminiCode)  # Your existing parser
  
  # Analyze function calls
  let calls = analyzeFunctionCalls(ast)
  
  # Generate imports
  let imports = generateImportList(calls, targetLibrary)
  
  # Generate native Nim code (using your existing backend)
  let nativeCode = backend.generate(ast)  # Your existing Nim backend
  
  # Combine imports + code
  result = imports.join("\n") & "\n\n"
  result &= "# Generated from Nimini\n"
  result &= "# Target: " & targetLibrary & "\n"
  result &= "# Estimated size: " & formatSize(estimateBuildSize(calls, targetLibrary)) & "\n\n"
  result &= nativeCode

proc printAnalysisReport*(niminiCode: string, targetLibrary: string) =
  ## Print detailed analysis of Nimini code requirements
  let ast = parseDsl(niminiCode)
  let calls = analyzeFunctionCalls(ast)
  let registry = getRegistry()
  let modules = registry.getRequiredModules(calls)
  
  echo "=== Nimini Code Analysis ==="
  echo "Target: ", targetLibrary
  echo ""
  echo "Function calls detected: ", calls.len
  for call in calls:
    echo "  - ", call
  echo ""
  
  echo "Required modules:"
  var totalSize = 0
  for meta in modules:
    if meta.library == targetLibrary:
      echo "  - ", meta.module, " (", formatSize(meta.estimatedSize), ")"
      totalSize += meta.estimatedSize
  
  echo ""
  echo "Estimated build size: ", formatSize(totalSize + 50_000)
  echo ""

# Example usage for web interface:
proc exportToNative*(niminiCode: string, targetLibrary: string): tuple[code: string, size: int] =
  ## Export Nimini code to native Nim with metadata
  ## Returns: (generated Nim code, estimated binary size)
  
  let ast = parseDsl(niminiCode)
  let calls = analyzeFunctionCalls(ast)
  let size = estimateBuildSize(calls, targetLibrary)
  
  # Generate code using Nim backend
  let backend = newNimBackend()  # Your existing backend
  let code = generateNativeCode(niminiCode, targetLibrary, backend)
  
  return (code, size)
