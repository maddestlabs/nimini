# Raylib Plugin for Nimini

import std/[strutils, unicode]
import raylib
import ../../src/nimini/[runtime, plugin]

# ------------------------------------------------------------------------------
# Helper: convert simple colors to Nimini Value (just use name constants for DSL)
# ------------------------------------------------------------------------------

proc valColorName(name: string): Value =
  ## For now, color constants are just strings; plugin functions interpret them.
  valString(name)

# ------------------------------------------------------------------------------
# Nimini native functions wrapping raylib
# ------------------------------------------------------------------------------

proc fnInitWindow(env: ref Env; args: seq[Value]): Value =
  ## InitWindow(width: int, height: int, title: string)
  if args.len < 3:
    echo "InitWindow(width, height, title)"
    return valNil()

  let w = args[0].i
  let h = args[1].i
  let t = args[2].s

  initWindow(w.cint, h.cint, t)
  result = valNil()

proc fnCloseWindow(env: ref Env; args: seq[Value]): Value =
  closeWindow()
  result = valNil()

proc fnSetTargetFPS(env: ref Env; args: seq[Value]): Value =
  if args.len < 1:
    echo "SetTargetFPS(fps)"
    return valNil()

  setTargetFPS(args[0].i.cint)
  result = valNil()

proc fnWindowShouldClose(env: ref Env; args: seq[Value]): Value =
  ## Return true if the window should close
  result = valBool(windowShouldClose())

proc resolveColor(v: Value): Color =
  ## Interpret a Nimini color value; here we assume it's a name like "BLUE".
  case v.kind
  of vkString:
    case v.s.toLower()
    of "red":    RED
    of "green":  GREEN
    of "blue":   BLUE
    of "yellow": YELLOW
    of "black":  BLACK
    of "white":  RAYWHITE
    of "gray", "grey": GRAY
    else: RAYWHITE
  else:
    RAYWHITE

proc fnBeginDrawing(env: ref Env; args: seq[Value]): Value =
  beginDrawing()
  result = valNil()

proc fnEndDrawing(env: ref Env; args: seq[Value]): Value =
  endDrawing()
  result = valNil()

proc fnClearBackground(env: ref Env; args: seq[Value]): Value =
  if args.len < 1:
    echo "ClearBackground(colorName)"
    return valNil()

  let col = resolveColor(args[0])
  clearBackground(col)
  result = valNil()

proc fnDrawText(env: ref Env; args: seq[Value]): Value =
  ## DrawText(text: string, x: int, y: int, fontSize: int, colorName: string)
  if args.len < 5:
    echo "DrawText(text, x, y, fontSize, colorName)"
    return valNil()

  let text     = args[0].s
  let x        = args[1].i
  let y        = args[2].i
  let fontSize = args[3].i
  let col      = resolveColor(args[4])

  drawText(text, x.cint, y.cint, fontSize.cint, col)
  result = valNil()

# ------------------------------------------------------------------------------
# Plugin Factory (same pattern as the working ones)
# ------------------------------------------------------------------------------

proc createRaylibPlugin*(): Plugin =
  let p = newPlugin(
    name        = "raylib",
    author      = "Nimini",
    version     = "1.0.0",
    description = "Raylib window + drawing plugin using real raylib bindings"
  )

  # Core window control
  p.registerFunc("InitWindow",        fnInitWindow)
  p.registerFunc("CloseWindow",       fnCloseWindow)
  p.registerFunc("SetTargetFPS",      fnSetTargetFPS)
  p.registerFunc("WindowShouldClose", fnWindowShouldClose)

  # Drawing
  p.registerFunc("BeginDrawing",     fnBeginDrawing)
  p.registerFunc("EndDrawing",       fnEndDrawing)
  p.registerFunc("ClearBackground",  fnClearBackground)
  p.registerFunc("DrawText",         fnDrawText)

  # Color name constants for DSL side
  p.registerConstant("RED",    valColorName("red"))
  p.registerConstant("GREEN",  valColorName("green"))
  p.registerConstant("BLUE",   valColorName("blue"))
  p.registerConstant("YELLOW", valColorName("yellow"))
  p.registerConstant("BLACK",  valColorName("black"))
  p.registerConstant("WHITE",  valColorName("white"))
  p.registerConstant("GRAY",   valColorName("gray"))

  p

# ------------------------------------------------------------------------------
# Example usage: open a real raylib window via the plugin
# ------------------------------------------------------------------------------

when isMainModule:
  echo "=== Real Raylib Plugin Test ==="

  initRuntime()

  let rp = createRaylibPlugin()
  registerPlugin(rp)
  loadPlugin(rp, runtimeEnv)

  # Call the functions through the plugin API (same as DSL would)
  discard fnInitWindow(runtimeEnv,
    @[valInt(800), valInt(450), valString("Nimini + Raylib")])
  discard fnSetTargetFPS(runtimeEnv, @[valInt(60)])

  # Main loop
  while not windowShouldClose():
    discard fnBeginDrawing(runtimeEnv, @[])
    discard fnClearBackground(runtimeEnv, @[valColorName("blue")])

    discard fnDrawText(runtimeEnv, @[
      valString("Hello from Nimini + Raylib!"),
      valInt(100),
      valInt(100),
      valInt(24),
      valColorName("white")
    ])

    discard fnEndDrawing(runtimeEnv, @[])

  discard fnCloseWindow(runtimeEnv, @[])
  echo "=== Window closed, test complete ==="
