## # sdl/events
##
## SDL event handling and input processing
##
## This module provides the complete event system for SDL 1.2, handling keyboard,
## mouse, joystick, window, and custom events. Events are the primary way to
## receive input and respond to system actions in SDL applications.
##
## ## SDL 1.2 Reference
##
## SDL 1.2 uses an event queue where all input and system events are stored.
## Applications poll or wait for events in their main loop. Events are represented
## as a union type that can hold any event variant.
##
## **Key C functions:**
## ```c
## int SDL_PollEvent(SDL_Event *event);
## int SDL_WaitEvent(SDL_Event *event);
## int SDL_PushEvent(SDL_Event *event);
## void SDL_PumpEvents(void);
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
##   var running = true
##   while running:
##     for event in pollEvents():
##       case event.kind
##       of quit:
##         running = false
##       of keyDown:
##         let key = event.key.keyInfo.key
##         if key == K_ESCAPE:
##           running = false
##       else:
##         discard
## ```
##
## ## Advantages over C SDL 1.2
##
## | C SDL 1.2                              | Nim SDL                          |
## |----------------------------------------|----------------------------------|
## | `SDL_Event event;` + switch statement  | `for event in pollEvents()`      |
## | Manual event mask calculations         | Predefined `*Mask` constants     |
## | No iterator for event loop             | `pollEvents()` / `waitEvents()`  |
## | Union type requires manual casting     | Type-safe field access           |
## | `SDL_PollEvent(&event)` return check   | `pollEvent(event)` returns bool  |
##
## ## Event Types
##
## - **Keyboard**: `keyDown`, `keyUp`
## - **Mouse**: `mouseMotion`, `mouseButtonDown`, `mouseButtonUp`
## - **Joystick**: `joyAxisMotion`, `joyBallMotion`, `joyDPadMotion`, `joyButtonDown`, `joyButtonUp`
## - **Window**: `activeEvent`, `videoResize`, `videoExpose`, `quit`
## - **Custom**: `userEvent` for application-defined events
##
## ## See Also
##
## - `sdl/keyboard` - Keyboard state and key symbols
## - `sdl/mouse` - Mouse state and cursor control
## - `sdl/joystick` - Joystick initialization and access

import keyboard, joystick, keysym
import private/utils

type
  ButtonState* {.pure, size: sizeof(uint8).} = enum
    ## State of a button (mouse or joystick).
    released = 0  ## Button is not pressed
    pressed = 1   ## Button is pressed

{.push header: "SDL_events.h", bycopy, cdecl.}

type
  EventType* {.importc: "SDL_EventType", pure, size: sizeof(uint8).} = enum
    ## All possible event types in SDL 1.2.
    noEvent = 0           ## No event
    activeEvent = 1       ## Application state changed (focus, minimize)
    keyDown = 2           ## Key pressed
    keyUp = 3             ## Key released
    mouseMotion = 4       ## Mouse moved
    mouseButtonDown = 5   ## Mouse button pressed
    mouseButtonUp = 6     ## Mouse button released
    joyAxisMotion = 7     ## Joystick axis moved
    joyBallMotion = 8     ## Joystick trackball moved
    joyDPadMotion = 9     ## Joystick D-pad moved
    joyButtonDown = 10    ## Joystick button pressed
    joyButtonUp = 11      ## Joystick button released
    quit = 12             ## Window close requested
    sysWmEvent = 13       ## Window manager event
    videoResize = 16      ## Window resized (resizeable windows)
    videoExpose = 17      ## Window needs redraw
    userEvent = 24        ## Application-defined event
    numEvents = 32        ## Total number of event types

  EventAction* {.importc: "SDL_eventaction", pure, size: sizeof(cint).} = enum
    ## Actions for SDL_PeepEvents.
    add = 0   ## Add events to the queue
    peek = 1  ## Check events without removing
    get = 2   ## Get events and remove from queue

  ActiveEvent* {.importc: "SDL_ActiveEvent", header: "SDL_events.h".} = object
    ## Application state change event (focus, minimize, mouse focus).
    kind {.importc: "type".}: EventType
    gained {.importc: "gain".}: uint8
    state: uint8

  KeyboardEvent* {.importc: "SDL_KeyboardEvent".} = object
    ## Keyboard key press/release event.
    kind {.importc: "type".}: EventType
    deviceIndex {.importc: "which".}: uint8
    state: ButtonState
    keysym: KeyInfo

  MouseMotionEvent* {.importc: "SDL_MouseMotionEvent".} = object
    ## Mouse movement event with position and relative motion.
    kind {.importc: "type".}: EventType
    deviceIndex{.importc: "which".}: uint8
    state: uint8
    x, y: uint16
    deltaX{.importc: "xrel".}: int16
    deltaY{.importc: "yrel".}: int16

  MouseButtonEvent* {.importc: "SDL_MouseButtonEvent".} = object
    ## Mouse button press/release event.
    kind {.importc: "type".}: EventType
    deviceIndex {.importc: "which".}: uint8
    buttonIndex {.importc: "button".}: uint8
    state: ButtonState
    x, y: uint16

  JoyAxisEvent* {.importc: "SDL_JoyAxisEvent".} = object
    ## Joystick axis movement event (analog sticks, triggers).
    kind {.importc: "type".}: EventType
    deviceIndex {.importc: "which".}: uint8
    axisIndex {.importc: "axis".}: uint8
    value: int16

  JoyBallEvent* {.importc: "SDL_JoyBallEvent".} = object
    ## Joystick trackball movement event.
    kind {.importc: "type".}: EventType
    deviceIndex {.importc: "which".}: uint8
    ballIndex {.importc: "ball".}: uint8
    deltaX {.importc: "xrel".}: int16
    deltaY {.importc: "yrel".}: int16

  JoyDPadEvent* {.importc: "SDL_JoyHatEvent".} = object
    ## Joystick D-pad (hat) movement event.
    kind {.importc: "type".}: EventType
    deviceIndex {.importc: "which".}: uint8
    dPadIndex {.importc: "hat".}: uint8
    value: DPadState

  JoyButtonEvent* {.importc: "SDL_JoyButtonEvent".} = object
    ## Joystick button press/release event.
    kind {.importc: "type".}: EventType
    deviceIndex {.importc: "which".}: uint8
    buttonIndex {.importc: "button".}: uint8
    state: ButtonState

  ResizeEvent* {.importc: "SDL_ResizeEvent".} = object
    ## Window resize event (for resizeable windows).
    kind {.importc: "type".}: EventType
    width {.importc: "w".}: cint
    height {.importc: "h".}: cint

  ExposeEvent* {.importc: "SDL_ExposeEvent".} = object
    ## Window expose event (needs redraw).
    kind {.importc: "type".}: EventType

  QuitEvent* {.importc: "SDL_QuitEvent".} = object
    ## Application quit event (window close, Ctrl+C, etc).
    kind {.importc: "type".}: EventType

  UserEvent* {.importc: "SDL_UserEvent".} = object
    ## Application-defined custom event.
    kind {.importc: "type".}: EventType
    code: cint
    data1, data2: pointer

  SysWmEvent* {.importc: "SDL_SysWMEvent".} = object
    ## Window manager specific event.
    kind {.importc: "type".}: EventType
    message {.importc: "msg".}: pointer

  Event* {.importc: "SDL_Event", header: "SDL_events.h", union.} = object
    ## Union type representing any SDL event.
    ## Access the appropriate field based on `kind`.
    kind {.importc: "type".}: EventType
    active: ActiveEvent
    key: KeyboardEvent
    motion: MouseMotionEvent
    button: MouseButtonEvent
    joyAxis {.importc: "jaxis".}: JoyAxisEvent
    joyBall {.importc: "jball".}: JoyBallEvent
    joyDPad {.importc: "jhat".}: JoyDPadEvent
    joyButton {.importc: "jbutton".}: JoyButtonEvent
    resize: ResizeEvent
    expose: ExposeEvent
    quit: QuitEvent
    user: UserEvent
    systemWm {.importc: "syswm".}: SysWmEvent

  EventFilter* {.importc: "SDL_EventFilter".} = proc (event: ptr Event): cint
    ## Callback type for event filtering.

{.pop.}

{.push header: "SDL_events.h", importc, cdecl.}

proc SDL_PumpEvents()
proc SDL_PeepEvents(events: ptr Event, numevents: cint, action: EventAction, mask: uint32): cint
proc SDL_PollEvent(event: ptr Event): cint
proc SDL_WaitEvent(event: ptr Event): cint
proc SDL_PushEvent(event: ptr Event): cint
proc SDL_SetEventFilter(filter: EventFilter)
proc SDL_GetEventFilter(): EventFilter
proc SDL_EventState(kind: uint8, state: cint): uint8

{.pop.}

type 
  EventState* {.pure, size: sizeof(cint).} = enum
    ## Event state for enabling/disabling event types.
    query = -1   ## Query current state
    disable = 0  ## Disable event type
    enable = 1   ## Enable event type

const ignore* = EventState.disable
  ## Semantic alias (SDL_DISABLE and SDL_IGNORE are both 0).

type EventMasks* = distinct uint32
  ## Bitmask for filtering event types.

proc `or`*(x, y: EventMasks): EventMasks {.borrow.}
proc `and`*(x, y: EventMasks): EventMasks {.borrow.}
proc `==`*(x, y: EventMasks): bool {.borrow.}

# Safe cast with 'ord'
template eventMask(x: EventType): EventMasks = EventMasks(1'u32 shl ord(x))

const
  activeEventMask* = eventMask(EventType.activeEvent)
    ## Mask for application state events.
  keyDownMask* = eventMask(EventType.keyDown)
    ## Mask for key press events.
  keyUpMask* = eventMask(EventType.keyUp)
    ## Mask for key release events.
  keyEventMask* = keyDownMask or keyUpMask
    ## Mask for all keyboard events.
  mouseMotionMask* = eventMask(EventType.mouseMotion)
    ## Mask for mouse movement events.
  mouseButtonDownMask* = eventMask(EventType.mouseButtonDown)
    ## Mask for mouse button press events.
  mouseButtonUpMask* = eventMask(EventType.mouseButtonUp)
    ## Mask for mouse button release events.
  mouseEventMask* = mouseMotionMask or mouseButtonDownMask or mouseButtonUpMask
    ## Mask for all mouse events.
  joyAxisMotionMask* = eventMask(EventType.joyAxisMotion)
    ## Mask for joystick axis events.
  joyBallMotionMask* = eventMask(EventType.joyBallMotion)
    ## Mask for joystick trackball events.
  joyDPadMotionMask* = eventMask(EventType.joyDPadMotion)
    ## Mask for joystick D-pad events.
  joyButtonDownMask* = eventMask(EventType.joyButtonDown)
    ## Mask for joystick button press events.
  joyButtonUpMask* = eventMask(EventType.joyButtonUp)
    ## Mask for joystick button release events.
  joyEventMask* = joyAxisMotionMask or joyBallMotionMask or joyDPadMotionMask or joyButtonDownMask or joyButtonUpMask
    ## Mask for all joystick events.
  videoResizeMask* = eventMask(EventType.videoResize)
    ## Mask for window resize events.
  videoExposeMask* = eventMask(EventType.videoExpose)
    ## Mask for window expose events.
  quitMask* = eventMask(EventType.quit)
    ## Mask for quit events.
  sysWmEventMask* = eventMask(EventType.sysWmEvent)
    ## Mask for window manager events.
  allEventsMask* = EventMasks(0xFFFFFFFF'u32)
    ## Mask for all event types.

# =========================================================
# GETTERS (Read-Only Access)
# =========================================================

proc kind*(e: ActiveEvent): EventType {.inline.} = e.kind
  ## Event type.
proc gained*(e: ActiveEvent): bool {.inline.} = e.gained != 0
  ## Whether the state was gained (true) or lost (false).
proc state*(e: ActiveEvent): uint8 {.inline.} = e.state
  ## Which state changed (app active, input focus, or mouse focus).

# ResizeEvent
proc kind*(e: ResizeEvent): EventType {.inline.} = e.kind
  ## Event type.
proc width*(e: ResizeEvent): uint16 {.inline.} = uint16(e.width)
  ## New window width.
proc height*(e: ResizeEvent): uint16 {.inline.} = uint16(e.height)
  ## New window height.

# Quit / Expose (Only Kind)
proc kind*(e: QuitEvent): EventType {.inline.} = e.kind
  ## Event type.
proc kind*(e: ExposeEvent): EventType {.inline.} = e.kind
  ## Event type.

# KeyboardEvent
proc kind*(e: KeyboardEvent): EventType {.inline.} = e.kind
  ## Event type.
proc deviceIndex*(e: KeyboardEvent): uint8 {.inline.} = e.deviceIndex
  ## Keyboard device index.
proc state*(e: KeyboardEvent): ButtonState {.inline.} = e.state
  ## Button state (pressed or released).
proc keyInfo*(e: KeyboardEvent): KeyInfo {.inline.} = e.keysym
  ## Key press information. Nim wrapper for C `SDL_keysym`.
  ## See `sdl/keyboard` for the `KeyInfo` struct fields.

# MouseMotionEvent
proc kind*(e: MouseMotionEvent): EventType {.inline.} = e.kind
  ## Event type.
proc deviceIndex*(e: MouseMotionEvent): uint8 {.inline.} = e.deviceIndex
  ## Mouse device index.
proc state*(e: MouseMotionEvent): uint8 {.inline.} = e.state
  ## Button state bitmask.
proc x*(e: MouseMotionEvent): uint16 {.inline.} = e.x
  ## Current X position.
proc y*(e: MouseMotionEvent): uint16 {.inline.} = e.y
  ## Current Y position.
proc deltaX*(e: MouseMotionEvent): int16 {.inline.} = e.deltaX
  ## Relative X motion.
proc deltaY*(e: MouseMotionEvent): int16 {.inline.} = e.deltaY
  ## Relative Y motion.

# MouseButtonEvent
proc kind*(e: MouseButtonEvent): EventType {.inline.} = e.kind
  ## Event type.
proc deviceIndex*(e: MouseButtonEvent): uint8 {.inline.} = e.deviceIndex
  ## Mouse device index.
proc buttonIndex*(e: MouseButtonEvent): uint8 {.inline.} = e.buttonIndex
  ## Button index (1=left, 2=middle, 3=right).
proc state*(e: MouseButtonEvent): ButtonState {.inline.} = e.state
  ## Button state.
proc x*(e: MouseButtonEvent): uint16 {.inline.} = e.x
  ## X position at click.
proc y*(e: MouseButtonEvent): uint16 {.inline.} = e.y
  ## Y position at click.

# JoyAxisEvent
proc kind*(e: JoyAxisEvent): EventType {.inline.} = e.kind
  ## Event type.
proc axisIndex*(e: JoyAxisEvent): uint8 {.inline.} = e.axisIndex
  ## Axis index.
proc value*(e: JoyAxisEvent): int16 {.inline.} = e.value
  ## Axis value (-32768 to 32767).

# JoyDPadEvent
proc kind*(e: JoyDPadEvent): EventType {.inline.} = e.kind
  ## Event type.
proc dPadIndex*(e: JoyDPadEvent): uint8 {.inline.} = e.dPadIndex
  ## D-pad index.
proc value*(e: JoyDPadEvent): DPadState {.inline.} = e.value
  ## D-pad direction state.

# JoyButtonEvent
proc kind*(e: JoyButtonEvent): EventType {.inline.} = e.kind
  ## Event type.
proc buttonIndex*(e: JoyButtonEvent): uint8 {.inline.} = e.buttonIndex
  ## Button index.
proc state*(e: JoyButtonEvent): ButtonState {.inline.} = e.state
  ## Button state.

# UserEvent
proc kind*(e: UserEvent): EventType {.inline.} = e.kind
  ## Event type.
proc code*(e: UserEvent): int32 {.inline.} = int32(e.code)
  ## User-defined event code.
proc data1*(e: UserEvent): pointer {.inline.} = e.data1
  ## User data pointer 1.
proc data2*(e: UserEvent): pointer {.inline.} = e.data2
  ## User data pointer 2.

# Event
proc kind*(e: Event): EventType {.inline.} = e.kind
  ## Event type (use this to determine which field to access).
proc active*(e: Event): ActiveEvent {.inline.} = e.active
  ## Access as ActiveEvent.
proc key*(e: Event): KeyboardEvent {.inline.} = e.key
  ## Access as KeyboardEvent.
proc motion*(e: Event): MouseMotionEvent {.inline.} = e.motion
  ## Access as MouseMotionEvent.
proc button*(e: Event): MouseButtonEvent {.inline.} = e.button
  ## Access as MouseButtonEvent.
proc joyAxis*(e: Event): JoyAxisEvent {.inline.} = e.joyAxis
  ## Access as JoyAxisEvent.
proc joyBall*(e: Event): JoyBallEvent {.inline.} = e.joyBall
  ## Access as JoyBallEvent.
proc joyDPad*(e: Event): JoyDPadEvent {.inline.} = e.joyDPad
  ## Access as JoyDPadEvent.
proc joyButton*(e: Event): JoyButtonEvent {.inline.} = e.joyButton
  ## Access as JoyButtonEvent.
proc resize*(e: Event): ResizeEvent {.inline.} = e.resize
  ## Access as ResizeEvent.
proc expose*(e: Event): ExposeEvent {.inline.} = e.expose
  ## Access as ExposeEvent.
proc quit*(e: Event): QuitEvent {.inline.} = e.quit
  ## Access as QuitEvent.
proc user*(e: Event): UserEvent {.inline.} = e.user
  ## Access as UserEvent.
proc systemWm*(e: Event): SysWmEvent {.inline.} = e.systemWm
  ## Access as SysWmEvent.

# --- UserEvent Setters (For Internal Engine Communication) ---

proc `code=`*(e: var UserEvent, val: int32) {.inline.} =
  ## Sets a custom identification code for the event.
  e.code = cint(val)

proc `data1=`*(e: var UserEvent, val: pointer) {.inline.} =
  ## Assigns the first generic data pointer.
  e.data1 = val

proc `data2=`*(e: var UserEvent, val: pointer) {.inline.} =
  ## Assigns the second generic data pointer.
  e.data2 = val

proc createKeyEvent*(key: Key, pressed: bool): Event {.inline.} =
  ## Creates a synthetic keyboard event.
  ## Useful for injecting keyboard input programmatically.
  ##
  ## ```nim
  ## let ev = createKeyEvent(K_SPACE, pressed = true)
  ## discard pushEvent(ev)
  ## ```
  result.kind = if pressed: EventType.keyDown else: EventType.keyUp
  result.key.state = if pressed: ButtonState.pressed else: ButtonState.released
  result.key.keysym = initKeyInfo(key)

# =========================================================
# PUBLIC API (The Minimalist Game Loop)
# =========================================================

proc pumpEvents*() {.inline.} =
  ## Synchronizes hardware state with SDL's internal event queue.
  ## Call this once per frame before polling events.
  SDL_PumpEvents()

proc pollEvent*(event: var Event): bool {.inline.} =
  ## Polls for the next event in the queue.
  ## Returns `true` if an event was available, `false` otherwise.
  ##
  ## ```nim
  ## var event: Event
  ## while pollEvent(event):
  ##   case event.kind
  ##   of quit: running = false
  ##   else: discard
  ## ```
  sdlTrue SDL_PollEvent(addr event)

proc pollEvent*(): bool {.inline.} =
  ## Processes the queue and discards the event immediately.
  ## Useful for cleanup loops: `while pollEvent(): discard`
  sdlTrue SDL_PollEvent(nil)

proc waitEvent*(event: var Event): bool {.inline.} =
  ## Blocks until the next event is available.
  ## Useful for menus or pause screens to save CPU.
  sdlTrue SDL_WaitEvent(addr event)

proc waitEvent*(): bool {.inline.} =
  ## Freezes until any event occurs, discarding the read.
  sdlTrue SDL_WaitEvent(nil)

proc pushEvent*(event: Event): bool {.inline.} =
  ## Injects an event into the queue.
  ## Pass by value allows creating the event inline.
  ##
  ## ```nim
  ## discard pushEvent(Event(kind: EventType.quit))
  ## ```
  var ev = event # Nim creates a safe mutable copy on the stack
  sdlOk SDL_PushEvent(addr ev)

proc countEvents*(mask: EventMasks): int {.inline.} =
  ## Counts how many events of a specific type are in the queue
  ## without removing them.
  SDL_PeepEvents(nil, 0, EventAction.peek, uint32(mask))

proc peekEvents*(events: var openArray[Event], mask: EventMasks = allEventsMask): int {.inline.} =
  ## Copies events to the buffer but LEAVES them in SDL's queue.
  if events.len == 0: return 0
  SDL_PeepEvents(addr events[0], cint(events.len), EventAction.peek, uint32(mask))

proc events*(events: var openArray[Event], mask: EventMasks = allEventsMask): int {.inline.} =
  ## Extracts events, copying to buffer and REMOVING them from SDL's queue.
  if events.len == 0: return 0
  SDL_PeepEvents(addr events[0], cint(events.len), EventAction.get, uint32(mask))

proc addEvents*(events: var openArray[Event], mask: EventMasks = allEventsMask): int {.inline.} =
  ## Injects multiple events at once into SDL's queue.
  if events.len == 0: return 0
  SDL_PeepEvents(addr events[0], cint(events.len), EventAction.add, uint32(mask))

proc hasEvent*(mask: EventMasks): bool {.inline.} =
  ## Quick check if a specific event type is in the queue.
  ##
  ## ```nim
  ## if hasEvent(quitMask):
  ##   cleanup()
  ## ```
  result = (SDL_PeepEvents(nil, 0, EventAction.peek, uint32(mask)) > 0)

proc eventState*(kind: EventType, state: EventState): EventState {.inline.} =
  ## Enables or disables entire event types.
  ## Disabled events are not added to the queue.
  cast[EventState](SDL_EventState(uint8(kind), cint(state)))

proc enableEvent*(kind: EventType) {.inline.} =
  ## Enables a specific event type.
  discard eventState(kind, EventState.enable)

proc disableEvent*(kind: EventType) {.inline.} =
  ## Disables a specific event type.
  discard eventState(kind, EventState.disable)

proc `eventFilter=`*(filter: EventFilter) {.inline.} =
  ## Sets a callback to filter events before they enter the queue.
  SDL_SetEventFilter(filter)

proc eventFilter*(): EventFilter {.inline.} =
  ## Returns the current event filter callback.
  SDL_GetEventFilter()

iterator pollEvents*(): Event =
  ## Supreme iterator for the game loop.
  ## Zero cost and cleans up variable scope.
  ##
  ## ```nim
  ## for event in pollEvents():
  ##   case event.kind
  ##   of quit: running = false
  ##   else: discard
  ## ```
  var ev: Event
  while sdlTrue SDL_PollEvent(addr ev):
    yield ev

iterator waitEvents*(): Event =
  ## Like pollEvents, but blocks the CPU until the first event arrives.
  ## Perfect for saving battery on Menu or Pause screens.
  var ev: Event
  if sdlTrue SDL_WaitEvent(addr ev):
    yield ev
    while sdlTrue SDL_PollEvent(addr ev):
      yield ev
