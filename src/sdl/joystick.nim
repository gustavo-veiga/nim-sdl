## # sdl/joystick
##
## Joystick and gamepad input handling
##
## This module provides comprehensive joystick and gamepad support through SDL 1.2.
## It handles multiple controllers, axes, buttons, D-pads (hats), and trackballs with
## real-time state querying.
##
## ## SDL 1.2 Reference
##
## SDL 1.2 provides joystick input through the `SDL_Joystick` API. Controllers are
## identified by device index and must be opened before use. Input states can be
## queried directly or received through events.
##
## **Key C functions:**
## ```c
## int SDL_NumJoysticks(void);
## SDL_Joystick *SDL_JoystickOpen(int device_index);
## void SDL_JoystickUpdate(void);
## Sint16 SDL_JoystickGetAxis(SDL_Joystick *joystick, int axis);
## Uint8 SDL_JoystickGetButton(SDL_Joystick *joystick, int button);
## Uint8 SDL_JoystickGetHat(SDL_Joystick *joystick, int hat);
## ```
##
## ## Usage Example
##
## ```nim
## import sdl
##
## runMain:
##   let ctx = sdlInit(sdlInitJoystick)
##   defer: ctx.quit()
##
##   # Check available joysticks
##   let count = numJoysticks()
##   echo "Found ", count, " joystick(s)"
##
##   if count > 0:
##     # Open first joystick
##     let joy = JoystickIndex(0).open()
##     if joy.isSome:
##       var controller = joy.get
##
##       # Query controller capabilities
##       let name = JoystickIndex(0).name()
##       if name.isSome:
##         echo "Name: ", name.get
##       echo "Axes: ", controller.numAxes()
##       echo "Buttons: ", controller.numButtons()
##       echo "D-Pads: ", controller.numDPads()
##
##       var running = true
##       while running:
##         # Update joystick states
##         refreshJoysticks()
##
##         # Read axis values (typically -32768 to 32767)
##         let xAxis = controller.axis(0)
##         let yAxis = controller.axis(1)
##
##         # Read button states
##         if controller.button(0):
##           echo "Button A pressed!"
##
##         # Read D-Pad state
##         let dpad = controller.dPad(0)
##         if dpad == DPadDirection.up:
##           echo "D-Pad Up"
##         if dpad == DPadDirection.rightUp:
##           echo "D-Pad Up-Right (diagonal)"
##
##         # Process events
##         for event in pollEvents():
##           if event.kind == quit:
##             running = false
## ```
##
## ## Advantages over C SDL 1.2
##
## | C SDL 1.2                          | Nim SDL                                              |
## |------------------------------------|------------------------------------------------------|
## | `SDL_Joystick *` manual close      | `Joystick` RAII auto-close                           |
## | Raw device index (`int`)           | `JoystickIndex` distinct `uint32`                    |
## | `int` return codes                 | `Option[T]` for fallible operations                  |
## | `SDL_JoystickName()` returns `NULL`| `JoystickIndex.name()` → `Option[cstring]`          |
## | `SDL_JoystickGetAxis()`            | `controller.axis()` (no `get` prefix)                |
## | `SDL_JoystickGetHat()` bitmask     | `controller.dPad()` + `DPadState`                    |
## | `SDL_JoystickEventState()` 3-in-1  | `enableJoystickEvents()` / `disableJoystickEvents()` |
## | Manual diagonal bitmasks           | `DPadDirection.rightUp` etc. (built-in)              |
## | Error-prone pointer arithmetic     | Safe typed procedure calls                           |
##
## ## D-Pad States
##
## D-Pad (hat) states use bitmask operations for easy diagonal detection:
##
## ```nim
## let dpad = controller.dPad(0)
## if (dpad and DPadDirection.up) != 0:
##   echo "Up is pressed"
## if dpad == DPadDirection.rightUp:
##   echo "Diagonal: Up-Right"
## ```
##
## ## Important Notes
##
## - Call `refreshJoysticks()` each frame before reading states if events are disabled
## - With events enabled (`enableJoystickEvents()`), `pollEvents()` already updates state
## - Joysticks must be opened with `JoystickIndex(idx).open()` before use
## - Use `numJoysticks()` to detect connected controllers
## - Hotplugging requires checking joystick validity during gameplay
##
## ## See Also
##
## - `sdl/events` - Joystick event processing
## - `sdl/keyboard` - Keyboard input handling
## - `sdl/mouse` - Mouse input handling

import std/options
import private/utils

# =========================================================
# 1. ENUMS AND STATES
# =========================================================

type
  JoyEventState* {.pure, size: sizeof(cint).} = enum
    ## Controls joystick event processing mode.
    query  = -1  ## Returns current event state without changing it
    ignore = 0   ## Ignores joystick events (must poll manually)
    enable = 1   ## Enables joystick event generation

type
  DPadDirection* {.pure, size: sizeof(uint8).} = enum
    ## Directional pad (D-Pad) bitmask values.
    ## Cardinal directions can be combined with `or` for diagonals.
    ##
    ## **Example:**
    ## ```nim
    ## let input = DPadDirection.up or DPadDirection.right  # 0x03
    ## ```
    centered  = 0x00  ## Neutral position
    up        = 0x01  ## Up
    right     = 0x02  ## Right
    down      = 0x04  ## Down
    left      = 0x08  ## Left
    rightUp   = 0x03  ## Diagonal: right + up
    rightDown = 0x06  ## Diagonal: right + down
    leftUp    = 0x09  ## Diagonal: left + up
    leftDown  = 0x0B  ## Diagonal: left + down

  DPadState* = distinct uint8
    ## Combined D-Pad state supporting bitmask operations for diagonal detection.

  JoystickIndex* = distinct uint32
    ## Type-safe joystick device index. Use `.open()`, `.name()`, `.isOpen()`.

# Metaprogramming for smooth diagonal handling
operatorBitmask(DPadDirection, DPadState)

proc `==`*(x, y: DPadState): bool {.borrow.}
  ## Compares two D-Pad states for equality.

proc `and`*(x, y: DPadState): DPadState {.borrow.}
  ## Computes the bitwise AND between two D-Pad states.

# =========================================================
# 2. C STRUCTS AND FFI
# =========================================================
{.push header: "SDL_joystick.h", importc.}

type
  RawJoystick {.importc: "SDL_Joystick", incompleteStruct.} = object

  RawJoystickPtr* = ptr RawJoystick
    ## Pointer to an SDL_Joystick handle. Used with unsafeRaw/assumeRaw.

proc SDL_NumJoysticks(): cint
proc SDL_JoystickName(deviceIndex: cint): cstring
proc SDL_JoystickOpen(deviceIndex: cint): RawJoystickPtr
proc SDL_JoystickOpened(deviceIndex: cint): cint
proc SDL_JoystickIndex(joystick: RawJoystickPtr): cint
proc SDL_JoystickNumAxes(joystick: RawJoystickPtr): cint
proc SDL_JoystickNumBalls(joystick: RawJoystickPtr): cint
proc SDL_JoystickNumHats(joystick: RawJoystickPtr): cint
proc SDL_JoystickNumButtons(joystick: RawJoystickPtr): cint
proc SDL_JoystickUpdate()
proc SDL_JoystickEventState(state: cint): cint
proc SDL_JoystickGetAxis(joystick: RawJoystickPtr, axis: cint): int16
proc SDL_JoystickGetHat(joystick: RawJoystickPtr, hat: cint): uint8
proc SDL_JoystickGetBall(joystick: RawJoystickPtr, ball: cint, dx: ptr cint, dy: ptr cint): cint
proc SDL_JoystickGetButton(joystick: RawJoystickPtr, button: cint): uint8
proc SDL_JoystickClose(joystick: RawJoystickPtr)

{.pop.}

# =========================================================
# 3. SMART POINTER (RAII)
# =========================================================

type Joystick* {.requiresInit.} = object
  ## RAII wrapper around an SDL_Joystick handle. Automatically closes on scope exit.
  raw: RawJoystickPtr

proc `=destroy`*(s: var Joystick) =
  ## Closes the joystick handle automatically when Joystick goes out of scope.
  destroyImpl(s, SDL_JoystickClose)

proc `=sink`*(dest: var Joystick; source: Joystick) =
  ## Move semantics: transfers joystick ownership without double-close.
  sinkImpl(dest, source)

proc `=copy`*(dest: var Joystick, source: Joystick) {.error.}
  ## Copying is disabled to prevent double-free. Use move() instead.

proc unsafeRaw*(j: Joystick): RawJoystickPtr {.inline.} = j.raw
  ## Extracts the raw SDL_Joystick pointer. Only valid while `j` is in scope.

proc assumeRaw*(p: RawJoystickPtr): Joystick {.inline.} = Joystick(raw: p)
  ## Wraps a raw SDL_Joystick pointer into a Joystick object. Assumes ownership.

# =========================================================
# 4. PUBLIC API
# =========================================================

# ---------------------------------------------------------
# GLOBAL JOYSTICK SYSTEM
# ---------------------------------------------------------

proc numJoysticks*(): int32 {.inline.} =
  ## Returns the number of joysticks connected to the system.
  ##
  ## **Example:**
  ## ```nim
  ## let count = numJoysticks()
  ## if count > 0:
  ##   echo "Found ", count, " joystick(s)"
  ## ```
  SDL_NumJoysticks()

proc open*(idx: JoystickIndex): Option[Joystick] {.inline.} =
  ## Opens the joystick at this index. Returns `none` if the device cannot be opened.
  ##
  ## **Example:**
  ## ```nim
  ## let joy = JoystickIndex(0).open()
  ## if joy.isSome:
  ##   var ctrl = joy.get
  ## ```
  SDL_JoystickOpen(cint(uint32(idx))).toOption(Joystick)

proc name*(idx: JoystickIndex): Option[cstring] {.inline.} =
  ## Returns the name of the joystick at this index, or `none` if invalid.
  ##
  ## **Example:**
  ## ```nim
  ## let name = JoystickIndex(0).name()
  ## if name.isSome:
  ##   echo "Joystick: ", name.get
  ## ```
  let n = SDL_JoystickName(cint(uint32(idx)))
  if n.isNil: none(cstring)
  else: some(n)

proc isOpen*(idx: JoystickIndex): bool {.inline.} =
  ## Checks whether the joystick at this index is already open.
  sdlTrue SDL_JoystickOpened(cint(uint32(idx)))

proc refreshJoysticks*() {.inline.} =
  ## Refreshes the state of all joysticks. Only needed when event processing is
  ## disabled (`disableJoystickEvents()`). With `enableJoystickEvents()`, calling
  ## `pollEvents()` already updates joystick states automatically.
  ##
  ## **Example:**
  ## ```nim
  ## disableJoystickEvents()
  ## while running:
  ##   refreshJoysticks()
  ##   let xAxis = controller.axis(0)
  ## ```
  SDL_JoystickUpdate()

proc joystickEventState*(): JoyEventState {.inline.} =
  ## Returns the current joystick event processing state.
  cast[JoyEventState](SDL_JoystickEventState(cint(JoyEventState.query)))

proc enableJoystickEvents*() {.inline.} =
  ## Enables joystick event generation. Events will be posted to the event queue.
  discard SDL_JoystickEventState(cint(JoyEventState.enable))

proc disableJoystickEvents*() {.inline.} =
  ## Disables joystick event generation. State must be polled manually.
  discard SDL_JoystickEventState(cint(JoyEventState.ignore))

# ---------------------------------------------------------
# INDIVIDUAL JOYSTICK INTERACTION
# ---------------------------------------------------------

proc close*(j: var Joystick) {.inline.} =
  ## Manually closes the joystick and releases resources before scope exit.
  ## Essential for handling controller disconnections (hotplugging) during gameplay.
  if j.raw != nil:
    SDL_JoystickClose(j.raw)
    j.raw = nil

proc index*(j: Joystick): int32 {.inline.} =
  ## Returns the device index of the opened joystick.
  SDL_JoystickIndex(j.raw)

proc numAxes*(j: Joystick): int32 {.inline.} =
  ## Returns the number of analog axes on the joystick.
  SDL_JoystickNumAxes(j.raw)

proc numBalls*(j: Joystick): int32 {.inline.} =
  ## Returns the number of trackballs on the joystick.
  SDL_JoystickNumBalls(j.raw)

proc numDPads*(j: Joystick): int32 {.inline.} =
  ## Returns the number of D-Pads (hats) on the joystick.
  SDL_JoystickNumHats(j.raw)

proc numButtons*(j: Joystick): int32 {.inline.} =
  ## Returns the number of buttons on the joystick.
  SDL_JoystickNumButtons(j.raw)

# ---------------------------------------------------------
# BUTTON AND AXIS READING (Real-time Input)
# ---------------------------------------------------------

proc axis*(j: Joystick, axisIndex: int32): int16 {.inline.} =
  ## Returns the current position of the specified axis (-32768 to 32767).
  ##
  ## **Example:**
  ## ```nim
  ##   # Left analog stick
  ##   let xAxis = controller.axis(0)
  ##   let yAxis = controller.axis(1)
  ##
  ##   # Right analog stick
  ##   let rxAxis = controller.axis(2)
  ##   let ryAxis = controller.axis(3)
  ## ```
  ##
  ## **Note:** Axis 0-1 is typically the left stick, 2-3 is the right stick.
  SDL_JoystickGetAxis(j.raw, cint(axisIndex))

proc dPad*(j: Joystick, dPadIndex: int32): DPadState {.inline.} =
  ## Returns the current state of the D-Pad (hat switch).
  ##
  ## **Example:**
  ## ```nim
  ## let dpad = controller.dPad(0)
  ##
  ## # Check cardinal directions
  ## if dpad == DPadDirection.up:
  ##   echo "Up"
  ## if dpad == DPadDirection.down:
  ##   echo "Down"
  ##
  ## # Check diagonals
  ## if dpad == DPadDirection.rightUp:
  ##   echo "Up-Right"
  ## if dpad == DPadDirection.leftDown:
  ##   echo "Down-Left"
  ##
  ## # Check if any direction is pressed
  ## if (dpad and DPadDirection.left) != 0:
  ##   echo "Left is pressed"
  ## ```
  ##
  ## **Note:** Use bitmask operations to check individual directions or
  ## compare with predefined diagonal constants.
  DPadState(SDL_JoystickGetHat(j.raw, cint(dPadIndex)))

proc button*(j: Joystick, buttonIndex: int32): bool {.inline.} =
  ## Returns `true` if the specified button is currently pressed.
  ##
  ## **Example:**
  ## ```nim
  ## if controller.button(0):
  ##   echo "Button A pressed!"
  ## if controller.button(1):
  ##   echo "Button B pressed!"
  ## ```
  ##
  ## **Note:** Button indices vary by controller. Common mapping:
  ## 0=A, 1=B, 2=X, 3=Y, 4=LB, 5=RB, 6=Back, 7=Start
  sdlTrue SDL_JoystickGetButton(j.raw, cint(buttonIndex))

proc ball*(j: Joystick, ballIndex: int32): Option[tuple[dx, dy: int32]] {.inline.} =
  ## Returns the relative motion of the specified trackball as `(dx, dy)`.
  ## Returns `none` if the ball cannot be queried.
  ##
  ## **Example:**
  ## ```nim
  ## if controller.ball(0) isSome:
  ##   let (dx, dy) = controller.ball(0).get
  ##   echo "Ball moved by (", dx, ", ", dy, ")"
  ## ```
  ##
  ## **Note:** Trackballs report relative movement, not absolute position.
  var dx, dy: cint
  if sdlOk SDL_JoystickGetBall(j.raw, cint(ballIndex), addr dx, addr dy):
    some((int32(dx), int32(dy)))
  else:
    none(tuple[dx, dy: int32])
