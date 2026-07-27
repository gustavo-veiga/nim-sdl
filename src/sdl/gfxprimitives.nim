## # sdl/gfxprimitives
##
## Drawing primitives (pixel, line, circle, polygon, text, etc.) for SDL 1.2
## surfaces.
##
## All primitives are called as methods on `AnySurface` (e.g. `screen.circle(...)`).
## Every shape comes in two color variants:
##
## - **Packed color** — a single `uint32` in `0xRRGGBBAA` format
## - **Component** — individual `r, g, b: uint8` with optional `a: uint8 = 255`
##
## Every primitive returns `bool` — `true` on success, `false` on failure.
##
## ## Quick Start
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
##   screen.box(100, 100, 200, 200, 0xFF0000FF)        # red filled rect
##   screen.circle(320, 240, 50, 0x0000FFFF)            # blue circle (alpha)
##   screen.lineAA(0, 0, 640, 480, 0xFFFFFFFF)          # anti-aliased white line
##   screen.circleAA(100, 100, 80, 255, 255, 0)         # anti-aliased yellow circle
##
##   screen.flip()
## ```
##
## ## Advantages over C SDL_gfx
##
## | C SDL_gfx                                      | Nim SDL                                        |
## |------------------------------------------------|------------------------------------------------|
## | `circleColor(screen, x, y, r, color)`          | `screen.circle(x, y, r, color)`               |
## | Separate `*Color` / `*RGBA` calls              | Two overloads per primitive, same name         |
## | Manual pack: `0xRRGGBBAA` by hand              | Component overload: `r, g, b, a: uint8`       |
## | `int` return codes (0 success, -1 error)       | `bool` via `sdlOk` template                   |
## | `thickLine`: untyped `int` width               | `uint8` width                                 |
## | Polygons: `Sint16 *vx, *vy` + `int n`          | `openArray[int16]` — no pointer/length math   |
## | Manual `(Sint16)` cast for each coordinate     | Auto `int16()` truncation in wrapper          |
## | Bitmap text: `const char *s`                   | Nim `string` — auto `cstring` conversion      |
## | MT polygon: raw C pointers                     | `var pointer` / `var cint` scratch buffers    |
##
## ## Coordinate System
##
## The SDL coordinate system places (0, 0) at the top-left corner of the surface,
## with x increasing to the right and y increasing downward.
##
## Angles (for `arc`, `pie`, `filledPie`) are specified in degrees:
## - 0° = right (east)
## - 90° = down (south)
## - 180° = left (west)
## - 270° = up (north)
## - Increasing clockwise
##
## ## Polygon Vertex Arrays
##
## Polygons and bezier curves accept `openArray[int16]` vertex arrays:
##
## ```nim
## screen.polygon(
##   [0'i16, 100, 50],    # x coordinates
##   [0, 0, 100],         # y coordinates
##   0xFF0000FF)
## ```
##
## Polygons are automatically closed (last vertex connects to first).
##
## ## Multi-Thread Safe Variants
##
## `filledPolygonMT` and `polygonTexturedMT` accept pre-allocated scratch buffers
## (`intBuffer: var pointer`, `allocated: var cint`). Pass the same pair across
## calls to avoid repeated allocation — useful when drawing many polygons in a loop.
##
## ## Differences from SDL 2D Renderer
##
## Unlike SDL's modern 2D renderer, these primitives operate directly on
## `SDL_Surface` pixel buffers. This means:
## - Drawing is immediate (no command queue)
## - Results persist until the surface is modified or flipped
## - Works on any surface (screen, software surface, image)
## - Alpha blending is applied during draw
##
## ## Requirements
##
## Compile with `-d:gfx` flag. Requires the SDL_gfx library installed.
##
## ## See Also
##
## - `sdl/rotozoom` — Surface rotation and scaling
## - `sdl/framerate` — Frame rate control
## - `sdl/gfxfilter` — MMX-accelerated image filters
## - `sdl/ttf` — TrueType font rendering (alternative to bitmap text)

when defined(gfx) or defined(nimdoc):
  import private/utils
  import video

  {.push header: "SDL_gfxPrimitives.h", cdecl, importc.}

  # --- Pixel ---
  proc pixelColor(dst: RawSurfacePtr; x, y: int16; color: uint32): cint
  proc pixelRGBA(dst: RawSurfacePtr; x, y: int16; r, g, b, a: uint8): cint

  # --- Horizontal line ---
  proc hlineColor(dst: RawSurfacePtr; x1, x2, y: int16; color: uint32): cint
  proc hlineRGBA(dst: RawSurfacePtr; x1, x2, y: int16; r, g, b, a: uint8): cint

  # --- Vertical line ---
  proc vlineColor(dst: RawSurfacePtr; x, y1, y2: int16; color: uint32): cint
  proc vlineRGBA(dst: RawSurfacePtr; x, y1, y2: int16; r, g, b, a: uint8): cint

  # --- Rectangle ---
  proc rectangleColor(dst: RawSurfacePtr; x1, y1, x2, y2: int16; color: uint32): cint
  proc rectangleRGBA(dst: RawSurfacePtr; x1, y1, x2, y2: int16; r, g, b, a: uint8): cint

  # --- Rounded rectangle ---
  proc roundedRectangleColor(dst: RawSurfacePtr; x1, y1, x2, y2, rad: int16; color: uint32): cint
  proc roundedRectangleRGBA(dst: RawSurfacePtr; x1, y1, x2, y2, rad: int16; r, g, b, a: uint8): cint

  # --- Filled rectangle (Box) ---
  proc boxColor(dst: RawSurfacePtr; x1, y1, x2, y2: int16; color: uint32): cint
  proc boxRGBA(dst: RawSurfacePtr; x1, y1, x2, y2: int16; r, g, b, a: uint8): cint

  # --- Rounded filled box ---
  proc roundedBoxColor(dst: RawSurfacePtr; x1, y1, x2, y2, rad: int16; color: uint32): cint
  proc roundedBoxRGBA(dst: RawSurfacePtr; x1, y1, x2, y2, rad: int16; r, g, b, a: uint8): cint

  # --- Line ---
  proc lineColor(dst: RawSurfacePtr; x1, y1, x2, y2: int16; color: uint32): cint
  proc lineRGBA(dst: RawSurfacePtr; x1, y1, x2, y2: int16; r, g, b, a: uint8): cint

  # --- AA Line ---
  proc aalineColor(dst: RawSurfacePtr; x1, y1, x2, y2: int16; color: uint32): cint
  proc aalineRGBA(dst: RawSurfacePtr; x1, y1, x2, y2: int16; r, g, b, a: uint8): cint

  # --- Thick Line ---
  proc thickLineColor(dst: RawSurfacePtr; x1, y1, x2, y2: int16; width: uint8; color: uint32): cint
  proc thickLineRGBA(dst: RawSurfacePtr; x1, y1, x2, y2: int16; width: uint8; r, g, b, a: uint8): cint

  # --- Circle ---
  proc circleColor(dst: RawSurfacePtr; x, y, rad: int16; color: uint32): cint
  proc circleRGBA(dst: RawSurfacePtr; x, y, rad: int16; r, g, b, a: uint8): cint

  # --- Arc ---
  proc arcColor(dst: RawSurfacePtr; x, y, rad, angleStart, angleEnd: int16; color: uint32): cint
  proc arcRGBA(dst: RawSurfacePtr; x, y, rad, angleStart, angleEnd: int16; r, g, b, a: uint8): cint

  # --- AA Circle ---
  proc aacircleColor(dst: RawSurfacePtr; x, y, rad: int16; color: uint32): cint
  proc aacircleRGBA(dst: RawSurfacePtr; x, y, rad: int16; r, g, b, a: uint8): cint

  # --- Filled Circle ---
  proc filledCircleColor(dst: RawSurfacePtr; x, y, rad: int16; color: uint32): cint
  proc filledCircleRGBA(dst: RawSurfacePtr; x, y, rad: int16; r, g, b, a: uint8): cint

  # --- Ellipse ---
  proc ellipseColor(dst: RawSurfacePtr; x, y, rx, ry: int16; color: uint32): cint
  proc ellipseRGBA(dst: RawSurfacePtr; x, y, rx, ry: int16; r, g, b, a: uint8): cint

  # --- AA Ellipse ---
  proc aaellipseColor(dst: RawSurfacePtr; x, y, rx, ry: int16; color: uint32): cint
  proc aaellipseRGBA(dst: RawSurfacePtr; x, y, rx, ry: int16; r, g, b, a: uint8): cint

  # --- Filled Ellipse ---
  proc filledEllipseColor(dst: RawSurfacePtr; x, y, rx, ry: int16; color: uint32): cint
  proc filledEllipseRGBA(dst: RawSurfacePtr; x, y, rx, ry: int16; r, g, b, a: uint8): cint

  # --- Pie ---
  proc pieColor(dst: RawSurfacePtr; x, y, rad, angleStart, angleEnd: int16; color: uint32): cint
  proc pieRGBA(dst: RawSurfacePtr; x, y, rad, angleStart, angleEnd: int16; r, g, b, a: uint8): cint

  # --- Filled Pie ---
  proc filledPieColor(dst: RawSurfacePtr; x, y, rad, angleStart, angleEnd: int16; color: uint32): cint
  proc filledPieRGBA(dst: RawSurfacePtr; x, y, rad, angleStart, angleEnd: int16; r, g, b, a: uint8): cint

  # --- Trigon ---
  proc trigonColor(dst: RawSurfacePtr; x1, y1, x2, y2, x3, y3: int16; color: uint32): cint
  proc trigonRGBA(dst: RawSurfacePtr; x1, y1, x2, y2, x3, y3: int16; r, g, b, a: uint8): cint

  # --- AA Trigon ---
  proc aatrigonColor(dst: RawSurfacePtr; x1, y1, x2, y2, x3, y3: int16; color: uint32): cint
  proc aatrigonRGBA(dst: RawSurfacePtr; x1, y1, x2, y2, x3, y3: int16; r, g, b, a: uint8): cint

  # --- Filled Trigon ---
  proc filledTrigonColor(dst: RawSurfacePtr; x1, y1, x2, y2, x3, y3: int16; color: uint32): cint
  proc filledTrigonRGBA(dst: RawSurfacePtr; x1, y1, x2, y2, x3, y3: int16; r, g, b, a: uint8): cint

  # --- Polygon ---
  proc polygonColor(dst: RawSurfacePtr; vx, vy: ptr int16; n: cint; color: uint32): cint
  proc polygonRGBA(dst: RawSurfacePtr; vx, vy: ptr int16; n: cint; r, g, b, a: uint8): cint

  # --- AA Polygon ---
  proc aapolygonColor(dst: RawSurfacePtr; vx, vy: ptr int16; n: cint; color: uint32): cint
  proc aapolygonRGBA(dst: RawSurfacePtr; vx, vy: ptr int16; n: cint; r, g, b, a: uint8): cint

  # --- Filled Polygon ---
  proc filledPolygonColor(dst: RawSurfacePtr; vx, vy: ptr int16; n: cint; color: uint32): cint
  proc filledPolygonRGBA(dst: RawSurfacePtr; vx, vy: ptr int16; n: cint; r, g, b, a: uint8): cint
  proc texturedPolygon(dst: RawSurfacePtr; vx, vy: ptr int16; n: cint; texture: RawSurfacePtr; textureDx, textureDy: cint): cint

  # --- MT Polygon ---
  proc filledPolygonColorMT(dst: RawSurfacePtr; vx, vy: ptr int16; n: cint; color: uint32; polyInts: var pointer; polyAllocated: var cint): cint
  proc filledPolygonRGBAMT(dst: RawSurfacePtr; vx, vy: ptr int16; n: cint; r, g, b, a: uint8; polyInts: var pointer; polyAllocated: var cint): cint
  proc texturedPolygonMT(dst: RawSurfacePtr; vx, vy: ptr int16; n: cint; texture: RawSurfacePtr; textureDx, textureDy: cint; polyInts: var pointer; polyAllocated: var cint): cint

  # --- Bezier ---
  proc bezierColor(dst: RawSurfacePtr; vx, vy: ptr int16; n, s: cint; color: uint32): cint
  proc bezierRGBA(dst: RawSurfacePtr; vx, vy: ptr int16; n, s: cint; r, g, b, a: uint8): cint

  # --- Characters/Strings ---
  proc gfxPrimitivesSetFont(fontdata: pointer; cw, ch: uint32)
  proc gfxPrimitivesSetFontRotation(rotation: uint32)
  proc characterColor(dst: RawSurfacePtr; x, y: int16; c: char; color: uint32): cint
  proc characterRGBA(dst: RawSurfacePtr; x, y: int16; c: char; r, g, b, a: uint8): cint
  proc stringColor(dst: RawSurfacePtr; x, y: int16; s: cstring; color: uint32): cint
  proc stringRGBA(dst: RawSurfacePtr; x, y: int16; s: cstring; r, g, b, a: uint8): cint

  {.pop.}

  # =========================================================
  # PUBLIC API (method-style on AnySurface)
  # =========================================================

  # --- Pixel ---

  proc pixel*(
      surface: AnySurface;
      x, y: int;
      color: uint32
    ): bool {.inline.} =
    ## Draws a single pixel at the given coordinates.
    ##
    ## **Note:** This is the lowest-level drawing primitive. All other shapes
    ## are composed of individual pixels. Performance is best on 32-bit surfaces.
    sdlOk pixelColor(surface.raw, int16(x), int16(y), color)

  proc pixel*(
      surface: AnySurface;
      x, y: int;
      r, g, b: uint8; a: uint8 = 255
    ): bool {.inline.} =
    ## Component overload of `pixel`.
    sdlOk pixelRGBA(surface.raw, int16(x), int16(y), r, g, b, a)

  # --- Horizontal / Vertical lines ---

  proc hline*(
      surface: AnySurface;
      x1, x2, y: int;
      color: uint32
    ): bool {.inline.} =
    ## Draws a horizontal line from (`x1`, `y`) to (`x2`, `y`).
    ##
    ## **Note:** This is faster than drawing individual pixels for each point
    ## on the line. Works on 8, 16, 24, and 32-bit surfaces.
    sdlOk hlineColor(surface.raw, int16(x1), int16(x2), int16(y), color)

  proc hline*(
      surface: AnySurface;
      x1, x2, y: int;
      r, g, b: uint8; a: uint8 = 255
    ): bool {.inline.} =
    ## Component overload of `hline`.
    sdlOk hlineRGBA(surface.raw, int16(x1), int16(x2), int16(y), r, g, b, a)

  proc vline*(
      surface: AnySurface;
      x, y1, y2: int;
      color: uint32
    ): bool {.inline.} =
    ## Draws a vertical line from (`x`, `y1`) to (`x`, `y2`).
    ##
    ## **Note:** Optimized for vertical strokes. Use this instead of `line`
    ## when drawing axis-aligned vertical segments.
    sdlOk vlineColor(surface.raw, int16(x), int16(y1), int16(y2), color)

  proc vline*(
      surface: AnySurface;
      x, y1, y2: int;
      r, g, b: uint8; a: uint8 = 255
    ): bool {.inline.} =
    ## Component overload of `vline`.
    sdlOk vlineRGBA(surface.raw, int16(x), int16(y1), int16(y2), r, g, b, a)

  # --- Rectangles ---

  proc rect*(
      surface: AnySurface;
      x1, y1, x2, y2: int;
      color: uint32
    ): bool {.inline.} =
    ## Draws a rectangular outline.
    ##
    ## The rectangle spans from the top-left corner (`x1`, `y1`) to the
    ## bottom-right corner (`x2`, `y2`), inclusive.
    ##
    ## **Note:** For a filled rectangle, use `box()` instead.
    sdlOk rectangleColor(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), color)

  proc rect*(
      surface: AnySurface;
      x1, y1, x2, y2: int;
      r, g, b: uint8; a: uint8 = 255
    ): bool {.inline.} =
    ## Component overload of `rect`.
    sdlOk rectangleRGBA(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), r, g, b, a)

  proc roundedRect*(
      surface: AnySurface;
      x1, y1, x2, y2, radius: int;
      color: uint32
    ): bool {.inline.} =
    ## Draws a rectangle outline with rounded corners.
    ##
    ## `radius` controls the corner radius in pixels. Larger values produce
    ## more rounded corners.
    sdlOk roundedRectangleColor(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), int16(radius), color)

  proc roundedRect*(
      surface: AnySurface;
      x1, y1, x2, y2, radius: int;
      r, g, b: uint8; a: uint8 = 255
    ): bool {.inline.} =
    ## Component overload of `roundedRect`.
    sdlOk roundedRectangleRGBA(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), int16(radius), r, g, b, a)

  proc box*(
      surface: AnySurface;
      x1, y1, x2, y2: int;
      color: uint32
    ): bool {.inline.} =
    ## Draws a filled rectangle (solid box).
    ##
    ## Fills the area from (`x1`, `y1`) to (`x2`, `y2`), inclusive.
    ## This is the filled counterpart of `rect()`.
    sdlOk boxColor(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), color)

  proc box*(
      surface: AnySurface;
      x1, y1, x2, y2: int;
      r, g, b: uint8; a: uint8 = 255
    ): bool {.inline.} =
    ## Component overload of `box`.
    sdlOk boxRGBA(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), r, g, b, a)

  proc roundedBox*(
      surface: AnySurface;
      x1, y1, x2, y2, radius: int;
      color: uint32
    ): bool {.inline.} =
    ## Draws a filled rectangle with rounded corners.
    ##
    ## `radius` controls the corner radius. This is the filled counterpart
    ## of `roundedRect()`.
    sdlOk roundedBoxColor(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), int16(radius), color)

  proc roundedBox*(
      surface: AnySurface;
      x1, y1, x2, y2, radius: int;
      r, g, b: uint8; a: uint8 = 255
    ): bool {.inline.} =
    ## Component overload of `roundedBox`.
    sdlOk roundedBoxRGBA(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), int16(radius), r, g, b, a)

  # --- Lines ---

  proc line*(
      surface: AnySurface;
      x1, y1, x2, y2: int;
      color: uint32
    ): bool {.inline.} =
    ## Draws a line between two points using Bresenham's algorithm.
    ##
    ## **Note:** The line is not anti-aliased. For smooth lines, use `lineAA()`.
    sdlOk lineColor(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), color)

  proc line*(
      surface: AnySurface;
      x1, y1, x2, y2: int;
      r, g, b: uint8; a: uint8 = 255
    ): bool {.inline.} =
    ## Component overload of `line`.
    sdlOk lineRGBA(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), r, g, b, a)

  proc lineAA*(
      surface: AnySurface;
      x1, y1, x2, y2: int;
      color: uint32
    ): bool {.inline.} =
    ## Draws an anti-aliased (smooth) line between two points.
    ##
    ## Anti-aliasing reduces jagged edges by blending the line color with
    ## the background. Slightly slower than `line()`.
    sdlOk aalineColor(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), color)

  proc lineAA*(
      surface: AnySurface;
      x1, y1, x2, y2: int;
      r, g, b: uint8; a: uint8 = 255
    ): bool {.inline.} =
    ## Component overload of `lineAA`.
    sdlOk aalineRGBA(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), r, g, b, a)

  proc thickLine*(
      surface: AnySurface;
      x1, y1, x2, y2: int;
      width: uint8;
      color: uint32
    ): bool {.inline.} =
    ## Draws a line with a specified thickness in pixels.
    ##
    ## `width` controls the line thickness. Values larger than 1 produce a
    ## filled rectangular stroke instead of a single-pixel line.
    sdlOk thickLineColor(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), width, color)

  proc thickLine*(
      surface: AnySurface;
      x1, y1, x2, y2: int;
      width: uint8;
      r, g, b: uint8; a: uint8 = 255
    ): bool {.inline.} =
    ## Component overload of `thickLine`.
    sdlOk thickLineRGBA(
      surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), width, r, g, b, a)

  # --- Circles ---

  proc circle*(
      surface: AnySurface;
      x, y, radius: int;
      color: uint32
    ): bool {.inline.} =
    ## Draws a circle outline centered at (`x`, `y`) with the given radius.
    ##
    ## **Note:** For filled circles, use `filledCircle()`. For smoother edges,
    ## use `aacircle()`.
    sdlOk circleColor(surface.raw, int16(x), int16(y), int16(radius), color)

  proc circle*(
      surface: AnySurface;
      x, y, radius: int;
      r, g, b: uint8; a: uint8 = 255
    ): bool {.inline.} =
    ## Component overload of `circle`.
    sdlOk circleRGBA(surface.raw, int16(x), int16(y), int16(radius), r, g, b, a)

  proc circleAA*(
      surface: AnySurface;
      x, y, radius: int;
      color: uint32
    ): bool {.inline.} =
    ## Draws an anti-aliased circle outline with smoother edges.
    ##
    ## **Note:** Slightly slower than `circle()` but produces visually
    ## superior results, especially at small radii.
    sdlOk aacircleColor(surface.raw, int16(x), int16(y), int16(radius), color)

  proc circleAA*(
      surface: AnySurface;
      x, y, radius: int;
      r, g, b: uint8; a: uint8 = 255
    ): bool {.inline.} =
    ## Component overload of `circleAA`.
    sdlOk aacircleRGBA(surface.raw, int16(x), int16(y), int16(radius), r, g, b, a)

  proc filledCircle*(
      surface: AnySurface;
      x, y, radius: int;
      color: uint32
    ): bool {.inline.} =
    ## Draws a filled (solid) circle.
    ##
    ## The circle is centered at (`x`, `y`) with the given radius.
    sdlOk filledCircleColor(surface.raw, int16(x), int16(y), int16(radius), color)

  proc filledCircle*(
      surface: AnySurface;
      x, y, radius: int;
      r, g, b: uint8; a: uint8 = 255
    ): bool {.inline.} =
    ## Component overload of `filledCircle`.
    sdlOk filledCircleRGBA(surface.raw, int16(x), int16(y), int16(radius), r, g, b, a)

  # --- Ellipses ---

  proc ellipse*(
      surface: AnySurface;
      x, y, radiusX, radiusY: int;
      color: uint32
    ): bool {.inline.} =
    ## Draws an ellipse outline centered at (`x`, `y`).
    ##
    ## `radiusX` controls the horizontal radius, `radiusY` the vertical radius.
    sdlOk ellipseColor(surface.raw, int16(x), int16(y), int16(radiusX), int16(radiusY), color)

  proc ellipse*(
      surface: AnySurface;
      x, y, radiusX, radiusY: int;
      r, g, b: uint8; a: uint8 = 255
    ): bool {.inline.} =
    ## Component overload of `ellipse`.
    sdlOk ellipseRGBA(surface.raw, int16(x), int16(y), int16(radiusX), int16(radiusY), r, g, b, a)

  proc ellipseAA*(
      surface: AnySurface;
      x, y, radiusX, radiusY: int;
      color: uint32
    ): bool {.inline.} =
    ## Draws an anti-aliased ellipse outline with smoother edges.
    sdlOk aaellipseColor(surface.raw, int16(x), int16(y), int16(radiusX), int16(radiusY), color)

  proc ellipseAA*(
      surface: AnySurface;
      x, y, radiusX, radiusY: int;
      r, g, b: uint8; a: uint8 = 255
    ): bool {.inline.} =
    ## Component overload of `ellipseAA`.
    sdlOk aaellipseRGBA(surface.raw, int16(x), int16(y), int16(radiusX), int16(radiusY), r, g, b, a)

  proc filledEllipse*(
      surface: AnySurface;
      x, y, radiusX, radiusY: int;
      color: uint32
    ): bool {.inline.} =
    ## Draws a filled (solid) ellipse.
    sdlOk filledEllipseColor(surface.raw, int16(x), int16(y), int16(radiusX), int16(radiusY), color)

  proc filledEllipse*(
      surface: AnySurface;
      x, y, radiusX, radiusY: int;
      r, g, b: uint8; a: uint8 = 255
    ): bool {.inline.} =
    ## Component overload of `filledEllipse`.
    sdlOk filledEllipseRGBA(surface.raw, int16(x), int16(y), int16(radiusX), int16(radiusY), r, g, b, a)

  # --- Arcs / Pies ---

  proc arc*(
      surface: AnySurface;
      x, y, radius, startAngle, endAngle: int;
      color: uint32
    ): bool {.inline.} =
    ## Draws an arc (partial circle segment) from `startAngle` to `endAngle`.
    ##
    ## Angles are specified in degrees, with 0° pointing right and increasing
    ## clockwise.
    sdlOk arcColor(surface.raw, int16(x), int16(y), int16(radius), int16(startAngle), int16(endAngle), color)

  proc arc*(
      surface: AnySurface;
      x, y, radius, startAngle, endAngle: int;
      r, g, b: uint8; a: uint8 = 255
    ): bool {.inline.} =
    ## Component overload of `arc`.
    sdlOk arcRGBA(surface.raw, int16(x), int16(y), int16(radius), int16(startAngle), int16(endAngle), r, g, b, a)

  proc pie*(
      surface: AnySurface;
      x, y, radius, startAngle, endAngle: int;
      color: uint32
    ): bool {.inline.} =
    ## Draws a pie-shaped wedge (outline) from `startAngle` to `endAngle`.
    ##
    ## A pie is an arc with straight lines connecting the endpoints to the center.
    sdlOk pieColor(surface.raw, int16(x), int16(y), int16(radius), int16(startAngle), int16(endAngle), color)

  proc pie*(
      surface: AnySurface;
      x, y, radius, startAngle, endAngle: int;
      r, g, b: uint8; a: uint8 = 255
    ): bool {.inline.} =
    ## Component overload of `pie`.
    sdlOk pieRGBA(surface.raw, int16(x), int16(y), int16(radius), int16(startAngle), int16(endAngle), r, g, b, a)

  proc filledPie*(
      surface: AnySurface;
      x, y, radius, startAngle, endAngle: int;
      color: uint32
    ): bool {.inline.} =
    ## Draws a filled pie-shaped wedge.
    ##
    ## The wedge is filled from the center point (`x`, `y`) out to the arc.
    sdlOk filledPieColor(surface.raw, int16(x), int16(y), int16(radius), int16(startAngle), int16(endAngle), color)

  proc filledPie*(
      surface: AnySurface;
      x, y, radius, startAngle, endAngle: int;
      r, g, b: uint8; a: uint8 = 255
    ): bool {.inline.} =
    ## Component overload of `filledPie`.
    sdlOk filledPieRGBA(surface.raw, int16(x), int16(y), int16(radius), int16(startAngle), int16(endAngle), r, g, b, a)

  # --- Triangles ---

  proc trigon*(
      surface: AnySurface;
      x1, y1, x2, y2, x3, y3: int;
      color: uint32
    ): bool {.inline.} =
    ## Draws a triangle outline connecting three points.
    ##
    ## The three vertices are specified as (`x1`, `y1`), (`x2`, `y2`), (`x3`, `y3`).
    sdlOk trigonColor(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), int16(x3), int16(y3), color)

  proc trigon*(
      surface: AnySurface;
      x1, y1, x2, y2, x3, y3: int;
      r, g, b: uint8; a: uint8 = 255
    ): bool {.inline.} =
    ## Component overload of `trigon`.
    sdlOk trigonRGBA(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), int16(x3), int16(y3), r, g, b, a)

  proc trigonAA*(
      surface: AnySurface;
      x1, y1, x2, y2, x3, y3: int;
      color: uint32
    ): bool {.inline.} =
    ## Draws an anti-aliased triangle outline.
    sdlOk aatrigonColor(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), int16(x3), int16(y3), color)

  proc trigonAA*(
      surface: AnySurface;
      x1, y1, x2, y2, x3, y3: int;
      r, g, b: uint8; a: uint8 = 255
    ): bool {.inline.} =
    ## Component overload of `aatrigon`.
    sdlOk aatrigonRGBA(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), int16(x3), int16(y3), r, g, b, a)

  proc filledTrigon*(
      surface: AnySurface;
      x1, y1, x2, y2, x3, y3: int;
      color: uint32
    ): bool {.inline.} =
    ## Draws a filled (solid) triangle.
    sdlOk filledTrigonColor(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), int16(x3), int16(y3), color)

  proc filledTrigon*(
      surface: AnySurface;
      x1, y1, x2, y2, x3, y3: int;
      r, g, b: uint8; a: uint8 = 255
    ): bool {.inline.} =
    ## Component overload of `filledTrigon`.
    sdlOk filledTrigonRGBA(surface.raw, int16(x1), int16(y1), int16(x2), int16(y2), int16(x3), int16(y3), r, g, b, a)

  # --- Polygons ---

  proc polygon*(
      surface: AnySurface;
      vertexX, vertexY: openArray[int16];
      color: uint32
    ): bool {.inline.} =
    ## Draws a polygon outline from arrays of vertex coordinates.
    ##
    ## `vertexX` and `vertexY` must contain the x and y coordinates of each vertex.
    ## The polygon is automatically closed (last vertex connects to first).
    ##
    ## **Example:** `screen.polygon([0'i16, 100, 50], [0, 0, 100], 0xFF0000FF)`
    sdlOk polygonColor(surface.raw, addr vertexX[0], addr vertexY[0], cint(vertexX.len), color)

  proc polygon*(
      surface: AnySurface;
      vertexX, vertexY: openArray[int16];
      r, g, b: uint8; a: uint8 = 255
    ): bool {.inline.} =
    ## Component overload of `polygon`.
    sdlOk polygonRGBA(surface.raw, addr vertexX[0], addr vertexY[0], cint(vertexX.len), r, g, b, a)

  proc polygonAA*(
      surface: AnySurface;
      vertexX, vertexY: openArray[int16];
      color: uint32
    ): bool {.inline.} =
    ## Draws an anti-aliased polygon outline.
    sdlOk aapolygonColor(surface.raw, addr vertexX[0], addr vertexY[0], cint(vertexX.len), color)

  proc polygonAA*(
      surface: AnySurface;
      vertexX, vertexY: openArray[int16];
      r, g, b: uint8; a: uint8 = 255
    ): bool {.inline.} =
    ## Component overload of `polygonAA`.
    sdlOk aapolygonRGBA(surface.raw, addr vertexX[0], addr vertexY[0], cint(vertexX.len), r, g, b, a)

  proc filledPolygon*(
      surface: AnySurface;
      vertexX, vertexY: openArray[int16];
      color: uint32
    ): bool {.inline.} =
    ## Draws a filled (solid) polygon.
    ##
    ## **Note:** The polygon must be simple (non-self-intersecting) for
    ## correct filling.
    sdlOk filledPolygonColor(surface.raw, addr vertexX[0], addr vertexY[0], cint(vertexX.len), color)

  proc filledPolygon*(
      surface: AnySurface;
      vertexX, vertexY: openArray[int16];
      r, g, b: uint8; a: uint8 = 255
    ): bool {.inline.} =
    ## Component overload of `filledPolygon`.
    sdlOk filledPolygonRGBA(surface.raw, addr vertexX[0], addr vertexY[0], cint(vertexX.len), r, g, b, a)

  proc polygonTextured*(
      surface: AnySurface;
      vertexX, vertexY: openArray[int16];
      texture: AnySurface;
      textureDx, textureDy: int
    ): bool {.inline.} =
    ## Draws a polygon filled with a texture instead of a solid color.
    ##
    ## `textureDx` and `textureDy` offset the texture mapping within the polygon.
    ## **Note:** The texture must be a valid surface with the same pixel format
    ## as the destination.
    sdlOk texturedPolygon(
      surface.raw, addr vertexX[0], addr vertexY[0], cint(vertexX.len),
      texture.raw, cint(textureDx), cint(textureDy))

  proc filledPolygonMT*(
      surface: AnySurface;
      vertexX, vertexY: openArray[int16];
      color: uint32;
      intBuffer: var pointer;
      allocated: var cint
    ): bool {.inline.} =
    ## Filled polygon using pre-allocated intersection tables (multi-thread safe).
    ##
    ## `intBuffer` and `allocated` are scratch buffers reused across calls.
    ## **Note:** Pass the same `intBuffer`/`allocated` pair to avoid repeated
    ## allocation when drawing multiple polygons.
    sdlOk filledPolygonColorMT(surface.raw, addr vertexX[0], addr vertexY[0], cint(vertexX.len), color, intBuffer, allocated)

  proc filledPolygonMT*(
      surface: AnySurface;
      vertexX, vertexY: openArray[int16];
      r, g, b: uint8; a: uint8 = 255;
      intBuffer: var pointer;
      allocated: var cint
    ): bool {.inline.} =
    ## Component overload of `filledPolygonMT`.
    sdlOk filledPolygonRGBAMT(
      surface.raw, addr vertexX[0], addr vertexY[0], cint(vertexX.len),
      r, g, b, a, intBuffer, allocated)

  proc polygonTexturedMT*(
      surface: AnySurface;
      texture: AnySurface;
      textureDx, textureDy: int;
      vertexX, vertexY: openArray[int16];
      intBuffer: var pointer;
      allocated: var cint
    ): bool {.inline.} =
    ## Multi-thread safe textured polygon with pre-allocated intersection tables.
    sdlOk texturedPolygonMT(
      surface.raw, addr vertexX[0], addr vertexY[0], cint(vertexX.len),
      texture.raw, cint(textureDx), cint(textureDy), intBuffer, allocated)

  # --- Bezier ---

  proc bezier*(
      surface: AnySurface;
      vertexX, vertexY: openArray[int16];
      steps: int;
      color: uint32
    ): bool {.inline.} =
    ## Draws a Bezier curve from control points.
    ##
    ## `steps` controls the number of interpolation steps (higher = smoother curve).
    ## Typical values range from 3 to 20.
    sdlOk bezierColor(surface.raw, addr vertexX[0], addr vertexY[0], cint(vertexX.len), cint(steps), color)

  proc bezier*(
      surface: AnySurface;
      vertexX, vertexY: openArray[int16];
      steps: int;
      r, g, b: uint8; a: uint8 = 255
    ): bool {.inline.} =
    ## Component overload of `bezier`.
    sdlOk bezierRGBA(surface.raw, addr vertexX[0], addr vertexY[0], cint(vertexX.len), cint(steps), r, g, b, a)

  # --- Font control ---

  proc setGfxFont*(
      fontdata: pointer;
      charWidth, charHeight: uint32
    ) {.inline.} =
    ## Sets a custom bitmap font for `character()` and `string()` drawing.
    ##
    ## `fontdata` points to a raw bitmap font, `charWidth` and `charHeight`
    ## specify the dimensions of each glyph in pixels.
    gfxPrimitivesSetFont(fontdata, charWidth, charHeight)

  proc setGfxFontRotation*(
      rotation: uint32
    ) {.inline.} =
    ## Sets the font rotation for `character()` and `string()`.
    ##
    ## Valid values are 0, 90, 180, and 270 degrees.
    gfxPrimitivesSetFontRotation(rotation)

  # --- Text ---

  proc character*(
      surface: AnySurface;
      x, y: int;
      c: char;
      color: uint32
    ): bool {.inline.} =
    ## Draws a single bitmap character at (`x`, `y`).
    ##
    ## Uses the font set by `setGfxFont()`. Defaults to a built-in font.
    sdlOk characterColor(surface.raw, int16(x), int16(y), c, color)

  proc character*(
      surface: AnySurface;
      x, y: int;
      c: char;
      r, g, b: uint8; a: uint8 = 255
    ): bool {.inline.} =
    ## Component overload of `character`.
    sdlOk characterRGBA(surface.raw, int16(x), int16(y), c, r, g, b, a)

  proc string*(
      surface: AnySurface;
      x, y: int;
      s: string;
      color: uint32
    ): bool {.inline.} =
    ## Draws a bitmap text string at (`x`, `y`).
    ##
    ## Uses the font set by `setGfxFont()`. The string is drawn character by
    ## character at the current font's character width spacing.
    ##
    ## **Note:** This is not a TrueType renderer. For TTF text, use `sdl/ttf`.
    sdlOk stringColor(surface.raw, int16(x), int16(y), cstring(s), color)

  proc string*(
      surface: AnySurface;
      x, y: int;
      s: string;
      r, g, b: uint8; a: uint8 = 255
    ): bool {.inline.} =
    ## Component overload of `string`.
    sdlOk stringRGBA(surface.raw, int16(x), int16(y), cstring(s), r, g, b, a)
else:
  {.fatal: "sdl/gfxprimitives requires -d:gfx compile flag (SDL_gfx library)".}
