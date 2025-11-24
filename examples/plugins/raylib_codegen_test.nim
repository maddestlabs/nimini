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
initWindow(800, 450, "Raylib test")
setTargetFPS(60)
while not windowShouldClose():
  beginDrawing()
  clearBackground(White)
  drawText("Congrats! You created your first window!", 190, 200, 20, Black)
  endDrawing()
closeWindow()
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
  # echo "Running in DSL runtime (interpreted):"
  # execProgram(program, runtimeEnv)
  # echo "v = ", getVar(runtimeEnv, "v")
  # echo "c = ", getVar(runtimeEnv, "c")
  # echo ""

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
