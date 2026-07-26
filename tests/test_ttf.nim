import std/unittest
import testutils

const hasSdlTtf = checkPkg("sdl_ttf")

when hasSdlTtf:
  import sdl/ttf

  suite "TTF":
    test "type":
      discard
else:
  suite "TTF":
    test "SKIP: SDL_ttf not installed (needed by sdl/ttf)":
      skip()
