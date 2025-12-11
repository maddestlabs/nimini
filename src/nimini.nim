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

import nimini/[ast, runtime, tokenizer, parser, codegen, codegen_ext, backend, frontend]
import nimini/stdlib/seqops

# backends allow exporting generated code in various languages
import nimini/backends/[nim_backend, python_backend, javascript_backend]

# frontends allow scripting in various languages
import nimini/frontends/[nim_frontend]
# Uncomment to enable Python frontend support:
# import nimini/frontends/[py_frontend]
# Uncomment to enable JavaScript frontend support:
# import nimini/frontends/[js_frontend]

import nimini/lang/[nim_extensions]

# Re-export everything
export ast
export tokenizer
export parser
export runtime
export codegen
export codegen_ext
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
export python_backend
export javascript_backend

export frontend
export nim_frontend