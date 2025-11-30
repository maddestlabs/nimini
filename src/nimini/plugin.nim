# Compile-time Plugin Architecture for Nimini
# Allows extending the DSL with custom native functions, constants, and types

import std/tables
import runtime

export NativeFunc

# ------------------------------------------------------------------------------
# Plugin Core Types
# ------------------------------------------------------------------------------

type
  NodeDef* = object
    ## Defines a custom AST node type that a plugin may introduce
    ## Currently for documentation/planning - full AST extension in future
    name*: string
    description*: string

  BackendMapping* = object
    ## Mappings for a specific backend
    imports*: seq[string]
    functionMappings*: Table[string, string]  # DSL func -> target code
    constantMappings*: Table[string, string]  # DSL const -> target value

  CodegenMapping* = object
    ## Multi-backend codegen metadata for transpiling DSL to various languages
    nimImports*: seq[string]              # Nim modules to import (backward compat)
    functionMappings*: Table[string, string]  # DSL func -> Nim code (backward compat)
    constantMappings*: Table[string, string]  # DSL const -> Nim value (backward compat)
    backends*: Table[string, BackendMapping]  # Backend name -> mappings

  PluginInfo* = object
    ## Plugin metadata
    name*: string
    author*: string
    version*: string
    description*: string

  PluginContext* = ref object
    ## Runtime context provided to plugins during initialization
    env*: ref Env
    metadata*: Table[string, string]

  PluginHooks* = object
    ## Lifecycle hooks for plugins
    onLoad*: proc(ctx: PluginContext): void
    onUnload*: proc(ctx: PluginContext): void

  Plugin* = ref object
    ## A plugin that extends Nimini with native functions and values
    info*: PluginInfo
    functions*: Table[string, NativeFunc]
    constants*: Table[string, Value]
    nodes*: seq[NodeDef]
    hooks*: PluginHooks
    enabled*: bool
    codegen*: CodegenMapping  # Codegen metadata for transpilation

# ------------------------------------------------------------------------------
# Plugin Constructors
# ------------------------------------------------------------------------------

proc newPlugin*(name, author, version, description: string): Plugin =
  ## Create a new plugin
  result = Plugin(
    info: PluginInfo(
      name: name,
      author: author,
      version: version,
      description: description
    ),
    functions: initTable[string, NativeFunc](),
    constants: initTable[string, Value](),
    nodes: @[],
    hooks: PluginHooks(
      onLoad: nil,
      onUnload: nil
    ),
    enabled: true,
    codegen: CodegenMapping(
      nimImports: @[],
      functionMappings: initTable[string, string](),
      constantMappings: initTable[string, string](),
      backends: initTable[string, BackendMapping]()
    )
  )

proc newPluginContext*(env: ref Env): PluginContext =
  ## Create a new plugin context
  result = PluginContext(
    env: env,
    metadata: initTable[string, string]()
  )

# ------------------------------------------------------------------------------
# Plugin Registration API
# ------------------------------------------------------------------------------

proc registerFunc*(plugin: Plugin; name: string; fn: NativeFunc) =
  ## Register a native function with this plugin
  plugin.functions[name] = fn

proc registerConstant*(plugin: Plugin; name: string; value: Value) =
  ## Register a constant value with this plugin
  plugin.constants[name] = value

proc registerConstantInt*(plugin: Plugin; name: string; value: int) =
  ## Register an integer constant
  plugin.registerConstant(name, valInt(value))

proc registerConstantFloat*(plugin: Plugin; name: string; value: float) =
  ## Register a float constant
  plugin.registerConstant(name, valFloat(value))

proc registerConstantString*(plugin: Plugin; name: string; value: string) =
  ## Register a string constant
  plugin.registerConstant(name, valString(value))

proc registerConstantBool*(plugin: Plugin; name: string; value: bool) =
  ## Register a boolean constant
  plugin.registerConstant(name, valBool(value))

proc registerNode*(plugin: Plugin; name, description: string) =
  ## Register a custom node definition (for future AST extensions)
  plugin.nodes.add(NodeDef(name: name, description: description))

proc setOnLoad*(plugin: Plugin; hook: proc(ctx: PluginContext): void) =
  ## Set the onLoad lifecycle hook
  plugin.hooks.onLoad = hook

proc setOnUnload*(plugin: Plugin; hook: proc(ctx: PluginContext): void) =
  ## Set the onUnload lifecycle hook
  plugin.hooks.onUnload = hook

# ------------------------------------------------------------------------------
# Codegen Registration API
# ------------------------------------------------------------------------------

proc addNimImport*(plugin: Plugin; module: string) =
  ## Add a Nim import required for codegen (backward compatible)
  plugin.codegen.nimImports.add(module)
  # Also add to Nim backend mapping
  if "Nim" notin plugin.codegen.backends:
    plugin.codegen.backends["Nim"] = BackendMapping(
      imports: @[],
      functionMappings: initTable[string, string](),
      constantMappings: initTable[string, string]()
    )
  plugin.codegen.backends["Nim"].imports.add(module)

proc mapFunction*(plugin: Plugin; dslName, nimCode: string) =
  ## Map a DSL function to its Nim implementation (backward compatible)
  ## Example: mapFunction("InitWindow", "raylib.InitWindow")
  plugin.codegen.functionMappings[dslName] = nimCode
  # Also add to Nim backend mapping
  if "Nim" notin plugin.codegen.backends:
    plugin.codegen.backends["Nim"] = BackendMapping(
      imports: @[],
      functionMappings: initTable[string, string](),
      constantMappings: initTable[string, string]()
    )
  plugin.codegen.backends["Nim"].functionMappings[dslName] = nimCode

proc mapConstant*(plugin: Plugin; dslName, nimValue: string) =
  ## Map a DSL constant to its Nim value (backward compatible)
  ## Example: mapConstant("RED", "raylib.RED")
  plugin.codegen.constantMappings[dslName] = nimValue
  # Also add to Nim backend mapping
  if "Nim" notin plugin.codegen.backends:
    plugin.codegen.backends["Nim"] = BackendMapping(
      imports: @[],
      functionMappings: initTable[string, string](),
      constantMappings: initTable[string, string]()
    )
  plugin.codegen.backends["Nim"].constantMappings[dslName] = nimValue

# ------------------------------------------------------------------------------
# Multi-Backend Codegen API
# ------------------------------------------------------------------------------

proc addImportForBackend*(plugin: Plugin; backend, module: string) =
  ## Add an import for a specific backend
  ## Example: addImportForBackend("Python", "math")
  if backend notin plugin.codegen.backends:
    plugin.codegen.backends[backend] = BackendMapping(
      imports: @[],
      functionMappings: initTable[string, string](),
      constantMappings: initTable[string, string]()
    )
  plugin.codegen.backends[backend].imports.add(module)

proc mapFunctionForBackend*(plugin: Plugin; backend, dslName, targetCode: string) =
  ## Map a DSL function to a backend-specific implementation
  ## Example: mapFunctionForBackend("Python", "sqrt", "math.sqrt")
  if backend notin plugin.codegen.backends:
    plugin.codegen.backends[backend] = BackendMapping(
      imports: @[],
      functionMappings: initTable[string, string](),
      constantMappings: initTable[string, string]()
    )
  plugin.codegen.backends[backend].functionMappings[dslName] = targetCode

proc mapConstantForBackend*(plugin: Plugin; backend, dslName, targetValue: string) =
  ## Map a DSL constant to a backend-specific value
  ## Example: mapConstantForBackend("Python", "PI", "math.pi")
  if backend notin plugin.codegen.backends:
    plugin.codegen.backends[backend] = BackendMapping(
      imports: @[],
      functionMappings: initTable[string, string](),
      constantMappings: initTable[string, string]()
    )
  plugin.codegen.backends[backend].constantMappings[dslName] = targetValue

# ------------------------------------------------------------------------------
# Plugin Registry
# ------------------------------------------------------------------------------

type
  PluginRegistry* = ref object
    ## Central registry for all loaded plugins
    plugins*: Table[string, Plugin]
    loadOrder*: seq[string]

var globalRegistry*: PluginRegistry

proc newPluginRegistry*(): PluginRegistry =
  ## Create a new plugin registry
  result = PluginRegistry(
    plugins: initTable[string, Plugin](),
    loadOrder: @[]
  )

proc initPluginSystem*() =
  ## Initialize the global plugin system
  globalRegistry = newPluginRegistry()

proc registerPlugin*(registry: PluginRegistry; plugin: Plugin) =
  ## Register a plugin with the registry
  if plugin.info.name in registry.plugins:
    quit "Plugin Error: Plugin '" & plugin.info.name & "' already registered"

  registry.plugins[plugin.info.name] = plugin
  registry.loadOrder.add(plugin.info.name)

proc registerPlugin*(plugin: Plugin) =
  ## Register a plugin with the global registry
  if globalRegistry.isNil:
    initPluginSystem()
  globalRegistry.registerPlugin(plugin)

proc getPlugin*(registry: PluginRegistry; name: string): Plugin =
  ## Get a plugin by name
  if name notin registry.plugins:
    quit "Plugin Error: Plugin '" & name & "' not found"
  return registry.plugins[name]

proc getPlugin*(name: string): Plugin =
  ## Get a plugin from the global registry
  if globalRegistry.isNil:
    quit "Plugin Error: Plugin system not initialized"
  return globalRegistry.getPlugin(name)

proc hasPlugin*(registry: PluginRegistry; name: string): bool =
  ## Check if a plugin is registered
  return name in registry.plugins

proc hasPlugin*(name: string): bool =
  ## Check if a plugin is registered in the global registry
  if globalRegistry.isNil:
    return false
  return globalRegistry.hasPlugin(name)

# ------------------------------------------------------------------------------
# Plugin Loading
# ------------------------------------------------------------------------------

proc loadPlugin*(registry: PluginRegistry; plugin: Plugin; env: ref Env) =
  ## Load a plugin into the runtime environment
  let ctx = newPluginContext(env)

  # Call onLoad hook if present
  if plugin.hooks.onLoad != nil:
    plugin.hooks.onLoad(ctx)

  # Register all functions to the provided environment
  for name, fn in plugin.functions:
    defineVar(env, name, valNativeFunc(fn))

  # Register all constants
  for name, val in plugin.constants:
    defineVar(env, name, val)

  plugin.enabled = true

proc loadPlugin*(plugin: Plugin; env: ref Env) =
  ## Load a plugin using the global registry
  if globalRegistry.isNil:
    initPluginSystem()
  globalRegistry.loadPlugin(plugin, env)

proc unloadPlugin*(registry: PluginRegistry; name: string; env: ref Env) =
  ## Unload a plugin from the runtime
  let plugin = registry.getPlugin(name)

  let ctx = newPluginContext(env)

  # Call onUnload hook if present
  if plugin.hooks.onUnload != nil:
    plugin.hooks.onUnload(ctx)

  # Note: We don't actually remove the functions/constants from the env
  # as that could break existing code. This just marks the plugin as disabled.
  plugin.enabled = false

proc loadAllPlugins*(registry: PluginRegistry; env: ref Env) =
  # Load all registered plugins in registration order
  for name in registry.loadOrder:
    let plugin = registry.plugins[name]
    registry.loadPlugin(plugin, env)

proc loadAllPlugins*(env: ref Env) =
  # Load all plugins from the global registry
  if globalRegistry.isNil:
    return
  globalRegistry.loadAllPlugins(env)

# ------------------------------------------------------------------------------
# Plugin Introspection
# ------------------------------------------------------------------------------

proc listPlugins*(registry: PluginRegistry): seq[string] =
  ## List all registered plugin names
  return registry.loadOrder

proc listPlugins*(): seq[string] =
  ## List all registered plugin names from global registry
  if globalRegistry.isNil:
    return @[]
  return globalRegistry.listPlugins()

proc getPluginInfo*(plugin: Plugin): PluginInfo =
  ## Get plugin metadata
  return plugin.info

proc `$`*(plugin: Plugin): string =
  ## String representation of a plugin
  result = "Plugin(" & plugin.info.name & " v" & plugin.info.version
  result &= " by " & plugin.info.author & ")"
  if not plugin.enabled:
    result &= " [disabled]"

proc `$`*(info: PluginInfo): string =
  ## String representation of plugin info
  result = info.name & " v" & info.version
  result &= " by " & info.author
  if info.description.len > 0:
    result &= "\n  " & info.description

# ------------------------------------------------------------------------------
# Codegen Integration
# ------------------------------------------------------------------------------

# Note: Codegen integration procs are provided by codegen.nim
# The plugin module only provides the codegen metadata storage (CodegenMapping)
# and registration API (addNimImport, mapFunction, mapConstant)
