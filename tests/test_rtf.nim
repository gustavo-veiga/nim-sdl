import std/unittest
import testutils

const hasSdlRtf = checkPkg("sdl_rtf")

when hasSdlRtf:
  import sdl/rtf

  suite "Rtf":
    test "type":
      discard
else:
  suite "Rtf":
    test "SKIP: SDL_rtf not installed (needed by sdl/rtf)":
      skip()
