import std/unittest
import sdl/keyboard
import sdl/keysym

suite "Keyboard":
  test "keyName":
    check $keyName(Key.escape) == "escape"
    check $keyName(Key.space) == "space"
    check $keyName(Key.a) == "a"

  test "initKeyInfo / getters":
    let ks = initKeyInfo(Key.escape)
    check ks.key == Key.escape
    check ks.mods == cast[KeyMods](0)
    check ks.unicode == 0'u16
    check ks.scanCode == 0'u8
