# Package
version       = "0.1.0"
author        = "Maddest Labs"
description   = "Nimini - Lightweight Nim-inspired DSL for interactive applications"
license       = "MIT"
srcDir        = "src"
installDirs   = @["nimini"]
installFiles  = @["nimini.nim"]
skipDirs      = @["tests", "examples", "docs"]
skipFiles     = @["config.nims"]

# Dependencies
requires "nim >= 1.6.0"

# Tasks
task test, "Run all tests":
  exec "nim c -r tests/tests.nim"

task test_autopragma, "Run autopragma tests":
  exec "nim c -r tests/test_autopragma.nim"

task test_loops, "Run loop tests":
  exec "nim c -r tests/test_loops.nim"

task test_robustness, "Run parser robustness tests":
  exec "nim c -r tests/test_parser_robustness.nim"

task examples, "Build all examples":
  exec "nim c examples/autopragma_example.nim"
  exec "nim c examples/codegen_example.nim"
  exec "nim c examples/loop_examples.nim"

task example_autopragma, "Run autopragma example":
  exec "nim c -r examples/autopragma_example.nim"

task example_codegen, "Run codegen example":
  exec "nim c -r examples/codegen_example.nim"

task example_loops, "Run loop example":
  exec "nim c -r examples/loop_examples.nim"

task docs, "Generate documentation":
  exec "nim doc --project --index:on --git.url:https://github.com/maddestlabs/nimini --git.commit:main --outdir:docs src/nimini.nim"

task clean, "Clean build artifacts":
  exec "rm -rf nimcache"
  exec "find . -name '*.exe' -delete"
  exec "find . -name 'nimini' -type f -delete"
  exec "find examples -type f ! -name '*.nim' ! -name 'README.md' -delete"
  exec "find tests -type f ! -name '*.nim' -delete"

task uninstall_clean, "Force clean nimble cache for this package":
  echo "This will remove nimini from nimble cache. Run: nimble uninstall nimini -y && rm -rf ~/.nimble/pkgs/nimini-*"