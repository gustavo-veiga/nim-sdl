## # sdl/rotozoom
##
## Surface rotation, zoom, and transformations using SDL_gfx
##
## This module provides high-quality surface transformations including rotation, zoom,
## shrinking, and 90-degree rotation through the SDL_gfx library.
##
## ## SDL 1.2 Reference
##
## SDL_gfx provides surface transformation functions that are not part of core SDL 1.2.
## These include rotation with anti-aliasing, zoom with interpolation, and fast 90-degree rotations.
##
## **Key C functions:**
## ```c
## SDL_Surface *rotozoomSurface(SDL_Surface *src, double angle, double zoom, int smooth);
## SDL_Surface *zoomSurface(SDL_Surface *src, double zoomx, double zoomy, int smooth);
## SDL_Surface *shrinkSurface(SDL_Surface *src, int factorx, int factory);
## SDL_Surface *rotateSurface90Degrees(SDL_Surface *src, int numClockwiseTurns);
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
##   # Load an image
##   let img = loadImage("sprite.png")
##   if img.isSome:
##     var sprite = img.get
##
##     # Rotate 45 degrees with smooth interpolation
##     let rotated = rotozoom(sprite, 45.0, 1.0, smooth = true)
##     if rotated.isSome:
##       discard rotated.get.blit(screen, 100, 100)
##
##     # Zoom 2x
##     let zoomed = zoom(sprite, 2.0, 2.0, smooth = true)
##     if zoomed.isSome:
##       discard zoomed.get.blit(screen, 300, 100)
##
##     # Shrink by factor of 2
##     let shrunk = shrink(sprite, 2, 2)
##     if shrunk.isSome:
##       discard shrunk.get.blit(screen, 500, 100)
##
##     # Fast 90-degree rotation
##     let rotated90 = rotate90(sprite, 1)  # 1 = 90 degrees clockwise
##     if rotated90.isSome:
##       discard rotated90.get.blit(screen, 100, 300)
##
##   var running = true
##   while running:
##     for event in pollEvents():
##       if event.kind == quit:
##         running = false
##
##     screen.flip()
## ```
##
## ## Advantages over C SDL_gfx
##
## | C SDL_gfx                      | Nim SDL                     |
## |--------------------------------|-----------------------------|
## | `SDL_Surface *` manual free    | `Surface` RAII auto-free    |
## | Integer parameters for smooth  | `bool smooth` parameter     |
## | Manual size calculation        | `calcRotozoomSize()` helper |
## | Error-prone pointer operations | Safe Option returns         |
##
## ## Transformation Types
##
## - **rotozoom**: Rotate and zoom simultaneously with optional anti-aliasing
## - **zoom**: Scale by arbitrary factors (can be non-uniform)
## - **shrink**: Fast integer-factor shrinking (no interpolation)
## - **rotate90**: Fast 90-degree rotations (0, 90, 180, 270 degrees)
##
## ## Requirements
##
## Compile with `-d:gfx` flag. Requires SDL_gfx library installed.
##
## ## See Also
##
## - `sdl/video` - Surface management
## - `sdl/framerate` - Frame rate control

when defined(gfx):
  import std/options
  import video

  # =========================================================
  # 1. PRIVATE BINDINGS (FFI - SDL_gfx)
  # =========================================================

  {.push header: "SDL_rotozoom.h", importc, cdecl.}

  proc rotozoomSurface(src: RawSurfacePtr, angle: cdouble, zoom: cdouble, smooth: cint): RawSurfacePtr
  proc rotozoomSurfaceXY(src: RawSurfacePtr, angle: cdouble, zoomx: cdouble, zoomy: cdouble, smooth: cint): RawSurfacePtr
  proc rotozoomSurfaceSize(width: cint, height: cint, angle: cdouble, zoom: cdouble, dstwidth: ptr cint, dstheight: ptr cint)
  proc rotozoomSurfaceSizeXY(width: cint, height: cint, angle: cdouble, zoomx: cdouble, zoomy: cdouble, dstwidth: ptr cint, dstheight: ptr cint)

  proc zoomSurface(src: RawSurfacePtr, zoomx: cdouble, zoomy: cdouble, smooth: cint): RawSurfacePtr
  proc zoomSurfaceSize(width: cint, height: cint, zoomx: cdouble, zoomy: cdouble, dstwidth: ptr cint, dstheight: ptr cint)

  proc shrinkSurface(src: RawSurfacePtr, factorx: cint, factory: cint): RawSurfacePtr
  proc rotateSurface90Degrees(src: RawSurfacePtr, numClockwiseTurns: cint): RawSurfacePtr

  {.pop.}

  # =========================================================
  # 2. PUBLIC API
  # =========================================================

  template toSmoothFlag(smooth: bool): cint =
    if smooth: 1 else: 0

  proc rotozoom*(src: var Surface, angle: float, zoom: float = 1.0, smooth: bool = true): Option[Surface] {.inline.} =
    ## Rotates and zooms a surface with optional anti-aliasing.
    ##
    ## **Example:**
    ## ```nim
    ## # Rotate 45 degrees at 1x zoom
    ## let rotated = rotozoom(sprite, 45.0)
    ##
    ## # Rotate 90 degrees and zoom 2x
    ## let result = rotozoom(sprite, 90.0, 2.0, smooth = true)
    ## ```
    ##
    ## **Note:** Set `smooth = true` for anti-aliased output (slower but higher quality).
    let raw = rotozoomSurface(src.unsafeRaw, cdouble(angle), cdouble(zoom), smooth.toSmoothFlag())
    if raw.isNil: none(Surface)
    else: some(assumeRaw[Surface](raw))

  proc rotozoom*(src: var Surface, angle: float, zoomX, zoomY: float, smooth: bool = true): Option[Surface] {.inline.} =
    ## Rotates and zooms a surface with independent X/Y zoom factors.
    ##
    ## **Example:**
    ## ```nim
    ## let result = rotozoom(sprite, 45.0, 2.0, 1.0, smooth = true)
    ## ```
    let raw = rotozoomSurfaceXY(src.unsafeRaw, cdouble(angle), cdouble(zoomX), cdouble(zoomY), smooth.toSmoothFlag())
    if raw.isNil: none(Surface)
    else: some(assumeRaw[Surface](raw))

  proc zoom*(src: var Surface, zoomX, zoomY: float, smooth: bool = true): Option[Surface] {.inline.} =
    ## Scales a surface by the specified factors.
    ##
    ## **Example:**
    ## ```nim
    ## # Scale uniformly to 2x
    ## let zoomed = zoom(sprite, 2.0, 2.0)
    ##
    ## # Scale non-uniformly (stretch)
    ## let stretched = zoom(sprite, 3.0, 0.5)
    ## ```
    let raw = zoomSurface(src.unsafeRaw, cdouble(zoomX), cdouble(zoomY), smooth.toSmoothFlag())
    if raw.isNil: none(Surface)
    else: some(assumeRaw[Surface](raw))

  proc shrink*(src: var Surface, factorX, factorY: int): Option[Surface] {.inline.} =
    ## Shrinks a surface by integer factors (fast, no interpolation).
    ##
    ## **Example:**
    ## ```nim
    ## let shrunk = shrink(sprite, 2, 2)  # Half size
    ## let shrunk = shrink(sprite, 4, 2)  # 1/4 width, 1/2 height
    ## ```
    let raw = shrinkSurface(src.unsafeRaw, cint(factorX), cint(factorY))
    if raw.isNil: none(Surface)
    else: some(assumeRaw[Surface](raw))

  proc rotate90*(src: var Surface, clockwiseTurns: int = 1): Option[Surface] {.inline.} =
    ## Rotates a surface by 90-degree increments (very fast, no interpolation).
    ##
    ## **Example:**
    ## ```nim
    ## # Rotate 90 degrees clockwise
    ## let rotated90 = rotate90(sprite, 1)
    ##
    ## # Rotate 180 degrees
    ## let rotated180 = rotate90(sprite, 2)
    ##
    ## # Rotate 270 degrees clockwise (90 counter-clockwise)
    ## let rotated270 = rotate90(sprite, 3)
    ## ```
    let raw = rotateSurface90Degrees(src.unsafeRaw, cint(clockwiseTurns))
    if raw.isNil: none(Surface)
    else: some(assumeRaw[Surface](raw))

  proc calcRotozoomSize*(width, height: int, angle: float, zoom: float = 1.0): tuple[width: int, height: int] {.inline.} =
    ## Calculates the output size of a rotozoom transformation without rendering.
    ##
    ## **Example:**
    ## ```nim
    ## let (w, h) = calcRotozoomSize(sprite.w, sprite.h, 45.0, 2.0)
    ## ```
    var w, h: cint
    rotozoomSurfaceSize(cint(width), cint(height), cdouble(angle), cdouble(zoom), addr w, addr h)
    (int(w), int(h))

  proc calcRotozoomSize*(width, height: int, angle: float, zoomX, zoomY: float): tuple[width: int, height: int] {.inline.} =
    ## Calculates output size for rotozoom with independent X/Y zoom factors.
    var w, h: cint
    rotozoomSurfaceSizeXY(cint(width), cint(height), cdouble(angle), cdouble(zoomX), cdouble(zoomY), addr w, addr h)
    (int(w), int(h))

  proc calcZoomSize*(width, height: int, zoomX, zoomY: float): tuple[width: int, height: int] {.inline.} =
    ## Calculates the output size of a zoom transformation without rendering.
    ##
    ## **Example:**
    ## ```nim
    ## let (w, h) = calcZoomSize(sprite.w, sprite.h, 2.0, 2.0)
    ## ```
    var w, h: cint
    zoomSurfaceSize(cint(width), cint(height), cdouble(zoomX), cdouble(zoomY), addr w, addr h)
    (int(w), int(h))
