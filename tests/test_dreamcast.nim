import std/unittest
import sdl/dreamcast

# Dreamcast-specific functions. Not testable on standard hardware.
suite "Dreamcast":
  test "module imports cleanly":
    check true
