# Minimal Raylib Plugin for Nimini
# Demonstrates the plugin architecture with basic graphics primitives
# This is a test/example plugin with stub implementations

import nimini

# ------------------------------------------------------------------------------
# Raylib Stub Types & FFI
# ------------------------------------------------------------------------------
# In a real implementation, these would import from raylib bindings
# For testing purposes, we use stub implementations

type
  Color = object
    r, g, b, a: uint8

  Window = ref object
    width, height: int
    title: string
    shouldClose: bool
    isOpen: bool

var currentWindow: Window = nil
var drawingMode: bool = false

# Color constants
const
  RED = Color(r: 230, g: 41, b: 55, a: 255)
  GREEN = Color(r: 0, g: 228, b: 48, a: 255)
  BLUE = Color(r: 0, g: 121, b: 241, a: 255)
  YELLOW = Color(r: 253, g: 249, b: 0, a: 255)
  BLACK = Color(r: 0, g: 0, b: 0, a: 255)
  WHITE = Color(r: 255, g: 255, b: 255, a: 255)
  GRAY = Color(r: 130, g: 130, b: 130, a: 255)

proc colorToValue(c: Color): Value =
  ## Convert a Color to a Nimini integer value (packed RGBA)
  let packed = (c.r.int shl 24) or (c.g.int shl 16) or (c.b.int shl 8) or c.a.int
  return valInt(packed)

proc valueToColor(v: Value): Color =
  ## Convert a Nimini value to a Color (unpack RGBA)
  let packed = v.i
  return Color(
    r: uint8((packed shr 24) and 0xFF),
    g: uint8((packed shr 16) and 0xFF),
    b: uint8((packed shr 8) and 0xFF),
    a: uint8(packed and 0xFF)
  )

# ------------------------------------------------------------------------------
# Raylib Native Functions (Stub Implementations)
# ------------------------------------------------------------------------------

proc rlInitWindow(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
  ## InitWindow(width: int, height: int, title: string)
  ## Creates a window (stub implementation)
  if args.len < 3:
    echo "InitWindow requires 3 arguments: width, height, title"
    return valNil()

  let width = args[0].i
  let height = args[1].i
  let title = args[2].s

  if currentWindow != nil:
    echo "Warning: Window already initialized"
    return valNil()

  currentWindow = Window(
    width: width,
    height: height,
    title: title,
    shouldClose: false,
    isOpen: true
  )

  echo "[Raylib] InitWindow(", width, ", ", height, ", \"", title, "\")"
  return valNil()

proc rlCloseWindow(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
  ## CloseWindow()
  ## Closes the window (stub implementation)
  if currentWindow == nil:
    echo "Warning: No window to close"
    return valNil()

  echo "[Raylib] CloseWindow()"
  currentWindow.isOpen = false
  currentWindow = nil
  return valNil()

proc rlWindowShouldClose(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
  ## WindowShouldClose() -> bool
  ## Returns true if window should close (stub implementation)
  if currentWindow == nil:
    return valBool(true)

  # In stub mode, close after a simulated condition
  # In real implementation, this would check for ESC key or window close event
  return valBool(currentWindow.shouldClose)

proc rlBeginDrawing(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
  ## BeginDrawing()
  ## Begins drawing mode (stub implementation)
  if currentWindow == nil:
    echo "Error: No window initialized"
    return valNil()

  if drawingMode:
    echo "Warning: Already in drawing mode"
    return valNil()

  drawingMode = true
  echo "[Raylib] BeginDrawing()"
  return valNil()

proc rlEndDrawing(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
  ## EndDrawing()
  ## Ends drawing mode (stub implementation)
  if not drawingMode:
    echo "Warning: Not in drawing mode"
    return valNil()

  drawingMode = false
  echo "[Raylib] EndDrawing()"

  # Simulate frame advancement - close after 3 frames in stub mode
  if currentWindow != nil:
    if currentWindow.isOpen:
      # In a real game loop, this would be controlled by user input
      # For testing, we'll just track frames
      discard

  return valNil()

proc rlClearBackground(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
  ## ClearBackground(color: int)
  ## Clears the background with a color (stub implementation)
  if args.len < 1:
    echo "ClearBackground requires 1 argument: color"
    return valNil()

  if not drawingMode:
    echo "Error: ClearBackground must be called between BeginDrawing/EndDrawing"
    return valNil()

  let color = valueToColor(args[0])
  echo "[Raylib] ClearBackground(Color(", color.r, ", ", color.g, ", ", color.b, ", ", color.a, "))"
  return valNil()

proc rlDrawText(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
  ## DrawText(text: string, x: int, y: int, fontSize: int, color: int)
  ## Draws text at position (stub implementation)
  if args.len < 5:
    echo "DrawText requires 5 arguments: text, x, y, fontSize, color"
    return valNil()

  if not drawingMode:
    echo "Error: DrawText must be called between BeginDrawing/EndDrawing"
    return valNil()

  let text = args[0].s
  let x = args[1].i
  let y = args[2].i
  let fontSize = args[3].i
  let color = valueToColor(args[4])

  echo "[Raylib] DrawText(\"", text, "\", ", x, ", ", y, ", ", fontSize, ", Color(...))"
  return valNil()

proc rlSetTargetFPS(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
  ## SetTargetFPS(fps: int)
  ## Sets target FPS (stub implementation)
  if args.len < 1:
    echo "SetTargetFPS requires 1 argument: fps"
    return valNil()

  let fps = args[0].i
  echo "[Raylib] SetTargetFPS(", fps, ")"
  return valNil()

# ------------------------------------------------------------------------------
# Plugin Lifecycle Hooks
# ------------------------------------------------------------------------------

proc onLoadHook(ctx: PluginContext): void =
  echo "[RaylibPlugin] Plugin loaded successfully"
  echo "[RaylibPlugin] Available functions: InitWindow, CloseWindow, WindowShouldClose,"
  echo "                BeginDrawing, EndDrawing, ClearBackground, DrawText, SetTargetFPS"
  echo "[RaylibPlugin] Available colors: RED, GREEN, BLUE, YELLOW, BLACK, WHITE, GRAY"

proc onUnloadHook(ctx: PluginContext): void =
  echo "[RaylibPlugin] Plugin unloaded"
  # Clean up any resources
  if currentWindow != nil:
    currentWindow = nil

# ------------------------------------------------------------------------------
# Plugin Factory
# ------------------------------------------------------------------------------

proc createRaylibPlugin*(): Plugin =
  ## Creates and configures the Raylib plugin
  result = newPlugin(
    name: "raylib",
    author: "Maddest Labs",
    version: "0.1.0",
    description: "Minimal raylib bindings for Nimini (stub implementation for testing)"
  )

  # Register core window functions
  result.registerFunc("InitWindow", rlInitWindow)
  result.registerFunc("CloseWindow", rlCloseWindow)
  result.registerFunc("WindowShouldClose", rlWindowShouldClose)
  result.registerFunc("SetTargetFPS", rlSetTargetFPS)

  # Register drawing functions
  result.registerFunc("BeginDrawing", rlBeginDrawing)
  result.registerFunc("EndDrawing", rlEndDrawing)
  result.registerFunc("ClearBackground", rlClearBackground)
  result.registerFunc("DrawText", rlDrawText)

  # Register color constants
  result.registerConstant("RED", colorToValue(RED))
  result.registerConstant("GREEN", colorToValue(GREEN))
  result.registerConstant("BLUE", colorToValue(BLUE))
  result.registerConstant("YELLOW", colorToValue(YELLOW))
  result.registerConstant("BLACK", colorToValue(BLACK))
  result.registerConstant("WHITE", colorToValue(WHITE))
  result.registerConstant("GRAY", colorToValue(GRAY))

  # Register node types for documentation
  result.registerNode("DrawCall", "A graphics drawing operation")

  # Set lifecycle hooks
  result.setOnLoad(onLoadHook)
  result.setOnUnload(onUnloadHook)

  # Configure codegen mappings for transpilation to native Nim
  result.addNimImport("raylib")

  # Map DSL functions to native raylib functions
  result.mapFunction("InitWindow", "raylib.InitWindow")
  result.mapFunction("CloseWindow", "raylib.CloseWindow")
  result.mapFunction("WindowShouldClose", "raylib.WindowShouldClose")
  result.mapFunction("SetTargetFPS", "raylib.SetTargetFPS")
  result.mapFunction("BeginDrawing", "raylib.BeginDrawing")
  result.mapFunction("EndDrawing", "raylib.EndDrawing")
  result.mapFunction("ClearBackground", "raylib.ClearBackground")
  result.mapFunction("DrawText", "raylib.DrawText")

  # Map DSL color constants to raylib colors
  result.mapConstant("RED", "raylib.RED")
  result.mapConstant("GREEN", "raylib.GREEN")
  result.mapConstant("BLUE", "raylib.BLUE")
  result.mapConstant("YELLOW", "raylib.YELLOW")
  result.mapConstant("BLACK", "raylib.BLACK")
  result.mapConstant("WHITE", "raylib.WHITE")
  result.mapConstant("GRAY", "raylib.GRAY")

  echo "[RaylibPlugin] Plugin created: ", result.info.name, " v", result.info.version

# ------------------------------------------------------------------------------
# Example Usage
# ------------------------------------------------------------------------------

when isMainModule:
  echo "=== Raylib Plugin Test ==="
  echo ""

  # Initialize Nimini runtime
  initRuntime()

  # Create and register the plugin
  let plugin = createRaylibPlugin()
  registerPlugin(plugin)

  # Load the plugin into the runtime
  loadPlugin(plugin, runtimeEnv)

  echo ""
  echo "=== Testing Plugin Functions ==="
  echo ""

  # Test the functions directly
  discard rlInitWindow(runtimeEnv, @[valInt(800), valInt(600), valString("Nimini + Raylib")])
  discard rlSetTargetFPS(runtimeEnv, @[valInt(60)])
  discard rlBeginDrawing(runtimeEnv, @[])
  discard rlClearBackground(runtimeEnv, @[colorToValue(BLUE)])
  discard rlDrawText(runtimeEnv, @[valString("Hello Nimini!"), valInt(100), valInt(100), valInt(20), colorToValue(WHITE)])
  discard rlEndDrawing(runtimeEnv, @[])
  discard rlCloseWindow(runtimeEnv, @[])

  echo ""
  echo "=== Plugin Test Complete ==="
