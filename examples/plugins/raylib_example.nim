# Example: Using the Raylib Plugin from Nimini DSL
# This demonstrates how to load and use a plugin in a Nimini application

import nimini
import raylib_plugin

const dslCode = """
# Simple Raylib program in Nimini DSL
# This creates a window and draws some text

# Initialize window
InitWindow(800, 600, "Hello from Nimini DSL!")
SetTargetFPS(60)

# Main rendering
BeginDrawing()
ClearBackground(BLUE)
DrawText("Hello from Nimini!", 190, 200, 20, WHITE)
EndDrawing()

# Clean up
CloseWindow()
"""

proc main() =
  echo "=== Nimini Raylib Plugin Example ==="
  echo ""
  echo "DSL Code:"
  echo "---"
  echo dslCode
  echo "---"
  echo ""

  # Initialize runtime
  initRuntime()

  # Create and load the Raylib plugin
  let plugin = createRaylibPlugin()
  registerPlugin(plugin)
  loadPlugin(plugin, runtimeEnv)

  echo ""
  echo "=== Executing DSL Code ==="
  echo ""

  # Parse and execute the DSL
  let tokens = tokenizeDsl(dslCode)
  let program = parseDsl(tokens)
  execProgram(program, runtimeEnv)

  echo ""
  echo "=== Execution Complete ==="

when isMainModule:
  main()
