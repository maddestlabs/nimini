## Example demonstrating automatic proc registration using {.nimini.} pragma

import ../src/nimini
import ../src/nimini/autopragma

# Define some Nim procs that we want to expose to Nimini scripts
# Simply mark them with {.nimini.} pragma

proc hello(env: ref Env; args: seq[Value]): Value {.nimini.} =
  ## Simple hello function callable from Nimini
  echo "Hello from Nim!"
  return valNil()

proc greet(env: ref Env; args: seq[Value]): Value {.nimini.} =
  ## Greet with a custom name
  if args.len > 0 and args[0].kind == vkString:
    echo "Hello, ", args[0].s, "!"
  else:
    echo "Hello, stranger!"
  return valNil()

proc add(env: ref Env; args: seq[Value]): Value {.nimini.} =
  ## Add two numbers
  if args.len < 2:
    return valInt(0)
  let a = args[0].i
  let b = args[1].i
  return valInt(a + b)

proc multiply(env: ref Env; args: seq[Value]): Value {.nimini.} =
  ## Multiply two numbers
  if args.len < 2:
    return valInt(0)
  let a = args[0].i
  let b = args[1].i
  return valInt(a * b)

proc square(env: ref Env; args: seq[Value]): Value {.nimini.} =
  ## Square a number
  if args.len < 1:
    return valInt(0)
  let x = args[0].i
  return valInt(x * x)

proc print(env: ref Env; args: seq[Value]): Value {.nimini.} =
  ## Print values to stdout
  for i, arg in args:
    if i > 0:
      stdout.write(" ")
    stdout.write($arg)
  stdout.write("\n")
  return valNil()

# Main execution
when isMainModule:
  # Initialize the runtime
  initRuntime()
  
  # Register all procs marked with {.nimini.} - just list them once
  # The macro automatically uses each proc's name as the registration string
  exportNiminiProcs(hello, greet, add, multiply, square, print)
  
  # Now we can use these functions in Nimini scripts!
  let script = """
    # Call the exposed Nim functions
    hello()
    greet("Alice")
    
    let x = add(5, 3)
    let y = multiply(4, 7)
    let z = square(6)
    
    print("5 + 3 =", x)
    print("4 * 7 =", y)
    print("6^2 =", z)
  """
  
  echo "\n=== Running Nimini Script ==="
  let tokens = tokenizeDsl(script)
  let program = parseDsl(tokens)
  execProgram(program, runtimeEnv)
  echo "=== Script Complete ===\n"
