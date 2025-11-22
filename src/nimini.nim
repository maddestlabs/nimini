## Nimini - A lightweight Nim-inspired DSL for interactive applications
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

import nimini/[ast, tokenizer, parser, runtime, plugin]

# Re-export everything
export ast
export tokenizer
export parser
export runtime
export plugin