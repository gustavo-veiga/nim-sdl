## # sdl
##
## Main entry point for the SDL 1.2 Nim wrapper
##
## This module re-exports all core SDL functionality, allowing you to access the entire
## SDL 1.2 API through a single import: `import sdl`.
##
## ## Core Modules
##
## The following modules are always available and provide the fundamental SDL 1.2 features:
##
## | Module         | Description                                                          |
## |----------------|----------------------------------------------------------------------|
## | `sdl/core`     | Initialization, shutdown, and subsystem management                   |
## | `sdl/video`    | Window/surface creation, pixel formats, blitting, display management |
## | `sdl/events`   | Event loop, input event processing                                   |
## | `sdl/keyboard` | Keyboard state querying and key event handling                       |
## | `sdl/keysym`   | Key symbol definitions and modifier flags                            |
## | `sdl/mouse`    | Mouse state, button tracking, cursor management                      |
## | `sdl/joystick` | Joystick enumeration and input reading                               |
## | `sdl/audio`    | Audio device management, WAV loading, format conversion              |
## | `sdl/cdrom`    | CD-ROM drive enumeration and control                                 |
## | `sdl/timer`    | Time measurement, delays, and timer callbacks                        |
## | `sdl/error`    | Error message handling                                               |
## | `sdl/active`   | Application state queries (focus, visibility)                        |
## | `sdl/cpuinfo`  | CPU feature detection (SSE, MMX, etc.)                               |
## | `sdl/version`  | SDL version information                                              |
## | `sdl/rwops`    | Abstract I/O operations (files, memory)                              |
## | `sdl/endian`   | Endianness detection and byte swapping                               |
## | `sdl/main`     | Platform-specific entry point handling                               |
##
## ## Optional Modules (Require Compile Flags)
##
## Additional functionality is available through companion libraries. These modules
## are NOT imported by default and require specific compile flags:
##
## | Module             | Library   | Compile Flag | Description                                      |
## |--------------------|-----------|--------------|--------------------------------------------------|
## | `sdl/mixer`        | SDL_mixer | `-d:mixer`   | Audio mixing, music playback, sound effects      |
## | `sdl/image`        | SDL_image | `-d:image`   | Image loading (PNG, JPG, BMP, etc.)              |
## | `sdl/ttf`          | SDL_ttf   | `-d:ttf`     | TrueType font rendering                          |
## | `sdl/net`          | SDL_net   | `-d:net`     | Network communication (TCP/UDP)                  |
## | `sdl/rotozoom`     | SDL_gfx   | `-d:gfx`     | Surface rotation and scaling                     |
## | `sdl/framerate`    | SDL_gfx   | `-d:gfx`     | Frame rate control                               |
## | `sdl/gfxprimitives`| SDL_gfx   | `-d:gfx`     | Drawing primitives (lines, circles, polygons)    |
## | `sdl/gfxfilter`    | SDL_gfx   | `-d:gfx`     | MMX-accelerated byte-image filters               |
## | `sdl/rtf`          | SDL_rtf   | `-d:rtf`     | Rich Text Format rendering                       |
## | `sdl/pango`        | SDL_Pango | `-d:pango`   | Complex text layout with Pango                   |
##
## ## Usage Example
##
## ```nim
## import sdl
##
## runMain:
##   let ctx = sdlInit(sdlInitVideo or sdlInitAudio)
##   defer: ctx.quit()
##
##   let screen = setVideoMode(640, 480, 32, sdlSwSurface)
##   setCaption("My SDL Game")
##
##   var running = true
##   while running:
##     for event in pollEvents():
##       if event.kind == quit:
##         running = false
##
##     discard screen.fill(initRect(0, 0, 640, 480), mapRGB(screen, 100, 149, 237))
##     discard screen.flip()
##     delay(16)
## ```
##
## ## Compiling with Optional Libraries
##
## ```bash
## # Core SDL only
## nim c mygame.nim
##
## # With SDL_mixer and SDL_image
## nim c -d:mixer -d:image mygame.nim
## ```
##
## ## See Also
##
## - [SDL 1.2 Documentation](https://www.libsdl.org/release/SDL-1.2.15/docs/html/index.html)
## - Individual module documentation for detailed API reference

import
  sdl/core,
  sdl/video,
  sdl/events,
  sdl/keyboard,
  sdl/keysym,
  sdl/mouse,
  sdl/joystick,
  sdl/audio,
  sdl/cdrom,
  sdl/timer,
  sdl/error,
  sdl/active,
  sdl/cpuinfo,
  sdl/version,
  sdl/rwops,
  sdl/endian,
  sdl/main

export
  core,
  video,
  events,
  keyboard,
  keysym,
  mouse,
  joystick,
  audio,
  cdrom,
  timer,
  error,
  active,
  cpuinfo,
  version,
  rwops,
  endian,
  main
