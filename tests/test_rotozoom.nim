import std/unittest
import testutils

const hasSdlGfx = checkPkg("sdl_gfx")

when hasSdlGfx:
  import sdl/rotozoom

  suite "Rotozoom":
    test "type":
      discard
else:
  suite "Rotozoom":
    test "SKIP: SDL_gfx not installed (needed by sdl/rotozoom)":
      skip()
