# Nimini Error Handling

Nimini now uses proper exceptions for error handling instead of `quit()`, enabling better error recovery and reporting.

## Error Types

All nimini errors inherit from `NiminiError` which is a `CatchableError`:

```nim
type
  NiminiError* = object of CatchableError
    line*: int      # Line number where error occurred
    col*: int       # Column number where error occurred
  
  NiminiTokenizeError* = object of NiminiError
    ## Raised during tokenization phase
  
  NiminiParseError* = object of NiminiError
    ## Raised during parsing phase
  
  NiminiRuntimeError* = object of NiminiError
    ## Raised during runtime execution
```

## Usage

### Basic Error Handling

```nim
import nimini

try:
  let tokens = tokenizeDsl(code)
  let program = parseDsl(tokens)
  initRuntime()
  initStdlib()
  execProgram(program, runtimeEnv)
except NiminiTokenizeError as e:
  echo "Tokenization error at line ", e.line, ": ", e.msg
except NiminiParseError as e:
  echo "Parse error at line ", e.line, ": ", e.msg
except NiminiRuntimeError as e:
  echo "Runtime error at line ", e.line, ": ", e.msg
except NiminiError as e:
  echo "Nimini error: ", e.msg
```

### Catching All Phases

```nim
proc executeScript(code: string): bool =
  try:
    # Tokenization phase
    let tokens = tokenizeDsl(code)
    
    # Parsing phase
    let program = parseDsl(tokens)
    
    # Runtime phase
    initRuntime()
    initStdlib()
    execProgram(program, runtimeEnv)
    
    return true
  except NiminiError as e:
    echo "Error at line ", e.line, ", col ", e.col, ": ", e.msg
    return false
```

### Getting Detailed Error Information

```nim
try:
  let program = parseDsl(tokens)
except NiminiParseError as e:
  echo "Parse failed!"
  echo "  Location: line ", e.line, ", column ", e.col
  echo "  Message: ", e.msg
  echo "  Type: ", e.name
```

## Error Messages

Each error type provides specific, actionable error messages:

### Tokenization Errors

- **Unterminated string**: String literal not properly closed
- **Unexpected character**: Character not valid in nimini syntax

### Parse Errors  

- **Expected type name**: Type annotation missing or invalid
- **Expected 'in' after for variable**: Missing 'in' keyword in for loop
- **Expected indent block**: Missing indentation for block statement
- **Unexpected token in expression**: Invalid token in expression context
- **Tuple unpacking not supported for const**: Feature limitation
- And more...

### Runtime Errors

Runtime errors are typically raised during execution and include:
- Undefined variable access
- Type mismatches
- Invalid operations
- Division by zero
- And more...

## Benefits

### Before (using `quit`)

```nim
proc parseType(p: var Parser): TypeNode =
  if t.kind != tkIdent:
    quit "Parse Error: Expected type name at line " & $t.line
  # ...
```

**Problems:**
- Terminates the entire program
- Cannot be caught or recovered from
- Difficult to test
- Poor user experience in embedded scenarios

### After (using exceptions)

```nim
proc parseType(p: var Parser): TypeNode =
  if t.kind != tkIdent:
    var err = newException(NiminiParseError, "Expected type name at line " & $t.line)
    err.line = t.line
    err.col = t.col
    raise err
  # ...
```

**Benefits:**
- Can be caught and handled gracefully
- Enables error recovery
- Better testing capabilities
- Professional error reporting in tools
- Works well in embedded/library scenarios

## Tools Using Error Handling

### niminitest

The `niminitest` tool uses exception handling to provide detailed error reports:

```bash
$ ./niminitest broken_script.nim

================================================================================
NIMINI EXECUTION TEST REPORT
================================================================================
File: broken_script.nim
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
```

## Migration Guide

If you have existing code that catches nimini errors, no changes are needed - the exceptions are now catchable instead of causing program termination.

If you were relying on `quit()` behavior (immediate termination), you can still achieve this:

```nim
try:
  execProgram(program, runtimeEnv)
except NiminiError:
  quit(1)  # Exit immediately
```

## Future Enhancements

Potential future improvements to error handling:

1. **Error recovery**: Continue parsing after errors to report multiple issues
2. **Source context**: Include snippet of source code around error location
3. **Suggestions**: Provide hints for common mistakes
4. **Warning system**: Non-fatal issues that don't stop execution
5. **Error codes**: Unique identifiers for each error type for programmatic handling

## See Also

- [niminitest](README_NIMINITEST.md) - Dynamic execution testing
- [niminitry](README_NIMINITRY.md) - Static compatibility analysis
- [docs/NEW_FEATURES_SUMMARY.md](docs/NEW_FEATURES_SUMMARY.md) - Latest nimini features
