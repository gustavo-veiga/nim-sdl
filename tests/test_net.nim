import std/unittest
import testutils

const hasSdlNet = checkPkg("sdl_net")

when hasSdlNet:
  import sdl/net

  suite "Net":
    test "type":
      discard
else:
  suite "Net":
    test "SKIP: SDL_net not installed (needed by sdl/net)":
      skip()
