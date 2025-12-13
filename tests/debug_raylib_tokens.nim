## Debug tokenizer for raylib test

import ../nimini/tokenizer

let code = """# import raylib, std/[lenientops, random]

const
  MaxBuildings = 100

  screenWidth = 800
  screenHeight = 450

proc main =
  initWindow(screenWidth, screenHeight, "Camera 2D")
"""

let tokens = tokenizeDsl(code)

echo "Total tokens: ", tokens.len
for i, tok in tokens:
  if i < 30:  # Show first 30 tokens
    echo "  [", i, "] ", tok.kind, ": '", tok.lexeme, "' (line ", tok.line, ")"
