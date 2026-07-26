import std/unittest
import sdl/keysym

suite "KeySym":
  test "Key enum values":
    check ord(Key.unknown) == 0
    check ord(Key.a) == 97
    check ord(Key.escape) == 27
    check ord(Key.space) == 32
    check ord(Key.enter) == 13

  test "KeyModFlag enum values":
    check uint32(KeyModFlag.none)    == 0x0000'u32
    check uint32(KeyModFlag.lshift)  == 0x0001'u32
    check uint32(KeyModFlag.rshift)  == 0x0002'u32
    check uint32(KeyModFlag.lctrl)   == 0x0040'u32
    check uint32(KeyModFlag.rctrl)   == 0x0080'u32
    check uint32(KeyModFlag.lalt)    == 0x0100'u32
    check uint32(KeyModFlag.ralt)    == 0x0200'u32
    check uint32(KeyModFlag.lmeta)   == 0x0400'u32
    check uint32(KeyModFlag.rmeta)   == 0x0800'u32
    check uint32(KeyModFlag.num)     == 0x1000'u32
    check uint32(KeyModFlag.caps)    == 0x2000'u32
    check uint32(KeyModFlag.mode)    == 0x4000'u32
    check uint32(KeyModFlag.reserved)== 0x8000'u32

  test "mod consts":
    check uint32(modCtrl) == (0x0040'u32 or 0x0080'u32)
    check uint32(modShift) == (0x0001'u32 or 0x0002'u32)
    check uint32(modAlt) == (0x0100'u32 or 0x0200'u32)
    check uint32(modMeta) == (0x0400'u32 or 0x0800'u32)

  test "KeyMods bitmask":
    var km: KeyMods
    km = km or KeyModFlag.lshift
    km = km or KeyModFlag.lctrl
    check uint32(km) == (0x0001'u32 or 0x0040'u32)
