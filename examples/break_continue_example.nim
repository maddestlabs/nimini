# Example demonstrating break and continue in Nimini
# Shows how to use loop control statements

import nimini

let breakExample = """
# Break example: Find first number divisible by 7
echo("=== Break Example ===")
var found = 0
for i in 1..100:
  if i % 7 == 0:
    found = i
    break
echo("First number divisible by 7: ")
echo(found)
echo("")
"""

let continueExample = """
# Continue example: Sum only odd numbers
echo("=== Continue Example ===")
var sum = 0
for i in 1..10:
  if i % 2 == 0:
    continue
  sum = sum + i
echo("Sum of odd numbers 1-10: ")
echo(sum)
echo("")
"""

let nestedLoopBreak = """
# Nested loop with break
echo("=== Nested Loop Break Example ===")
var found = false
var foundI = 0
var foundJ = 0
for i in 1..10:
  for j in 1..10:
    if i * j == 24:
      found = true
      foundI = i
      foundJ = j
      break
  if found:
    break

if found:
  echo("Found: ")
  echo(foundI)
  echo(" * ")
  echo(foundJ)
  echo(" = 24")
echo("")
"""

let whileBreak = """
# While loop with break
echo("=== While Loop Break Example ===")
var count = 0
while true:
  count = count + 1
  if count > 5:
    break
echo("Counted to: ")
echo(count)
echo("")
"""

let whileContinue = """
# While loop with continue
echo("=== While Loop Continue Example ===")
var i = 0
var evenSum = 0
while i < 20:
  i = i + 1
  if i % 2 != 0:
    continue
  evenSum = evenSum + i
echo("Sum of even numbers 1-20: ")
echo(evenSum)
echo("")
"""

let primeCheck = """
# Practical example: Check if number is prime
echo("=== Prime Number Check ===")
var num = 17
var isPrime = true
if num < 2:
  isPrime = false
else:
  for i in 2..num-1:
    if num % i == 0:
      isPrime = false
      break
echo(num)
echo(" is prime: ")
echo(isPrime)
"""

proc runExample(code: string) =
  initRuntime()
  let tokens = tokenizeDsl(code)
  let prog = parseDsl(tokens)
  execProgram(prog, runtimeEnv)

echo "Running Break/Continue Examples:"
echo "================================\n"

runExample(breakExample)
echo ""
runExample(continueExample)
echo ""
runExample(nestedLoopBreak)
echo ""
runExample(whileBreak)
echo ""
runExample(whileContinue)
echo ""
runExample(primeCheck)
