import std/unittest
import std/options
import sdl/audio

suite "Audio":
  test "AudioFormat enum":
    check uint16(AudioFormat.u8)     == 0x0008'u16
    check uint16(AudioFormat.s8)     == 0x8008'u16
    check uint16(AudioFormat.u16Lsb) == 0x0010'u16
    check uint16(AudioFormat.s16Lsb) == 0x8010'u16
    check uint16(AudioFormat.u16Msb) == 0x1010'u16
    check uint16(AudioFormat.s16Msb) == 0x9010'u16

  test "audioS16Sys existe":
    check uint16(audioS16Sys) in {0x8010'u16, 0x9010'u16}

  test "initAudioSpec / getters":
    let spec = initAudioSpec(44100, 2, 1024, audioS16Sys)
    check spec.freq() == 44100
    check spec.format() == audioS16Sys
    check spec.channels() == 2
    check spec.samples() == 1024

suite "Audio Conversion":
  setup:
    proc SDL_Init(flags: uint32): cint {.importc, header: "SDL.h".}
    proc SDL_Quit() {.importc, header: "SDL.h".}
    discard SDL_Init(0x00000010'u32)
  teardown:
    proc SDL_Quit() {.importc, header: "SDL.h".}
    SDL_Quit()

  test "44100 stereo s16 -> 22050 mono u8":
    let src = initAudioSpec(44100, 2, 1024, audioS16Sys)
    let dst = initAudioSpec(22050, 1, 1024, AudioFormat.u8)
    let cvt = createAudioConverter(src, dst)
    check cvt.isSome

  test "22050 mono -> 44100 stereo":
    let src = initAudioSpec(22050, 1, 1024, audioS16Sys)
    let dst = initAudioSpec(44100, 2, 1024, audioS16Sys)
    let cvt = createAudioConverter(src, dst)
    check cvt.isSome
    let c = cvt.get()
    check c.needed() == true
