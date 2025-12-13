## Test demonstrating raylib-style math usage
## Shows that all required functionality for raylib examples is available

import ../nimini

proc main() =
  echo "=== Raylib-Style Math Test ==="
  echo ""
  
  initRuntime()
  initStdlib()
  
  let code = """
# Simulate raylib audio example math
const MaxSamples = 512
const MaxSamplesPerUpdate = 4096

var frequency = 440.0
var audioFrequency = 440.0
var sineIdx = 0.0

# Create buffer arrays
var data = newSeq(MaxSamples)
var waveLength = 1

# Calculate wavelength
waveLength = int(22050.0 / frequency)
if waveLength > MaxSamples / 2:
  waveLength = int(float(MaxSamples) / 2.0)
if waveLength < 1:
  waveLength = 1

# Write sine wave
for i in 0..<waveLength * 2:
  var angle = 2.0 * PI * float(i) / float(waveLength)
  data[i] = int(sin(angle) * 32000.0)

# Make rest flat
for j in waveLength * 2..<MaxSamples:
  data[j] = 0

echo("Generated sine wave with wavelength: " & $waveLength)
echo("First 10 samples:")
for i in 0..<10:
  echo("  data[" & $i & "] = " & $data[i])

# Test vector math (common in games)
var x = 3.0
var y = 4.0
var length = sqrt(pow(x, 2.0) + pow(y, 2.0))
var normalizedX = x / length
var normalizedY = y / length

echo("")
echo("Vector normalization:")
echo("  Original: (" & $x & ", " & $y & ")")
echo("  Length: " & $length)
echo("  Normalized: (" & $normalizedX & ", " & $normalizedY & ")")

# Test angle calculations (rotation)
var angle = 45.0
var radians = degToRad(angle)
var pointX = 10.0
var pointY = 0.0

var rotatedX = pointX * cos(radians) - pointY * sin(radians)
var rotatedY = pointX * sin(radians) + pointY * cos(radians)

echo("")
echo("Point rotation by " & $angle & " degrees:")
echo("  Original: (" & $pointX & ", " & $pointY & ")")
echo("  Rotated: (" & $rotatedX & ", " & $rotatedY & ")")

# Test clamping with min/max
var value = 150.0
var minVal = 0.0
var maxVal = 100.0
var clamped = min(max(value, minVal), maxVal)

echo("")
echo("Clamping:")
echo("  Value: " & $value)
echo("  Range: [" & $minVal & ", " & $maxVal & "]")
echo("  Clamped: " & $clamped)
"""

  let program = parseDsl(tokenizeDsl(code))
  execProgram(program, runtimeEnv)
  
  echo ""
  echo "✓ All raylib-style math operations working!"

when isMainModule:
  main()
