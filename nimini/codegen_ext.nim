# Codegen Extension System for Nimini
# Simple registry for cross-language codegen mappings

import std/tables

# ------------------------------------------------------------------------------
# Core Types
# ------------------------------------------------------------------------------

type
  BackendMapping* = object
    ## Mappings for a specific backend
    imports*: seq[string]
    functionMappings*: Table[string, string]  # DSL func -> target code
    constantMappings*: Table[string, string]  # DSL const -> target value

  CodegenExtension* = ref object
    ## Extension that provides codegen mappings for multiple backends
    name*: string
    backends*: Table[string, BackendMapping]  # Backend name -> mappings

  ExtensionRegistry* = ref object
    ## Central registry for all codegen extensions
    extensions*: Table[string, CodegenExtension]
    loadOrder*: seq[string]

# ------------------------------------------------------------------------------
# Global Registry
# ------------------------------------------------------------------------------

var globalExtRegistry*: ExtensionRegistry

proc initExtensionSystem*() =
  ## Initialize the global extension system
  if globalExtRegistry.isNil:
    globalExtRegistry = ExtensionRegistry(
      extensions: initTable[string, CodegenExtension](),
      loadOrder: @[]
    )

# ------------------------------------------------------------------------------
# Constructors
# ------------------------------------------------------------------------------

proc newCodegenExtension*(name: string): CodegenExtension =
  ## Create a new codegen extension
  result = CodegenExtension(
    name: name,
    backends: initTable[string, BackendMapping]()
  )

proc newExtensionRegistry*(): ExtensionRegistry =
  ## Create a new extension registry
  result = ExtensionRegistry(
    extensions: initTable[string, CodegenExtension](),
    loadOrder: @[]
  )

# ------------------------------------------------------------------------------
# Extension Mapping API
# ------------------------------------------------------------------------------

proc addImport*(ext: CodegenExtension; backend, module: string) =
  ## Add an import for a specific backend
  ## Example: addImport("Python", "math")
  if backend notin ext.backends:
    ext.backends[backend] = BackendMapping(
      imports: @[],
      functionMappings: initTable[string, string](),
      constantMappings: initTable[string, string]()
    )
  ext.backends[backend].imports.add(module)

proc mapFunction*(ext: CodegenExtension; backend, dslName, targetCode: string) =
  ## Map a DSL function to a backend-specific implementation
  ## Example: mapFunction("Python", "sqrt", "math.sqrt")
  if backend notin ext.backends:
    ext.backends[backend] = BackendMapping(
      imports: @[],
      functionMappings: initTable[string, string](),
      constantMappings: initTable[string, string]()
    )
  ext.backends[backend].functionMappings[dslName] = targetCode

proc mapConstant*(ext: CodegenExtension; backend, dslName, targetValue: string) =
  ## Map a DSL constant to a backend-specific value
  ## Example: mapConstant("Python", "PI", "math.pi")
  if backend notin ext.backends:
    ext.backends[backend] = BackendMapping(
      imports: @[],
      functionMappings: initTable[string, string](),
      constantMappings: initTable[string, string]()
    )
  ext.backends[backend].constantMappings[dslName] = targetValue

# Convenience procs for Nim backend (most common case)
proc addNimImport*(ext: CodegenExtension; module: string) =
  ## Add a Nim import (convenience for Nim backend)
  ext.addImport("Nim", module)

proc mapNimFunction*(ext: CodegenExtension; dslName, nimCode: string) =
  ## Map a function for Nim backend (convenience)
  ext.mapFunction("Nim", dslName, nimCode)

proc mapNimConstant*(ext: CodegenExtension; dslName, nimValue: string) =
  ## Map a constant for Nim backend (convenience)
  ext.mapConstant("Nim", dslName, nimValue)

# ------------------------------------------------------------------------------
# Registry API
# ------------------------------------------------------------------------------

proc registerExtension*(registry: ExtensionRegistry; ext: CodegenExtension) =
  ## Register an extension with the registry
  if ext.name in registry.extensions:
    quit "Extension Error: Extension '" & ext.name & "' already registered"
  
  registry.extensions[ext.name] = ext
  registry.loadOrder.add(ext.name)

proc registerExtension*(ext: CodegenExtension) =
  ## Register an extension with the global registry
  initExtensionSystem()
  globalExtRegistry.registerExtension(ext)

proc getExtension*(registry: ExtensionRegistry; name: string): CodegenExtension =
  ## Get an extension by name
  if name notin registry.extensions:
    quit "Extension Error: Extension '" & name & "' not found"
  return registry.extensions[name]

proc getExtension*(name: string): CodegenExtension =
  ## Get an extension from the global registry
  initExtensionSystem()
  return globalExtRegistry.getExtension(name)

proc hasExtension*(registry: ExtensionRegistry; name: string): bool =
  ## Check if an extension is registered
  return name in registry.extensions

proc hasExtension*(name: string): bool =
  ## Check if an extension is registered in the global registry
  if globalExtRegistry.isNil:
    return false
  return globalExtRegistry.hasExtension(name)

proc listExtensions*(registry: ExtensionRegistry): seq[string] =
  ## List all registered extension names
  return registry.loadOrder

proc listExtensions*(): seq[string] =
  ## List all registered extension names from global registry
  if globalExtRegistry.isNil:
    return @[]
  return globalExtRegistry.listExtensions()

# ------------------------------------------------------------------------------
# Display
# ------------------------------------------------------------------------------

proc `$`*(ext: CodegenExtension): string =
  ## String representation of an extension
  result = "CodegenExtension(" & ext.name & ")"
  result &= "\n  Backends: " & $ext.backends.len
