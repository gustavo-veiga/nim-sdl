## # sdl/timer
##
## Time measurement and timer management
##
## This module provides functions for measuring elapsed time, delaying execution,
## and creating asynchronous timers that run callbacks in the background.
##
## ## SDL 1.2 Reference
##
## SDL 1.2 provides millisecond-precision timing through `SDL_GetTicks()` and
## `SDL_Delay()`. For asynchronous timers, `SDL_AddTimer()` creates a timer that
## calls a callback function at regular intervals.
##
## **Key C functions:**
## ```c
## Uint32 SDL_GetTicks(void);
## void SDL_Delay(Uint32 ms);
## SDL_TimerID SDL_AddTimer(Uint32 interval, SDL_NewTimerCallback callback, void *param);
## SDL_bool SDL_RemoveTimer(SDL_TimerID id);
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
##   # Measure elapsed time
##   let start = getTicks()
##   # ... do work ...
##   let elapsed = getTicks() - start
##   echo "Elapsed: ", elapsed, " ms"
##
##   # Delay execution
##   delay(100)  # Wait 100 milliseconds
##
##   # Async timer
##   proc timerCallback(interval: uint32, param: pointer): uint32 {.cdecl.} =
##     echo "Timer fired!"
##     return interval  # Continue timer
##
##   let timer = addTimer(1000, timerCallback)  # Fire every 1000ms
##   defer: timer.get().remove()
## ```
##
## ## Advantages over C SDL 1.2
##
## | C SDL 1.2                                 | Nim SDL                              |
## |-------------------------------------------|--------------------------------------|
## | `SDL_GetTicks()` returns `Uint32`         | `getTicks()` returns `uint32`        |
## | `SDL_AddTimer(...)` returns `SDL_TimerID` | `addTimer()` returns `Option[Timer]` |
## | Manual `SDL_RemoveTimer()`                | `Timer` RAII auto-remove             |
## | No type safety on callback                | `TimerCallback` type alias           |
##
## ## Key Features
##
## - **High-resolution timing**: Millisecond precision
## - **RAII timers**: Automatic cleanup when `Timer` goes out of scope
## - **Async callbacks**: Timer callbacks run in a background thread
## - **Return value**: Callbacks return the next interval (0 to stop)
##
## ## Timer Callback
##
## Timer callbacks must follow the `TimerCallback` signature and return the next
## interval in milliseconds. Return 0 to stop the timer.
##
## ```nim
## proc myCallback(interval: uint32, param: pointer): uint32 {.cdecl.} =
##   # Do work...
##   return interval  # Continue with same interval
##   # return 0       # Stop the timer
## ```
##
## ## See Also
##
## - `sdl/framerate` - Frame rate control using timers
## - `sdl/core` - SDL initialization

import std/options
import private/utils

when defined(debug):
  import error

# =========================================================
# 1. CONSTANTS AND TYPES
# =========================================================
const
  timeSlice* = 10'u32
    ## Default time slice in milliseconds.
  timerResolution* = 10'u32
    ## Timer resolution in milliseconds.

type
  OldTimerCallback* = proc(interval: uint32): uint32 {.cdecl.}
    ## Legacy timer callback (SDL 1.2 classic style).
  TimerCallback* = proc(interval: uint32, param: pointer): uint32 {.cdecl.}
    ## Modern timer callback with user data parameter.

# =========================================================
# 2. FFI - C CONTRACT
# =========================================================
{.push header: "SDL_timer.h", importc, cdecl.}

type
  RawTimer {.incompleteStruct.} = object
  RawTimerPtr* = ptr RawTimer

proc SDL_GetTicks(): uint32
proc SDL_Delay(ms: uint32)
proc SDL_SetTimer(interval: uint32, callback: OldTimerCallback): cint
proc SDL_AddTimer(interval: uint32, callback: TimerCallback, param: pointer): RawTimerPtr
proc SDL_RemoveTimer(t: RawTimerPtr): cint

{.pop.}

# =========================================================
# 3. SMART POINTER (RAII for Background Callbacks)
# =========================================================
type Timer* {.requiresInit.} = object
  ## RAII wrapper for an asynchronous timer.
  ## Automatically removes the timer when it goes out of scope.
  raw: RawTimerPtr

proc `=destroy`*(t: var Timer) =
  if t.raw != nil:
    let success = SDL_RemoveTimer(t.raw)
    if success == 0:
      when defined(debug):
        debugEcho error.getError()
    t.raw = nil

proc `=sink`*(dest: var Timer; source: Timer) = sinkImpl(dest, source)
proc `=copy`*(dest: var Timer; source: Timer) {.error.}

proc unsafeRaw*(t: Timer): RawTimerPtr {.inline.} = t.raw
proc assumeRaw*(p: RawTimerPtr): Timer {.inline.} = Timer(raw: p)

# =========================================================
# 4. BASE PUBLIC API (Control and Timers)
# =========================================================

proc getTicks*(): uint32 {.inline.} =
  ## Milliseconds since `sdlInit()`.
  ##
  ## **Example:**
  ## ```nim
  ## let start = getTicks()
  ## # ... do work ...
  ## let elapsed = getTicks() - start
  ## ```
  SDL_GetTicks()

proc delay*(ms: uint32) {.inline.} =
  ## Pauses the current thread for the specified milliseconds.
  ##
  ## **Example:**
  ## ```nim
  ## delay(100)  # Wait 100 milliseconds
  ## ```
  SDL_Delay(ms)

proc setSingleTimer*(interval: uint32, callback: OldTimerCallback): bool {.inline.} =
  ## Sets a global timer that calls the callback at regular intervals.
  ## Pass 0 to cancel the timer. Only one global timer can be active.
  ##
  ## **Example:**
  ## ```nim
  ## proc myTimer(interval: uint32): uint32 {.cdecl.} =
  ##   echo "Timer!"
  ##   return interval
  ##
  ## discard setSingleTimer(1000, myTimer)  # Fire every second
  ## discard setSingleTimer(0, nil)         # Cancel timer
  ## ```
  sdlOk SDL_SetTimer(interval, callback)

proc addTimer*(interval: uint32, callback: TimerCallback, param: pointer = nil): Option[Timer] {.inline.} =
  ## Creates an asynchronous timer that runs in the background.
  ## Protected by RAII: when the timer goes out of scope, it's automatically removed.
  ##
  ## **Example:**
  ## ```nim
  ## proc myCallback(interval: uint32, param: pointer): uint32 {.cdecl.} =
  ##   echo "Timer fired!"
  ##   return interval  # Continue timer
  ##
  ## let timer = addTimer(1000, myCallback)
  ## if timer.isSome:
  ##   defer: timer.get().remove()
  ##   # Timer runs in background...
  ## ```
  let p = SDL_AddTimer(interval, callback, param)
  if p == nil: none(Timer)
  else: some(Timer(raw: p))

proc remove*(t: var Timer): bool {.inline.} =
  ## Manually removes and destroys a timer before it goes out of scope.
  ##
  ## **Example:**
  ## ```nim
  ## var timer = addTimer(1000, myCallback).get
  ## # ... later ...
  ## discard timer.remove()
  ## ```
  if t.raw != nil:
    result = sdlNonZero SDL_RemoveTimer(t.raw)
    t.raw = nil
