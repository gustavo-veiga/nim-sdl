# Package
version       = "0.1.0"
author        = "Gustavo Veiga"
description   = "SDL 1.2 Modern Wrapper"
license       = "MIT"
srcDir        = "src"
skipDirs      = @["tests"]


# Dependencies
requires "nim >= 2.2.4"


# Tasks
import os

task test, "Run all test files":
  ## Runs all test files matching test_*.nim in the tests directory.
  var testFiles: seq[string] = @[]
  for kind, path in walkDir("tests"):
    if kind == pcFile and path.endsWith(".nim") and lastPathPart(path).startsWith("test_"):
      testFiles.add(path)
  
  for testFile in testFiles:
    echo "Running " & testFile
    exec "nim r --hints:off " & testFile

task lint, "Check all source files for errors":
  ## Runs nim check on the main module (covers all submodules transitively).
  exec "nim check --hints:off src/sdl.nim"

task fmt, "Format all source files with nimpretty (2-space indent)":
  ## Formats all .nim files in the project to a consistent style.
  exec "nimpretty --indent:2 src/sdl.nim src/sdl/*.nim tests/test_*.nim examples/*.nim"

task checkfmt, "Check formatting without modifying":
  ## Lists files that would be reformatted (exit code != 0 if any).
  exec "nimpretty --indent:2 --list src/sdl.nim src/sdl/*.nim tests/test_*.nim examples/*.nim"

task distclean, "Remove all build artifacts and generated files":
  exec "nim r scripts/distclean.nim"

task coverage, "Generate HTML coverage report (requires lcov, genhtml)":
  exec "nim r scripts/coverage.nim"
