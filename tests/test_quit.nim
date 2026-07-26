import std/unittest
import sdl/quit

# quitRequested() needs an initialized video subsystem.
suite "Quit":
  test "module imports cleanly":
    check true
