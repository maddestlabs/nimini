## Nimini - Lightweight Nim-inspired scripting for interactive applications
##
## This is the main module that exports all public APIs.
##
## Basic usage:
##
##   import nimini
##
##   # Tokenize DSL source
##   let tokens = tokenizeDsl(mySource)
##
##   # Parse into AST
##   let program = parseDsl(tokens)
##
##   # Initialize runtime
##   initRuntime()
##   registerNative("myFunc", myNativeFunc)
##
##   # Execute
##   execProgram(program, runtimeEnv)
##
## Multi-Language Frontend usage (new):
##
##   import nimini
##
##   # Auto-detect and compile from any supported language
##   let program = compileSource(myCode)
##
##   # Or specify frontend explicitly
##   let program = compileSource(myCode, getNimFrontend())

import nimini/[ast, runtime, tokenizer, plugin, parser, codegen, backend, frontend]
import nimini/stdlib/seqops

# backends allow exporting generated code in various languages
import ../src/nimini/backends/[nim_backend]
# Uncomment to enable Python backend support:
# import ../src/nimini/backends/[python_backend]
# Uncomment to enable JavaScript backend support:
# import ../src/nimini/backends/[javascript_backend]

# frontends allow scripting in various languages
import ../src/nimini/frontends/[nim_frontend]
# Uncomment to enable Python frontend support:
# import ../src/nimini/frontends/[py_frontend]
# Uncomment to enable JavaScript frontend support:
# import ../src/nimini/frontends/[js_frontend]

import ../src/nimini/lang/[nim_extensions]

# Re-export everything
export ast
export tokenizer
export parser
export runtime
export plugin
export codegen
export nim_extensions  # Nim-specific language extensions (autopragma features)
export seqops

# Initialize standard library - must be called after initRuntime()
proc initStdlib*() =
  ## Register standard library functions with the runtime
  registerNative("add", niminiAdd)
  registerNative("len", niminiLen)
  registerNative("newSeq", niminiNewSeq)
  registerNative("setLen", niminiSetLen)
  registerNative("delete", niminiDelete)
  registerNative("insert", niminiInsert)

export backend
export nim_backend
# Uncomment to export Python backend:
# export python_backend
# Uncomment to export JavaScript backend:
# export javascript_backend

export frontend
export nim_frontend
# Uncomment to export Python frontend:
# export py_frontend
# Uncomment to export JavaScript frontend:
# export js_frontend