## Auto-registration of Nim procs to Nimini runtime via {.nimini.} pragma
##
## This module provides a convenient way to mark and register Nim procedures
## for use in the Nimini scripting runtime using the {.nimini.} pragma.
##
## Usage:
##   import nimini/autopragma
##
##   proc myFunc(env: ref Env; args: seq[Value]): Value {.nimini.} =
##     # Your implementation
##     return valNil()
##
##   # In your initialization code:
##   initRuntime()
##   registerNimini(myFunc)  # or use the helper macro below

import macros
import runtime

template nimini*() {.pragma.}
  ## Pragma to mark a proc for registration with Nimini runtime.
  ## The proc must have signature: proc(env: ref Env; args: seq[Value]): Value
  ##
  ## After marking procs with this pragma, register them using:
  ##   registerNimini(procName)
  ## or use the exportNiminiProcs macro for automatic registration.

proc registerNimini*(name: string, fn: NativeFunc) {.inline.} =
  ## Register a native function with Nimini runtime.
  ## This is an alias for registerNative that makes intent clearer.
  registerNative(name, fn)

template registerNimini*(fn: NativeFunc) =
  ## Register a native function using its proc name automatically.
  const fnName = astToStr(fn)
  registerNative(fnName, fn)

macro exportNiminiProcs*(procs: varargs[untyped]): untyped =
  ## Automatically register multiple procs marked with {.nimini.}
  ##
  ## Usage:
  ##   exportNiminiProcs(hello, greet, add, multiply, square)
  ##
  ## This will register each proc using its name as the string identifier.
  result = newStmtList()
  
  for prc in procs:
    let procName = $prc
    let nameStr = newLit(procName)
    result.add quote do:
      registerNative(`nameStr`, `prc`)
