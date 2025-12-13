## Raylib Audio Example - Nim Host Application
## This demonstrates how to create a Nim application that runs nimini scripts
## with full raylib integration.

import ../nimini
import naylib
import std/os

# ============================================================================
# Raylib Native Function Bindings for Nimini
# ============================================================================

# Window management
proc niminiInitWindow(env: ref Env; args: seq[Value]): Value {.nimini.} =
  let width = args[0].i.int32
  let height = args[1].i.int32
  let title = args[2].s
  initWindow(width, height, title)
  return valNil()

proc niminiCloseWindow(env: ref Env; args: seq[Value]): Value {.nimini.} =
  closeWindow()
  return valNil()

proc niminiWindowShouldClose(env: ref Env; args: seq[Value]): Value {.nimini.} =
  return valBool(windowShouldClose())

proc niminiSetTargetFPS(env: ref Env; args: seq[Value]): Value {.nimini.} =
  setTargetFPS(args[0].i.int32)
  return valNil()

proc niminiGetScreenWidth(env: ref Env; args: seq[Value]): Value {.nimini.} =
  return valInt(getScreenWidth())

proc niminiGetScreenHeight(env: ref Env; args: seq[Value]): Value {.nimini.} =
  return valInt(getScreenHeight())

# Drawing
proc niminiBeginDrawing(env: ref Env; args: seq[Value]): Value {.nimini.} =
  beginDrawing()
  return valNil()

proc niminiEndDrawing(env: ref Env; args: seq[Value]): Value {.nimini.} =
  endDrawing()
  return valNil()

proc niminiClearBackground(env: ref Env; args: seq[Value]): Value {.nimini.} =
  # For simplicity, accept a color constant name as string
  clearBackground(RayWhite)
  return valNil()

proc niminiDrawText(env: ref Env; args: seq[Value]): Value {.nimini.} =
  let text = args[0].s
  let x = args[1].i.int32
  let y = args[2].i.int32
  let fontSize = args[3].i.int32
  # For simplicity, hardcode color based on last arg
  let color = if args.len > 4 and args[4].i == 1: Red else: DarkGray
  drawText(text, x, y, fontSize, color)
  return valNil()

proc niminiDrawPixelV(env: ref Env; args: seq[Value]): Value {.nimini.} =
  # Expect a tuple/object with x and y fields
  let pos = args[0]
  let x = toFloat(pos.map["x"]).float32
  let y = toFloat(pos.map["y"]).float32
  drawPixelV(Vector2(x: x, y: y), Red)
  return valNil()

# Input
proc niminiGetMousePosition(env: ref Env; args: seq[Value]): Value {.nimini.} =
  let pos = getMousePosition()
  var result = valMap()
  result.map["x"] = valFloat(pos.x)
  result.map["y"] = valFloat(pos.y)
  return result

proc niminiIsMouseButtonDown(env: ref Env; args: seq[Value]): Value {.nimini.} =
  let button = args[0].i.MouseButton
  return valBool(isMouseButtonDown(button))

# Audio
proc niminiInitAudioDevice(env: ref Env; args: seq[Value]): Value {.nimini.} =
  initAudioDevice()
  return valNil()

proc niminiCloseAudioDevice(env: ref Env; args: seq[Value]): Value {.nimini.} =
  closeAudioDevice()
  return valNil()

proc niminiSetAudioStreamBufferSizeDefault(env: ref Env; args: seq[Value]): Value {.nimini.} =
  setAudioStreamBufferSizeDefault(args[0].i.int32)
  return valNil()

# Store audio streams in a global table
var audioStreams: seq[AudioStream] = @[]

proc niminiLoadAudioStream(env: ref Env; args: seq[Value]): Value {.nimini.} =
  let sampleRate = args[0].i.uint32
  let sampleSize = args[1].i.uint32
  let channels = args[2].i.uint32
  let stream = loadAudioStream(sampleRate, sampleSize, channels)
  audioStreams.add(stream)
  return valInt(audioStreams.len - 1)  # Return stream ID

proc niminiPlayAudioStream(env: ref Env; args: seq[Value]): Value {.nimini.} =
  let streamId = args[0].i
  if streamId >= 0 and streamId < audioStreams.len:
    playAudioStream(audioStreams[streamId])
  return valNil()

proc niminiSetAudioStreamPan(env: ref Env; args: seq[Value]): Value {.nimini.} =
  let streamId = args[0].i
  let pan = toFloat(args[1]).float32
  if streamId >= 0 and streamId < audioStreams.len:
    setAudioStreamPan(audioStreams[streamId], pan)
  return valNil()

proc niminiUpdateAudioStreamInt16(env: ref Env; args: seq[Value]): Value {.nimini.} =
  let streamId = args[0].i
  let dataArray = args[1]
  
  if streamId >= 0 and streamId < audioStreams.len:
    # Convert nimini array to int16 sequence
    var data = newSeq[int16](dataArray.arr.len)
    for i in 0..<dataArray.arr.len:
      data[i] = toInt(dataArray.arr[i]).int16
    
    # Update the audio stream
    updateAudioStream(audioStreams[streamId], addr data[0], data.len.int32)
  
  return valNil()

proc niminiUnloadAudioStream(env: ref Env; args: seq[Value]): Value {.nimini.} =
  let streamId = args[0].i
  if streamId >= 0 and streamId < audioStreams.len:
    unloadAudioStream(audioStreams[streamId])
  return valNil()

# Color constants as native values
proc registerColorConstants() =
  # Register color constants as integers for simplicity
  defineVar(runtimeEnv, "RAYWHITE", valInt(0))
  defineVar(runtimeEnv, "RED", valInt(1))
  defineVar(runtimeEnv, "DARKGRAY", valInt(2))

# ============================================================================
# Main Program
# ============================================================================

proc main() =
  # Initialize nimini with stdlib
  initRuntime()
  initStdlib()
  
  # Register all raylib functions
  exportNiminiProcs(
    niminiInitWindow, niminiCloseWindow, niminiWindowShouldClose,
    niminiSetTargetFPS, niminiGetScreenWidth, niminiGetScreenHeight,
    niminiBeginDrawing, niminiEndDrawing, niminiClearBackground,
    niminiDrawText, niminiDrawPixelV,
    niminiGetMousePosition, niminiIsMouseButtonDown,
    niminiInitAudioDevice, niminiCloseAudioDevice,
    niminiSetAudioStreamBufferSizeDefault,
    niminiLoadAudioStream, niminiPlayAudioStream,
    niminiSetAudioStreamPan, niminiUpdateAudioStreamInt16,
    niminiUnloadAudioStream
  )
  
  registerColorConstants()
  
  # Load and execute the nimini script
  let scriptPath = if paramCount() > 0: paramStr(1) else: "test_raylib_nimini.nim"
  
  if not fileExists(scriptPath):
    echo "Error: Script file not found: ", scriptPath
    echo "Usage: raylib_audio_host <script.nim>"
    quit(1)
  
  echo "Loading nimini script: ", scriptPath
  let scriptCode = readFile(scriptPath)
  
  # Parse and execute
  let program = parseDsl(tokenizeDsl(scriptCode))
  execProgram(program, runtimeEnv)

when isMainModule:
  main()
