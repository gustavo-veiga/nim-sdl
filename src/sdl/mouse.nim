## # sdl/mouse
##
## Mouse input handling and cursor management
##
## This module provides functions for reading mouse state, managing custom cursors,
## and controlling cursor visibility. It supports both absolute and relative mouse motion.
##
## ## SDL 1.2 Reference
##
## SDL 1.2 provides mouse input through events and direct state queries. The mouse state
## includes position and button states. Custom cursors can be created from bitmap data.
##
## **Key C functions:**
## ```c
## Uint8 SDL_GetMouseState(int *x, int *y);
## SDL_Cursor *SDL_CreateCursor(Uint8 *data, Uint8 *mask, int w, int h, int hot_x, int hot_y);
## void SDL_SetCursor(SDL_Cursor *cursor);
## int SDL_ShowCursor(int toggle);
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
##   # Create custom cursor
##   let cursorData = [0xFF'u8, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0xFF]
##   let cursorMask = [0xFF'u8, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]
##   let c = createCursor(cursorData, cursorMask, 8, 8, 0, 0)
##   if c.isSome:
##     cursor = c.get
## 
##   # Read mouse state
##   let state = mouseState()
##   if isPressed(state.buttons, left):
##     echo "Left click at (", state.x, ", ", state.y, ")"
## 
##   # Hide cursor
##   discard showCursor(false)
## 
##   var running = true
##   while running:
##     for event in pollEvents():
##       if event.kind == quit:
##         running = false
## 
##     let mouse = mouseState()
##     if isPressed(mouse.buttons, right):
##       echo "Right click!"
## 
##     screen.flip()
## ```
##
## ## Advantages over C SDL 1.2
##
## | C SDL 1.2                        | Nim SDL                          |
## |----------------------------------|----------------------------------|
## | `SDL_GetMouseState(&x, &y)`      | `mouseState()` returns tuple     |
## | `SDL_Cursor *cursor` manual free | `Cursor` RAII auto-free          |
## | Manual bitmask checks            | `isPressed()` helper             |
## | Integer return codes             | `Option[T]` for error handling   |
##
## ## API Highlights
##
## - **RAII:** `Cursor` — auto-freed on scope exit, move-only
## - **Safe:** `createCursor()` returns `Option[Cursor]` — no null pointers
## - **Tuple returns:** `mouseState()` / `relativeMouseState()` return `(x, y, buttons)`
## - **Type safety:** `MouseButton` enum with `isPressed()` helper
## - **Dual ownership:** `Cursor` (owned), `CursorHandle` (read-only)
##
## ## See Also
##
## - `sdl/keyboard` - Keyboard input handling
## - `sdl/joystick` - Joystick input handling

import std/options
import private/utils
import video

# =========================================================
# 1. ENUMS AND BUTTON MASKS
# =========================================================
type
  MouseButton* {.pure, size: sizeof(uint8).} = enum
    ## Identifiers for mouse buttons.
    left       = 1  ## Left mouse button
    middle     = 2  ## Middle mouse button (scroll wheel click)
    right      = 3  ## Right mouse button
    wheelUp    = 4  ## Scroll wheel up
    wheelDown  = 5  ## Scroll wheel down
    x1         = 6  ## Extra button 1 (thumb button)
    x2         = 7  ## Extra button 2 (thumb button)

template buttonMask*(btn: MouseButton): uint8 =
  ## Replaces SDL's `SDL_BUTTON(X)` macro.
  ## Shifts bits safely to create a button state mask.
  1'u8 shl (uint8(btn) - 1'u8)

proc isPressed*(stateMask: uint8, btn: MouseButton): bool {.inline.} =
  ## Checks idiomatically if a button is set in the current state mask.
  (stateMask and buttonMask(btn)) != 0

# =========================================================
# 2. C STRUCTS
# =========================================================
{.push header: "SDL_mouse.h", importc, cdecl.}

type
  RawWMCursor {.importc: "WMcursor", incompleteStruct.} = object
  RawWMCursorPtr = ptr RawWMCursor

  RawCursor {.importc: "SDL_Cursor".} = object
    area: Rect
    hotX {.importc: "hot_x".}: int16
    hotY {.importc: "hot_y".}: int16
    data: ptr byte
    mask: ptr byte
    save: array[2, ptr byte]
    mwCursor {.importc: "wm_cursor".}: RawWMCursorPtr

  RawCursorPtr* = ptr RawCursor
    ## Pointer to the underlying `SDL_Cursor` C struct.

proc SDL_GetMouseState(x, y: ptr cint): uint8
proc SDL_GetRelativeMouseState(x, y: ptr cint): uint8
proc SDL_WarpMouse(x, y: uint16)
proc SDL_CreateCursor(data, mask: pointer, w, h, hot_x, hot_y: cint): RawCursorPtr
proc SDL_SetCursor(cursor: RawCursorPtr)
proc SDL_GetCursor(): RawCursorPtr
proc SDL_FreeCursor(cursor: RawCursorPtr)
proc SDL_ShowCursor(toggle: cint): cint

{.pop.}

# =========================================================
# 3. SMART POINTERS
# =========================================================

type Cursor* {.requiresInit.} = object
  ## RAII wrapper for a custom cursor. Automatically frees the cursor on scope exit.
  raw: RawCursorPtr

proc `=destroy`*(c: var Cursor) =
  ## Frees the cursor and unselects it if it is currently active.
  if c.raw != nil:
    if SDL_GetCursor() == c.raw:
      SDL_SetCursor(nil)
    SDL_FreeCursor(c.raw)
    c.raw = nil

proc `=sink`*(dest: var Cursor, source: Cursor) =
  ## Move semantics: transfers cursor ownership without double-free.
  sinkImpl(dest, source)

proc `=copy`*(dest: var Cursor, source: Cursor) {.error.}
  ## Copying is disabled to prevent double-free. Use move() instead.

proc unsafeRaw*(c: Cursor): RawCursorPtr {.inline.} = c.raw
  ## Extracts the raw SDL_Cursor pointer. Only valid while `c` is in scope.

proc assumeRaw*(p: RawCursorPtr): Cursor {.inline.} = Cursor(raw: p)
  ## Wraps a raw SDL_Cursor pointer into a Cursor. Assumes ownership.

type CursorHandle* = object
  ## Read-only handle to a system cursor. Does NOT free the cursor on scope exit.
  raw: RawCursorPtr

# =========================================================
# 4. PUBLIC API
# =========================================================

# ---------------------------------------------------------
# MOUSE STATE
# ---------------------------------------------------------

proc mouseState*(): tuple[x, y: int32, buttons: uint8] {.inline.} =
  ## Returns current mouse position and button states.
  ##
  ## **Example:**
  ## ```nim
  ## let state = mouseState()
  ## echo "Mouse at (", state.x, ", ", state.y, ")"
  ## if isPressed(state.buttons, left):
  ##   echo "Left button pressed"
  ## ```
  var cx, cy: cint
  result.buttons = SDL_GetMouseState(addr cx, addr cy)
  result.x = int32(cx)
  result.y = int32(cy)

proc relativeMouseState*(): tuple[x, y: int32, buttons: uint8] {.inline.} =
  ## Returns mouse motion since the last call and current button states.
  ##
  ## **Example:**
  ## ```nim
  ## let motion = relativeMouseState()
  ## echo "Mouse moved by (", motion.x, ", ", motion.y, ")"
  ## ```
  var cx, cy: cint
  result.buttons = SDL_GetRelativeMouseState(addr cx, addr cy)
  result.x = int32(cx)
  result.y = int32(cy)

proc warpMouse*(x, y: uint16) {.inline.} =
  ## Moves the mouse cursor to the specified coordinates on screen.
  SDL_WarpMouse(x, y)

# ---------------------------------------------------------
# CURSOR MANAGEMENT
# ---------------------------------------------------------

proc createCursor*(data, mask: openArray[uint8], w, h, hotX, hotY: int32): Option[Cursor] {.inline.} =
  ## Creates a custom monochrome cursor.
  ##
  ## **Example:**
  ## ```nim
  ## # Create an 8x8 cursor with hotspot at (0, 0)
  ## let data = [0xFF'u8, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0xFF]
  ## let mask = [0xFF'u8, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]
  ## let cursor = createCursor(data, mask, 8, 8, 0, 0)
  ## if cursor.isSome:
  ##   cursor = cursor.get
  ## ```
  ##
  ## **Note:** Data and mask must have the same length. Width must be a multiple of 8.
  if data.len == 0 or mask.len == 0 or data.len != mask.len:
    return none(Cursor)

  SDL_CreateCursor(
    unsafeAddr data[0],
    unsafeAddr mask[0],
    cint(w), cint(h),
    cint(hotX), cint(hotY)
  ).toOption(Cursor)

proc `cursor=`*(c: var Cursor) {.inline.} =
  ## Sets the active cursor (borrows `c`; `c` must outlive its use).
  SDL_SetCursor(c.raw)

proc cursor*(): CursorHandle {.inline.} =
  ## Returns a read-only handle to the currently active cursor.
  CursorHandle(raw: SDL_GetCursor())

proc restoreDefaultCursor*() {.inline.} =
  ## Restores the default arrow cursor.
  SDL_SetCursor(nil)

# ---------------------------------------------------------
# CURSOR PROPERTIES (Read-Only Getters)
# ---------------------------------------------------------

# For Cursor (Owned)
proc area*(c: Cursor): Rect {.inline.} = c.raw.area
  ## Returns the cursor's bounding rectangle.

proc hotX*(c: Cursor): int16 {.inline.} = c.raw.hotX
  ## Returns the cursor's hotspot X offset (click position).

proc hotY*(c: Cursor): int16 {.inline.} = c.raw.hotY
  ## Returns the cursor's hotspot Y offset (click position).

# For CursorHandle (Screen Read-Only)
proc area*(c: CursorHandle): Rect {.inline.} = c.raw.area
  ## Returns the cursor's bounding rectangle (read-only handle).

proc hotX*(c: CursorHandle): int16 {.inline.} = c.raw.hotX
  ## Returns the cursor's hotspot X offset (read-only handle).

proc hotY*(c: CursorHandle): int16 {.inline.} = c.raw.hotY
  ## Returns the cursor's hotspot Y offset (read-only handle).

# (Optional) Safe read-only access to the original bitmap arrays
proc maskData*(c: Cursor): ptr byte {.inline.} = c.raw.mask
  ## Returns a read-only pointer to the cursor's mask bitmap.

proc pixelData*(c: Cursor): ptr byte {.inline.} = c.raw.data
  ## Returns a read-only pointer to the cursor's pixel data bitmap.

# ---------------------------------------------------------
# VISIBILIDADE DO CURSOR
# ---------------------------------------------------------

proc showCursor*(visible: bool): bool {.inline.} =
  ## Shows or hides the mouse cursor.
  ##
  ## **Example:**
  ## ```nim
  ## discard showCursor(false)  # Hide cursor
  ## discard showCursor(true)   # Show cursor
  ## ```
  sdlTrue SDL_ShowCursor(cint(visible))

proc isCursorVisible*(): bool {.inline.} =
  ## Returns `true` if the mouse cursor is currently visible.
  sdlTrue SDL_ShowCursor(-1)
