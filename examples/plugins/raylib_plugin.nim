import macros
import raylib
import std/tables
import ../../src/nimini/[runtime, plugin]  # adjust the import to your Nimini runtime/plugin

# Helper converters between Value and raylib structs / enums

proc valToVec2(v: Value): Vector2 =
  ## Expect v to be a map or struct-like Value with keys "x","y"
  # (You need to define how Value holds structured data; this is just an example.)
  let xm = v.getByKey("x")
  let ym = v.getByKey("y")
  result = Vector2(x: float32(xm.f), y: float32(ym.f))

proc vec2ToVal(v: Vector2): Value =
  var m = newMapValue()  # or whatever you use in Value to create map-like
  m["x"] = valFloat(float64(v.x))
  m["y"] = valFloat(float64(v.y))
  result = m

proc valToColor(v: Value): Color =
  # assuming v has "r","g","b","a"
  let r = uint8(v.getByKey("r").i)
  let g = uint8(v.getByKey("g").i)
  let b = uint8(v.getByKey("b").i)
  let a = uint8(v.getByKey("a").i)
  result = Color(r: r, g: g, b: b, a: a)

proc colorToVal(c: Color): Value =
  var m = newMapValue()
  m["r"] = valInt(int(c.r))
  m["g"] = valInt(int(c.g))
  m["b"] = valInt(int(c.b))
  m["a"] = valInt(int(c.a))
  result = m

# Macro to generate binding

macro generateRaylibPlugin*(p: var Plugin) =
  var stmts = newStmtList()

  # add codegen import
  stmts.add quote do:
    p.codegen.nimImports.add("raylib")

  # Manually register commonly used raylib functions
  # You can expand this list as needed for your specific use case

  # --- Window Management ---
  stmts.add quote do:
    p.registerFunc("initWindow", proc (env: ref Env; args: seq[Value]): Value =
      if args.len >= 3:
        initWindow(cint(args[0].i), cint(args[1].i), args[2].s)
      valNil()
    )
    p.codegen.functionMappings["initWindow"] = "initWindow"

  stmts.add quote do:
    p.registerFunc("closeWindow", proc (env: ref Env; args: seq[Value]): Value =
      closeWindow()
      valNil()
    )
    p.codegen.functionMappings["closeWindow"] = "closeWindow"

  stmts.add quote do:
    p.registerFunc("windowShouldClose", proc (env: ref Env; args: seq[Value]): Value =
      valBool(windowShouldClose())
    )
    p.codegen.functionMappings["windowShouldClose"] = "windowShouldClose"

  stmts.add quote do:
    p.registerFunc("setTargetFPS", proc (env: ref Env; args: seq[Value]): Value =
      if args.len >= 1:
        setTargetFPS(cint(args[0].i))
      valNil()
    )
    p.codegen.functionMappings["setTargetFPS"] = "setTargetFPS"

  # --- Drawing ---
  stmts.add quote do:
    p.registerFunc("beginDrawing", proc (env: ref Env; args: seq[Value]): Value =
      beginDrawing()
      valNil()
    )
    p.codegen.functionMappings["beginDrawing"] = "beginDrawing"

  stmts.add quote do:
    p.registerFunc("endDrawing", proc (env: ref Env; args: seq[Value]): Value =
      endDrawing()
      valNil()
    )
    p.codegen.functionMappings["endDrawing"] = "endDrawing"

  stmts.add quote do:
    p.registerFunc("clearBackground", proc (env: ref Env; args: seq[Value]): Value =
      if args.len >= 1:
        clearBackground(valToColor(args[0]))
      valNil()
    )
    p.codegen.functionMappings["clearBackground"] = "clearBackground"

  stmts.add quote do:
    p.registerFunc("drawText", proc (env: ref Env; args: seq[Value]): Value =
      if args.len >= 5:
        drawText(args[0].s, cint(args[1].i), cint(args[2].i), cint(args[3].i), valToColor(args[4]))
      valNil()
    )
    p.codegen.functionMappings["drawText"] = "drawText"

  stmts.add quote do:
    p.registerFunc("drawRectangle", proc (env: ref Env; args: seq[Value]): Value =
      if args.len >= 5:
        drawRectangle(cint(args[0].i), cint(args[1].i), cint(args[2].i), cint(args[3].i), valToColor(args[4]))
      valNil()
    )
    p.codegen.functionMappings["drawRectangle"] = "drawRectangle"

  stmts.add quote do:
    p.registerFunc("drawCircle", proc (env: ref Env; args: seq[Value]): Value =
      if args.len >= 4:
        drawCircle(cint(args[0].i), cint(args[1].i), float32(args[2].f), valToColor(args[3]))
      valNil()
    )
    p.codegen.functionMappings["drawCircle"] = "drawCircle"

  # --- Enums & Constants ---

  # Now, generate constant + enum mappings for codegen and runtime
  # We'll do a small whitelist of enums and constants based on raylib/naylib

  # Example enum: BlendMode, KeyboardKey, MouseButton, etc.
  # (You should expand this list based on raylib + naylib API)
  let enumNames = [
    "BlendMode", "KeyboardKey", "MouseButton", "Gesture", "CameraMode"
  ]

  for e in enumNames:
    stmts.add quote do:
      p.codegen.functionMappings[`e`] = `e`

  # Example of color constants
  # You could read all color consts, but here is a manual list
  let colorConsts = [
    "LightGray", "Gray", "DarkGray", "Yellow", "Gold", "Orange", "Pink",
    "Red", "Maroon", "Green", "Lime", "DarkGreen", "SkyBlue", "Blue",
    "DarkBlue", "Purple", "Violet", "DarkPurple", "Beige", "Brown",
    "DarkBrown", "White", "Black", "Blank", "Magenta", "RayWhite",
  ]
  for c in colorConsts:
    let colorIdent = ident(c)
    stmts.add quote do:
      # runtime constant: wrap as Value map struct
      p.registerConstant(`c`, colorToVal(`colorIdent`))
      p.codegen.constantMappings[`c`] = `c`

  result = stmts

# Plugin factory

proc createRaylibPlugin*(): Plugin =
  var p = newPlugin(
    name        = "raylib",
    author      = "Nimini",
    version     = "1.0.0",
    description = "Naylib (planetis-m) plugin for Nimini"
  )

  generateRaylibPlugin(p)

  # Make sure any helpers needed at runtime are available:
  p.registerFunc("vec2", proc (env: ref Env; args: seq[Value]): Value =
    if args.len >= 2:
      let vx = float32(args[0].f)
      let vy = float32(args[1].f)
      return vec2ToVal(Vector2(x: vx, y: vy))
    else:
      echo "vec2(x, y)"
      return valNil()
  )
  p.codegen.functionMappings["vec2"] = "Vector2"

  # Similarly for color constructor (if you want):
  p.registerFunc("color", proc (env: ref Env; args: seq[Value]): Value =
    if args.len >= 4:
      let r = uint8(args[0].i)
      let g = uint8(args[1].i)
      let b = uint8(args[2].i)
      let a = uint8(args[3].i)
      return colorToVal(Color(r: r, g: g, b: b, a: a))
    else:
      echo "color(r, g, b, a)"
      return valNil()
  )
  p.codegen.functionMappings["color"] = "Color"

  return p
