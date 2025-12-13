# Niminitest - Dynamic Execution Testing for Nimini

`niminitest` executes Nim files through nimini's actual parser and runtime engine, providing real execution feedback instead of static analysis.

## What Does It Do?

`niminitest` **runs your code** through nimini to see if it works.

It reports which phase failed:
1. **Tokenization** - Breaking source code into tokens
2. **Parsing** - Building an Abstract Syntax Tree (AST)
3. **Execution** - Actually running the code

## Installation

```bash
nim c niminitest.nim
```

## Usage

```bash
./niminitest <nim_file>
```

### Example with Working Code

```bash
$ ./niminitest test_working.nim
```

```
Sum: 30
sin(pi) = 0.00000265358979335273
Point: (3.0, 4.0)
Array sum: 15
Double 5: 10

================================================================================
NIMINI EXECUTION TEST REPORT
================================================================================
File: test_working.nim
Execution Time: 0.000694s

✅ SUCCESS - Script executed completely
--------------------------------------------------------------------------------

📊 Statistics:
  • Tokens parsed: 182
  • Statements: 16
  • Output lines: 0

================================================================================
ANALYSIS
================================================================================

🎉 This script is fully compatible with nimini!

Next steps:
  • Integrate into your nimini-based application
  • Test with your specific native function bindings
  • Try different nimini backends (Nim/Python/JavaScript)
```

### Example with Broken Code

```bash
$ ./niminitest test_compatibility.nim
```

```
================================================================================
NIMINI EXECUTION TEST REPORT
================================================================================
File: test_compatibility.nim
Execution Time: 0.000195s

❌ FAILED in Parsing phase
--------------------------------------------------------------------------------

🔍 Parsing Error:
  The tokens were generated but could not be parsed. This indicates:
  • Syntax not supported by nimini's parser
  • Incorrect statement structure
  • Missing or unexpected tokens

  Statistics before failure:
    • Tokens parsed: 240

  Error: Unexpected token in expression at line 8

💡 Suggestions:
  • Check for Nim features not supported by nimini
  • Use 'niminitry' tool for static feature analysis
  • Review nimini documentation for supported syntax
  • Simplify complex expressions

================================================================================
ANALYSIS
================================================================================

To fix this script for nimini compatibility:

1. Run static analysis:
   ./niminitry test_compatibility.nim

2. Review the error message above

3. Check nimini documentation:
   • docs/NEW_FEATURES_SUMMARY.md - Supported features
   • docs/STDLIB_SUMMARY.md - Available stdlib functions
   • docs/RAYLIB_NIMINI_ANALYSIS.md - Integration examples

4. Simplify or adapt the code:
   • Remove unsupported features (imports, macros, etc.)
   • Replace stdlib calls with nimini stdlib equivalents
   • Expose needed functions as native bindings
```

## Understanding the Phases

### Phase 1: Tokenization

Breaks source code into tokens (keywords, operators, literals, etc.).

**Common failures:**
- Unterminated strings
- Invalid characters
- Malformed literals

**Example error:**
```
❌ FAILED in Tokenization phase

🔍 Tokenization Error:
  The script could not be tokenized. This usually indicates:
  • Invalid syntax or characters
  • Unsupported string literal formats
  • Malformed tokens

  Error: Unterminated string at line 42
```

### Phase 2: Parsing

Builds an Abstract Syntax Tree from tokens.

**Common failures:**
- Unsupported syntax (templates, macros, etc.)
- Missing keywords (`in` after for variable)
- Incorrect indentation
- Invalid expressions

**Example error:**
```
❌ FAILED in Parsing phase

🔍 Parsing Error:
  The tokens were generated but could not be parsed. This indicates:
  • Syntax not supported by nimini's parser
  • Incorrect statement structure
  • Missing or unexpected tokens

  Statistics before failure:
    • Tokens parsed: 156

  Error: Expected 'in' after for variable at line 23
```

### Phase 3: Execution

Actually runs the parsed code.

**Common failures:**
- Undefined functions or variables
- Type mismatches
- Runtime errors (division by zero, etc.)

**Example error:**
```
❌ FAILED in Execution phase

🔍 Runtime Error:
  The code parsed successfully but failed during execution. This indicates:
  • Undefined variables or functions
  • Type mismatches
  • Invalid operations
  • Logic errors

  Statistics before failure:
    • Tokens parsed: 156
    • Statements: 23

  Error: Undefined variable 'foo' at line 15
```

## Comparison with Niminitry

| Feature | niminitry | niminitest |
|---------|-----------|------------|
| **Analysis Type** | Static (reads code) | Dynamic (executes code) |
| **Speed** | Very fast | Slower (actually runs) |
| **Accuracy** | Heuristic | Definitive |
| **False Positives** | Possible | None |
| **Function Calls** | Lists all calls | Only reports undefined |
| **Stdlib Check** | Shows which are supported | Tests actual availability |
| **Best For** | Quick overview | Final verification |

## Workflow

The recommended workflow is to use both tools:

```bash
# 1. Quick static analysis
./niminitry my_script.nim

# Review what features and functions are used
# Adapt code based on recommendations

# 2. Dynamic verification
./niminitest my_script.nim

# See if it actually works in nimini
# Get real execution feedback
```

## Testing Your Host Application

When developing a nimini-based application with custom native functions:

### Step 1: Test vanilla script

```bash
$ ./niminitest my_game_script.nim
❌ FAILED in Execution phase
Error: Undefined variable 'initWindow' at line 5
```

### Step 2: Create test file with bindings

```nim
# test_with_bindings.nim
import nimini
import raylib
import nimini/autopragma

# Expose your native functions
proc initWindow(env: ref Env; args: seq[Value]): Value {.nimini.} =
  raylib.initWindow(args[0].i.int32, args[1].i.int32, args[2].s)
  return valNil()

proc drawCircle(env: ref Env; args: seq[Value]): Value {.nimini.} =
  raylib.drawCircle(args[0].i.int32, args[1].i.int32, 
                    args[2].f.float32, ...)
  return valNil()

# ... expose other functions ...

# Now test the script
initRuntime()
initStdlib()

let code = readFile("my_game_script.nim")
let tokens = tokenizeDsl(code)
let program = parseDsl(tokens)
execProgram(program, runtimeEnv)
```

This way you can test your scripts with your actual native function bindings.

## Use Cases

1. **Development Testing** - Verify scripts work before deploying
2. **CI/CD Integration** - Automated testing of nimini scripts
3. **Educational** - Learn what works in nimini by trying examples
4. **Debugging** - Get exact error messages with line numbers
5. **Regression Testing** - Ensure changes don't break existing scripts

## Limitations

Since niminitest uses nimini's actual engine:

- ✅ Tests real compatibility
- ✅ Catches actual runtime errors
- ✅ Verifies stdlib function availability
- ❌ Cannot test native functions (unless you create custom test wrapper)
- ❌ Slower than static analysis
- ❌ Won't catch issues specific to code generation backends

## Future Enhancements

Planned improvements:

1. **Custom native functions** - Load .so/.dll with test bindings
2. **Performance metrics** - Benchmark script execution
3. **Memory usage** - Track memory consumption
4. **Code coverage** - Which statements were executed
5. **Step debugging** - Interactive execution
6. **Multiple files** - Test entire project directory
