import std/unittest
when defined(mixer):
  import sdl/mixer

suite "Mixer":
  when defined(mixer):
    test "AudioChannel / AudioGroup types":
      let ch = AudioChannel(0)
      check uint8(ch) == 0

    test "MixInitFlag enum":
      check uint32(MixInitFlag.flac)       == 0x00000001'u32
      check uint32(MixInitFlag.modType)    == 0x00000002'u32
      check uint32(MixInitFlag.mp3)        == 0x00000004'u32
      check uint32(MixInitFlag.ogg)        == 0x00000008'u32
      check uint32(MixInitFlag.fluidSynth) == 0x00000010'u32
