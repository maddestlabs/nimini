## Nimini Test - Dynamic execution testing for nimini scripts
## 
## This tool attempts to execute Nim code through nimini's actual parser
## and runtime, providing real execution feedback and error reports.

import std/[os, strutils, times]
import nimini

type
  ExecutionPhase = enum
    epTokenization = "Tokenization"
    epParsing = "Parsing"
    epExecution = "Execution"
  
  TestResult = object
    fileName: string
    success: bool
    phase: ExecutionPhase
    errorMsg: string
    executionTime: float
    output: seq[string]
    tokensCount: int
    statementsCount: int
    
proc captureEcho(text: string) =
  ## Captures echo output during execution
  discard

proc executeNiminiScript(filePath: string): TestResult =
  ## Execute a nimini script and return test results
  result.fileName = filePath
  result.success = false
  result.phase = epTokenization
  result.output = @[]
  
  if not fileExists(filePath):
    result.errorMsg = "File not found"
    return
  
  let code = readFile(filePath)
  let startTime = cpuTime()
  
  # Phase 1: Tokenization
  var tokens: seq[Token]
  try:
    tokens = tokenizeDsl(code)
    result.tokensCount = tokens.len
    result.phase = epParsing
  except CatchableError as e:
    result.errorMsg = e.msg
    result.executionTime = cpuTime() - startTime
    return
  except:
    result.errorMsg = getCurrentExceptionMsg()
    result.executionTime = cpuTime() - startTime
    return
  
  # Phase 2: Parsing
  var program: Program
  try:
    program = parseDsl(tokens)
    result.statementsCount = program.stmts.len
    result.phase = epExecution
  except CatchableError as e:
    result.errorMsg = e.msg
    result.executionTime = cpuTime() - startTime
    return
  except:
    result.errorMsg = getCurrentExceptionMsg()
    result.executionTime = cpuTime() - startTime
    return
  
  # Phase 3: Execution
  try:
    # Initialize runtime with stdlib
    initRuntime()
    initStdlib()
    
    # Execute the program
    execProgram(program, runtimeEnv)
    
    result.success = true
    result.executionTime = cpuTime() - startTime
    
  except CatchableError as e:
    result.errorMsg = e.msg
    result.executionTime = cpuTime() - startTime
    return
  except:
    result.errorMsg = getCurrentExceptionMsg()
    result.executionTime = cpuTime() - startTime
    return

proc printTestReport(result: TestResult) =
  ## Print a formatted test execution report
  echo ""
  echo "=" .repeat(80)
  echo "NIMINI EXECUTION TEST REPORT"
  echo "=" .repeat(80)
  echo "File: ", result.fileName
  echo "Execution Time: ", result.executionTime.formatFloat(ffDecimal, 6), "s"
  echo ""
  
  if result.success:
    echo "✅ SUCCESS - Script executed completely"
    echo "-" .repeat(80)
    echo ""
    echo "📊 Statistics:"
    echo "  • Tokens parsed: ", result.tokensCount
    echo "  • Statements: ", result.statementsCount
    echo "  • Output lines: ", result.output.len
    echo ""
    
    if result.output.len > 0:
      echo "📝 Program Output:"
      echo "-" .repeat(80)
      for line in result.output:
        echo "  ", line
      echo ""
  else:
    echo "❌ FAILED in ", result.phase, " phase"
    echo "-" .repeat(80)
    echo ""
    
    case result.phase
    of epTokenization:
      echo "🔍 Tokenization Error:"
      echo "  The script could not be tokenized. This usually indicates:"
      echo "  • Invalid syntax or characters"
      echo "  • Unsupported string literal formats"
      echo "  • Malformed tokens"
      echo ""
      echo "  Error: ", result.errorMsg
      echo ""
      
    of epParsing:
      echo "🔍 Parsing Error:"
      echo "  The tokens were generated but could not be parsed. This indicates:"
      echo "  • Syntax not supported by nimini's parser"
      echo "  • Incorrect statement structure"
      echo "  • Missing or unexpected tokens"
      echo ""
      echo "  Statistics before failure:"
      echo "    • Tokens parsed: ", result.tokensCount
      echo ""
      echo "  Error: ", result.errorMsg
      echo ""
      
    of epExecution:
      echo "🔍 Runtime Error:"
      echo "  The code parsed successfully but failed during execution. This indicates:"
      echo "  • Undefined variables or functions"
      echo "  • Type mismatches"
      echo "  • Invalid operations"
      echo "  • Logic errors"
      echo ""
      echo "  Statistics before failure:"
      echo "    • Tokens parsed: ", result.tokensCount
      echo "    • Statements: ", result.statementsCount
      echo ""
      echo "  Error: ", result.errorMsg
      echo ""
    
    echo "💡 Suggestions:"
    case result.phase
    of epTokenization:
      echo "  • Check for syntax errors in the code"
      echo "  • Ensure all strings are properly quoted"
      echo "  • Look for unsupported character sequences"
      
    of epParsing:
      echo "  • Check for Nim features not supported by nimini"
      echo "  • Use 'niminitry' tool for static feature analysis"
      echo "  • Review nimini documentation for supported syntax"
      echo "  • Simplify complex expressions"
      
    of epExecution:
      echo "  • Verify all called functions are registered or defined"
      echo "  • Check variable names and scopes"
      echo "  • Ensure types are compatible with operations"
      echo "  • Use 'niminitry' to see which stdlib functions are available"
    echo ""
  
  echo "=" .repeat(80)
  echo "ANALYSIS"
  echo "=" .repeat(80)
  echo ""
  
  if result.success:
    echo "🎉 This script is fully compatible with nimini!"
    echo ""
    echo "Next steps:"
    echo "  • Integrate into your nimini-based application"
    echo "  • Test with your specific native function bindings"
    echo "  • Try different nimini backends (Nim/Python/JavaScript)"
  else:
    echo "To fix this script for nimini compatibility:"
    echo ""
    echo "1. Run static analysis:"
    echo "   ./niminitry ", result.fileName
    echo ""
    echo "2. Review the error message above"
    echo ""
    echo "3. Check nimini documentation:"
    echo "   • docs/NEW_FEATURES_SUMMARY.md - Supported features"
    echo "   • docs/STDLIB_SUMMARY.md - Available stdlib functions"
    echo "   • docs/RAYLIB_NIMINI_ANALYSIS.md - Integration examples"
    echo ""
    echo "4. Simplify or adapt the code:"
    echo "   • Remove unsupported features (imports, macros, etc.)"
    echo "   • Replace stdlib calls with nimini stdlib equivalents"
    echo "   • Expose needed functions as native bindings"
  
  echo ""

proc main() =
  let args = commandLineParams()
  
  if args.len == 0:
    echo "Usage: niminitest <nim_file>"
    echo ""
    echo "Executes a Nim file through nimini's actual parser and runtime,"
    echo "providing a detailed report of the execution results."
    echo ""
    echo "This complements 'niminitry' (static analysis) by providing"
    echo "real execution feedback from nimini's actual engine."
    echo ""
    echo "Example:"
    echo "  niminitest myscript.nim"
    echo ""
    echo "See also:"
    echo "  niminitry - Static feature compatibility analysis"
    quit(1)
  
  let filePath = args[0]
  
  try:
    let result = executeNiminiScript(filePath)
    printTestReport(result)
  except:
    echo "Fatal error during test execution:"
    echo getCurrentExceptionMsg()
    quit(1)

when isMainModule:
  main()
