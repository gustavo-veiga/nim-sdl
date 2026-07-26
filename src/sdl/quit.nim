## # sdl/quit
##
## Application quit event detection
##
## This module provides a simple utility to check if the user has requested
## to quit the application (e.g., by closing the window or pressing Alt+F4).
##
## ## Overview
##
## The `quitRequested()` procedure pumps the event queue and checks for
## pending quit events without removing them. This allows you to detect
## quit requests at any point in your game loop.
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
##   var running = true
##   while running:
##     # Check for quit request
##     if quitRequested():
##       running = false
##       break
##
##     # Process other events
##     for event in pollEvents():
##       case event.kind
##       of keyDown:
##         # Handle key press
##       else: discard
##
##     # Render frame
##     screen.flip()
## ```
##
## ## Advantages over Manual Event Checking
##
## | Manual Approach                    | quitRequested()                |
## |------------------------------------|--------------------------------|
## | `pumpEvents(); hasEvent(quitMask)` | `quitRequested()`              |
## | Two function calls                 | One function call              |
## | Easy to forget pump step           | Handles pumping internally     |
##
## ## See Also
##
## - `sdl/events` - Full event processing system
## - `sdl/core` - SDL initialization and shutdown

import events

# =========================================================
# PUBLIC API (Original macro converted to inline function)
# =========================================================

proc quitRequested*(): bool {.inline.} =
  ## Checks if the user has requested to quit the application.
  ##
  ## This function:
  ## 1. Pumps the OS event queue to synchronize with SDL
  ## 2. Peeks for pending quit events without removing them
  ##
  ## Returns `true` if a quit event is pending, `false` otherwise.
  ##
  ## ```nim
  ## while running:
  ##   if quitRequested():
  ##     running = false
  ## ```
  pumpEvents()
  result = hasEvent(quitMask)
