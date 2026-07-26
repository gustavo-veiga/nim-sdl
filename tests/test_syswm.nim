import std/unittest
import sdl/syswm

# SysWM info requires an active window.
suite "SysWM":
  test "module imports cleanly":
    check true
