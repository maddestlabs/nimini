## Comprehensive example showing for and while loops

import ../src/nimini/[tokenizer, parser, codegen]
import std/strutils

echo """
# Nimini Loop Examples - Generated Nim Code

This demonstrates the Nim-style for loops and while statements
in the Nimini DSL that generate native Nim code.
"""

# Example 1: Nim-style range for loop
let example1 = """
# Count from 1 to 5
for i in 1..5:
  echo(i)
"""

echo "\n## Example 1: Basic for loop with .. operator"
echo "```nimini"
echo example1.strip()
echo "```"
echo "\n**Generated Nim:**"
echo "```nim"
echo generateNimCode(parseDsl(tokenizeDsl(example1)))
echo "```"

# Example 2: Exclusive range
let example2 = """
# Count from 0 to 9 (exclusive end)
for i in 0..<10:
  echo(i)
"""

echo "\n## Example 2: For loop with ..< operator"
echo "```nimini"
echo example2.strip()
echo "```"
echo "\n**Generated Nim:**"
echo "```nim"
echo generateNimCode(parseDsl(tokenizeDsl(example2)))
echo "```"

# Example 3: While loop
let example3 = """
var count = 0
while count < 5:
  echo(count)
  count = count + 1
"""

echo "\n## Example 3: Basic while loop"
echo "```nimini"
echo example3.strip()
echo "```"
echo "\n**Generated Nim:**"
echo "```nim"
echo generateNimCode(parseDsl(tokenizeDsl(example3)))
echo "```"

# Example 4: While with complex condition
let example4 = """
var running = true
var frame = 0
while running and frame < 100:
  update(frame)
  frame = frame + 1
  if shouldQuit():
    running = false
"""

echo "\n## Example 4: While with complex condition"
echo "```nimini"
echo example4.strip()
echo "```"
echo "\n**Generated Nim:**"
echo "```nim"
echo generateNimCode(parseDsl(tokenizeDsl(example4)))
echo "```"

# Example 5: Nested loops
let example5 = """
for y in 0..2:
  for x in 0..2:
    echo(x + y * 3)
"""

echo "\n## Example 5: Nested for loops"
echo "```nimini"
echo example5.strip()
echo "```"
echo "\n**Generated Nim:**"
echo "```nim"
echo generateNimCode(parseDsl(tokenizeDsl(example5)))
echo "```"

echo "\n---\n"
echo "All examples successfully transpiled to Nim code!"
