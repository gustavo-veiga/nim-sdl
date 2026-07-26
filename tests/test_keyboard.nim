import std/unittest
import sdl/keyboard
import sdl/keysym

suite "Keyboard":
  test "getKeyName":
    check $getKeyName(Key.escape) == "escape"
    check $getKeyName(Key.space) == "space"
    check $getKeyName(Key.a) == "a"

  test "initKeySym / getters":
    let ks = initKeySym(Key.escape)
    check ks.key == Key.escape
    check ks.mods == cast[KeyMods](0)
    check ks.unicode == 0'u16
    check ks.scanCode == 0'u8
