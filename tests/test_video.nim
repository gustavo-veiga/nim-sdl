import std/unittest
import std/options
import sdl/video

suite "Video":
  test "Rect":
    let r = initRect(10, 20, 100, 200)
    check r.x == 10
    check r.y == 20
    check r.width == 100
    check r.height == 200

  test "Color: valores separados":
    let c = initColor(100, 150, 200)
    check c.r == 100
    check c.g == 150
    check c.b == 200

  test "Color: tuple":
    let c = initColor((r: 10'u8, g: 20'u8, b: 30'u8))
    check c.r == 10

  test "GammaRamp tamanho":
    var ramp: GammaRamp
    check ramp.len == 256

  test "ColorMask constantes":
    check maskRgb565.r == 0xF800'u32
    check maskRgb565.g == 0x07E0'u32
    check maskRgb565.b == 0x001F'u32

  test "ColorDepth valores":
    check ord(ColorDepth.desktop) == 0
    check ord(ColorDepth.bpp8)    == 8
    check ord(ColorDepth.bpp16)   == 16

  test "SurfaceFlag bitmask":
    let flags = SurfaceFlag.hwSurface or SurfaceFlag.doubleBuf
    check uint32(flags) == (0x00000001'u32 or 0x40000000'u32)

suite "Surface":
  setup:
    proc SDL_Init(flags: uint32): cint {.importc, header: "SDL.h".}
    proc SDL_Quit() {.importc, header: "SDL.h".}
    discard SDL_Init(0x00000020'u32)
  teardown:
    proc SDL_Quit() {.importc, header: "SDL.h".}
    SDL_Quit()

  test "createRgbSurface":
    let surf = createRgbSurface(100, 50)
    check surf.isSome

  test "propriedades":
    let surf = createRgbSurface(100, 50).get()
    check surf.width() == 100
    check surf.height() == 50

  test "fill":
    let s = createRgbSurface(10, 10).get()
    check s.fill(Pixel(0xFFFF0000'u32)) == true

  test "fill com Rect":
    let s = createRgbSurface(10, 10).get()
    let rect = initRect(0, 0, 5, 5)
    check s.fill(rect, Pixel(0xFFFFFFFF'u32)) == true

  test "toPixel":
    let s = createRgbSurface(10, 10).get()
    let c1 = s.toPixel(255, 0, 0)
    let c2 = s.toPixel((r: 255'u8, g: 0'u8, b: 0'u8))
    check c1 == c2

  test "toPixel (RGBA)":
    let s = createRgbSurface(10, 10).get()
    let rgba = s.toPixel(100, 150, 200, 128)
    check uint32(rgba) > 0

  test "lock/unlock":
    let s = createRgbSurface(10, 10).get()
    check s.lock() == true
    let pixels = s.pixels()
    check pixels.len > 0
    s.unlock()

  test "withLock":
    let s = createRgbSurface(10, 10).get()
    var ok = false
    discard s.withLock:
      ok = true
    check ok == true

  test "alpha":
    let s = createRgbSurface(10, 10).get()
    check s.`alpha=`(128) == true

  test "colorKey":
    let s = createRgbSurface(10, 10).get()
    check s.`colorKey=`((r: 0'u8, g: 0'u8, b: 0'u8)) == true
    check s.clearColorKey() == true

  test "clipRect":
    let s = createRgbSurface(10, 10).get()
    let rect = initRect(1, 1, 8, 8)
    check s.`clipRect=`(rect) == true
    let got = s.clipRect()
    check got.x == 1
    check got.width == 8

  test "blit":
    let src = createRgbSurface(10, 10).get()
    let dst = createRgbSurface(20, 20).get()
    check src.blit(dst) == true

  test "displayFormat":
    let s = createRgbSurface(10, 10).get()
    let conv = s.displayFormat()
    if conv.isSome:
      check conv.get().width() == 10
