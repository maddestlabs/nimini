# Nim Frontend - Wraps existing Nim-like DSL parser
# Maintains backward compatibility with existing Nimini code

import ../frontend
import ../tokenizer
import ../parser
import ../ast

export frontend

type
  NimFrontend* = ref object of Frontend

proc newNimFrontend*(): NimFrontend =
  ## Create a new Nim frontend
  ## This wraps the existing tokenizeDsl/parseDsl functions
  result = NimFrontend(
    name: "Nim",
    fileExtensions: @[".nim", ".nims", ".nimini"],
    supportsTypeAnnotations: true
  )

method tokenize*(frontend: NimFrontend; source: string): seq[Token] =
  ## Tokenize Nim-like DSL source code
  ## Uses the existing tokenizeDsl implementation
  return tokenizeDsl(source)

method parse*(frontend: NimFrontend; tokens: seq[Token]): Program =
  ## Parse tokens into Nimini AST
  ## Uses the existing parseDsl implementation
  return parseDsl(tokens)

# Auto-register this frontend
static:
  discard  # Registration happens at runtime in module init

var nimFrontendInstance: NimFrontend = nil

proc getNimFrontend*(): NimFrontend =
  ## Get or create the singleton Nim frontend instance
  if nimFrontendInstance.isNil:
    nimFrontendInstance = newNimFrontend()
    registerFrontend(nimFrontendInstance)
  return nimFrontendInstance

# Auto-register on module load
discard getNimFrontend()
