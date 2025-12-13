# Multiline Blocks (const, type, var, let)

Nimini supports multiline `const`, `type`, `var`, and `let` blocks, allowing you to define multiple declarations under a single keyword, just like in standard Nim.

## Multiline Var Blocks

You can define multiple variables in a single `var` block:

```nim
var
  x = 10
  y = 20
  z = 30
```

This is equivalent to:

```nim
var x = 10
var y = 20
var z = 30
```

### With Type Suffixes

```nim
var
  l1 = 15'f32
  m1 = 0.2'f32
  count = 100'i32
```

## Multiline Let Blocks

Similarly, you can define multiple immutable bindings in a single `let` block:

```nim
let
  maxValue = 100
  minValue = 0
  defaultName = "Player"
```

## Multiline Const Blocks

You can define multiple constants in a single `const` block:

```nim
const
  MaxPlayers = 4
  WindowWidth = 800
  WindowHeight = 600
  GameTitle = "My Game"
```

This is equivalent to:

```nim
const MaxPlayers = 4
const WindowWidth = 800
const WindowHeight = 600
const GameTitle = "My Game"
```

### Features

- **Blank lines are allowed** between constant declarations
- **Type annotations are supported**:
  ```nim
  const
    width: int = 800
    height: int = 600
    title = "Window"  # Type inference works too
  ```

## Multiline Type Blocks

Similarly, you can define multiple type aliases in a single `type` block:

```nim
type
  PlayerId = int
  Score = int
  Position = float
  Name = string
```

### Object and Enum Types

Multiline type blocks also work with object and enum type definitions:

```nim
type
  MyInt = int
  
  Point = object
    x: float
    y: float
  
  Color = enum
    Red
    Green
    Blue
```

## Complete Example

```nim
## Game configuration with all multiline blocks

const
  # Window settings
  WindowWidth = 800
  WindowHeight = 600
  WindowTitle = "Space Game"
  
  # Game settings
  MaxEnemies = 50

type
  # Type aliases
  EntityId = int
  Health = int
  Speed = float
  
  # Custom types
  Player = object
    id: EntityId
    health: Health
    x: float
    y: float

var
  # Game state
  currentLevel = 1
  enemyCount = 0
  
  # Player variables
  player: Player

let
  # Constants for this session
  playerSpeed: Speed = 5.0
  bulletSpeed: Speed = 10.0

# Use the declarations
player.id = 1
player.health = 100
player.x = WindowWidth / 2.0
player.y = WindowHeight / 2.0

echo("Game: ", WindowTitle)
echo("Window: ", WindowWidth, "x", WindowHeight)
echo("Player at (", player.x, ", ", player.y, ")")
echo("Player speed: ", playerSpeed)
```

## Implementation Details

- Multiline blocks are detected by a newline immediately after the `var`, `let`, `const`, or `type` keyword
- The parser expects an indented block following the keyword
- Each declaration within the block is parsed as a separate statement
- Blank lines and comments are allowed within the block
- The block ends when the indentation level decreases (dedent)

## Syntax Rules

1. After `var`, `let`, `const`, or `type`, if there's a newline, it's treated as a multiline block
2. The next line must be indented
3. Each declaration follows standard Nim syntax
4. Blank lines within the block are ignored
5. The block ends with a dedent

## Single-line vs Multiline

You can still use single-line declarations:

```nim
var x = 10        # Single-line var
let y = 20        # Single-line let
const MaxValue = 100  # Single-line const
type MyInt = int      # Single-line type
```

The parser automatically detects which form you're using based on whether a newline follows the keyword.
