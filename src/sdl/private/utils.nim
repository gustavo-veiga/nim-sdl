## # sdl/private/utils
##
## Internal utility templates for SDL wrapper implementation
##
## This module provides zero-cost templates used throughout the SDL wrapper
## for common patterns: RAII hooks, C interop conversions, and result checking.
## These utilities are not part of the public API but are essential for the
## wrapper's internal implementation.
##
## ## Overview
##
## The templates are organized into four categories:
##
## ### 1. Bitmask Operators
## - `operatorBitmask`: Generates `or` operators for combining enum flags
##
## ### 2. RAII Hooks (ARC/ObjectSeq)
## - `destroyImpl`: Implements `=destroy` for RAII types
## - `sinkImpl`: Implements `=sink` for move semantics
## - `copyImpl`: Implements `=copy` with reference counting
##
## ### 3. C Interop Utilities
## - `toOption`: Converts nullable pointers to `Option[T]`
## - `cBuf`: Gets array pointer as `cstring`
## - `cLen`: Gets array length as `cint`
##
## ### 4. Result Checking
## - `sdlOk`: Checks if result is 0 (success)
## - `sdlTrue`: Checks if result is 1 (success)
## - `sdlValid`: Checks if pointer is not nil
## - `sdlNoErr`: Checks if result is not -1 (success)
## - `sdlNonZero`: Checks if result is not 0 (success)
##
## ## Usage Example
##
## ```nim
## import sdl/private/utils
##
## # Define bitmask operators for flags
## type
##   MyFlag = enum flag1, flag2, flag3
##   MyFlags = distinct uint32
##
## operatorBitmask(MyFlag, MyFlags)
##
## # Now you can combine flags:
## let flags = flag1 or flag2
## ```
##
## ## See Also
##
## - `sdl/private/macros` - Error checking macros

import std/options

template operatorBitmask*(TypeEnum, TypeFlags: typedesc) =
  ## Generates `or` operators for combining enum values into a distinct flags type.
  ##
  ## ```nim
  ## type
  ##   Flag = enum a, b, c
  ##   Flags = distinct uint32
  ##
  ## operatorBitmask(Flag, Flags)
  ##
  ## let combined = a or b  # Flags(a.uint32 or b.uint32)
  ## ```
  proc `or`*(a, b: TypeEnum): TypeFlags {.inline.} =
    TypeFlags(uint32(a) or uint32(b))

  proc `or`*(a: TypeFlags, b: TypeEnum): TypeFlags {.inline.} =
    TypeFlags(uint32(a) or uint32(b))

  proc `or`*(a, b: TypeFlags): TypeFlags {.inline.} =
    TypeFlags(uint32(a) or uint32(b))

# ---------------------------------------------------------
# RAII HOOKS
# ---------------------------------------------------------

template destroyImpl*(x, freeFunc: untyped) =
  ## Implements the `=destroy` hook for RAII types.
  ## Calls `freeFunc` on the raw pointer and sets it to nil.
  ##
  ## ```nim
  ## proc `=destroy`*(s: var Surface) = destroyImpl(s, SDL_FreeSurface)
  ## ```
  if x.raw != nil:
    freeFunc(x.raw)
    x.raw = cast[typeof(x.raw)](nil)

template sinkImpl*(dest, src: untyped) =
  ## Implements the `=sink` hook for move semantics.
  ## Destroys the destination and moves the source's raw pointer.
  ##
  ## ```nim
  ## proc `=sink`*(dest: var Surface; source: Surface) = sinkImpl(dest, source)
  ## ```
  `=destroy`(dest)
  dest.raw = src.raw

template copyImpl*(dest, src, refField: untyped) =
  ## Implements the `=copy` hook with reference counting.
  ## Increments the reference count field after copying.
  ##
  ## ```nim
  ## proc `=copy`*(dest: var Surface; source: Surface) = copyImpl(dest, source, refCount)
  ## ```
  if dest.raw == src.raw: return
  `=destroy`(dest)
  dest.raw = src.raw
  if dest.raw != nil:
    inc dest.raw.refField

# ---------------------------------------------------------
# C INTEROP UTILITIES
# ---------------------------------------------------------

template toOption*[T](p: T): Option[T] =
  ## Converts a nullable pointer to an `Option[T]`.
  ## Returns `none(T)` if nil, `some(p)` otherwise.
  ##
  ## ```nim
  ## let ptr = SDL_CreateSurface(...)
  ## let opt = ptr.toOption()
  ## ```
  if p.isNil: none(T) else: some(p)

template toOption*[P, W](ptrExpr: P, WrapperType: typedesc[W]): Option[W] =
  ## Converts a nullable pointer to an `Option[WrapperType]`.
  ## Wraps the pointer in the wrapper type's `raw` field.
  ##
  ## ```nim
  ## let surface = SDL_CreateSurface(...).toOption(Surface)
  ## ```
  let evaluatedPtr = ptrExpr
  if evaluatedPtr.isNil:
    none(WrapperType)
  else:
    some(WrapperType(raw: evaluatedPtr))

template cBuf*(buf: array): cstring =
  ## Returns the array's starting pointer as `cstring`.
  ## Used for passing Nim arrays to C functions expecting strings.
  ##
  ## ```nim
  ## var buffer: array[64, char]
  ## SDL_GetName(buffer.cBuf, buffer.cLen)
  ## ```
  cast[cstring](unsafeAddr buf[0])

template cLen*(buf: array): cint =
  ## Returns the array's length as `cint`.
  ## Used for passing array sizes to C functions.
  cint(buf.len)

template sdlOk*(call: untyped): bool =
  ## Checks if an SDL call succeeded (returns 0).
  ##
  ## ```nim
  ## if sdlOk SDL_LockSurface(surface):
  ##   # Modify pixels
  ##   SDL_UnlockSurface(surface)
  ## ```
  (call == 0)

template sdlTrue*(call: untyped): bool =
  ## Checks if an SDL call succeeded (returns 1).
  ## Used for functions like palette operations.
  (call == 1)

template sdlValid*(call: untyped): bool =
  ## Checks if a pointer is not nil.
  (call != nil)

template sdlNoErr*(call: untyped): bool =
  ## Checks if an SDL call succeeded (returns != -1).
  ## Used for functions where -1 indicates failure.
  (call != -1)

template sdlNonZero*(call: untyped): bool =
  ## Checks if an SDL call succeeded (returns != 0).
  ## Used for functions where any non-zero value indicates success.
  (call != 0)
