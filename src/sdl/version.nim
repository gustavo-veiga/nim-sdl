## # sdl/version
##
## SDL version information and comparison
##
## This module provides access to SDL version information, allowing you to
## query both the compiled version (at compile time) and the linked version
## (at runtime). It also provides version comparison operators.
##
## ## SDL 1.2 Reference
##
## SDL 1.2 provides version information through the `SDL_version` structure
## and related functions. The compiled version is determined by preprocessor
## macros, while the linked version is retrieved at runtime.
##
## **Key C structures and functions:**
## ```c
## typedef struct {
##     Uint8 major;
##     Uint8 minor;
##     Uint8 patch;
## } SDL_version;
##
## const SDL_version *SDL_Linked_Version(void);
## ```
##
## ## Usage Example
##
## ```nim
## import sdl
##
## let compiled = sdlCompiledVersion()
## echo "Compiled against SDL ", compiled
##
## let linked = sdlLinkedVersion()
## if linked.isSome:
##   echo "Linked with SDL ", linked.get
##
## # Version comparison
## if compiled >= Version(major: 1, minor: 2, patch: 0):
##   echo "SDL 1.2.0 or later is available"
## ```
##
## ## Advantages over C SDL 1.2
##
## | C SDL 1.2                         | Nim SDL                       |
## |-----------------------------------|-------------------------------|
## | `SDL_version v; v.major; v.minor` | `Version(major: 1, minor: 2)` |
## | Manual field access               | Dot notation: `v.major`       |
## | No comparison operators           | `==`, `<`, `<=` operators     |
## | `printf("%d.%d.%d", ...)`         | `$version` or `toCstring()`   |
##
## ## Version Comparison
##
## Versions are compared lexicographically: major first, then minor, then patch.
##
## ```nim
## let v1 = Version(major: 1, minor: 2, patch: 10)
## let v2 = Version(major: 1, minor: 2, patch: 9)
## assert v1 > v2  # 1.2.10 > 1.2.9
## ```
##
## ## String Formatting
##
## Three ways to format a version:
##
## | Method                   | Allocation                | Thread-safe | Expression-safe | Best for                             |
## |--------------------------|---------------------------|-------------|-----------------|--------------------------------------|
## | `$version`               | Heap (`string`)           | Yes         | Yes             | General use, `echo`, string building |
## | `version.toCstring(buf)` | Stack (`array[16, char]`) | Yes         | Yes             | Hot paths, no-heap environments      |
## | `version.toCstring()`    | BSS (global buffer)       | **No**      | **No**          | C interop only                       |
##
## ```nim
## echo "SDL version: ", $version     # heap string
## var buf: array[16, char]
## echo version.toCstring(buf)        # stack buffer, thread-safe
## ```
##
## ## See Also
##
## - `sdl/core` - SDL initialization

import std/options

# =========================================================
# 1. VERSION MODEL
# =========================================================

{.push header: "SDL_version.h".}

type
  Version* {.importc: "SDL_version".} = object
    ## Represents an SDL version (major.minor.patch).
    ## Maps directly to the C `SDL_version` structure.
    ## Fields are private; use getters to access them.
    major, minor, patch: uint8

# ---------------------------------------------------------
# PUBLIC GETTERS AND OPERATORS
# ---------------------------------------------------------

proc major*(v: Version): uint8 {.inline.} =
  ## Returns the major version number.
  v.major

proc minor*(v: Version): uint8 {.inline.} =
  ## Returns the minor version number.
  v.minor

proc patch*(v: Version): uint8 {.inline.} =
  ## Returns the patch level.
  v.patch

proc `==`*(a, b: Version): bool {.inline.} =
  ## Compares two versions for equality.
  (a.major == b.major) and (a.minor == b.minor) and (a.patch == b.patch)

proc `<`*(a, b: Version): bool {.inline.} =
  ## Compares two versions lexicographically.
  if a.major != b.major: return a.major < b.major
  if a.minor != b.minor: return a.minor < b.minor
  return a.patch < b.patch

proc `<=`*(a, b: Version): bool {.inline.} =
  ## Returns `true` if `a` is less than or equal to `b`.
  (a < b) or (a == b)

# =========================================================
# 2. HARDWARE LINKAGE
# =========================================================

# SDL defines SDL_MAJOR_VERSION / MINOR / PATCHLEVEL as preprocessor macros.
# We read them via the C preprocessor using {.emit.} inside sdlCompiledVersion.
proc SDL_Linked_Version(): ptr Version {.importc.}

{.pop.}

# =========================================================
# 3. PUBLIC API AND FORMATTING
# =========================================================

proc sdlCompiledVersion*(): Version =
  ## Returns the SDL version that the code was compiled against.
  ##
  ## This is determined at compile time from the SDL headers.
  ##
  ## ```nim
  ## let compiled = sdlCompiledVersion()
  ## echo "Compiled with SDL ", compiled
  ## ```
  var mmaj, mmin, mpat: cint
  {.emit: "`mmaj` = SDL_MAJOR_VERSION; `mmin` = SDL_MINOR_VERSION; `mpat` = SDL_PATCHLEVEL;".}
  Version(major: uint8(mmaj), minor: uint8(mmin), patch: uint8(mpat))

proc sdlLinkedVersion*(): Option[Version] {.inline.} =
  ## Returns the SDL version that the code is linked against at runtime.
  ##
  ## Returns `none` if the linked version cannot be determined.
  ##
  ## ```nim
  ## let linked = sdlLinkedVersion()
  ## if linked.isSome:
  ##   echo "Running with SDL ", linked.get
  ## ```
  let p = SDL_Linked_Version()
  if p != nil:
    result = some(p[])
  else:
    result = none(Version)

# ---------------------------------------------------------
# FORMATTING
# ---------------------------------------------------------

proc writeInt(val: uint8, buf: var openArray[char], pos: var int) {.inline.} =
  ## Writes a uint8 as decimal ASCII digits into `buf` at position `pos`.
  ## Updates `pos` to point past the last written character.
  if val == 0:
    if pos < buf.len:
      buf[pos] = '0'
      inc pos
    return

  var temp = val
  var digits: array[3, char]
  var dIdx = 0

  while temp > 0:
    digits[dIdx] = char((temp mod 10) + ord('0'))
    temp = temp div 10
    inc dIdx

  while dIdx > 0:
    dec dIdx
    if pos < buf.len:
      buf[pos] = digits[dIdx]
      inc pos

proc toCstring*(v: Version, buffer: var array[16, char]): cstring {.inline.} =
  ## Formats the version into a caller-provided buffer and returns a `cstring`.
  ##
  ## Zero-allocation: only stack memory is used. The buffer must be at least 16 characters.
  ## The returned `cstring` is valid until `buffer` goes out of scope.
  ## Thread-safe and expression-safe (each call uses its own buffer).
  ##
  ## **Example:**
  ## ```nim
  ## var buf: array[16, char]
  ## echo version.toCstring(buf)  # "1.2.15"
  ## ```
  var pos = 0
  writeInt(v.major, buffer, pos); buffer[pos] = '.'; inc pos
  writeInt(v.minor, buffer, pos); buffer[pos] = '.'; inc pos
  writeInt(v.patch, buffer, pos); buffer[pos] = '\0'

  return cast[cstring](addr buffer[0])

proc toCstring*(v: Version): cstring {.inline.} =
  ## Formats the version into a global buffer and returns a `cstring`.
  ##
  ## Zero-allocation: uses a single global buffer in BSS.
  ##
  ## **Warning:** NOT thread-safe and NOT expression-safe. The buffer is shared
  ## across all calls — calling this from two threads simultaneously, or using it
  ## twice in the same expression (e.g. `f(v.toCstring(), v.toCstring())`), will
  ## cause both results to point at the same overwritten data. Prefer `$v` or
  ## `toCstring(v, buf)` for safe usage.
  ##
  ## ```nim
  ## echo "SDL version: ", version.toCstring()
  ## ```
  var staticBuf {.global.}: array[16, char]
  return v.toCstring(staticBuf)

proc `$`*(v: Version): string {.inline.} =
  ## Returns the version as a heap-allocated Nim string (e.g. `"1.2.15"`).
  ##
  ## This is the recommended formatting method: safe, convenient, and works
  ## with `echo`, string interpolation, and all Nim string operations.
  ## Allocates on the heap on every call.
  ##
  ## **Example:**
  ## ```nim
  ## echo $version              # "1.2.15"
  ## echo "SDL v" & $version   # "SDL v1.2.15"
  ## ```
  result = $v.major & "." & $v.minor & "." & $v.patch
