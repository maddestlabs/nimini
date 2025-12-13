# Constants
const screenWidth = 800
const screenHeight = 450
const MaxSamples = 512
const MaxSamplesPerUpdate = 4096

# Global state - nimini supports module-level variables
var frequency = 440.0
var oldFrequency = 1.0
var mousePosition = (x: -100.0, y: -100.0)
var waveLength = 1
var position = (x: 0.0, y: 0.0)

# Main procedure
proc main():
  # Initialize window and audio
  InitWindow(screenWidth, screenHeight, "raylib [audio] - nimini script")
  InitAudioDevice()
  SetAudioStreamBufferSizeDefault(MaxSamplesPerUpdate)
  
  # Create audio stream (44100 Hz, 16-bit, mono)
  var stream = LoadAudioStream(44100, 16, 1)
  PlayAudioStream(stream)
  
  # Create waveform buffer using nimini's stdlib
  var data = newSeq(MaxSamples)
  
  # Initialize waveform data
  for i in 0..<MaxSamples:
    data[i] = 0
  
  SetTargetFPS(30)
  
  # Main game loop
  while not WindowShouldClose():
    # ========================================
    # UPDATE
    # ========================================
    
    # Get mouse input
    mousePosition = GetMousePosition()
    
    # Change frequency based on mouse Y position
    if IsMouseButtonDown(0):
      var fp = mousePosition.y
      frequency = 40.0 + fp
      
      # Set audio pan based on mouse X position
      var pan = mousePosition.x / float(screenWidth)
      SetAudioStreamPan(stream, pan)
    
    # Regenerate waveform when frequency changes
    if frequency != oldFrequency:
      # Calculate wavelength with bounds checking
      waveLength = int(22050.0 / frequency)
      if waveLength > MaxSamples / 2:
        waveLength = MaxSamples / 2
      if waveLength < 1:
        waveLength = 1
      
      # Generate sine wave - using nimini's math stdlib!
      for i in 0..<waveLength * 2:
        var angle = 2.0 * PI * float(i) / float(waveLength)
        data[i] = int(sin(angle) * 32000.0)
      
      # Flatten the rest of the buffer
      for j in waveLength * 2..<MaxSamples:
        data[j] = 0
      
      # Update audio stream with new waveform
      UpdateAudioStreamInt16(stream, data)
      
      oldFrequency = frequency
    
    # ========================================
    # DRAW
    # ========================================
    
    BeginDrawing()
    ClearBackground(RAYWHITE)
    
    # Display current frequency
    var freqText = "sine frequency: " & $int(frequency)
    DrawText(freqText, GetScreenWidth() - 220, 10, 20, RED)
    DrawText("click mouse button to change frequency or pan", 10, 10, 20, DARKGRAY)
    
    # Visualize the waveform
    for i in 0..<screenWidth:
      position.x = float(i)
      var sampleIdx = i * MaxSamples / screenWidth
      var sampleValue = float(data[sampleIdx])
      position.y = 250.0 + 50.0 * sampleValue / 32000.0
      DrawPixelV(position, RED)
    
    EndDrawing()
  
  # Cleanup
  UnloadAudioStream(stream)
  CloseAudioDevice()
  CloseWindow()

# Run the program
main()
