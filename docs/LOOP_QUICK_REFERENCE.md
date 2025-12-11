# Loop Features Quick Reference

## Fixed Loop Bug
The for loop range iteration now works correctly:
```nim
for i in 0..<5:    # Now correctly iterates: 0, 1, 2, 3, 4 (not 0-5)
  echo(i)

for i in 0..5:     # Correctly iterates: 0, 1, 2, 3, 4, 5
  echo(i)
```

## Loop Labels

### Basic Labeled Block
```nim
block myLabel:
  for i in 0..<10:
    if i == 5:
      break myLabel  # Exits the labeled block
```

### Nested Loop Control
```nim
block outer:
  for i in 0..<3:
    for j in 0..<3:
      if i + j == 4:
        break outer  # Breaks out of both loops
```

### Labeled While Loops
```nim
block loop:
  while condition:
    if shouldExit:
      break loop
```

## Multi-Variable For Loops

### With Arrays (Index and Element)
```nim
var items = ["apple", "banana", "cherry"]

for idx, item in items:
  echo(idx, ": ", item)
  # Output:
  # 0: apple
  # 1: banana  
  # 2: cherry
```

### With Ranges (Index Only)
```nim
for i, j in 0..<5:
  # i gets values: 0, 1, 2, 3, 4
  # j is nil (extra variables ignored for ranges)
  echo(i)
```

### Single Variable (Elements Only)
```nim
var numbers = [10, 20, 30]

for num in numbers:
  echo(num)  # Gets: 10, 20, 30 (elements only, no index)
```

## Complete Examples

### Example 1: Find in 2D Grid
```nim
var found = false
var position = 0

block search:
  for y in 0..<10:
    for x in 0..<10:
      if grid[y][x] == target:
        position = y * 100 + x
        found = true
        break search
```

### Example 2: Process Array with Index
```nim
var data = ["a", "b", "c", "d"]
var processed = 0

for i, item in data:
  if i > 0:  # Skip first item
    process(item)
    processed = processed + 1
```

### Example 3: Early Exit from Complex Loop
```nim
var result = -1

block findPair:
  for a in 1..100:
    for b in 1..100:
      if a * a + b * b == 25:
        result = a * 1000 + b
        break findPair
```

## Code Generation

Both features work seamlessly with Nimini's code generation:

```nim
# Input Nimini code
block outer:
  for i, item in array:
    if item == target:
      break outer

# Generated Nim code
block outer:
  for i, item in array:
    if (item == target):
      break outer
```

## Notes

- Labels are optional - `break` without a label breaks the innermost loop
- `continue` works with unlabeled loops only (standard Nim behavior)
- Multi-variable syntax mimics Nim's `pairs()` iterator behavior
- All features maintain full backward compatibility
