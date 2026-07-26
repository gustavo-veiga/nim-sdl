import std/unittest
import sdl/active

suite "Active":
  test "getAppState returns AppState":
    let s = getAppState()
    check typeof(s) is AppState
