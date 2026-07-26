import std/unittest
import testutils

const hasSdlGfx = checkPkg("sdl_gfx")

when hasSdlGfx:
  import sdl/framerate

  suite "Framerate":
    test "initFpsManager / rate":
      var fps = initFpsManager(60)
      check fps.rate() == 60

    test "frameCount starts at 0":
      var fps = initFpsManager(30)
      check fps.frameCount() == 0

    test "delay returns":
      var fps = initFpsManager(60)
      let ret = fps.delay()
      check ret is bool
else:
  suite "Framerate":
    test "SKIP: SDL_gfx not installed (needed by sdl/framerate)":
      skip()
