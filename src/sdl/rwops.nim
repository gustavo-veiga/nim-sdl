## # sdl/rwops
##
## Abstract I/O operations for reading and writing data
##
## This module provides the `RWops` (Read/Write operations) abstraction for
## reading and writing data from various sources: files, memory buffers, or
## custom streams. It's the foundation for loading images, audio, fonts, and
## other assets in SDL.
##
## ## SDL 1.2 Reference
##
## SDL 1.2 uses `SDL_RWops` as a generic I/O interface. It provides function
## pointers for seek, read, write, and close operations, allowing SDL to load
## assets from any source without knowing the underlying implementation.
##
## **Key C structures and functions:**
## ```c
## typedef struct SDL_RWops {
##     int (SDLCALL *seek)(struct SDL_RWops *context, int offset, int whence);
##     int (SDLCALL *read)(struct SDL_RWops *context, void *ptr, int size, int maxnum);
##     int (SDLCALL *write)(struct SDL_RWops *context, const void *ptr, int size, int num);
##     int (SDLCALL *close)(struct SDL_RWops *context);
##     Uint32 type;
## } SDL_RWops;
##
## SDL_RWops *SDL_RWFromFile(const char *file, const char *mode);
## SDL_RWops *SDL_RWFromMem(void *mem, int size);
## ```
##
## ## Usage Example
##
## ```nim
## import sdl
##
## # Load from file
## var file = openFile("data.bin", "rb")
## if file.isSome:
##   var stream = file.get
##   var data: uint32
##   discard stream.read(data)
##   echo "Read: ", data
##
## # Load from memory
## var buffer = [1'u8, 2, 3, 4]
## var mem = openMemory(addr buffer[0], buffer.len)
## if mem.isSome:
##   var stream = mem.get
##   var value: uint32
##   discard stream.read(value)
## ```
##
## ## Advantages over C SDL 1.2
##
## | C SDL 1.2                             | Nim SDL                       |
## |---------------------------------------|-------------------------------|
## | `SDL_RWFromFile(...)` returns pointer | `openFile()` returns `Option` |
## | Manual `SDL_RWclose()`                | `RWops` RAII auto-close       |
## | `SDL_RWread(ctx, ptr, size, maxnum)`  | Type-safe `read[T]()`         |
## | Manual endianness handling            | `readLE32()`, `readBE32()`    |
## | Unsafe pointer arithmetic             | Safe array operations         |
##
## ## Key Features
##
## - **RAII**: Automatic resource cleanup when `RWops` goes out of scope
## - **Type-safe I/O**: `read[T]()` and `write[T]()` for any type
## - **Endianness helpers**: `readLE16()`, `readBE32()`, etc.
## - **Seek modes**: `seekSet`, `seekCur`, `seekEnd`
## - **Memory sources**: Load from files or memory buffers
##
## ## See Also
##
## - `sdl/video` - Surface loading (BMP)
## - `sdl/image` - Image loading (PNG, JPG, etc.)
## - `sdl/audio` - WAV loading

import std/options
import private/utils

# =========================================================
# 1. ENUMS AND CONSTANTS (Protected from Reserved Words)
# =========================================================
type
  SeekMode* {.pure, size: sizeof(cint).} = enum
    ## Seek mode for positioning in the stream.
    seekSet = 0  ## Seek from the beginning of the file
    seekCur = 1  ## Seek from the current position
    seekEnd = 2  ## Seek from the end of the file

# =========================================================
# 2. C STRUCTURES (Opaque Types and Clean Mapping)
# =========================================================
# Push #1 — Type definition for SDL_RWops.
# Uses `bycopy` (struct passed by value, C convention for function pointer args)
# and `incompleteStruct` (we only need a few fields, rest is hidden).
# Separated from Push #2 because `type` definitions need different pragmas
# than `proc` FFI imports.
{.push header: "SDL_rwops.h", bycopy, cdecl.}

type
  RawRWops {.importc: "SDL_RWops", incompleteStruct.} = object
    ## Internal RWops structure with function pointers.
    seek: proc(context: ptr RawRWops, offset: cint, whence: cint): cint {.cdecl, raises: [].}
    read: proc(context: ptr RawRWops, data: pointer, size: cint, maxnum: cint): cint {.cdecl, raises: [].}
    write: proc(context: ptr RawRWops, data: pointer, size: cint, num: cint): cint {.cdecl, raises: [].}
    close: proc(context: ptr RawRWops): cint {.cdecl, raises: [].}
    kind {.importc: "type".}: uint32

  RawRWopsPtr* = ptr RawRWops
    ## Pointer to the underlying `SDL_RWops` C struct.

{.pop.}

# Push #2 — FFI function imports.
# Uses `importc` to bind C functions by their SDL_ names.
# Separate from Push #1 because `importc` here applies to procs, not types.
# SDL_RWops functions have no `bycopy` requirement — they take/return pointers.
{.push header: "SDL_rwops.h", importc, cdecl}

# Constructors
proc SDL_RWFromFile(file, mode: cstring): RawRWopsPtr
proc SDL_RWFromMem(mem: pointer, size: cint): RawRWopsPtr
proc SDL_RWFromConstMem(mem: pointer, size: cint): RawRWopsPtr
proc SDL_RWFromFP(fp: pointer, autoclose: cint): RawRWopsPtr
proc SDL_AllocRW(): RawRWopsPtr
proc SDL_FreeRW(area: RawRWopsPtr)

# Endianness - Reading
proc SDL_ReadLE16(src: RawRWopsPtr): uint16
proc SDL_ReadBE16(src: RawRWopsPtr): uint16
proc SDL_ReadLE32(src: RawRWopsPtr): uint32
proc SDL_ReadBE32(src: RawRWopsPtr): uint32
proc SDL_ReadLE64(src: RawRWopsPtr): uint64
proc SDL_ReadBE64(src: RawRWopsPtr): uint64

# Endianness - Writing
proc SDL_WriteLE16(dst: RawRWopsPtr, value: uint16): cint
proc SDL_WriteBE16(dst: RawRWopsPtr, value: uint16): cint
proc SDL_WriteLE32(dst: RawRWopsPtr, value: uint32): cint
proc SDL_WriteBE32(dst: RawRWopsPtr, value: uint32): cint
proc SDL_WriteLE64(dst: RawRWopsPtr, value: uint64): cint
proc SDL_WriteBE64(dst: RawRWopsPtr, value: uint64): cint

{.pop.}

# =========================================================
# 3. SMART POINTER (RAII)
# =========================================================
type RWops* {.requiresInit.} = object
  ## RAII wrapper for SDL's RWops I/O abstraction.
  ## Automatically closes the stream when it goes out of scope.
  raw: RawRWopsPtr

proc `=destroy`*(stream: var RWops) =
  ## Closes the stream automatically when RWops goes out of scope.
  if stream.raw != nil:
    discard stream.raw.close(stream.raw)
    stream.raw = nil

proc `=sink`*(dest: var RWops; source: RWops) =
  ## Move semantics: transfers stream ownership without double-close.
  sinkImpl(dest, source)

proc `=copy`*(dest: var RWops, source: RWops) {.error.}
  ## Copying is disabled to prevent double-close. Use move() instead.

proc unsafeRaw*(stream: RWops): RawRWopsPtr {.inline.} = stream.raw
  ## Extracts the raw SDL_RWops pointer. Only valid while `stream` is in scope.

proc assumeRaw*(p: RawRWopsPtr): RWops {.inline.} = RWops(raw: p)
  ## Wraps a raw SDL_RWops pointer into an RWops. Assumes ownership.

# =========================================================
# 4. PUBLIC API
# =========================================================

# ---------------------------------------------------------
# FILE OPENING AND CONTROL
# ---------------------------------------------------------

proc openFile*(file: string, mode: string = "rb"): Option[RWops] {.inline.} =
  ## Opens a file for reading or writing. Returns `some(RWops)` on success, `none` on failure.
  ##
  ## **Example:**
  ## ```nim
  ## let file = openFile("data.bin", "rb")
  ## if file.isSome:
  ##   var stream = file.get
  ##   # Use stream...
  ## ```
  SDL_RWFromFile(file.cstring, mode.cstring).toOption(RWops)

proc openMemory*(mem: pointer, size: int): Option[RWops] {.inline.} =
  ## Creates a RWops stream from a memory buffer. Returns `some(RWops)` on success, `none` on failure.
  ##
  ## **Example:**
  ## ```nim
  ## var buffer = [1'u8, 2, 3, 4]
  ## let mem = openMemory(addr buffer[0], buffer.len)
  ## ```
  SDL_RWFromMem(mem, cint(size)).toOption(RWops)

proc openConstMemory*(mem: pointer, size: int): Option[RWops] {.inline.} =
  ## Creates a read-only RWops stream from a constant memory buffer.
  ## Returns `some(RWops)` on success, `none` on failure.
  SDL_RWFromConstMem(mem, cint(size)).toOption(RWops)

proc openFilePointer*(fp: pointer, autoclose: bool = false): Option[RWops] {.inline.} =
  ## Creates a RWops stream from a C `FILE*` pointer.
  ## If `autoclose` is true, SDL will `fclose` the file when the stream closes.
  SDL_RWFromFP(fp, cint(autoclose)).toOption(RWops)

proc allocRW*(): Option[RWops] {.inline.} =
  ## Allocates an uninitialized RWops struct for custom I/O.
  SDL_AllocRW().toOption(RWops)

proc freeRW*(stream: var RWops) {.inline.} =
  ## Frees an RWops allocated with `allocRW`. The stream is closed first.
  if stream.raw != nil:
    SDL_FreeRW(stream.raw)
    stream.raw = nil

proc close*(stream: var RWops) {.inline.} =
  ## Manually closes the stream.
  ## The stream is also automatically closed when it goes out of scope.
  if stream.raw != nil:
    discard stream.raw.close(stream.raw)
    stream.raw = nil

proc isOpen*(stream: RWops): bool {.inline.} =
  ## Returns `true` if the stream is open.
  stream.raw != nil

# ---------------------------------------------------------
# NAVIGATION
# ---------------------------------------------------------

proc seek*(stream: RWops, offset: int32, mode: SeekMode = SeekMode.seekSet): int32 {.inline.} =
  ## Seeks to a position in the stream. Returns the new position.
  ##
  ## **Example:**
  ## ```nim
  ## stream.seek(0)            # Seek to beginning
  ## stream.seek(100, seekCur) # Skip 100 bytes forward
  ## stream.seek(-50, seekEnd) # Seek 50 bytes before end
  ## ```
  assert stream.raw != nil
  result = int32(stream.raw.seek(stream.raw, cint(offset), cint(mode)))

proc tell*(stream: RWops): int32 {.inline.} =
  ## Returns the current position in the stream in bytes.
  ##
  ## **Example:**
  ## ```nim
  ## let pos = stream.tell()
  ## echo "Current position: ", pos
  ## ```
  assert stream.raw != nil
  result = int32(stream.raw.seek(stream.raw, 0, cint(SeekMode.seekCur)))

# ---------------------------------------------------------
# CORE OPERATIONS
# ---------------------------------------------------------

proc kind*(stream: RWops): uint32 =
  ## Returns the type of the RWops stream (file, memory, etc.).
  stream.raw.kind

proc read*[T](stream: RWops, dest: var T): int32 {.inline.} =
  ## Reads a single value of type `T` from the stream. Returns 1 on success, 0 on failure.
  ##
  ## **Example:**
  ## ```nim
  ## var value: uint32
  ## discard stream.read(value)
  ## ```
  assert stream.raw != nil
  result = int32(stream.raw.read(stream.raw, addr dest, cint(sizeof(T)), 1))

proc readArray*[T](stream: RWops, dest: var openArray[T]): int32 {.inline.} =
  ## Reads an array of values from the stream. Returns the number of items read.
  ##
  ## **Example:**
  ## ```nim
  ## var buffer: array[1024, uint8]
  ## let count = stream.readArray(buffer)
  ## ```
  assert stream.raw != nil
  let p = if dest.len > 0: addr dest[0] else: nil
  result = int32(stream.raw.read(stream.raw, p, cint(sizeof(T)), cint(dest.len)))

proc write*[T](stream: RWops, src: var T): int32 {.inline.} =
  ## Writes a single value of type `T` to the stream. Returns 1 on success, 0 on failure.
  assert stream.raw != nil
  result = int32(stream.raw.write(stream.raw, addr src, cint(sizeof(T)), 1))

proc writeArray*[T](stream: RWops, src: openArray[T]): int32 {.inline.} =
  ## Writes an array of values to the stream. Returns the number of items written.
  assert stream.raw != nil
  let p = if src.len > 0: unsafeAddr src[0] else: nil
  result = int32(stream.raw.write(stream.raw, p, cint(sizeof(T)), cint(src.len)))

# ---------------------------------------------------------
# RAW API (Safe Executable Access to C Pointers)
# ---------------------------------------------------------

proc seek*(ctx: RawRWopsPtr, offset: cint, whence: cint): cint {.inline.} =
  ## Calls the native C seek function.
  ##
  ## **Warning:** Use the high-level `seek()` on `RWops` instead.
  assert ctx != nil, "Null RWops pointer!"
  ctx.seek(ctx, offset, whence)

proc read*(ctx: RawRWopsPtr, ptrData: pointer, size: cint, maxnum: cint): cint {.inline.} =
  ## Calls the native C read function.
  ##
  ## **Warning:** Use the high-level `read[T]()` on `RWops` instead.
  assert ctx != nil, "Null RWops pointer!"
  ctx.read(ctx, ptrData, size, maxnum)

proc write*(ctx: RawRWopsPtr, ptrData: pointer, size: cint, num: cint): cint {.inline.} =
  ## Calls the native C write function.
  ##
  ## **Warning:** Use the high-level `write[T]()` on `RWops` instead.
  assert ctx != nil, "Null RWops pointer!"
  ctx.write(ctx, ptrData, size, num)

proc close*(ctx: RawRWopsPtr): cint {.inline.} =
  ## Calls the native C close function.
  ##
  ## **Warning:** Use the high-level `close()` on `RWops` instead.
  assert ctx != nil, "Null RWops pointer!"
  ctx.close(ctx)

# ---------------------------------------------------------
# ENDIANNESS (Quick shortcuts)
# ---------------------------------------------------------
proc readLE16*(stream: RWops): uint16 {.inline.} =
  ## Reads a 16-bit value in little-endian format.
  SDL_ReadLE16(stream.raw)

proc readLE32*(stream: RWops): uint32 {.inline.} =
  ## Reads a 32-bit value in little-endian format.
  SDL_ReadLE32(stream.raw)

proc readLE64*(stream: RWops): uint64 {.inline.} =
  ## Reads a 64-bit value in little-endian format.
  SDL_ReadLE64(stream.raw)

proc readBE16*(stream: RWops): uint16 {.inline.} =
  ## Reads a 16-bit value in big-endian format.
  SDL_ReadBE16(stream.raw)

proc readBE32*(stream: RWops): uint32 {.inline.} =
  ## Reads a 32-bit value in big-endian format.
  SDL_ReadBE32(stream.raw)

proc readBE64*(stream: RWops): uint64 {.inline.} =
  ## Reads a 64-bit value in big-endian format.
  SDL_ReadBE64(stream.raw)

proc writeLE16*(stream: RWops, value: uint16): bool {.inline.} =
  ## Writes a 16-bit value in little-endian format. Returns `true` on success.
  (SDL_WriteLE16(stream.raw, value) == 1)

proc writeLE32*(stream: RWops, value: uint32): bool {.inline.} =
  ## Writes a 32-bit value in little-endian format. Returns `true` on success.
  (SDL_WriteLE32(stream.raw, value) == 1)

proc writeLE64*(stream: RWops, value: uint64): bool {.inline.} =
  ## Writes a 64-bit value in little-endian format. Returns `true` on success.
  (SDL_WriteLE64(stream.raw, value) == 1)

proc writeBE16*(stream: RWops, value: uint16): bool {.inline.} =
  ## Writes a 16-bit value in big-endian format. Returns `true` on success.
  (SDL_WriteBE16(stream.raw, value) == 1)

proc writeBE32*(stream: RWops, value: uint32): bool {.inline.} =
  ## Writes a 32-bit value in big-endian format. Returns `true` on success.
  (SDL_WriteBE32(stream.raw, value) == 1)

proc writeBE64*(stream: RWops, value: uint64): bool {.inline.} =
  ## Writes a 64-bit value in big-endian format. Returns `true` on success.
  (SDL_WriteBE64(stream.raw, value) == 1)
