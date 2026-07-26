## # sdl/cpuinfo
##
## CPU capability detection for runtime optimization
##
## This module provides functions to detect CPU features at runtime, allowing
## you to choose optimized code paths for SIMD instructions (MMX, SSE, AltiVec, etc.).
##
## ## SDL 1.2 Reference
##
## SDL 1.2 provides CPU feature detection to help applications select the best
## code path for the current processor. These functions are particularly useful
## for performance-critical code like audio mixing, image processing, or physics.
##
## **Key C functions:**
## ```c
## SDL_bool SDL_HasRDTSC(void);
## SDL_bool SDL_HasMMX(void);
## SDL_bool SDL_HasSSE(void);
## SDL_bool SDL_HasSSE2(void);
## SDL_bool SDL_Has3DNow(void);
## SDL_bool SDL_HasAltiVec(void);
## ```
##
## ## Usage Example
##
## ```nim
## import sdl
##
## # Choose optimized code path based on CPU capabilities
## if hasSse2():
##   processWithSse2(data)
## elif hasSse():
##   processWithSse(data)
## elif hasMmx():
##   processWithMmx(data)
## else:
##   processGeneric(data)
## ```
##
## ## Advantages over C SDL 1.2
##
## | C SDL 1.2                              | Nim SDL                          |
## |----------------------------------------|----------------------------------|
## | `SDL_HasSSE()` returns `SDL_bool`      | `hasSse()` returns native `bool` |
## | Manual casting required                | Automatic conversion             |
##
## ## Platform Notes
##
## - **x86/x64**: RDTSC, MMX, SSE, SSE2, 3DNow! detection available
## - **PowerPC**: AltiVec detection available
## - All functions are `{.inline.}` with zero overhead after optimization

import private/utils

# =========================================================
# 1. C STRUCTURES AND FFI (Strict ABI Contract)
# =========================================================
{.push header: "SDL_cpuinfo.h", importc.}

# CRITICAL ABI FIX: SDL_bool is an enum in C (4 bytes).
# We can't map it directly to Nim's 'bool' (1 byte).
# We use 'cint' in FFI and do safe conversion in the API.

proc SDL_HasRDTSC(): cint
proc SDL_HasMMX(): cint
proc SDL_HasMMXExt(): cint
proc SDL_Has3DNow(): cint
proc SDL_Has3DNowExt(): cint
proc SDL_HasSSE(): cint
proc SDL_HasSSE2(): cint
proc SDL_HasAltiVec(): cint

{.pop.}

# =========================================================
# 2. PUBLIC API (Zero Cost and Safe Conversion)
# =========================================================

# We use 'inline' so the compiler substitutes the call directly.
# The '  '(X != 0)' conversion is optimized to zero overhead.

proc hasRdtsc*(): bool {.inline.} =
  ## Returns `true` if the CPU supports the RDTSC instruction (Timestamp Counter).
  ## Useful for high-resolution timing on x86 processors.
  sdlNonZero SDL_HasRDTSC()

proc hasMmx*(): bool {.inline.} =
  ## Returns `true` if the CPU supports MMX instructions.
  ## Common on x86 processors since Pentium MMX.
  sdlNonZero SDL_HasMMX()

proc hasMmxExt*(): bool {.inline.} =
  ## Returns `true` if the CPU supports MMX extensions.
  ## Additional MMX instructions added in later processors.
  sdlNonZero SDL_HasMMXExt()

proc has3DNow*(): bool {.inline.} =
  ## Returns `true` if the CPU supports 3DNow! instructions.
  ## AMD's SIMD instruction set (older AMD CPUs).
  sdlNonZero SDL_Has3DNow()

proc has3DNowExt*(): bool {.inline.} =
  ## Returns `true` if the CPU supports 3DNow! extensions.
  ## Additional 3DNow! instructions in newer AMD processors.
  sdlNonZero SDL_Has3DNowExt()

proc hasSse*(): bool {.inline.} =
  ## Returns `true` if the CPU supports Streaming SIMD Extensions (SSE).
  ## Essential for heavy vector math operations on x86.
  sdlNonZero SDL_HasSSE()

proc hasSse2*(): bool {.inline.} =
  ## Returns `true` if the CPU supports SSE2 instructions.
  ## Enhanced SSE with integer operations and double-precision floats.
  sdlNonZero SDL_HasSSE2()

proc hasAltiVec*(): bool {.inline.} =
  ## Returns `true` if the CPU supports AltiVec (Velocity Engine) instructions.
  ## SIMD instruction set for PowerPC architectures (used in older Macs and game consoles).
  sdlNonZero SDL_HasAltiVec()
