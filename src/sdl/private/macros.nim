## # sdl/private/macros
##
## Internal error handling macros for SDL operations
##
## This module provides compile-time macros that automatically wrap SDL function
## calls with error checking and panic reporting. These macros are used internally
## by the SDL wrapper to provide safe, fail-fast behavior during development.
##
## ## Overview
##
## The macros intercept SDL function calls and check their return values:
## - `sdlCheck`: For functions returning pointers (nil = failure) or integers (< 0 = failure)
## - `sdlCheckZero`: For functions returning 0 on failure (e.g., Mix_Init, IMG_Init)
##
## ## Error Reporting
##
## When an SDL call fails, the macros:
## 1. Display a panic message with the failed function name
## 2. Include the SDL error message if available (via `SDL_GetError()`)
## 3. Terminate the program with `quit(1)`
##
## ## Usage Example
##
## ```nim
## import sdl/private/macros
##
## # Automatically checks if result is nil or < 0
## let surface = sdlCheck SDL_SetVideoMode(640, 480, 32, SDL_SWSURFACE)
##
## # Automatically checks if result is 0
## let flags = sdlCheckZero IMG_Init(IMG_INIT_PNG)
## ```
##
## ## Build Modes
##
## - **Debug**: Full error messages with SDL error strings
## - **Release**: Minimal error messages (SDL error calls are omitted)
##
## ## See Also
##
## - `sdl/error` - Runtime error handling
## - `sdl/private/utils` - Utility templates for SDL interop

import std/macros

macro sdlCheck*(call: untyped): untyped =
  ## Wraps an SDL call with automatic error checking.
  ## Checks for nil pointers or negative return values.
  ##
  ## ```nim
  ## let surface = sdlCheck SDL_CreateRGBSurface(...)
  ## if surface.isNil:
  ##   # This branch is never reached; macro panics on failure
  ## ```
  let callStr = newLit(call.repr)
  result = quote do:
    let res = `call`
    template sdlErrMsg: string =
      when not defined(release) and compiles(SDL_GetError()):
        let err = $SDL_GetError()
        if err.len > 0: ": " & err else: ""
      else:
        ""

    when compiles(res == nil):
      if res == nil:
        echo "[SDL PANIC] Falha ao executar: ", `callStr`, sdlErrMsg()
        quit(1)
    elif compiles(res < 0):
      if res < 0:
        echo "[SDL PANIC] Falha ao executar: ", `callStr`, sdlErrMsg()
        quit(1)
    res

macro sdlCheckZero*(call: untyped): untyped =
  ## Wraps an SDL call that returns 0 on failure.
  ## Used for initialization functions like `Mix_Init`, `IMG_Init`.
  ##
  ## ```nim
  ## let flags = sdlCheckZero IMG_Init(IMG_INIT_PNG or IMG_INIT_JPG)
  ## ```
  let callStr = newLit(call.repr)
  result = quote do:
    let res = `call`
    if res == 0:
      when compiles(SDL_GetError()):
        let err = $SDL_GetError()
        if err.len > 0:
          echo "[SDL PANIC] Falha ao executar: ", `callStr`, ": ", err
        else:
          echo "[SDL PANIC] Falha ao executar: ", `callStr`
      else:
        echo "[SDL PANIC] Falha ao executar: ", `callStr`
      quit(1)
    res
