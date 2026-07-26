import std/unittest
import sdl/mutex

suite "Mutex":
  test "type sizes":
    check sizeof(Mutex) > 0
    check sizeof(Semaphore) > 0
    check sizeof(Condition) > 0
