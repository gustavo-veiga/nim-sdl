## # sdl/endian
##
## Endianness detection and byte-swapping utilities.
##
## Provides compile-time endian detection and efficient byte-swapping for 16, 32,
## and 64-bit values. The swapLE/SwapBE variants are conditional — they only swap
## when the host byte order differs from the requested order, making them
## zero-cost for natively-ordered data.
##
## ## SDL 1.2 Reference
##
## SDL 1.2 provides the `SDL_endian.h` header with macros for byte order detection
## (`SDL_BYTEORDER`, `SDL_LIL_ENDIAN`, `SDL_BIG_ENDIAN`) and byte swapping
## (`SDL_Swap16/32/64`, `SDL_SwapLE/BE16/32/64`). This module implements the same
## functionality using pure Nim, avoiding any C dependency.
##
## **Key C macros:**
## ```c
## #define SDL_LIL_ENDIAN  1234
## #define SDL_BIG_ENDIAN  4321
## #define SDL_BYTEORDER   SDL_LIL_ENDIAN  // (or SDL_BIG_ENDIAN)
## #define SDL_Swap16(x)   ...
## #define SDL_SwapLE32(x) ...
## ```
##
## ## Advantages over C SDL 1.2
##
## | C SDL 1.2                     | Nim SDL                    |
## |-------------------------------|----------------------------|
## | C macros, no type safety      | Pure Nim functions, typed  |
## | `Uint16`/`Uint32`/`Uint64`    | `uint16`/`uint32`/`uint64` |
## | Platform detection via macro  | `isLittleEndian` constant  |
## | Manual `#ifdef` for endianness| Compile-time `when` idioms |
##
## ## Usage Example
##
## ```nim
## import sdl
##
## let ctx = sdlInit()
## defer: ctx.quit()
##
## # Check platform endianness
## when isBigEndian:
##   echo "Running on big-endian hardware"
##
## # Read a 16-bit value from a big-endian stream
## var buf: array[2, uint8] = [0x12'u8, 0x34'u8]
## let val = swapBE16(cast[ptr uint16](addr buf[0])[])
## echo val.toHex  # 0x1234
## ```
##
## ## See Also
##
## - `sdl/rwops` - Read/write LE/BE values from I/O streams

type
  EndianOrder* {.pure.} = enum
    ## Platform byte order identifier.
    unknown  = 0   ## Undetermined byte order
    little   = 1234  ## Least significant byte first (e.g., x86, x64)
    big      = 4321  ## Most significant byte first (e.g., network protocols)

when system.cpuEndian == system.littleEndian:
  const
    byteOrder* = 1234
      ## Numeric byte order identifier for the current platform.
      ## Matches `SDL_LIL_ENDIAN` (1234) on little-endian or `SDL_BIG_ENDIAN` (4321) on big-endian.
    isLittleEndian* = true
      ## Compile-time constant: `true` on little-endian platforms (x86, x64).
    isBigEndian* = false
      ## Compile-time constant: `true` on big-endian platforms (PowerPC, SPARC, network byte order).
elif system.cpuEndian == system.bigEndian:
  const
    byteOrder* = 4321
    isLittleEndian* = false
    isBigEndian* = true

func swap16*(x: uint16): uint16 {.inline.} =
  ## Swaps the byte order of a 16-bit unsigned integer.
  ##
  ## **Example:**
  ## ```nim
  ## swap16(0x1234'u16)  # 0x3412
  ## ```
  (x shl 8) or (x shr 8)

func swap32*(x: uint32): uint32 {.inline.} =
  ## Swaps the byte order of a 32-bit unsigned integer.
  ##
  ## **Example:**
  ## ```nim
  ## swap32(0x12345678'u32)  # 0x78563412
  ## ```
  (x shl 24) or ((x shl 8) and 0x00FF0000'u32) or ((x shr 8) and 0x0000FF00'u32) or (x shr 24)

func swap64*(x: uint64): uint64 {.inline.} =
  ## Swaps the byte order of a 64-bit unsigned integer.
  ##
  ## **Example:**
  ## ```nim
  ## swap64(0x0102030405060708'u64)  # 0x0807060504030201
  ## ```
  let lo = swap32(uint32(x and 0xFFFFFFFF'u64))
  let hi = swap32(uint32(x shr 32))
  (uint64(lo) shl 32) or uint64(hi)

func swapLE16*(x: uint16): uint16 {.inline.} =
  ## Converts a 16-bit value from native byte order to little-endian (no-op on LE hosts).
  when system.cpuEndian == system.littleEndian: x else: swap16(x)

func swapLE32*(x: uint32): uint32 {.inline.} =
  ## Converts a 32-bit value from native byte order to little-endian (no-op on LE hosts).
  when system.cpuEndian == system.littleEndian: x else: swap32(x)

func swapLE64*(x: uint64): uint64 {.inline.} =
  ## Converts a 64-bit value from native byte order to little-endian (no-op on LE hosts).
  when system.cpuEndian == system.littleEndian: x else: swap64(x)

func swapBE16*(x: uint16): uint16 {.inline.} =
  ## Converts a 16-bit value from native byte order to big-endian (no-op on BE hosts).
  ##
  ## **Example:**
  ## ```nim
  ## # On little-endian x86:
  ## swapBE16(0x1234'u16)  # 0x3412
  ## ```
  when system.cpuEndian == system.bigEndian: x else: swap16(x)

func swapBE32*(x: uint32): uint32 {.inline.} =
  ## Converts a 32-bit value from native byte order to big-endian (no-op on BE hosts).
  when system.cpuEndian == system.bigEndian: x else: swap32(x)

func swapBE64*(x: uint64): uint64 {.inline.} =
  ## Converts a 64-bit value from native byte order to big-endian (no-op on BE hosts).
  when system.cpuEndian == system.bigEndian: x else: swap64(x)
