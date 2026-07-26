## # sdl/syswm
##
## Platform-specific window manager information
##
## This module provides access to low-level window manager information for
## platform-specific operations. It exposes native window handles (HWND on Windows,
## X11 Display/Window on Linux, etc.) for integration with platform-specific APIs.
##
## ## SDL 1.2 Reference
##
## SDL 1.2 provides the `SDL_SysWMinfo` structure to access platform-specific
## window information. The structure varies by platform and requires version
## initialization before use.
##
## **Key C structures:**
## ```c
## typedef struct {
##     SDL_version version;
##     // Platform-specific fields...
## } SDL_SysWMinfo;
##
## int SDL_GetWMInfo(SDL_SysWMinfo *info);
## ```
##
## ## Usage Example
##
## ```nim
## import sdl
##
## runMain:
##   let ctx = sdlInit(sdlInitVideo)
##   defer: ctx.quit()
##
##   let screen = setVideoMode(640, 480, 32, sdlSwSurface)
##
##   let info = getWmInfo()
##   if info.isSome:
##     let wm = info.get
##     when defined(windows):
##       echo "HWND: ", wm.window
##     elif defined(linux):
##       echo "X11 Display: ", wm.info.x11.display
##       echo "X11 Window: ", wm.info.x11.window
## ```
##
## ## Platform Support
##
## | Platform    | Structure Fields                       | Use Case                 |
## |-------------|----------------------------------------|--------------------------|
## | Windows     | `window` (HWND), `hglrc` (HGLRC)       | Win32 API integration    |
## | Linux/X11   | `display`, `window`, `lock_func`, etc. | X11 API integration      |
## | Nano-X      | `window` (GR_WINDOW_ID)                | Microwindows integration |
## | RISC OS     | `taskHandle`, `window`                 | RISC OS integration      |
## | Photon      | `data`                                 | QNX Photon integration   |
##
## ## Advantages over C SDL 1.2
##
## | C SDL 1.2                           | Nim SDL                       |
## |-------------------------------------|-------------------------------|
## | Manual `SDL_VERSION(&info.version)` | `getWmInfo()` handles it      |
## | Manual struct declaration + init    | `Option[SysWmInfo]` return    |
## | Platform-specific `#ifdef` blocks   | Conditional compilation       |
##
## ## Safety
##
## The `getWmInfo()` procedure returns an `Option[SysWmInfo]` and automatically
## initializes the version field using the `SDL_VERSION` macro, preventing
## crashes from uninitialized structures.
##
## ## See Also
##
## - `sdl/video` - Video subsystem and surface management
## - `sdl/version` - Version information

import std/options
import version

# =========================================================
# THE WINDOW MANAGER PORTAL
# =========================================================

# =========================================================
# 2. PLATFORM-SPECIFIC STRUCTURES
# =========================================================
# Simplified compilation flags: -d:windows, -d:x11, -d:nanox, -d:riscos, -d:photon

{.push header: "SDL_syswm.h", importc, cdecl.}

when defined(windows) or defined(windib) or defined(ddraw) or defined(gapi):
  # ---------------------------------------------------------
  # WINDOWS STRUCTURES (Win32 API)
  # ---------------------------------------------------------
  type
    SysWmMsg* {.importc: "SDL_SysWMmsg".} = object
      ## Windows-specific window manager message.
      version*: Version
      hwnd*: pointer       ## Native HWND
      msg*: cuint          ## UINT message
      wParam*: uint        ## WPARAM
      lParam*: int         ## LPARAM

    SysWmInfo* {.importc: "SDL_SysWMinfo".} = object
      ## Windows-specific window manager information.
      version*: Version
      window*: pointer     ## HWND of the window
      hglrc*: pointer      ## HGLRC (OpenGL context)

elif defined(linux) or defined(freebsd) or defined(openbsd) or defined(x11):
  # ---------------------------------------------------------
  # X11 STRUCTURES (UNIX / Linux)
  # ---------------------------------------------------------
  type
    SysWmType* {.importc: "SDL_SYSWM_TYPE", pure, size: sizeof(cint).} = enum
      ## Window manager subsystem type.
      x11 = 0

    SysWmInfoX11* = object
      ## X11-specific window information.
      display*: pointer    ## Display*
      window*: culong      ## Window (XID)
      lockFunc* {.importc: "lock_func".}: proc() {.cdecl.}
      unlockFunc* {.importc: "unlock_func".}: proc() {.cdecl.}
      fsWindow* {.importc: "fswindow".}: culong
      wmWindow* {.importc: "wmwindow".}: culong
      gfxDisplay* {.importc: "gfxdisplay".}: pointer

    SysWmInfoUnion* {.union.} = object
      ## Union of platform-specific window info.
      x11*: SysWmInfoX11

    SysWmEventUnion* {.union.} = object
      ## Union of platform-specific events.
      xevent*: array[24, clong] ## Safe padding for C's XEvent without <X11.h>

    SysWmMsg* {.importc: "SDL_SysWMmsg".} = object
      ## X11-specific window manager message.
      version*: Version
      subsystem*: SysWmType
      event*: SysWmEventUnion

    SysWmInfo* {.importc: "SDL_SysWMinfo".} = object
      ## X11-specific window manager information.
      version*: Version
      subsystem*: SysWmType
      info*: SysWmInfoUnion

elif defined(nanox):
  # ---------------------------------------------------------
  # NANO-X STRUCTURES (Microwindows)
  # ---------------------------------------------------------
  type
    SysWmMsg* {.importc: "SDL_SysWMmsg".} = object
      version*: Version
      data*: cint

    SysWmInfo* {.importc: "SDL_SysWMinfo".} = object
      version*: Version
      window*: cint        ## GR_WINDOW_ID

elif defined(riscos):
  # ---------------------------------------------------------
  # RISC OS STRUCTURES (Acorn Computers)
  # ---------------------------------------------------------
  type
    SysWmMsg* {.importc: "SDL_SysWMmsg".} = object
      version*: Version
      eventCode*: cint
      pollBlock*: array[64, cint]

    SysWmInfo* {.importc: "SDL_SysWMinfo".} = object
      version*: Version
      wimpVersion*: cint
      taskHandle*: cint
      window*: cint

elif defined(photon):
  # ---------------------------------------------------------
  # QNX PHOTON STRUCTURES (BlackBerry / QNX)
  # ---------------------------------------------------------
  type
    SysWmMsg* {.importc: "SDL_SysWMmsg".} = object
      version*: Version
      data*: cint

    SysWmInfo* {.importc: "SDL_SysWMinfo".} = object
      version*: Version
      data*: cint

else:
  # ---------------------------------------------------------
  # GENERIC STRUCTURES (Fallback for Classic MacOS, etc)
  # ---------------------------------------------------------
  type
    SysWmMsg* {.importc: "SDL_SysWMmsg".} = object
      version*: Version
      data*: cint

    SysWmInfo* {.importc: "SDL_SysWMinfo".} = object
      version*: Version
      data*: cint


# =========================================================
# 3. FFI - WINDOW MANAGER FUNCTIONS
# =========================================================

proc SDL_GetWMInfo(info: ptr SysWmInfo): cint

{.pop.}


proc getWmInfo*(): Option[SysWmInfo] {.inline.} =
  ## Retrieves platform-specific window manager information.
  ## Returns `some(SysWmInfo)` on success, `none` on failure.
  ## Automatically initializes the version field.
  ## The returned pointers are only valid while the window exists.
  ##
  ## **Example:**
  ## ```nim
  ## let info = getWmInfo()
  ## if info.isSome:
  ##   let wm = info.get
  ##   when defined(windows):
  ##     echo "HWND: ", wm.window
  ## ```
  var info: SysWmInfo
  let pVersion = addr info.version
  {.emit: ["SDL_VERSION(", pVersion, ");"].}
  if SDL_GetWMInfo(addr info) == 1:
    result = some(info)
