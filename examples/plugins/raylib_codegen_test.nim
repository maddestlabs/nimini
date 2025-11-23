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
var v = vec2(10.0, 20.0)
var c = color(255, 128, 64, 255)
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
  echo "Running in DSL runtime (interpreted):"
  execProgram(program, runtimeEnv)

  echo "v = ", getVar(runtimeEnv, "v")
  echo "c = ", getVar(runtimeEnv, "c")
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

  # ------------------------------------------------------
  # [Optional] Window test (uncomment to see a Raylib window)
  # ------------------------------------------------------
  # echo ""
  # echo "Starting window test..."
  # execProgram(parseDsl(tokenizeDsl("""
  #   InitWindow(800, 450, "Raylib test")
  #   SetTargetFPS(60)
  # """)), runtimeEnv)
  #
  # while true:
  #   if WindowShouldClose():
  #     break
  #   BeginDrawing()
  #   ClearBackground(RED)
  #   DrawText("Hello from Nimini + Raylib!", 100, 100, 24, WHITE)
  #   EndDrawing()
  #
  # execProgram(parseDsl(tokenizeDsl("CloseWindow()")), runtimeEnv)
  # echo "Window test complete."

when isMainModule:
  main()
