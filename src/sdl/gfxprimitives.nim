## # sdl/gfxprimitives
##
## Drawing primitives using SDL_gfx (pixel, line, circle, polygon, etc.)
##
## This module provides hardware-accelerated drawing primitives for SDL 1.2 surfaces
## through the SDL_gfx library. All functions support alpha blending and work on
## 8, 16, 24, and 32-bit surfaces.
##
## Each primitive comes in two variants:
## - `*Color`: accepts a packed 32-bit color in `0xRRGGBBAA` format
## - `*RGBA`: accepts individual r, g, b, a components (0-255 each)
##
## ## SDL 1.2 Reference
##
## SDL_gfx provides graphics primitives not available in core SDL 1.2, including
## anti-aliased lines, circles, ellipses, filled shapes, bezier curves, and text.
##
## **Key C functions:**
## ```c
## int SDL_pixelColor(SDL_Surface *dst, Sint16 x, Sint16 y, Uint32 color);
## int SDL_lineColor(SDL_Surface *dst, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color);
## int SDL_circleColor(SDL_Surface *dst, Sint16 x, Sint16 y, Sint16 rad, Uint32 color);
## int SDL_boxColor(SDL_Surface *dst, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color);
## ```
##
## ## Usage Example
##
## ```nim
## import sdl
##
## runMain:
##   let ctx = sdlInit(sdlInitVideo)
##   defer: ctx.quit()
##
##   let screen = setVideoMode(640, 480, 32, sdlSwSurface)
##
##   # Draw a red rectangle
##   screen.box(100, 100, 200, 200, 0xFF0000FF)
##
##   # Draw a blue circle with alpha
##   screen.circle(320, 240, 50, 0x0000FFFF)
##
##   # Draw an anti-aliased white line
##   screen.aaline(0, 0, 640, 480, 0xFFFFFFFF)
##   screen.flip()
## ```
##
## ## Requirements
##
## Compile with `-d:gfx` flag. Requires SDL_gfx library installed.
##
## ## See Also
##
## - `sdl/rotozoom` - Surface rotation and scaling
## - `sdl/framerate` - Frame rate control
## - `sdl/gfxfilter` - MMX-accelerated image filters

when defined(gfx):
  import private/utils
  import video

  {.push header: "SDL_gfxPrimitives.h", cdecl.}

  # --- Pixel ---
  proc SDL_pixelColor(dst: RawSurfacePtr, x: int16, y: int16, color: uint32): cint {.importc: "pixelColor".}
  proc SDL_pixelRGBA(dst: RawSurfacePtr, x: int16, y: int16, r: uint8, g: uint8, b: uint8, a: uint8): cint {.importc: "pixelRGBA".}

  # --- Horizontal line ---
  proc SDL_hlineColor(dst: RawSurfacePtr, x1: int16, x2: int16, y: int16, color: uint32): cint {.importc: "hlineColor".}
  proc SDL_hlineRGBA(dst: RawSurfacePtr, x1: int16, x2: int16, y: int16, r: uint8, g: uint8, b: uint8, a: uint8): cint {.importc: "hlineRGBA".}

  # --- Vertical line ---
  proc SDL_vlineColor(dst: RawSurfacePtr, x: int16, y1: int16, y2: int16, color: uint32): cint {.importc: "vlineColor".}
  proc SDL_vlineRGBA(dst: RawSurfacePtr, x: int16, y1: int16, y2: int16, r: uint8, g: uint8, b: uint8, a: uint8): cint {.importc: "vlineRGBA".}

  # --- Rectangle ---
  proc SDL_rectangleColor(dst: RawSurfacePtr, x1: int16, y1: int16, x2: int16, y2: int16, color: uint32): cint {.importc: "rectangleColor".}
  proc SDL_rectangleRGBA(dst: RawSurfacePtr, x1: int16, y1: int16, x2: int16, y2: int16, r: uint8, g: uint8, b: uint8, a: uint8): cint {.importc: "rectangleRGBA".}

  # --- Rounded rectangle ---
  proc SDL_roundedRectangleColor(dst: RawSurfacePtr, x1: int16, y1: int16, x2: int16, y2: int16, rad: int16, color: uint32): cint {.importc: "roundedRectangleColor".}
  proc SDL_roundedRectangleRGBA(dst: RawSurfacePtr, x1: int16, y1: int16, x2: int16, y2: int16, rad: int16, r: uint8, g: uint8, b: uint8, a: uint8): cint {.importc: "roundedRectangleRGBA".}

  # --- Filled rectangle (Box) ---
  proc SDL_boxColor(dst: RawSurfacePtr, x1: int16, y1: int16, x2: int16, y2: int16, color: uint32): cint {.importc: "boxColor".}
  proc SDL_boxRGBA(dst: RawSurfacePtr, x1: int16, y1: int16, x2: int16, y2: int16, r: uint8, g: uint8, b: uint8, a: uint8): cint {.importc: "boxRGBA".}

  # --- Rounded filled box ---
  proc SDL_roundedBoxColor(dst: RawSurfacePtr, x1: int16, y1: int16, x2: int16, y2: int16, rad: int16, color: uint32): cint {.importc: "roundedBoxColor".}
  proc SDL_roundedBoxRGBA(dst: RawSurfacePtr, x1: int16, y1: int16, x2: int16, y2: int16, rad: int16, r: uint8, g: uint8, b: uint8, a: uint8): cint {.importc: "roundedBoxRGBA".}

  # --- Line ---
  proc SDL_lineColor(dst: RawSurfacePtr, x1: int16, y1: int16, x2: int16, y2: int16, color: uint32): cint {.importc: "lineColor".}
  proc SDL_lineRGBA(dst: RawSurfacePtr, x1: int16, y1: int16, x2: int16, y2: int16, r: uint8, g: uint8, b: uint8, a: uint8): cint {.importc: "lineRGBA".}

  # --- AA Line ---
  proc SDL_aalineColor(dst: RawSurfacePtr, x1: int16, y1: int16, x2: int16, y2: int16, color: uint32): cint {.importc: "aalineColor".}
  proc SDL_aalineRGBA(dst: RawSurfacePtr, x1: int16, y1: int16, x2: int16, y2: int16, r: uint8, g: uint8, b: uint8, a: uint8): cint {.importc: "aalineRGBA".}

  # --- Thick Line ---
  proc SDL_thickLineColor(dst: RawSurfacePtr, x1: int16, y1: int16, x2: int16, y2: int16, width: uint8, color: uint32): cint {.importc: "thickLineColor".}
  proc SDL_thickLineRGBA(dst: RawSurfacePtr, x1: int16, y1: int16, x2: int16, y2: int16, width: uint8, r: uint8, g: uint8, b: uint8, a: uint8): cint {.importc: "thickLineRGBA".}

  # --- Circle ---
  proc SDL_circleColor(dst: RawSurfacePtr, x: int16, y: int16, rad: int16, color: uint32): cint {.importc: "circleColor".}
  proc SDL_circleRGBA(dst: RawSurfacePtr, x: int16, y: int16, rad: int16, r: uint8, g: uint8, b: uint8, a: uint8): cint {.importc: "circleRGBA".}

  # --- Arc ---
  proc SDL_arcColor(dst: RawSurfacePtr, x: int16, y: int16, rad: int16, angleStart: int16, angleEnd: int16, color: uint32): cint {.importc: "arcColor".}
  proc SDL_arcRGBA(dst: RawSurfacePtr, x: int16, y: int16, rad: int16, angleStart: int16, angleEnd: int16, r: uint8, g: uint8, b: uint8, a: uint8): cint {.importc: "arcRGBA".}

  # --- AA Circle ---
  proc SDL_aacircleColor(dst: RawSurfacePtr, x: int16, y: int16, rad: int16, color: uint32): cint {.importc: "aacircleColor".}
  proc SDL_aacircleRGBA(dst: RawSurfacePtr, x: int16, y: int16, rad: int16, r: uint8, g: uint8, b: uint8, a: uint8): cint {.importc: "aacircleRGBA".}

  # --- Filled Circle ---
  proc SDL_filledCircleColor(dst: RawSurfacePtr, x: int16, y: int16, rad: int16, color: uint32): cint {.importc: "filledCircleColor".}
  proc SDL_filledCircleRGBA(dst: RawSurfacePtr, x: int16, y: int16, rad: int16, r: uint8, g: uint8, b: uint8, a: uint8): cint {.importc: "filledCircleRGBA".}

  # --- Ellipse ---
  proc SDL_ellipseColor(dst: RawSurfacePtr, x: int16, y: int16, rx: int16, ry: int16, color: uint32): cint {.importc: "ellipseColor".}
  proc SDL_ellipseRGBA(dst: RawSurfacePtr, x: int16, y: int16, rx: int16, ry: int16, r: uint8, g: uint8, b: uint8, a: uint8): cint {.importc: "ellipseRGBA".}

  # --- AA Ellipse ---
  proc SDL_aaellipseColor(dst: RawSurfacePtr, x: int16, y: int16, rx: int16, ry: int16, color: uint32): cint {.importc: "aaellipseColor".}
  proc SDL_aaellipseRGBA(dst: RawSurfacePtr, x: int16, y: int16, rx: int16, ry: int16, r: uint8, g: uint8, b: uint8, a: uint8): cint {.importc: "aaellipseRGBA".}

  # --- Filled Ellipse ---
  proc SDL_filledEllipseColor(dst: RawSurfacePtr, x: int16, y: int16, rx: int16, ry: int16, color: uint32): cint {.importc: "filledEllipseColor".}
  proc SDL_filledEllipseRGBA(dst: RawSurfacePtr, x: int16, y: int16, rx: int16, ry: int16, r: uint8, g: uint8, b: uint8, a: uint8): cint {.importc: "filledEllipseRGBA".}

  # --- Pie ---
  proc SDL_pieColor(dst: RawSurfacePtr, x: int16, y: int16, rad: int16, angleStart: int16, angleEnd: int16, color: uint32): cint {.importc: "pieColor".}
  proc SDL_pieRGBA(dst: RawSurfacePtr, x: int16, y: int16, rad: int16, angleStart: int16, angleEnd: int16, r: uint8, g: uint8, b: uint8, a: uint8): cint {.importc: "pieRGBA".}

  # --- Filled Pie ---
  proc SDL_filledPieColor(dst: RawSurfacePtr, x: int16, y: int16, rad: int16, angleStart: int16, angleEnd: int16, color: uint32): cint {.importc: "filledPieColor".}
  proc SDL_filledPieRGBA(dst: RawSurfacePtr, x: int16, y: int16, rad: int16, angleStart: int16, angleEnd: int16, r: uint8, g: uint8, b: uint8, a: uint8): cint {.importc: "filledPieRGBA".}

  # --- Trigon ---
  proc SDL_trigonColor(dst: RawSurfacePtr, x1: int16, y1: int16, x2: int16, y2: int16, x3: int16, y3: int16, color: uint32): cint {.importc: "trigonColor".}
  proc SDL_trigonRGBA(dst: RawSurfacePtr, x1: int16, y1: int16, x2: int16, y2: int16, x3: int16, y3: int16, r: uint8, g: uint8, b: uint8, a: uint8): cint {.importc: "trigonRGBA".}

  # --- AA Trigon ---
  proc SDL_aatrigonColor(dst: RawSurfacePtr, x1: int16, y1: int16, x2: int16, y2: int16, x3: int16, y3: int16, color: uint32): cint {.importc: "aatrigonColor".}
  proc SDL_aatrigonRGBA(dst: RawSurfacePtr, x1: int16, y1: int16, x2: int16, y2: int16, x3: int16, y3: int16, r: uint8, g: uint8, b: uint8, a: uint8): cint {.importc: "aatrigonRGBA".}

  # --- Filled Trigon ---
  proc SDL_filledTrigonColor(dst: RawSurfacePtr, x1: int16, y1: int16, x2: int16, y2: int16, x3: int16, y3: int16, color: uint32): cint {.importc: "filledTrigonColor".}
  proc SDL_filledTrigonRGBA(dst: RawSurfacePtr, x1: int16, y1: int16, x2: int16, y2: int16, x3: int16, y3: int16, r: uint8, g: uint8, b: uint8, a: uint8): cint {.importc: "filledTrigonRGBA".}

  # --- Polygon ---
  proc SDL_polygonColor(dst: RawSurfacePtr, vx: ptr int16, vy: ptr int16, n: cint, color: uint32): cint {.importc: "polygonColor".}
  proc SDL_polygonRGBA(dst: RawSurfacePtr, vx: ptr int16, vy: ptr int16, n: cint, r: uint8, g: uint8, b: uint8, a: uint8): cint {.importc: "polygonRGBA".}

  # --- AA Polygon ---
  proc SDL_aapolygonColor(dst: RawSurfacePtr, vx: ptr int16, vy: ptr int16, n: cint, color: uint32): cint {.importc: "aapolygonColor".}
  proc SDL_aapolygonRGBA(dst: RawSurfacePtr, vx: ptr int16, vy: ptr int16, n: cint, r: uint8, g: uint8, b: uint8, a: uint8): cint {.importc: "aapolygonRGBA".}

  # --- Filled Polygon ---
  proc SDL_filledPolygonColor(dst: RawSurfacePtr, vx: ptr int16, vy: ptr int16, n: cint, color: uint32): cint {.importc: "filledPolygonColor".}
  proc SDL_filledPolygonRGBA(dst: RawSurfacePtr, vx: ptr int16, vy: ptr int16, n: cint, r: uint8, g: uint8, b: uint8, a: uint8): cint {.importc: "filledPolygonRGBA".}
  proc SDL_texturedPolygon(dst: RawSurfacePtr, vx: ptr int16, vy: ptr int16, n: cint, texture: RawSurfacePtr, textureDx: cint, textureDy: cint): cint {.importc: "texturedPolygon".}

  # --- MT Polygon ---
  proc SDL_filledPolygonColorMT(dst: RawSurfacePtr, vx: ptr int16, vy: ptr int16, n: cint, color: uint32, polyInts: ptr pointer, polyAllocated: ptr cint): cint {.importc: "filledPolygonColorMT".}
  proc SDL_filledPolygonRGBAMT(dst: RawSurfacePtr, vx: ptr int16, vy: ptr int16, n: cint, r: uint8, g: uint8, b: uint8, a: uint8, polyInts: ptr pointer, polyAllocated: ptr cint): cint {.importc: "filledPolygonRGBAMT".}
  proc SDL_texturedPolygonMT(dst: RawSurfacePtr, vx: ptr int16, vy: ptr int16, n: cint, texture: RawSurfacePtr, textureDx: cint, textureDy: cint, polyInts: ptr pointer, polyAllocated: ptr cint): cint {.importc: "texturedPolygonMT".}

  # --- Bezier ---
  proc SDL_bezierColor(dst: RawSurfacePtr, vx: ptr int16, vy: ptr int16, n: cint, s: cint, color: uint32): cint {.importc: "bezierColor".}
  proc SDL_bezierRGBA(dst: RawSurfacePtr, vx: ptr int16, vy: ptr int16, n: cint, s: cint, r: uint8, g: uint8, b: uint8, a: uint8): cint {.importc: "bezierRGBA".}

  # --- Characters/Strings ---
  proc SDL_gfxPrimitivesSetFont(fontdata: pointer, cw: uint32, ch: uint32) {.importc: "gfxPrimitivesSetFont".}
  proc SDL_gfxPrimitivesSetFontRotation(rotation: uint32) {.importc: "gfxPrimitivesSetFontRotation".}
  proc SDL_characterColor(dst: RawSurfacePtr, x: int16, y: int16, c: char, color: uint32): cint {.importc: "characterColor".}
  proc SDL_characterRGBA(dst: RawSurfacePtr, x: int16, y: int16, c: char, r: uint8, g: uint8, b: uint8, a: uint8): cint {.importc: "characterRGBA".}
  proc SDL_stringColor(dst: RawSurfacePtr, x: int16, y: int16, s: cstring, color: uint32): cint {.importc: "stringColor".}
  proc SDL_stringRGBA(dst: RawSurfacePtr, x: int16, y: int16, s: cstring, r: uint8, g: uint8, b: uint8, a: uint8): cint {.importc: "stringRGBA".}

  {.pop.}


  # =========================================================
  # PUBLIC API (method-style on AnySurface)
  # =========================================================

  # --- Pixel ---

  proc pixel*(surface: AnySurface; x, y: int; color: uint32): bool {.inline.} =
    ## Draws a single pixel at the given coordinates.
    ##
    ## **Note:** This is the lowest-level drawing primitive. All other shapes
    ## are composed of individual pixels. Performance is best on 32-bit surfaces.
    sdlOk SDL_pixelColor(surface.raw, int16(x), int16(y), color)

  proc pixel*(surface: AnySurface; x, y: int; r, g, b: int; a: int = 255): bool {.inline.} =
    ## Component overload of `pixel`.
    sdlOk SDL_pixelRGBA(surface.raw, int16(x), int16(y), uint8(r), uint8(g), uint8(b), uint8(a))

  # --- Horizontal / Vertical lines ---

  proc hline*(surface: AnySurface; x1, x2, y: int; color: uint32): bool {.inline.} =
    ## Draws a horizontal line from (`x1`, `y`) to (`x2`, `y`).
    ##
    ## **Note:** This is faster than drawing individual pixels for each point
    ## on the line. Works on 8, 16, 24, and 32-bit surfaces.
    sdlOk SDL_hlineColor(surface.raw, int16(x1), int16(x2), int16(y), color)

  proc hline*(surface: AnySurface; x1, x2, y: int; r, g, b: int; a: int = 255): bool {.inline.} =
    ## Component overload of `hline`.
    sdlOk SDL_hlineRGBA(surface.raw, int16(x1), int16(x2), int16(y), uint8(r), uint8(g), uint8(b), uint8(a))

  proc vline*(surface: AnySurface; x, y1, y2: int; color: uint32): bool {.inline.} =
    ## Draws a vertical line from (`x`, `y1`) to (`x`, `y2`).
    ##
    ## **Note:** Optimized for vertical strokes. Use this instead of `line`
    ## when drawing axis-aligned vertical segments.
    sdlOk SDL_vlineColor(surface.raw, int16(x), int16(y1), int16(y2), color)

  proc vline*(surface: AnySurface; x, y1, y2: int; r, g, b: int; a: int = 255): bool {.inline.} =
    ## Component overload of `vline`.
    sdlOk SDL_vlineRGBA(surface.raw, int16(x), int16(y1), int16(y2), uint8(r), uint8(g), uint8(b), uint8(a))

  # --- Rectangles ---

  proc rect*(surface: AnySurface; x1, y1, x2, y2: int; color: uint32): bool {.inline.} =
    ## Draws a rectangular outline.
    ##
    ## The rectangle spans from the top-left corner (`x1`, `y1`) to the
    ## bottom-right corner (`x2`, `y2`), inclusive.
    ##
    ## **Note:** For a filled rectangle, use `box()` instead.
    sdlOk SDL_rectangleColor(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), color)

  proc rect*(surface: AnySurface; x1, y1, x2, y2: int; r, g, b: int; a: int = 255): bool {.inline.} =
    ## Component overload of `rect`.
    sdlOk SDL_rectangleRGBA(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), uint8(r), uint8(g), uint8(b), uint8(a))

  proc roundedRect*(surface: AnySurface; x1, y1, x2, y2, rad: int; color: uint32): bool {.inline.} =
    ## Draws a rectangle outline with rounded corners.
    ##
    ## `rad` controls the corner radius in pixels. Larger values produce
    ## more rounded corners.
    sdlOk SDL_roundedRectangleColor(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), int16(rad), color)

  proc roundedRect*(surface: AnySurface; x1, y1, x2, y2, rad: int; r, g, b: int; a: int = 255): bool {.inline.} =
    ## Component overload of `roundedRect`.
    sdlOk SDL_roundedRectangleRGBA(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), int16(rad), uint8(r), uint8(g), uint8(b), uint8(a))

  proc box*(surface: AnySurface; x1, y1, x2, y2: int; color: uint32): bool {.inline.} =
    ## Draws a filled rectangle (solid box).
    ##
    ## Fills the area from (`x1`, `y1`) to (`x2`, `y2`), inclusive.
    ## This is the filled counterpart of `rect()`.
    sdlOk SDL_boxColor(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), color)

  proc box*(surface: AnySurface; x1, y1, x2, y2: int; r, g, b: int; a: int = 255): bool {.inline.} =
    ## Component overload of `box`.
    sdlOk SDL_boxRGBA(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), uint8(r), uint8(g), uint8(b), uint8(a))

  proc roundedBox*(surface: AnySurface; x1, y1, x2, y2, rad: int; color: uint32): bool {.inline.} =
    ## Draws a filled rectangle with rounded corners.
    ##
    ## `rad` controls the corner radius. This is the filled counterpart
    ## of `roundedRect()`.
    sdlOk SDL_roundedBoxColor(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), int16(rad), color)

  proc roundedBox*(surface: AnySurface; x1, y1, x2, y2, rad: int; r, g, b: int; a: int = 255): bool {.inline.} =
    ## Component overload of `roundedBox`.
    sdlOk SDL_roundedBoxRGBA(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), int16(rad), uint8(r), uint8(g), uint8(b), uint8(a))

  # --- Lines ---

  proc line*(surface: AnySurface; x1, y1, x2, y2: int; color: uint32): bool {.inline.} =
    ## Draws a line between two points using Bresenham's algorithm.
    ##
    ## **Note:** The line is not anti-aliased. For smooth lines, use `lineAA()`.
    sdlOk SDL_lineColor(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), color)

  proc line*(surface: AnySurface; x1, y1, x2, y2: int; r, g, b: int; a: int = 255): bool {.inline.} =
    ## Component overload of `line`.
    sdlOk SDL_lineRGBA(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), uint8(r), uint8(g), uint8(b), uint8(a))

  proc lineAA*(surface: AnySurface; x1, y1, x2, y2: int; color: uint32): bool {.inline.} =
    ## Draws an anti-aliased (smooth) line between two points.
    ##
    ## Anti-aliasing reduces jagged edges by blending the line color with
    ## the background. Slightly slower than `line()`.
    sdlOk SDL_aalineColor(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), color)

  proc lineAA*(surface: AnySurface; x1, y1, x2, y2: int; r, g, b: int; a: int = 255): bool {.inline.} =
    ## Component overload of `lineAA`.
    sdlOk SDL_aalineRGBA(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), uint8(r), uint8(g), uint8(b), uint8(a))

  proc thickLine*(surface: AnySurface; x1, y1, x2, y2: int; width: int; color: uint32): bool {.inline.} =
    ## Draws a line with a specified thickness.
    ##
    ## `width` controls the line thickness in pixels. Unlike `line()`, this
    ## draws a line wide enough to be visible at any scale.
    sdlOk SDL_thickLineColor(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), uint8(width), color)

  proc thickLine*(surface: AnySurface; x1, y1, x2, y2, width: int; r, g, b: int; a: int = 255): bool {.inline.} =
    ## Component overload of `thickLine`.
    sdlOk SDL_thickLineRGBA(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), uint8(width), uint8(r), uint8(g), uint8(b), uint8(a))

  # --- Circles ---

  proc circle*(surface: AnySurface; x, y, rad: int; color: uint32): bool {.inline.} =
    ## Draws a circle outline centered at (`x`, `y`) with the given radius.
    ##
    ## **Note:** For filled circles, use `filledCircle()`. For smoother edges,
    ## use `aacircle()`.
    sdlOk SDL_circleColor(surface.raw, int16(x), int16(y), int16(rad), color)

  proc circle*(surface: AnySurface; x, y, rad: int; r, g, b: int; a: int = 255): bool {.inline.} =
    ## Component overload of `circle`.
    sdlOk SDL_circleRGBA(surface.raw, int16(x), int16(y), int16(rad), uint8(r), uint8(g), uint8(b), uint8(a))

  proc circleAA*(surface: AnySurface; x, y, rad: int; color: uint32): bool {.inline.} =
    ## Draws an anti-aliased circle outline with smoother edges.
    ##
    ## **Note:** Slightly slower than `circle()` but produces visually
    ## superior results, especially at small radii.
    sdlOk SDL_aacircleColor(surface.raw, int16(x), int16(y), int16(rad), color)

  proc circleAA*(surface: AnySurface; x, y, rad: int; r, g, b: int; a: int = 255): bool {.inline.} =
    ## Component overload of `circleAA`.
    sdlOk SDL_aacircleRGBA(surface.raw, int16(x), int16(y), int16(rad), uint8(r), uint8(g), uint8(b), uint8(a))

  proc filledCircle*(surface: AnySurface; x, y, rad: int; color: uint32): bool {.inline.} =
    ## Draws a filled (solid) circle.
    ##
    ## The circle is centered at (`x`, `y`) with the given radius.
    sdlOk SDL_filledCircleColor(surface.raw, int16(x), int16(y), int16(rad), color)

  proc filledCircle*(surface: AnySurface; x, y, rad: int; r, g, b: int; a: int = 255): bool {.inline.} =
    ## Component overload of `filledCircle`.
    sdlOk SDL_filledCircleRGBA(surface.raw, int16(x), int16(y), int16(rad), uint8(r), uint8(g), uint8(b), uint8(a))

  # --- Ellipses ---

  proc ellipse*(surface: AnySurface; x, y, rx, ry: int; color: uint32): bool {.inline.} =
    ## Draws an ellipse outline centered at (`x`, `y`).
    ##
    ## `rx` controls the horizontal radius, `ry` the vertical radius.
    sdlOk SDL_ellipseColor(surface.raw, int16(x), int16(y), int16(rx), int16(ry), color)

  proc ellipse*(surface: AnySurface; x, y, rx, ry: int; r, g, b: int; a: int = 255): bool {.inline.} =
    ## Component overload of `ellipse`.
    sdlOk SDL_ellipseRGBA(surface.raw, int16(x), int16(y), int16(rx), int16(ry), uint8(r), uint8(g), uint8(b), uint8(a))

  proc ellipseAA*(surface: AnySurface; x, y, rx, ry: int; color: uint32): bool {.inline.} =
    ## Draws an anti-aliased ellipse outline with smoother edges.
    sdlOk SDL_aaellipseColor(surface.raw, int16(x), int16(y), int16(rx), int16(ry), color)

  proc ellipseAA*(surface: AnySurface; x, y, rx, ry: int; r, g, b: int; a: int = 255): bool {.inline.} =
    ## Component overload of `aaellipse`.
    sdlOk SDL_aaellipseRGBA(surface.raw, int16(x), int16(y), int16(rx), int16(ry), uint8(r), uint8(g), uint8(b), uint8(a))

  proc filledEllipse*(surface: AnySurface; x, y, rx, ry: int; color: uint32): bool {.inline.} =
    ## Draws a filled (solid) ellipse.
    sdlOk SDL_filledEllipseColor(surface.raw, int16(x), int16(y), int16(rx), int16(ry), color)

  proc filledEllipse*(surface: AnySurface; x, y, rx, ry: int; r, g, b: int; a: int = 255): bool {.inline.} =
    ## Component overload of `filledEllipse`.
    sdlOk SDL_filledEllipseRGBA(surface.raw, int16(x), int16(y), int16(rx), int16(ry), uint8(r), uint8(g), uint8(b), uint8(a))

  # --- Arcs / Pies ---

  proc arc*(surface: AnySurface; x, y, rad, startAngle, endAngle: int; color: uint32): bool {.inline.} =
    ## Draws an arc (partial circle segment) from `startAngle` to `endAngle`.
    ##
    ## Angles are specified in degrees, with 0° pointing right and increasing
    ## clockwise.
    sdlOk SDL_arcColor(surface.raw, int16(x), int16(y), int16(rad), int16(startAngle), int16(endAngle), color)

  proc arc*(surface: AnySurface; x, y, rad, startAngle, endAngle: int; r, g, b: int; a: int = 255): bool {.inline.} =
    ## Component overload of `arc`.
    sdlOk SDL_arcRGBA(surface.raw, int16(x), int16(y), int16(rad), int16(startAngle), int16(endAngle), uint8(r), uint8(g), uint8(b), uint8(a))

  proc pie*(surface: AnySurface; x, y, rad, startAngle, endAngle: int; color: uint32): bool {.inline.} =
    ## Draws a pie-shaped wedge (outline) from `startAngle` to `endAngle`.
    ##
    ## A pie is an arc with straight lines connecting the endpoints to the center.
    sdlOk SDL_pieColor(surface.raw, int16(x), int16(y), int16(rad), int16(startAngle), int16(endAngle), color)

  proc pie*(surface: AnySurface; x, y, rad, startAngle, endAngle: int; r, g, b: int; a: int = 255): bool {.inline.} =
    ## Component overload of `pie`.
    sdlOk SDL_pieRGBA(surface.raw, int16(x), int16(y), int16(rad), int16(startAngle), int16(endAngle), uint8(r), uint8(g), uint8(b), uint8(a))

  proc filledPie*(surface: AnySurface; x, y, rad, startAngle, endAngle: int; color: uint32): bool {.inline.} =
    ## Draws a filled pie-shaped wedge.
    ##
    ## The wedge is filled from the center point (`x`, `y`) out to the arc.
    sdlOk SDL_filledPieColor(surface.raw, int16(x), int16(y), int16(rad), int16(startAngle), int16(endAngle), color)

  proc filledPie*(surface: AnySurface; x, y, rad, startAngle, endAngle: int; r, g, b: int; a: int = 255): bool {.inline.} =
    ## Component overload of `filledPie`.
    sdlOk SDL_filledPieRGBA(surface.raw, int16(x), int16(y), int16(rad), int16(startAngle), int16(endAngle), uint8(r), uint8(g), uint8(b), uint8(a))

  # --- Triangles ---

  proc trigon*(surface: AnySurface; x1, y1, x2, y2, x3, y3: int; color: uint32): bool {.inline.} =
    ## Draws a triangle outline connecting three points.
    ##
    ## The three vertices are specified as (`x1`, `y1`), (`x2`, `y2`), (`x3`, `y3`).
    sdlOk SDL_trigonColor(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), int16(x3), int16(y3), color)

  proc trigon*(surface: AnySurface; x1, y1, x2, y2, x3, y3: int; r, g, b: int; a: int = 255): bool {.inline.} =
    ## Component overload of `trigon`.
    sdlOk SDL_trigonRGBA(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), int16(x3), int16(y3), uint8(r), uint8(g), uint8(b), uint8(a))

  proc trigonAA*(surface: AnySurface; x1, y1, x2, y2, x3, y3: int; color: uint32): bool {.inline.} =
    ## Draws an anti-aliased triangle outline.
    sdlOk SDL_aatrigonColor(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), int16(x3), int16(y3), color)

  proc trigonAA*(surface: AnySurface; x1, y1, x2, y2, x3, y3: int; r, g, b: int; a: int = 255): bool {.inline.} =
    ## Component overload of `aatrigon`.
    sdlOk SDL_aatrigonRGBA(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), int16(x3), int16(y3), uint8(r), uint8(g), uint8(b), uint8(a))

  proc filledTrigon*(surface: AnySurface; x1, y1, x2, y2, x3, y3: int; color: uint32): bool {.inline.} =
    ## Draws a filled (solid) triangle.
    sdlOk SDL_filledTrigonColor(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), int16(x3), int16(y3), color)

  proc filledTrigon*(surface: AnySurface; x1, y1, x2, y2, x3, y3: int; r, g, b: int; a: int = 255): bool {.inline.} =
    ## Component overload of `filledTrigon`.
    sdlOk SDL_filledTrigonRGBA(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), int16(x3), int16(y3), uint8(r), uint8(g), uint8(b), uint8(a))

  # --- Polygons ---

  proc polygon*(surface: AnySurface; vx, vy: openArray[int16]; color: uint32): bool {.inline.} =
    ## Draws a polygon outline from arrays of vertex coordinates.
    ##
    ## `vx` and `vy` must contain the x and y coordinates of each vertex.
    ## The polygon is automatically closed (last vertex connects to first).
    ##
    ## **Example:** `screen.polygon([0'i16, 100, 50], [0, 0, 100], 0xFF0000FF)`
    sdlOk SDL_polygonColor(surface.raw, addr vx[0], addr vy[0], cint(vx.len), color)

  proc polygon*(surface: AnySurface; vx, vy: openArray[int16]; r, g, b: int; a: int = 255): bool {.inline.} =
    ## Component overload of `polygon`.
    sdlOk SDL_polygonRGBA(surface.raw, addr vx[0], addr vy[0], cint(vx.len), uint8(r), uint8(g), uint8(b), uint8(a))

  proc polygonAA*(surface: AnySurface; vx, vy: openArray[int16]; color: uint32): bool {.inline.} =
    ## Draws an anti-aliased polygon outline.
    sdlOk SDL_aapolygonColor(surface.raw, addr vx[0], addr vy[0], cint(vx.len), color)

  proc polygonAA*(surface: AnySurface; vx, vy: openArray[int16]; r, g, b: int; a: int = 255): bool {.inline.} =
    ## Component overload of `polygonAA`.
    sdlOk SDL_aapolygonRGBA(surface.raw, addr vx[0], addr vy[0], cint(vx.len), uint8(r), uint8(g), uint8(b), uint8(a))

  proc filledPolygon*(surface: AnySurface; vx, vy: openArray[int16]; color: uint32): bool {.inline.} =
    ## Draws a filled (solid) polygon.
    ##
    ## **Note:** The polygon must be simple (non-self-intersecting) for
    ## correct filling.
    sdlOk SDL_filledPolygonColor(surface.raw, addr vx[0], addr vy[0], cint(vx.len), color)

  proc filledPolygon*(surface: AnySurface; vx, vy: openArray[int16]; r, g, b: int; a: int = 255): bool {.inline.} =
    ## Component overload of `filledPolygon`.
    sdlOk SDL_filledPolygonRGBA(surface.raw, addr vx[0], addr vy[0], cint(vx.len), uint8(r), uint8(g), uint8(b), uint8(a))

  proc polygonTextured*(surface: AnySurface; vx, vy: openArray[int16]; texture: AnySurface; textureDx, textureDy: int): bool {.inline.} =
    ## Draws a polygon filled with a texture instead of a solid color.
    ##
    ## `textureDx` and `textureDy` offset the texture mapping within the polygon.
    ## **Note:** The texture must be a valid surface with the same pixel format
    ## as the destination.
    sdlOk SDL_texturedPolygon(surface.raw, addr vx[0], addr vy[0], cint(vx.len), texture.raw, cint(textureDx), cint(textureDy))

  proc filledPolygonMT*(surface: AnySurface; vx, vy: openArray[int16]; color: uint32; polyInts: var pointer; polyAllocated: var cint): bool {.inline.} =
    ## Filled polygon using pre-allocated intersection tables (multi-thread safe).
    ##
    ## `polyInts` and `polyAllocated` are scratch buffers reused across calls.
    ## **Note:** Pass the same `polyInts`/`polyAllocated` pairs to avoid repeated
    ## allocation when drawing multiple polygons.
    sdlOk SDL_filledPolygonColorMT(surface.raw, addr vx[0], addr vy[0], cint(vx.len), color, addr polyInts, addr polyAllocated)

  proc filledPolygonMT*(surface: AnySurface; vx, vy: openArray[int16]; r, g, b: int; a: int = 255; polyInts: var pointer; polyAllocated: var cint): bool {.inline.} =
    ## Component overload of `filledPolygonMT`.
    sdlOk SDL_filledPolygonRGBAMT(surface.raw, addr vx[0], addr vy[0], cint(vx.len), uint8(r), uint8(g), uint8(b), uint8(a), addr polyInts, addr polyAllocated)

  proc polygonTexturedMT*(surface: AnySurface; vx, vy: openArray[int16]; texture: AnySurface; textureDx, textureDy: int; polyInts: var pointer; polyAllocated: var cint): bool {.inline.} =
    ## Multi-thread safe textured polygon with pre-allocated intersection tables.
    sdlOk SDL_texturedPolygonMT(surface.raw, addr vx[0], addr vy[0], cint(vx.len), texture.raw, cint(textureDx), cint(textureDy), addr polyInts, addr polyAllocated)

  # --- Bezier ---

  proc bezier*(surface: AnySurface; vx, vy: openArray[int16]; s: int; color: uint32): bool {.inline.} =
    ## Draws a Bezier curve from control points.
    ##
    ## `s` controls the number of interpolation steps (higher = smoother curve).
    ## Typical values range from 3 to 20.
    sdlOk SDL_bezierColor(surface.raw, addr vx[0], addr vy[0], cint(vx.len), cint(s), color)

  proc bezier*(surface: AnySurface; vx, vy: openArray[int16]; s: int; r, g, b: int; a: int = 255): bool {.inline.} =
    ## Component overload of `bezier`.
    sdlOk SDL_bezierRGBA(surface.raw, addr vx[0], addr vy[0], cint(vx.len), cint(s), uint8(r), uint8(g), uint8(b), uint8(a))

  # --- Font control ---

  proc setGfxFont*(fontdata: pointer; charWidth, charHeight: uint32) {.inline.} =
    ## Sets a custom bitmap font for `character()` and `string()` drawing.
    ##
    ## `fontdata` points to a raw bitmap font, `charWidth` and `charHeight`
    ## specify the dimensions of each glyph in pixels.
    SDL_gfxPrimitivesSetFont(fontdata, charWidth, charHeight)

  proc setGfxFontRotation*(rotation: uint32) {.inline.} =
    ## Sets the font rotation for `character()` and `string()`.
    ##
    ## Valid values are 0, 90, 180, and 270 degrees.
    SDL_gfxPrimitivesSetFontRotation(rotation)

  # --- Text ---

  proc character*(surface: AnySurface; x, y: int; ch: char; color: uint32): bool {.inline.} =
    ## Draws a single bitmap character at (`x`, `y`).
    ##
    ## Uses the font set by `setGfxFont()`. Defaults to a built-in font.
    sdlOk SDL_characterColor(surface.raw, int16(x), int16(y), ch, color)

  proc character*(surface: AnySurface; x, y: int; ch: char; r, g, b: int; a: int = 255): bool {.inline.} =
    ## Component overload of `character`.
    sdlOk SDL_characterRGBA(surface.raw, int16(x), int16(y), ch, uint8(r), uint8(g), uint8(b), uint8(a))

  proc string*(surface: AnySurface; x, y: int; s: string; color: uint32): bool {.inline.} =
    ## Draws a bitmap text string at (`x`, `y`).
    ##
    ## Uses the font set by `setGfxFont()`. The string is drawn character by
    ## character at the current font's character width spacing.
    ##
    ## **Note:** This is not a TrueType renderer. For TTF text, use `sdl/ttf`.
    sdlOk SDL_stringColor(surface.raw, int16(x), int16(y), cstring(s), color)

  proc string*(surface: AnySurface; x, y: int; s: string; r, g, b: int; a: int = 255): bool {.inline.} =
    ## Component overload of `string`.
    sdlOk SDL_stringRGBA(surface.raw, int16(x), int16(y), cstring(s), uint8(r), uint8(g), uint8(b), uint8(a))
