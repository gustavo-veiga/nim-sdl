## # sdl/framerate
##
## Frame rate control and timing management
##
## This module provides precise frame rate limiting using the SDL_gfx library.
## The `FpsManager` tracks frame timing and provides delay functions to maintain
## a consistent frame rate, essential for smooth gameplay and predictable physics.
##
## ## SDL 1.2 Reference
##
## Frame rate control in SDL 1.2 is not built-in. The SDL_gfx extension library
## provides `FpsManager` for this purpose. It tracks the time between frames and
## calculates the optimal delay to maintain the target frame rate.
##
## **Key C functions:**
## ```c
## void SDL_initFramerate(FPSmanager *manager);
## int SDL_setFramerate(FPSmanager *manager, Uint32 rate);
## int SDL_getFramerate(FPSmanager *manager);
## Uint32 SDL_framerateDelay(FPSmanager *manager);
## ```
##
## ## Usage Example
##
## ```nim
## import sdl
##
## # Compile with: nim c -d:gfx game.nim
##
## runMain:
##   let ctx = sdlInit(sdlInitVideo)
##   defer: ctx.quit()
##
##   let screen = setVideoMode(640, 480, 32, sdlHwSurface)
##   var fps = initFpsManager(60)  # Target 60 FPS
##
##   var running = true
##   while running:
##     for event in pollEvents():
##       if event.kind == quit:
##         running = false
##
##     # Game logic and rendering here
##     screen.fill(color(0, 0, 255))
##     screen.flip()
##
##     # Delay to maintain frame rate
##     discard fps.delay()
## ```
##
## ## Advantages over C SDL 1.2
##
## | C SDL 1.2                              | Nim SDL                          |
## |----------------------------------------|----------------------------------|
## | `FPSmanager fps;` manual init          | `initFpsManager(60)` builder     |
## | `SDL_setFramerate(&fps, 60)`           | `fps.rate = 60` property syntax  |
## | Manual delay calculation               | `fps.delay()` one-liner          |
## | No type safety on rate limits          | Constants `FpsUpperLimit`/`Lower`|
##
## ## Constants
##
## - `FpsUpperLimit` = 200 (maximum allowed frame rate)
## - `FpsLowerLimit` = 1 (minimum allowed frame rate)
## - `FpsDefault` = 30 (default frame rate if none specified)
##
## ## Requirements
##
## This module requires the SDL_gfx library and compilation with `-d:gfx` flag.
##
## ## See Also
##
## - `sdl/timer` - Lower-level timing functions
## - `sdl/video` - Video subsystem for rendering

when defined(gfx):
  # =========================================================
  # 1. CONSTANTS AND STRUCTURE (Stack-allocated)
  # =========================================================

  const
    FpsUpperLimit* = 200
      ## Maximum allowed frame rate (200 FPS).
    FpsLowerLimit* = 1
      ## Minimum allowed frame rate (1 FPS).
    FpsDefault* = 30
      ## Default frame rate if none specified (30 FPS).

  type
    FpsManager* = object
      ## Frame rate manager that tracks timing and provides delay functions.
      ## Stack-allocated for zero overhead.
      frameCount: uint32
      rateTicks: cfloat
      baseTicks: uint32
      lastTicks: uint32
      rate: uint32

  # =========================================================
  # 2. PRIVATE BINDINGS (FFI - SDL_gfx)
  # =========================================================

  {.push header: "SDL_framerate.h", cdecl.}

  proc SDL_initFramerate(manager: ptr FpsManager) {.importc.}
  proc SDL_setFramerate(manager: ptr FpsManager, rate: uint32): cint {.importc.}
  proc SDL_getFramerate(manager: ptr FpsManager): cint {.importc.}
  proc SDL_getFramecount(manager: ptr FpsManager): cint {.importc.}
  proc SDL_framerateDelay(manager: ptr FpsManager): uint32 {.importc.}

  {.pop.}

  # =========================================================
  # 3. PUBLIC API (Pure Nim and Ergonomic)
  # =========================================================

  proc initFpsManager*(rate: int = FpsDefault): FpsManager =
    ## Creates a new frame rate manager with the specified target rate.
    ## Defaults to `FpsDefault` (30 FPS) if no rate is provided.
    ##
    ## ```nim
    ## var fps = initFpsManager(60)  # Target 60 FPS
    ## ```
    SDL_initFramerate(addr result)
    if rate != FpsDefault:
      discard SDL_setFramerate(addr result, uint32(rate))

  proc `rate=`*(manager: var FpsManager, rate: int): bool {.inline, discardable.} =
    ## Sets the target frame rate. Returns `true` on success.
    ## Rate must be between `FpsLowerLimit` and `FpsUpperLimit`.
    ##
    ## ```nim
    ## fps.rate = 60  # Change to 60 FPS
    ## ```
    SDL_setFramerate(addr manager, uint32(rate)) == 0

  proc rate*(manager: var FpsManager): int {.inline.} =
    ## Returns the current target frame rate.
    int(SDL_getFramerate(addr manager))

  proc frameCount*(manager: var FpsManager): int {.inline.} =
    ## Returns the number of frames since the manager was initialized.
    int(SDL_getFramecount(addr manager))

  proc delay*(manager: var FpsManager): int {.inline, discardable.} =
    ## Delays execution to maintain the target frame rate.
    ## Returns the actual delay in milliseconds.
    ## Call this at the end of each frame.
    ##
    ## ```nim
    ## discard fps.delay()  # Maintain frame rate
    ## ```
    int(SDL_framerateDelay(addr manager))
