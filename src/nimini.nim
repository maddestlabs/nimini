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

import ../src/nimini/[ast, runtime, tokenizer, plugin, parser, codegen, autopragma]

# Re-export everything
export ast
export tokenizer
export parser
export runtime
export plugin
export codegen
export autopragma