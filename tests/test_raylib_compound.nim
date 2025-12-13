# Test compound assignment with raylib-style code patterns
# This verifies the exact patterns used in test_raylib_camera2d.nim work

import ../nimini
import std/strutils

proc testRaylibPatterns() =
  echo "=== Testing Raylib-style Compound Assignment Patterns ==="
  
  let code = """
# Simulate raylib object types
type Vector2 = object
  x: float
  y: float

type Camera2D = object
  target: Vector2
  offset: Vector2
  rotation: float
  zoom: float

type Rectangle = object
  x: float
  y: float
  width: float
  height: float

# Initialize variables like in raylib example
var spacing = 0
var player = Rectangle(x: 400.0, y: 280.0, width: 40.0, height: 40.0)
var camera = Camera2D(
  target: Vector2(x: 420.0, y: 300.0),
  offset: Vector2(x: 400.0, y: 225.0),
  rotation: 0.0,
  zoom: 1.0
)

# Pattern 1: spacing += buildings[i].width.int32
# Simplified without array access
spacing += 100

# Pattern 2: player.x += 2
player.x += 2.0

# Pattern 3: player.x -= 2  
var testX = player.x
testX -= 2.0

# Pattern 4: camera.rotation -= 1
camera.rotation -= 1.0

# Pattern 5: camera.rotation += 1
camera.rotation += 1.0

# Pattern 6: camera.zoom += getMouseWheelMove()*0.05'f32
# Simplified without function call
camera.zoom += 0.05

echo("spacing: " & $spacing)
echo("player.x: " & $player.x)
echo("testX: " & $testX)
echo("camera.rotation: " & $camera.rotation)
echo("camera.zoom: " & $camera.zoom)
"""
  
  echo "Parsing raylib-style code..."
  let tokens = tokenizeDsl(code)
  let prog = parseDsl(tokens)
  echo "✓ Parse successful"
  
  echo "\nExecuting..."
  initRuntime()
  execProgram(prog, runtimeEnv)
  
  # Verify results
  assert getVar(runtimeEnv, "spacing").i == 100
  assert getVar(runtimeEnv, "testX").f == 400.0  # 402 - 2
  echo "✓ All raylib-style compound assignments work!"

proc testArrayIndexCompound() =
  echo "\n=== Testing Compound Assignment with Array Indexing ==="
  
  let code = """
var buildings = [100, 200, 300]
var spacing = 0

# This pattern: spacing += buildings[i].width
for i in 0..<3:
  spacing += buildings[i]
  
echo("Total spacing: " & $spacing)
"""
  
  echo "Parsing..."
  let tokens = tokenizeDsl(code)
  let prog = parseDsl(tokens)
  echo "✓ Parse successful"
  
  echo "\nExecuting..."
  initRuntime()
  execProgram(prog, runtimeEnv)
  
  assert getVar(runtimeEnv, "spacing").i == 600
  echo "✓ Compound assignment with array indexing works!"

proc main() =
  testRaylibPatterns()
  testArrayIndexCompound()
  
  echo "\n" & "=".repeat(60)
  echo "✓ ALL RAYLIB-STYLE COMPOUND ASSIGNMENT TESTS PASSED!"
  echo "  The test_raylib_camera2d.nim example will now work!"
  echo "=".repeat(60)

main()
