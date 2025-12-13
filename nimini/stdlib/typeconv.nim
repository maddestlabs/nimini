## Nimini Standard Library - Type Conversion Functions
## Provides explicit type conversion functions

import ../runtime

proc niminiToInt*(env: ref Env; args: seq[Value]): Value =
  ## int(x) - Convert value to integer
  if args.len < 1:
    quit "int requires 1 argument"
  case args[0].kind
  of vkInt: return args[0]
  of vkFloat: return valInt(int(args[0].f))
  of vkString: return valInt(toInt(args[0]))
  else: return valInt(0)

proc niminiToFloat*(env: ref Env; args: seq[Value]): Value =
  ## float(x) - Convert value to float
  if args.len < 1:
    quit "float requires 1 argument"
  case args[0].kind
  of vkInt: return valFloat(float(args[0].i))
  of vkFloat: return args[0]
  of vkString: return valFloat(toFloat(args[0]))
  else: return valFloat(0.0)

proc niminiToBool*(env: ref Env; args: seq[Value]): Value =
  ## bool(x) - Convert value to boolean
  if args.len < 1:
    quit "bool requires 1 argument"
  case args[0].kind
  of vkBool: return args[0]
  of vkInt: return valBool(args[0].i != 0)
  of vkFloat: return valBool(args[0].f != 0.0)
  of vkString: return valBool(args[0].s.len > 0)
  else: return valBool(toBool(args[0]))

proc niminiToString*(env: ref Env; args: seq[Value]): Value =
  ## str(x) - Convert value to string (same as $ operator)
  if args.len < 1:
    quit "str requires 1 argument"
  return valString($args[0])
