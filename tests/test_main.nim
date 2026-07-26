import std/unittest
import sdl/main

# main.nim provides runMain template and platform-specific procs.
# runMain wraps the application entry point and cannot be tested
# in a unit test context (it IS the main entry).
suite "Main":
  test "module imports cleanly":
    check true
