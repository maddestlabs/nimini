# Nimini-compatible version of the raylib audio streaming example
# This shows what features nimini currently supports and what might need extension

# Assuming raylib functions are exposed as native functions via {.nimini.} pragma:
# - InitWindow, CloseWindow, InitAudioDevice, CloseAudioDevice
# - LoadAudioStream, SetAudioStreamCallback, PlayAudioStream, etc.
# - BeginDrawing, EndDrawing, ClearBackground, DrawText, DrawPixelV
# - GetMousePosition, IsMouseButtonDown, WindowShouldClose, SetTargetFPS

const
  screenWidth = 800
  screenHeight = 450
  MaxSamples = 512
  MaxSamplesPerUpdate = 4096
  PI = 3.14159265358979323846

# Global state (nimini supports module-level vars)
var frequency = 440.0      # Cycles per second (hz)
var audioFrequency = 440.0 # Audio frequency, for smoothing
var oldFrequency = 1.0     # Previous value
var sineIdx = 0.0          # Index for audio rendering

# ============================================================================
# POTENTIAL EXTENSIONS NEEDED (minor):
# ============================================================================
# 🔧 newSeq[T](size) - Create array of specific size (could be native function)
# 🔧 sin(), cos() math functions (can be exposed as native functions)
# 🔧 Type conversion: float(value), int(value) (partially supported)

# Native function to create an array of a specific size initialized to zeros
# This would be registered in the host application:
# proc newIntArray(size: int): seq[int] = newSeq[int](size)

proc main():
  # Initialize window
  InitWindow(screenWidth, screenHeight, "raylib [audio] example - raw stream")
  
  InitAudioDevice()
  SetAudioStreamBufferSizeDefault(MaxSamplesPerUpdate)
  
  # Init raw audio stream (44100 Hz, 16-bit, mono)
  var stream = LoadAudioStream(44100, 16, 1)
  
  # Set the callback (this would need special handling - see note below)
  SetAudioStreamCallback(stream, AudioInputCallback)
  
  # Create buffers - using native function to create typed arrays
  var data = newIntArray(MaxSamples)
  var writeBuf = newIntArray(MaxSamplesPerUpdate)
  
  PlayAudioStream(stream)
  
  # Mouse position (assuming Vector2 is an object type exposed by raylib)
  var mousePosition = Vector2(x: -100.0, y: -100.0)
  var waveLength = 1
  var position = Vector2(x: 0.0, y: 0.0)
  
  SetTargetFPS(30)
  
  # Main game loop
  while not WindowShouldClose():
    # Update
    mousePosition = GetMousePosition()
    
    if IsMouseButtonDown(0):  # MOUSE_BUTTON_LEFT = 0
      var fp = mousePosition.y
      frequency = 40.0 + fp
      
      var pan = mousePosition.x / screenWidth
      SetAudioStreamPan(stream, pan)
    
    # Rewrite sine wave when frequency changes
    if frequency != oldFrequency:
      waveLength = int(22050.0 / frequency)
      if waveLength > MaxSamples / 2:
        waveLength = MaxSamples / 2
      if waveLength < 1:
        waveLength = 1
      
      # Write sine wave
      for i in 0..<waveLength * 2:
        var angle = 2.0 * PI * float(i) / float(waveLength)
        data[i] = int(sin(angle) * 32000.0)
      
      # Make sure the rest of the line is flat
      for j in waveLength * 2..<MaxSamples:
        data[j] = 0
      
      oldFrequency = frequency
    
    # Draw
    BeginDrawing()
    ClearBackground(RAYWHITE)
    
    var freqText = "sine frequency: " & $int(frequency)
    DrawText(freqText, GetScreenWidth() - 220, 10, 20, RED)
    DrawText("click mouse button to change frequency or pan", 10, 10, 20, DARKGRAY)
    
    # Draw the current buffer state
    for i in 0..<screenWidth:
      position.x = float(i)
      position.y = 250.0 + 50.0 * float(data[i * MaxSamples / screenWidth]) / 32000.0
      DrawPixelV(position, RED)
    
    EndDrawing()
  
  # Cleanup
  UnloadAudioStream(stream)
  CloseAudioDevice()
  CloseWindow()

main()
