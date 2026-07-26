import std/unittest
import sdl/thread

suite "Thread":
  test "currentThreadId":
    let tid = currentThreadId()
    check tid > 0'u32
