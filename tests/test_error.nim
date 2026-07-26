import std/unittest
import sdl/error

suite "Error":
  test "setError / getError":
    setError("hello world")
    check $getError() == "hello world"

  test "clearError":
    setError("x")
    clearError()
    let e = getError()
    check e == nil or $e == ""

  test "multiple setError":
    setError("first")
    setError("second")
    check $getError() == "second"
