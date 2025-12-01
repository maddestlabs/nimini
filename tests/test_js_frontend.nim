# Tests for JavaScript Frontend

import ../src/nimini
import std/[unittest, strutils]

suite "JavaScript Frontend":
  
  test "JavaScript frontend creation":
    let frontend = newJavaScriptFrontend()
    check frontend.name == "JavaScript"
    check ".js" in frontend.fileExtensions
    check frontend.supportsTypeAnnotations == false
  
  test "JavaScript frontend singleton":
    let fe1 = getJavaScriptFrontend()
    let fe2 = getJavaScriptFrontend()
    check fe1 == fe2
  
  test "Parse simple JavaScript variable":
    let jsCode = "const x = 10;"
    let program = compileSource(jsCode, getJavaScriptFrontend())
    check program.stmts.len == 1
  
  test "Parse JavaScript function":
    let jsCode = """
function add(a, b) {
  return a + b;
}
"""
    let program = compileSource(jsCode, getJavaScriptFrontend())
    check program.stmts.len == 1
  
  test "Parse JavaScript true/false":
    let jsCode = """
const a = true;
let b = false;
"""
    let program = compileSource(jsCode, getJavaScriptFrontend())
    check program.stmts.len == 2
  
  test "Parse console.log as echo":
    let jsCode = """
const x = 42;
console.log(x);
"""
    let program = compileSource(jsCode, getJavaScriptFrontend())
    check program.stmts.len == 2
  
  test "Parse JavaScript if/else":
    let jsCode = """
let x = 15;
if (x > 20) {
  console.log("big");
} else if (x > 10) {
  console.log("medium");
} else {
  console.log("small");
}
"""
    let program = compileSource(jsCode, getJavaScriptFrontend())
    check program.stmts.len == 2
  
  test "Parse JavaScript for loop":
    let jsCode = """
for (let i of range(1, 10)) {
  console.log(i);
}
"""
    let program = compileSource(jsCode, getJavaScriptFrontend())
    check program.stmts.len == 1
  
  test "Parse JavaScript while loop":
    let jsCode = """
let x = 5;
while (x > 0) {
  x = x - 1;
}
"""
    let program = compileSource(jsCode, getJavaScriptFrontend())
    check program.stmts.len == 2
  
  test "Parse JavaScript arrays":
    let jsCode = """
const numbers = [1, 2, 3, 4, 5];
const first = numbers[0];
"""
    let program = compileSource(jsCode, getJavaScriptFrontend())
    check program.stmts.len == 2
  
  test "Parse JavaScript boolean operators":
    let jsCode = """
const result = true && false;
const result2 = true || false;
const result3 = !true;
"""
    let program = compileSource(jsCode, getJavaScriptFrontend())
    check program.stmts.len == 3
  
  test "JavaScript to Nim codegen":
    let jsCode = """
function square(x) {
  return x * x;
}
const result = square(5);
"""
    let program = compileSource(jsCode, getJavaScriptFrontend())
    let nimCode = generateCode(program, newNimBackend())
    check nimCode.contains("proc")
    check nimCode.contains("square")
  
  test "JavaScript to Python codegen":
    let jsCode = """
let x = 10;
let y = 20;
"""
    let program = compileSource(jsCode, getJavaScriptFrontend())
    let pyOutput = generateCode(program, newPythonBackend())
    check pyOutput.contains("=")
  
  test "JavaScript to JavaScript codegen":
    let jsCode = """
const x = 10;
const y = 20;
"""
    let program = compileSource(jsCode, getJavaScriptFrontend())
    let jsOutput = generateCode(program, newJavaScriptBackend())
    check jsOutput.len > 0
  
  test "Auto-detect JavaScript by content":
    let jsCode = """
function test() {
  console.log("hello");
}
"""
    let program = compileSource(jsCode)  # Auto-detect
    check program.stmts.len == 1
  
  test "Detect JavaScript by filename":
    let jsCode = "const x = 10;"
    let program = compileSource(jsCode, filename="script.js")
    check program.stmts.len == 1
  
  test "Complex JavaScript program":
    let jsCode = """
function factorial(n) {
  if (n <= 1) {
    return 1;
  } else {
    return n * factorial(n - 1);
  }
}

const result = factorial(5);
console.log(result);
"""
    let program = compileSource(jsCode, getJavaScriptFrontend())
    check program.stmts.len == 3
    
    # Test it generates to all backends
    let nimCode = generateCode(program, newNimBackend())
    let pyOutput = generateCode(program, newPythonBackend())
    let jsOutput = generateCode(program, newJavaScriptBackend())
    
    check nimCode.len > 0
    check pyOutput.len > 0
    check jsOutput.len > 0
  
  test "JavaScript strings with escapes":
    let jsCode = """
const text = "Hello\\nWorld";
"""
    let program = compileSource(jsCode, getJavaScriptFrontend())
    check program.stmts.len == 1
  
  test "JavaScript comments ignored":
    let jsCode = """
// This is a comment
const x = 10;  // inline comment
/* Multi-line
   comment */
const y = 20;
"""
    let program = compileSource(jsCode, getJavaScriptFrontend())
    check program.stmts.len == 2
  
  test "JavaScript operator mapping":
    let jsCode = """
const a = true && false;
const b = true || false;
const c = x === y;
const d = x !== y;
"""
    let program = compileSource(jsCode, getJavaScriptFrontend())
    check program.stmts.len == 4

when isMainModule:
  echo "Running JavaScript Frontend Tests..."
