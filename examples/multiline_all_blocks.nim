## Comprehensive example with all multiline blocks

const
  WindowWidth = 800
  WindowHeight = 600
  GameTitle = "My Game"

type
  PlayerId = int
  Score = int
  Health = int

var
  player1: PlayerId = 1
  player2: PlayerId = 2
  
  score1: Score = 100
  score2: Score = 150

let
  maxHealth: Health = 100
  minHealth: Health = 0

echo("Game: ", GameTitle, " (", WindowWidth, "x", WindowHeight, ")")
echo("Player 1: ID=", player1, " Score=", score1)
echo("Player 2: ID=", player2, " Score=", score2)
echo("Health range: ", minHealth, " to ", maxHealth)
