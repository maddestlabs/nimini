# String Operations Example for Nimini DSL
# Demonstrates string slicing, $ operator, and string methods

import nimini

proc main() =
  # Example 1: Using the $ stringify operator
  echo "=== Example 1: $ Stringify Operator ==="
  let num = 42
  let numStr = $num
  echo "Number as string: " & numStr
  
  let temperature = 25
  echo "Temperature: " & $temperature & " degrees"
  
  # Example 2: String slicing with inclusive range (..)
  echo "\n=== Example 2: String Slicing (Inclusive ..) ==="
  let message = "Hello, World!"
  let hello = message[0..4]
  echo "message[0..4] = " & hello  # Outputs: Hello
  
  let world = message[7..11]
  echo "message[7..11] = " & world  # Outputs: World
  
  # Example 3: String slicing with exclusive range (..<)
  echo "\n=== Example 3: String Slicing (Exclusive ..<) ==="
  let text = "Programming"
  let prog = text[0..<4]
  echo "text[0..<4] = " & prog  # Outputs: Prog
  
  let gram = text[3..<7]
  echo "text[3..<7] = " & gram  # Outputs: gram
  
  # Example 4: String length
  echo "\n=== Example 4: String Length ==="
  let name = "Nimini"
  let nameLength = name.len
  echo "Length of '" & name & "': " & $nameLength
  
  # Example 5: String case conversion
  echo "\n=== Example 5: Case Conversion ==="
  let original = "Hello World"
  echo "Original: " & original
  echo "Uppercase: " & original.toUpper()
  echo "Lowercase: " & original.toLower()
  
  # Example 6: String trimming
  echo "\n=== Example 6: String Trimming ==="
  let padded = "   spaces   "
  echo "Before trim: '" & padded & "'"
  echo "After trim: '" & padded.strip() & "'"
  
  # Example 7: Combining operations
  echo "\n=== Example 7: Complex Operations ==="
  let data = "temperature: 25"
  let dataUpper = data.toUpper()
  echo "Uppercase: " & dataUpper
  echo "Length: " & $dataUpper.len
  echo "Slice: " & dataUpper[0..10]
  
  # Example 8: String operations in loops
  echo "\n=== Example 8: String Operations in Loops ==="
  let words = ["cat", "dog", "bird"]
  var i = 0
  while i < 3:
    let word = words[i]
    echo "Word: " & word & ", Length: " & $word.len & ", Upper: " & word.toUpper()
    i = i + 1
  
  # Example 9: Practical example - formatting output
  echo "\n=== Example 9: Formatting Output ==="
  let items = ["Apple", "Banana", "Cherry"]
  let prices = [100, 150, 200]
  
  var idx = 0
  while idx < 3:
    let item = items[idx]
    let price = prices[idx]
    let priceStr = $price
    let output = item & ": $" & priceStr
    echo output
    idx = idx + 1

# Run the example
main()
