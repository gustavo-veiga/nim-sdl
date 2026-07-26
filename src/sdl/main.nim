## # sdl/main
##
## Platform-specific entry point handling
##
## This module handles the quirks of SDL's main function across different platforms.
## On Windows, SDL requires a special entry point (`SDL_main`). On Linux, BSD, and
## Dreamcast, SDL uses the native entry point. This module provides the `runMain`
## template to handle these differences transparently.
##
## ## SDL 1.2 Reference
##
## SDL 1.2 redefines `main` on Windows to `SDL_main` to ensure proper initialization.
## On other platforms, SDL uses the standard `main` function. This module abstracts
## away these platform differences.
##
## **Key C functions (Windows only):**
## ```c
## int SDL_RegisterApp(char *name, Uint32 style, void *hInstance);
## void SDL_SetModuleHandle(void *hInstance);
## void SDL_UnregisterApp(void);
## ```
##
## ## Usage Example
##
## ```nim
## import sdl
##
## runMain:
##   let ctx = sdlInit()
##   defer: ctx.quit()
##
##   # Your game code here
##   let screen = setVideoMode(640, 480, 32, sdlSwSurface)
##   # ...
## ```
##
## ## Platform Support
##
## | Platform    | Entry Point  | Notes                              |
## |-------------|--------------|------------------------------------|
## | Windows     | `SDL_main`   | Requires `SDL_RegisterApp`         |
## | Linux/BSD   | `main`       | Native entry point                 |
## | Dreamcast   | `main`       | Native entry point (KallistiOS)    |
## | macOS       | `main`       | Requires `SDL_InitQuickDraw`       |
##
## ## Windows-Specific Functions
##
## On Windows, you may need to register your application with the OS:
##
## ```nim
## when defined(windows):
##   registerApp("MyGame", 0, nil)
## ```
##
## ## Advantages over C SDL 1.2
##
## | C SDL 1.2                         | Nim SDL                      |
## |-----------------------------------|------------------------------|
## | `#ifdef WIN32` manual entry point | `runMain:` template          |
## | Platform-specific `#include`      | Automatic platform detection |
## | Manual `SDL_RegisterApp` call     | Handled by `runMain`         |
##
## ## See Also
##
## - `sdl/core` - SDL initialization and subsystem management

# =========================================================
# THE SDL_MAIN SECRET (System-Specific I/O)
# =========================================================
# On Linux (including Flatpaks), BSD, and Dreamcast (KallistiOS),
# SDL does not interfere with the native binary entry point.
# This file only handles the peculiarities of specific operating systems.

# =========================================================
# 1. FFI
# =========================================================
{.push header: "SDL_main.h", importc, cdecl.}

when defined(windows):
  proc SDL_RegisterApp(name: cstring, style: uint32, hInstance: pointer): cint
  proc SDL_SetModuleHandle(hInstance: pointer)
  proc SDL_UnregisterApp()

elif defined(macosx) or defined(macos):
  type QDGlobals* {.incompleteStruct.} = object
    ## Legacy QuickDraw globals structure for Apple video initialization.
  proc SDL_InitQuickDraw(qd: ptr QDGlobals)

{.pop.}

# =========================================================
# 2. PUBLIC API
# =========================================================

when defined(windows):
  proc registerApp*(name: string, style: uint32, hInstance: pointer): bool {.inline.} =
    ## Registers the window class on Windows.
    ## `SDL_Init` already does this internally, so manual registration is rarely needed.
    ## Returns `true` on success, `false` on failure.
    result = (SDL_RegisterApp(name.cstring, style, hInstance) == 0)

  proc setModuleHandle*(hInstance: pointer) {.inline.} =
    ## Sets the module handle (HINSTANCE) for SDL to use on Windows.
    SDL_SetModuleHandle(hInstance)

  proc unregisterApp*() {.inline.} =
    ## Unregisters the window class on shutdown.
    ## Called automatically by SDL, but available for manual cleanup if needed.
    SDL_UnregisterApp()

elif defined(macosx) or defined(macos):
  proc initQuickDraw*(qd: ptr QDGlobals) {.inline.} =
    ## Initializes the legacy Apple video subsystem on macOS.
    SDL_InitQuickDraw(qd)

template runMain*(body: untyped) =
  ## Entry point template that handles platform-specific main function requirements.
  ##
  ## On Windows, this generates an `SDL_main` function and emits C code to call it
  ## from the actual `main` function. On other platforms, it simply executes the body.
  ##
  ## **Usage:**
  ## ```nim
  ## runMain:
  ##   let ctx = sdlInit()
  ##   defer: ctx.quit()
  ##   # Your game code here
  ## ```
  when defined(windows):
    proc sdlMain() {.exportc: "SDLMain", cdecl.} =
      body

    {.emit: """
    #ifdef __cplusplus
    extern "C" {
    #endif

    extern void NimMain(void);
    extern void SDLMain(void);

    int SDL_main(int argc, char** argv) {
        NimMain();
        SDLMain();
        return 0;
    }

    #ifdef __cplusplus
    }
    #endif
    """.}

  else:
    proc sdlMain() =
      body

    sdlMain()
