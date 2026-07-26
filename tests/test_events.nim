import std/unittest
import sdl
import sdl/events

suite "Events":
  test "ButtonState enum":
    check ord(ButtonState.released) == 0
    check ord(ButtonState.pressed) == 1

  test "EventType enum values":
    check ord(EventType.noEvent) == 0
    check ord(EventType.keyDown) == 2
    check ord(EventType.keyUp) == 3
    check ord(EventType.mouseMotion) == 4
    check ord(EventType.quit) == 12

  test "createKeyEvent":
    let ev = createKeyEvent(Key.escape, pressed = true)
    check ev.key.keyInfo.key == Key.escape

  test "createKeyEvent with released":
    let ev = createKeyEvent(Key.a, pressed = false)
    check ev.key.keyInfo.key == Key.a

  test "pushEvent / pollEvent":
    proc SDL_Init(flags: uint32): cint {.importc, header: "SDL.h".}
    proc SDL_Quit() {.importc, header: "SDL.h".}
    discard SDL_Init(0x00000020'u32)
    let ev = createKeyEvent(Key.escape, pressed = true)
    check pushEvent(ev) == true
    var outEv: Event
    check pollEvent(outEv) == true
    check outEv.kind == EventType.keyDown
    check outEv.key.keyInfo.key == Key.escape
    SDL_Quit()
