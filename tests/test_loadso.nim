import std/unittest
import std/options
import sdl/loadso

suite "LoadSO":
  test "type existence":
    check sizeof(SharedObject) > 0
