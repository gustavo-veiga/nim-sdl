## # sdl/active
##
## Application state management for SDL 1.2
##
## This module provides access to the current application state, allowing you to check
## if the window is active, has input focus (keyboard), and if the mouse is over the
## application area.
##
## ## SDL 1.2 Reference
##
## In SDL 1.2, application state is traditionally queried via events (`SDL_APPMOUSEFOCUS`,
## `SDL_APPINPUTFOCUS`, `SDL_APPACTIVE`). This module wraps that functionality in a
## unified, type-safe API.
##
## **Original C function:**
## ```c
## Uint8 SDL_GetAppState(void);
## ```
##
## The return value is a bitmask combining:
## - `SDL_APPMOUSEFOCUS` (0x01) - Mouse is over the window
## - `SDL_APPINPUTFOCUS` (0x02) - Application receives keyboard input
## - `SDL_APPACTIVE` (0x04) - Application is visible (not minimized)
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
##   let state = getAppState()
##
##   if state.hasInputFocus:
##     echo "Ready to receive input"
##
##   if not state.isVisible:
##     echo "Window minimized"
##
##   # Pause logic when minimized
##   if not state.isVisible:
##     delay(100)
##     continue
## ```
##
## ## Advantages over C SDL 1.2
##
## | C SDL 1.2                          | Nim SDL                        |
## |------------------------------------|--------------------------------|
## | `Uint8 state = SDL_GetAppState();` | `let state = getAppState()`    |
## | `if (state & SDL_APPACTIVE)`       | `if state.isVisible`           |
## | `if (state & SDL_APPINPUTFOCUS)`   | `if state.hasInputFocus`       |
## | `if (state & SDL_APPMOUSEFOCUS)`   | `if state.hasMouseFocus`       |
## | No type safety                     | Type-safe enum with `distinct` |
## | Magic constants                    | Semantic, readable API         |
##
## ## Performance
##
## All functions are marked with `{.inline.}` and allocate no memory. The cost is
## equivalent to the direct C call, with no additional overhead.
##
## ## Thread Safety
##
## `getAppState()` can be called from any thread, but reflects the state of the main
## window. In multi-threaded applications, consider caching the state in the main loop.
##
## ## See Also
##
## - `sdl/events` - For responding to state changes via `SDL_ACTIVEEVENT` events
## - `sdl/video` - For window focus and visibility control

import private/utils

# =========================================================
# 1. STATE ENUMS AND MASKS
# =========================================================

type
  AppStateFlag* {.pure, size: sizeof(uint8).} = enum
    ## Individual application state flags.
    mouseFocus = 0x01 ## The mouse is over the window/application area
    inputFocus = 0x02 ## The application has input focus (receives keyboard events)
    active = 0x04     ## The application is visible (not minimized)

  AppState* = distinct uint8
    ## Type-safe combination of application state flags.
    ## Supports bitmask operators (`and`, `or`).

# Inject bitmask template to allow: active or inputFocus
operatorBitmask(AppStateFlag, AppState)

# Borrow basics for comparisons and filtering
proc `==`*(x, y: AppState): bool {.borrow.}
proc `and`*(x, y: AppState): AppState {.borrow.}

# =========================================================
# 2. FFI
# =========================================================
{.push header: "SDL_active.h", importc.}

proc SDL_GetAppState(): uint8

{.pop.}

# =========================================================
# 3. PUBLIC API
# =========================================================

proc getAppState*(): AppState {.inline.} =
  ## Returns the current combined state of the application.
  ##
  ## ```nim
  ## let state = getAppState()
  ## if state.hasInputFocus:
  ##   processKeyboardInput()
  ## ```
  AppState(SDL_GetAppState())

# --- IDIOMATIC HELPERS (Easier reading in Game Loop) ---

proc isVisible*(state: AppState): bool {.inline.} =
  ## Whether the application is visible (not minimized or deactivated).
  ##
  ## ```nim
  ## let state = getAppState()
  ## if state.isVisible:
  ##   screen.flip()  # Only render when visible
  ## ```
  sdlNonZero uint8(state) and uint8(AppStateFlag.active)

proc hasInputFocus*(state: AppState): bool {.inline.} =
  ## Whether the application is capturing keyboard input.
  ##
  ## ```nim
  ## let state = getAppState()
  ## if state.hasInputFocus:
  ##   processKeyboardInput()
  ## ```
  sdlNonZero uint8(state) and uint8(AppStateFlag.inputFocus)

proc hasMouseFocus*(state: AppState): bool {.inline.} =
  ## Whether the mouse cursor is within the application area.
  ##
  ## ```nim
  ## let state = getAppState()
  ## if state.hasMouseFocus:
  ##   updateCustomCursor()
  ## ```
  sdlNonZero uint8(state) and uint8(AppStateFlag.mouseFocus)
