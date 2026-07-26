import std/unittest
import sdl/core

suite "Core":
  test "InitFlag enum values":
    check uint32(InitFlag.timer)       == 0x00000001'u32
    check uint32(InitFlag.audio)       == 0x00000010'u32
    check uint32(InitFlag.video)       == 0x00000020'u32
    check uint32(InitFlag.cdrom)       == 0x00000100'u32
    check uint32(InitFlag.joystick)    == 0x00000200'u32
    check uint32(InitFlag.noParachute) == 0x00100000'u32
    check uint32(InitFlag.eventThread) == 0x01000000'u32

  test "InitFlag bitmask":
    let flags = InitFlag.video or InitFlag.audio
    check uint32(flags) == (0x00000020'u32 or 0x00000010'u32)

  test "initEverything":
    check uint32(initEverything) == 0x0000FFFF'u32

  test "sdlInit / exit":
    var guard = sdlInit(InitFlag.timer or InitFlag.cdrom)
    let active = wasInit()
    check uint32(active) != 0
    guard.quit()

  test "initSubSystem / quitSubSystem":
    proc SDL_Init(flags: uint32): cint {.importc, header: "SDL.h".}
    proc SDL_Quit() {.importc, header: "SDL.h".}
    check SDL_Init(0) == 0
    let f = InitFlags(uint32(InitFlag.timer))
    check initSubSystem(f) == true
    quitSubSystem(f)
    SDL_Quit()
