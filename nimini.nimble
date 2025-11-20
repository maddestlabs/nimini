# Package
packageName   = "nimini"
version       = "0.1.0"
author        = "Maddest Labs"
description   = "Nimini - Lightweight Nim-inspired DSL for interactive applications"
license       = "MIT"

# Settings
srcDir = "src"
skipDirs = @["tests"]

# Dependencies
requires "nim >= 1.6.0"

# Tasks
task test, "Run all tests":
  exec "nim c -r tests/tests.nim"

task docs, "Generate docs":
  exec "nim doc --project --out:docs src/nimini.nim"