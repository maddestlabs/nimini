# Abstract Frontend Interface for Multi-Language Input Support
# Defines the contract that all language frontends must implement

import ast
import tokenizer
import std/strutils

export ast
export tokenizer

type
  Frontend* = ref object of RootObj
    ## Abstract frontend for parsing different source languages
    name*: string
    fileExtensions*: seq[string]
    supportsTypeAnnotations*: bool  # Whether the language supports type hints

# ------------------------------------------------------------------------------
# Core Frontend Methods
# ------------------------------------------------------------------------------

method tokenize*(frontend: Frontend; source: string): seq[Token] {.base.} =
  ## Tokenize source code into tokens
  ## Each frontend implements its own tokenization rules
  quit "tokenize not implemented for frontend: " & frontend.name

method parse*(frontend: Frontend; tokens: seq[Token]): Program {.base.} =
  ## Parse tokens into Nimini AST
  ## This is where language-specific syntax gets translated to universal AST
  quit "parse not implemented for frontend: " & frontend.name

# ------------------------------------------------------------------------------
# Convenience Methods
# ------------------------------------------------------------------------------

proc compile*(frontend: Frontend; source: string): Program =
  ## Compile source code directly to AST in one step
  ## This is the main entry point for most use cases
  let tokens = frontend.tokenize(source)
  return frontend.parse(tokens)

proc getFileExtension*(frontend: Frontend; index: int = 0): string =
  ## Get the primary file extension for this frontend
  if index < frontend.fileExtensions.len:
    return frontend.fileExtensions[index]
  else:
    return ".txt"

proc supportsExtension*(frontend: Frontend; extension: string): bool =
  ## Check if this frontend supports a given file extension
  for ext in frontend.fileExtensions:
    if ext == extension or ext == "." & extension:
      return true
  return false

# ------------------------------------------------------------------------------
# Frontend Registry and Detection
# ------------------------------------------------------------------------------

var registeredFrontends: seq[Frontend] = @[]

proc registerFrontend*(frontend: Frontend) =
  ## Register a frontend for auto-detection
  registeredFrontends.add(frontend)

proc detectFrontendByExtension*(filename: string): Frontend =
  ## Detect appropriate frontend based on file extension
  for frontend in registeredFrontends:
    for ext in frontend.fileExtensions:
      if filename.endsWith(ext):
        return frontend
  
  # Default to nil if no match
  return nil

proc detectFrontendByContent*(source: string): Frontend =
  ## Attempt to detect language from source code content
  ## Uses heuristics to identify the language
  
  # JavaScript indicators
  if source.contains("function ") or 
     source.contains("const ") or 
     source.contains("() => ") or
     source.contains("var ") and source.contains("{"):
    for frontend in registeredFrontends:
      if frontend.name == "JavaScript":
        return frontend
  
  # Python indicators
  if source.contains("def ") or 
     source.contains("True") or 
     source.contains("False") or
     source.contains("import "):
    for frontend in registeredFrontends:
      if frontend.name == "Python":
        return frontend
  
  # Nim indicators (current default)
  if source.contains("proc ") or 
     source.contains("discard ") or
     source.contains("method "):
    for frontend in registeredFrontends:
      if frontend.name == "Nim":
        return frontend
  
  # Default to Nim frontend if registered
  for frontend in registeredFrontends:
    if frontend.name == "Nim":
      return frontend
  
  return nil

proc autoDetectFrontend*(source: string; filename: string = ""): Frontend =
  ## Auto-detect frontend using both filename and content
  ## Prefers filename extension if available, falls back to content analysis
  
  # Try filename first
  if filename != "":
    let fe = detectFrontendByExtension(filename)
    if not fe.isNil:
      return fe
  
  # Fall back to content detection
  return detectFrontendByContent(source)

# ------------------------------------------------------------------------------
# Unified Compilation API
# ------------------------------------------------------------------------------

proc compileSource*(source: string; frontend: Frontend = nil; filename: string = ""): Program =
  ## Universal compilation function that auto-detects language if needed
  ## 
  ## Usage:
  ##   let program = compileSource(myCode)  # Auto-detect
  ##   let program = compileSource(myCode, newNimFrontend())  # Explicit
  ##   let program = compileSource(myCode, filename="script.js")  # By extension
  
  var fe = frontend
  
  if fe.isNil:
    fe = autoDetectFrontend(source, filename)
    
    if fe.isNil:
      quit "Unable to detect source language. Please specify a frontend explicitly."
  
  return fe.compile(source)
