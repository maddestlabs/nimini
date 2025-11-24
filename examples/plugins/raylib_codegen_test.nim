## Nimini Raylib Codegen Test

import std/[strutils]
import ../../src/nimini/[runtime, tokenizer, plugin, parser, codegen]

# Import the plugin next to this file
import raylib_plugin

# ------------------------------------------------------
# Main test
# ------------------------------------------------------

proc main() =
  echo "=== Nimini Raylib Codegen Test ==="
  echo ""

  # Small DSL program using raylib plugin functions
  # (No window operations here to avoid opening real window in automated test)
  let dslCode = """
  let screenWidth = 800
  let screenHeight = 600
  initWindow(screenWidth, screenHeight, "raylib [shapes] example - basic shapes drawing")
  setTargetFPS(60)
  while not windowShouldClose(): # Detect window close button or ESC key
    beginDrawing()
    clearBackground(RayWhite)
    drawText("some basic shapes available on raylib", 20, 20, 20, DarkGray)
    drawCircle(screenWidth/2, 120, 35, DarkBlue)
    # drawCircleGradient(screenWidth/2, 220, 60, Green, SkyBlue)
    # drawCircleLines(screenWidth, 340, 80, DarkBlue)
    drawRectangle(screenWidth - 60, 100, 120, 60, Red)
    # drawRectangleGradientH(screenWidth - 90, 170, 180, 130, Maroon, Gold)
    # drawRectangleLines(screenWidth * 2 - 40, 320, 80, 60, Orange)
    # drawLine(18, 42, screenWidth - 18, 42, Black)
    endDrawing()
  closeWindow() # Close window and OpenGL context
"""

  echo "DSL Code:"
  echo "---"
  echo dslCode
  echo "---"
  echo ""

  # ------------------------------------------------------
  # Parse the DSL
  # ------------------------------------------------------
  let tokens  = tokenizeDsl(dslCode)
  let program = parseDsl(tokens)

  # ------------------------------------------------------
  # Initialize runtime + plugin
  # ------------------------------------------------------
  initRuntime()

  # Load Raylib Plugin
  let rp = createRaylibPlugin()
  registerPlugin(rp)
  loadPlugin(rp, runtimeEnv)

  # ------------------------------------------------------
  # Execute in DSL runtime
  # ------------------------------------------------------
  # NOTE: Skipping runtime execution to avoid window creation in headless env
  echo "Running in DSL runtime (interpreted):"
  execProgram(program, runtimeEnv)
  echo ""

  # ------------------------------------------------------
  # Codegen transpilation
  # ------------------------------------------------------
  echo "Generated Nim code (transpiled):"
  echo "---"

  let ctx = newCodegenContext()
  loadPluginsCodegen(ctx)     # Important: load plugin's codegen mappings
  let nimCode = generateNimCode(program, ctx)

  echo nimCode
  echo "---"
  echo ""

  echo "You can compile the generated Nim code with:"
  echo "  nim c <file>.nim"

when isMainModule:
  main()
