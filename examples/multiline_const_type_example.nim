## Example: Multiline const and type definitions

const
  # Window configuration
  WindowWidth = 800
  WindowHeight = 600
  WindowTitle = "My Game"
  
  # Game settings
  MaxPlayers = 4
  DefaultSpeed = 10.0
  
type
  # Type aliases
  PlayerId = int
  Score = int
  Position = float

# Using the constants and types
var player1: PlayerId = 1
var score: Score = 100
var x: Position = 50.5

echo("Window: ", WindowWidth, "x", WindowHeight)
echo("Title: ", WindowTitle)
echo("Max players: ", MaxPlayers)
echo("Player ", player1, " at position ", x, " with score ", score)
