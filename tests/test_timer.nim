import std/unittest
import sdl/timer

{.push importc, cdecl, header: "SDL.h".}
proc SDL_Init(flags: uint32): cint
proc SDL_Quit()
{.pop.}

suite "Timer":
  test "getTicks returns > 0":
    discard SDL_Init(0x0000_0020'u32)  # SDL_INIT_TIMER
    let t = getTicks()
    SDL_Quit()
    check t > 0'u32

  test "delay aproximado":
    discard SDL_Init(0x0000_0020'u32)
    let t1 = getTicks()
    delay(50)
    let t2 = getTicks()
    SDL_Quit()
    check (t2 - t1) >= 45'u32
    check (t2 - t1) <= 100'u32
