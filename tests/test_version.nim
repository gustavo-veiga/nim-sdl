import std/unittest
import std/options
import sdl/version

suite "Version":
  test "sdlCompiledVersion":
    var buf: array[16, char]
    let v = sdlCompiledVersion()
    let s = $v.toCstring(buf)
    check s.len > 0
    check '.' in s

  test "sdlLinkedVersion":
    let v = sdlLinkedVersion()
    check v.isSome

  test "toCstring thread-safe":
    var buf: array[16, char]
    let cv = sdlCompiledVersion()
    let s = $cv.toCstring(buf)
    check s.len > 0
