import std/unittest
import testutils

const hasSdlPango = checkPkg("sdl_pango")

when hasSdlPango:
  import sdl/pango

  suite "Pango":
    test "type":
      discard
else:
  suite "Pango":
    test "SKIP: SDL_pango not installed (needed by sdl/pango)":
      skip()
