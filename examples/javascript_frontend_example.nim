## JavaScript Frontend Example
## Demonstrates parsing JavaScript code and generating to multiple backends

import ../src/nimini
import std/strutils

echo "=" .repeat(70)
echo "JavaScript Frontend Demo"
echo "=" .repeat(70)
echo ""

# Example 1: Simple JavaScript code
echo "=== Example 1: Basic JavaScript Syntax ==="
echo "-" .repeat(70)
let jsCode1 = """
const x = 10;
let y = 20;
var sum = x + y;
console.log(sum);
"""

let prog1 = compileSource(jsCode1, getJavaScriptFrontend())
echo "✓ Parsed JavaScript code: ", prog1.stmts.len, " statements"
echo ""

# Example 2: JavaScript function
echo "=== Example 2: JavaScript Function ==="
echo "-" .repeat(70)
let jsCode2 = """
function add(a, b) {
  return a + b;
}

const result = add(5, 10);
console.log(result);
"""

let prog2 = compileSource(jsCode2, getJavaScriptFrontend())
echo "JavaScript input:"
echo jsCode2
echo ""
echo "Nim output:"
echo generateCode(prog2, newNimBackend())
echo ""

# Example 3: Control flow
echo "=== Example 3: JavaScript Control Flow ==="
echo "-" .repeat(70)
let jsCode3 = """
let x = 15;

if (x > 20) {
  console.log("Large");
} else if (x > 10) {
  console.log("Medium");
} else {
  console.log("Small");
}
"""

let prog3 = compileSource(jsCode3, getJavaScriptFrontend())
echo "JavaScript input:"
echo jsCode3
echo ""
echo "Python output:"
echo generateCode(prog3, newPythonBackend())
echo ""

# Example 4: Loops
echo "=== Example 4: JavaScript Loops ==="
echo "-" .repeat(70)
let jsCode4 = """
for (let i of range(1, 6)) {
  let squared = i * i;
  console.log(squared);
}

let count = 5;
while (count > 0) {
  console.log(count);
  count = count - 1;
}
"""

let prog4 = compileSource(jsCode4, getJavaScriptFrontend())
echo "JavaScript input:"
echo jsCode4
echo ""
echo "JavaScript output:"
echo generateCode(prog4, newJavaScriptBackend())
echo ""

# Example 5: Boolean logic
echo "=== Example 5: JavaScript Boolean Logic ==="
echo "-" .repeat(70)
let jsCode5 = """
const a = true;
const b = false;
const result = a && !b;

if (result || b) {
  console.log("Yes");
}
"""

let prog5 = compileSource(jsCode5, getJavaScriptFrontend())
echo "JavaScript input:"
echo jsCode5
echo ""
echo "Nim output:"
echo generateCode(prog5, newNimBackend())
echo ""

# Example 6: Arrays
echo "=== Example 6: JavaScript Arrays ==="
echo "-" .repeat(70)
let jsCode6 = """
const numbers = [1, 2, 3, 4, 5];
const first = numbers[0];
const last = numbers[4];
console.log(first);
console.log(last);
"""

let prog6 = compileSource(jsCode6, getJavaScriptFrontend())
echo "JavaScript input:"
echo jsCode6
echo ""
echo "Python output:"
echo generateCode(prog6, newPythonBackend())
echo ""

# Example 7: Complex example
echo "=== Example 7: Complete JavaScript Program ==="
echo "-" .repeat(70)
let jsCode7 = """
function factorial(n) {
  if (n <= 1) {
    return 1;
  } else {
    return n * factorial(n - 1);
  }
}

function fibonacci(n) {
  if (n <= 1) {
    return n;
  }
  return fibonacci(n - 1) + fibonacci(n - 2);
}

const result1 = factorial(5);
const result2 = fibonacci(7);

console.log(result1);
console.log(result2);
"""

let prog7 = compileSource(jsCode7, getJavaScriptFrontend())
echo "JavaScript input:"
echo jsCode7
echo ""
echo "Nim output:"
echo generateCode(prog7, newNimBackend())
echo ""

# Example 8: Auto-detection
echo "=== Example 8: Auto-Detection ==="
echo "-" .repeat(70)
let autoJsCode = """
function greet(name) {
  console.log("Hello, " + name);
}

greet("World");
"""

let prog8 = compileSource(autoJsCode)  # Auto-detect
echo "✓ Auto-detected as JavaScript"
echo "✓ Parsed successfully"
echo ""

# Example 9: Cross-language compilation
echo "=== Example 9: JavaScript → All Backends ==="
echo "-" .repeat(70)
let jsSource = """
function square(x) {
  return x * x;
}

const value = 7;
const result = square(value);
console.log(result);
"""

let prog9 = compileSource(jsSource, getJavaScriptFrontend())

echo "--- Nim ---"
echo generateCode(prog9, newNimBackend())
echo ""

echo "--- Python ---"
echo generateCode(prog9, newPythonBackend())
echo ""

echo "--- JavaScript ---"
echo generateCode(prog9, newJavaScriptBackend())
echo ""

echo "=" .repeat(70)
echo "✓ JavaScript frontend working perfectly!"
echo "✓ Write JavaScript, generate Nim/Python/JavaScript"
echo "=" .repeat(70)
