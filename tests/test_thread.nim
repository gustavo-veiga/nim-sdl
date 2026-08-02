import std/unittest
import sdl/thread

{.push importc, cdecl, header: "SDL.h".}
proc SDL_Init(flags: uint32): cint
proc SDL_Quit()
{.pop.}

suite "Thread":
  test "currentThreadId":
    let tid = currentThreadId()
    check tid != ThreadId(0'u32)
