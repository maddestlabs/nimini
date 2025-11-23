import macros
import raylib
import ../../src/nimini/[runtime, plugin]  # adjust the import to your Nimini runtime/plugin

# Helper converters between Value and raylib structs / enums

proc valToVec2(v: Value): Vector2 =
  ## Expect v to be a map or struct-like Value with keys "x","y"
  # (You need to define how Value holds structured data; this is just an example.)
  let xm = v.getByKey("x")
  let ym = v.getByKey("y")
  result = Vector2(xm.f.f32, ym.f.f32)  # depends on how your Value stores floats

proc vec2ToVal(v: Vector2): Value =
  var m = newMapValue()  # or whatever you use in Value to create map-like
  m["x"] = valFloat(float64(v.x))
  m["y"] = valFloat(float64(v.y))
  result = m

proc valToColor(v: Value): Color =
  # assuming v has "r","g","b","a"
  let r = v.getByKey("r").i.uint8
  let g = v.getByKey("g").i.uint8
  let b = v.getByKey("b").i.uint8
  let a = v.getByKey("a").i.uint8
  result = Color(r, g, b, a)

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

  # Helper: convert argument from Value → native
  proc makeArgConv(paramType: NimNode, idx: int): NimNode =
    let ai = newLit(idx)
    let argsSym = ident("args")
    case $paramType
    of "int", "cint":
      quote do:
        let `ident("a" & $(idx))` = `argsSym`[`ai`].i.cint
    of "float32", "float", "cfloat":
      quote do:
        let `ident("a" & $(idx))` = `argsSym`[`ai`].f.f32
    of "string", "cstring":
      quote do:
        let `ident("a" & $(idx))` = `argsSym`[`ai`].s
    of "bool":
      quote do:
        let `ident("a" & $(idx))` = `argsSym`[`ai`].b
    of "Vector2":
      quote do:
        let `ident("a" & $(idx))` = valToVec2(`argsSym`[`ai`])
    of "Vector3":
      quote do:
        let `ident("a" & $(idx))` = valToVec2(`argsSym`[`ai`])  # (you'll want a valToVec3 similar)
    of "Color":
      quote do:
        let `ident("a" & $(idx))` = valToColor(`argsSym`[`ai`])
    of "Rectangle":
      # For Rectangle, assuming Value has "x","y","width","height"
      quote do:
        let rmap = `argsSym`[`ai`]
        let `ident("a" & $(idx))` = Rectangle(
          rmap.getByKey("x").f.f32,
          rmap.getByKey("y").f.f32,
          rmap.getByKey("width").f.f32,
          rmap.getByKey("height").f.f32)
    else:
      # unsupported, skip
      newStmtList()

  # Helper: convert native return → Value
  proc makeReturnConv(paramType: NimNode): NimNode =
    case $paramType
    of "void", "":
      quote do: return valNil()
    of "int", "cint":
      quote do: return valInt(int(`result`))
    of "float32", "cfloat", "float":
      quote do: return valFloat(float64(`result`))
    of "bool":
      quote do: return valBool(`result`)
    of "Vector2":
      quote do: return vec2ToVal(`result`)
    of "Color":
      quote do: return colorToVal(`result`)
    of "Rectangle":
      quote do:
        let r = `result`
        var m = newMapValue()
        m["x"] = valFloat(float64(r.x))
        m["y"] = valFloat(float64(r.y))
        m["width"] = valFloat(float64(r.width))
        m["height"] = valFloat(float64(r.height))
        return m
    else:
      # fallback: nil
      quote do: return valNil()

  # Iterate through raylib module procs
  let rayMod = getType(raylib)
  for node in rayMod.getTypeImpl:
    if node.kind == nnkProcDef:
      let origName = $node.name
      let wrapperName = ident("fn" & origName.capitalizeAscii())
      let params = node.params
      var convs = newStmtList()
      var callArgs: seq[NimNode] = @[]
      var supported = true
      for i in 1 ..< params.len:
        let param = params[i]
        let nm = param[0]
        let typ = param[1]
        let conv = makeArgConv(typ, i-1)
        if conv.kind == nnkEmptyStmtList:
          supported = false
          break
        convs.add(conv)
        callArgs.add(ident("a" & $(i-1)))
      if not supported:
        continue

      # Build call
      let call = newCall(ident(origName), callArgs)

      # Build wrapper
      let body = quote do:
        if args.len < `params.len` - 1:
          echo `origName`, " expects ", `params.len` - 1, " args"
          return valNil()
        `convs`
        let result = `call`
        `makeReturnConv(params[0])`

      let wrapperProc = quote do:
        proc `wrapperName`(env: ref Env; args: seq[Value]): Value =
          `body`

      stmts.add(wrapperProc)
      stmts.add quote do:
        p.registerFunc(`origName`, `wrapperName`)
      stmts.add quote do:
        p.codegen.functionMappings[`origName`] = `origName`

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
      # register mapping for codegen
      p.codegen.functionMappings[e] = e

  # Example of color constants
  # You could read all color consts, but here is a manual list
  let colorConsts = [
    "WHITE", "BLACK", "RED", "GREEN", "BLUE", "YELLOW", "PINK", "ORANGE",
    "PURPLE", "RAYWHITE", "LIGHTGRAY", "GRAY", "DARKGRAY"
  ]
  for c in colorConsts:
    stmts.add quote do:
      # runtime constant: wrap as Value map struct
      p.registerConstant(`c`, colorToVal(`ident(c)`))
    stmts.add quote do:
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
      let vx = args[0].f.f32
      let vy = args[1].f.f32
      return vec2ToVal(Vector2(vx, vy))
    else:
      echo "vec2(x, y)"
      return valNil()
  )
  p.codegen.functionMappings["vec2"] = "Vector2"

  # Similarly for color constructor (if you want):
  p.registerFunc("color", proc (env: ref Env; args: seq[Value]): Value =
    if args.len >= 4:
      let r = args[0].i.uint8
      let g = args[1].i.uint8
      let b = args[2].i.uint8
      let a = args[3].i.uint8
      return colorToVal(Color(r, g, b, a))
    else:
      echo "color(r, g, b, a)"
      return valNil()
  )
  p.codegen.functionMappings["color"] = "Color"

  return p
