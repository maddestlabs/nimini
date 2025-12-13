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

import nimini/[ast, runtime, tokenizer, plugin, parser, codegen, codegen_ext, backend, frontend]
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
export plugin
export codegen
export codegen_ext
export nim_extensions  # Nim-specific language extensions (autopragma features)
export seqops

# Import stdlib modules
import nimini/stdlib/[mathops, typeconv]
export mathops, typeconv

# Initialize standard library - must be called after initRuntime()
proc initStdlib*() =
  ## Register standard library functions with the runtime
  
  # Sequence operations
  registerNative("add", niminiAdd)
  registerNative("len", niminiLen)
  registerNative("newSeq", niminiNewSeq)
  registerNative("setLen", niminiSetLen)
  registerNative("delete", niminiDelete)
  registerNative("insert", niminiInsert)
  
  # Type conversion functions
  registerNative("int", niminiToInt)
  registerNative("float", niminiToFloat)
  registerNative("bool", niminiToBool)
  registerNative("str", niminiToString)
  
  # Math functions - trigonometric
  registerNative("sin", niminiSin)
  registerNative("cos", niminiCos)
  registerNative("tan", niminiTan)
  registerNative("arcsin", niminiArcsin)
  registerNative("arccos", niminiArccos)
  registerNative("arctan", niminiArctan)
  registerNative("arctan2", niminiArctan2)
  
  # Math functions - exponential and logarithmic
  registerNative("sqrt", niminiSqrt)
  registerNative("pow", niminiPow)
  registerNative("exp", niminiExp)
  registerNative("ln", niminiLn)
  registerNative("log10", niminiLog10)
  registerNative("log2", niminiLog2)
  
  # Math functions - rounding and absolute value
  registerNative("abs", niminiAbs)
  registerNative("floor", niminiFloor)
  registerNative("ceil", niminiCeil)
  registerNative("round", niminiRound)
  registerNative("trunc", niminiTrunc)
  
  # Math functions - min/max
  registerNative("min", niminiMin)
  registerNative("max", niminiMax)
  
  # Math functions - hyperbolic
  registerNative("sinh", niminiSinh)
  registerNative("cosh", niminiCosh)
  registerNative("tanh", niminiTanh)
  
  # Math functions - conversions
  registerNative("degToRad", niminiDegToRad)
  registerNative("radToDeg", niminiRadToDeg)

export backend
export nim_backend
export python_backend
export javascript_backend

export frontend
export nim_frontend
# Uncomment to export Python frontend:
# export py_frontend
# Uncomment to export JavaScript frontend:
# export js_frontend
