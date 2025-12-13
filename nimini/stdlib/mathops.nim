## Nimini Standard Library - Math Operations
## Provides common mathematical functions from std/math

import ../runtime
import std/math

# Helper to convert Value to float for math operations
proc getFloat(v: Value): float {.inline.} =
  case v.kind
  of vkInt: float(v.i)
  of vkFloat: v.f
  else: getFloat(v)

# Trigonometric functions
proc niminiSin*(env: ref Env; args: seq[Value]): Value =
  ## sin(x) - Sine function
  if args.len < 1:
    quit "sin requires 1 argument"
  return valFloat(math.sin(getFloat(args[0])))

proc niminiCos*(env: ref Env; args: seq[Value]): Value =
  ## cos(x) - Cosine function
  if args.len < 1:
    quit "cos requires 1 argument"
  return valFloat(math.cos(getFloat(args[0])))

proc niminiTan*(env: ref Env; args: seq[Value]): Value =
  ## tan(x) - Tangent function
  if args.len < 1:
    quit "tan requires 1 argument"
  return valFloat(math.tan(getFloat(args[0])))

proc niminiArcsin*(env: ref Env; args: seq[Value]): Value =
  ## arcsin(x) - Arcsine function
  if args.len < 1:
    quit "arcsin requires 1 argument"
  return valFloat(math.arcsin(getFloat(args[0])))

proc niminiArccos*(env: ref Env; args: seq[Value]): Value =
  ## arccos(x) - Arccosine function
  if args.len < 1:
    quit "arccos requires 1 argument"
  return valFloat(math.arccos(getFloat(args[0])))

proc niminiArctan*(env: ref Env; args: seq[Value]): Value =
  ## arctan(x) - Arctangent function
  if args.len < 1:
    quit "arctan requires 1 argument"
  return valFloat(math.arctan(getFloat(args[0])))

proc niminiArctan2*(env: ref Env; args: seq[Value]): Value =
  ## arctan2(y, x) - Two-argument arctangent
  if args.len < 2:
    quit "arctan2 requires 2 arguments"
  return valFloat(math.arctan2(getFloat(args[0]), getFloat(args[1])))

# Exponential and logarithmic functions
proc niminiSqrt*(env: ref Env; args: seq[Value]): Value =
  ## sqrt(x) - Square root
  if args.len < 1:
    quit "sqrt requires 1 argument"
  return valFloat(math.sqrt(getFloat(args[0])))

proc niminiPow*(env: ref Env; args: seq[Value]): Value =
  ## pow(x, y) - x raised to the power of y
  if args.len < 2:
    quit "pow requires 2 arguments"
  return valFloat(math.pow(getFloat(args[0]), getFloat(args[1])))

proc niminiExp*(env: ref Env; args: seq[Value]): Value =
  ## exp(x) - e raised to the power of x
  if args.len < 1:
    quit "exp requires 1 argument"
  return valFloat(math.exp(getFloat(args[0])))

proc niminiLn*(env: ref Env; args: seq[Value]): Value =
  ## ln(x) - Natural logarithm
  if args.len < 1:
    quit "ln requires 1 argument"
  return valFloat(math.ln(getFloat(args[0])))

proc niminiLog10*(env: ref Env; args: seq[Value]): Value =
  ## log10(x) - Base-10 logarithm
  if args.len < 1:
    quit "log10 requires 1 argument"
  return valFloat(math.log10(getFloat(args[0])))

proc niminiLog2*(env: ref Env; args: seq[Value]): Value =
  ## log2(x) - Base-2 logarithm
  if args.len < 1:
    quit "log2 requires 1 argument"
  return valFloat(math.log2(getFloat(args[0])))

# Rounding and absolute value functions
proc niminiAbs*(env: ref Env; args: seq[Value]): Value =
  ## abs(x) - Absolute value
  if args.len < 1:
    quit "abs requires 1 argument"
  
  case args[0].kind
  of vkInt:
    return valInt(abs(args[0].i))
  of vkFloat:
    return valFloat(abs(args[0].f))
  else:
    return valFloat(abs(getFloat(args[0])))

proc niminiFloor*(env: ref Env; args: seq[Value]): Value =
  ## floor(x) - Round down to nearest integer
  if args.len < 1:
    quit "floor requires 1 argument"
  return valFloat(math.floor(getFloat(args[0])))

proc niminiCeil*(env: ref Env; args: seq[Value]): Value =
  ## ceil(x) - Round up to nearest integer
  if args.len < 1:
    quit "ceil requires 1 argument"
  return valFloat(math.ceil(getFloat(args[0])))

proc niminiRound*(env: ref Env; args: seq[Value]): Value =
  ## round(x) - Round to nearest integer
  if args.len < 1:
    quit "round requires 1 argument"
  return valFloat(math.round(getFloat(args[0])))

proc niminiTrunc*(env: ref Env; args: seq[Value]): Value =
  ## trunc(x) - Truncate to integer (round toward zero)
  if args.len < 1:
    quit "trunc requires 1 argument"
  return valFloat(math.trunc(getFloat(args[0])))

# Min/Max functions
proc niminiMin*(env: ref Env; args: seq[Value]): Value =
  ## min(a, b) - Return minimum of two values
  if args.len < 2:
    quit "min requires 2 arguments"
  
  let a = getFloat(args[0])
  let b = getFloat(args[1])
  return valFloat(min(a, b))

proc niminiMax*(env: ref Env; args: seq[Value]): Value =
  ## max(a, b) - Return maximum of two values
  if args.len < 2:
    quit "max requires 2 arguments"
  
  let a = getFloat(args[0])
  let b = getFloat(args[1])
  return valFloat(max(a, b))

# Hyperbolic functions
proc niminiSinh*(env: ref Env; args: seq[Value]): Value =
  ## sinh(x) - Hyperbolic sine
  if args.len < 1:
    quit "sinh requires 1 argument"
  return valFloat(math.sinh(getFloat(args[0])))

proc niminiCosh*(env: ref Env; args: seq[Value]): Value =
  ## cosh(x) - Hyperbolic cosine
  if args.len < 1:
    quit "cosh requires 1 argument"
  return valFloat(math.cosh(getFloat(args[0])))

proc niminiTanh*(env: ref Env; args: seq[Value]): Value =
  ## tanh(x) - Hyperbolic tangent
  if args.len < 1:
    quit "tanh requires 1 argument"
  return valFloat(math.tanh(getFloat(args[0])))

# Degree/radian conversion
proc niminiDegToRad*(env: ref Env; args: seq[Value]): Value =
  ## degToRad(degrees) - Convert degrees to radians
  if args.len < 1:
    quit "degToRad requires 1 argument"
  return valFloat(degToRad(getFloat(args[0])))

proc niminiRadToDeg*(env: ref Env; args: seq[Value]): Value =
  ## radToDeg(radians) - Convert radians to degrees
  if args.len < 1:
    quit "radToDeg requires 1 argument"
  return valFloat(radToDeg(getFloat(args[0])))
