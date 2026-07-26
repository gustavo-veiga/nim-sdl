## # sdl/error
##
## SDL error handling and reporting
##
## This module provides functions to get, set, and clear error messages from SDL.
## Error handling is essential for diagnosing failures in SDL operations like
## initialization, file loading, or device access.
##
## ## SDL 1.2 Reference
##
## SDL 1.2 maintains a thread-local error string that can be set by any SDL function
## that fails. The error message persists until cleared or overwritten by another error.
##
## **Key C functions:**
## ```c
## const char *SDL_GetError(void);
## void SDL_SetError(const char *fmt, ...);
## void SDL_ClearError(void);
## int SDL_Error(SDL_errorcode code);
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
##   if not openAudio(desired, obtained):
##     echo "Audio init failed: ", getError()
##     clearError()  # Clear for next operation
## ```
##
## ## Advantages over C SDL 1.2
##
## | C SDL 1.2                              | Nim SDL                          |
## |----------------------------------------|----------------------------------|
## | `SDL_SetError("%s", msg)` risky        | `setError(msg)` format-safe      |
## | `const char*` return                   | `cstring` (zero allocation)      |
## | Manual error code constants            | Typed `ErrorCode` enum           |
## | No helper functions                    | `outOfMemory()`, `unsupported()` |
##
## ## Security Note
##
## The `setError()` procedure automatically injects `"%s"` as the format string
## to prevent format string vulnerabilities. Passing a message containing `%d`,
## `%x`, or `%n` will not cause undefined behavior.
##
## ## See Also
##
## - `sdl/core` - Initialization functions that may set errors
## - `sdl/video` - Video operations that may fail

{.push header: "SDL_error.h", importc, cdecl.}

# =========================================================
# 1. ENUMS AND CONSTANTS
# =========================================================
type
  ErrorCode* {.importc: "SDL_errorcode", pure, size: sizeof(cint).} = enum
    ## Internal SDL error codes for common failure conditions.
    noMem       = 0  ## Out of memory
    readError   = 1  ## File read error
    writeError  = 2  ## File write error
    seekError   = 3  ## File seek error
    unsupported = 4  ## Operation not supported
    lastError   = 5  ## Marker for last error code

# =========================================================
# 2. FFI - THE C CONTRACT
# =========================================================
proc SDL_SetError(format: cstring) {.varargs.}
proc SDL_GetError(): cstring
proc SDL_ClearError()
proc SDL_Error(code: ErrorCode)

{.pop.}

# =========================================================
# 3. PUBLIC API
# =========================================================

proc getError*(): cstring {.inline.} =
  ## Returns the last SDL error message.
  ## Zero cost: returns `cstring` pointing to SDL's internal static buffer,
  ## avoiding heap allocation.
  ##
  ## ```nim
  ## if not someOperation():
  ##   echo "Failed: ", getError()
  ## ```
  SDL_GetError()

proc setError*(message: string) {.inline.} =
  ## Sets a custom error message.
  ## Format-safe: automatically injects `"%s"` to prevent format string
  ## vulnerabilities if `message` contains `%d`, `%x`, `%n`, etc.
  ##
  ## ```nim
  ## setError("File not found: " & filename)
  ## ```
  SDL_SetError(cstring("%s"), message.cstring)

proc clearError*() {.inline.} =
  ## Clears the current SDL error state.
  ## Call this after handling an error to prevent stale messages.
  SDL_ClearError()

proc setErrorCode*(code: ErrorCode) {.inline.} =
  ## Triggers an internal SDL error code.
  ## Sets the error message to the predefined text for that code.
  SDL_Error(code)

# ---------------------------------------------------------
# PRIVATE C MACROS CONVERTED TO HELPERS
# ---------------------------------------------------------

proc outOfMemory*() {.inline.} =
  ## Helper: Signals out-of-memory condition (maps to SDL_OutOfMemory).
  ## Sets the error code to `noMem`.
  SDL_Error(ErrorCode.noMem)

proc unsupported*() {.inline.} =
  ## Helper: Signals unsupported operation (maps to SDL_Unsupported).
  ## Sets the error code to `unsupported`.
  SDL_Error(ErrorCode.unsupported)
