## # sdl/keyboard
##
## Keyboard input handling and state management
##
## This module provides functions for reading keyboard state, handling key events,
## managing key repeat, and working with Unicode text input.
##
## ## SDL 1.2 Reference
##
## SDL 1.2 provides keyboard input through events and direct state queries.
## The keyboard state is an array of key states that can be queried directly
## for real-time input, or processed through the event queue for discrete events.
##
## **Key C functions:**
## ```c
## Uint8 *SDL_GetKeyState(int *numkeys);
## SDLMod SDL_GetModState(void);
## void SDL_SetModState(SDLMod modstate);
## int SDL_EnableUNICODE(int enable);
## int SDL_EnableKeyRepeat(int delay, int interval);
## char *SDL_GetKeyName(SDLKey key);
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
##   # Real-time keyboard state
##   var running = true
##   while running:
##     for event in pollEvents():
##       if event.kind == quit:
##         running = false
##
##     # Get current keyboard state
##     let keys = getKeyboardState()
##     if keys.isKeyDown(K_ESCAPE):
##       running = false
##     if keys.isKeyDown(K_LEFT):
##       echo "Moving left"
##     if keys.isKeyDown(K_RIGHT):
##       echo "Moving right"
##
##     # Check modifier keys
##     let mods = getModState()
##     if (mods and modShift) != 0:
##       echo "Shift is pressed"
##
##     screen.flip()
## ```
##
## ## Advantages over C SDL 1.2
##
## | C SDL 1.2                          | Nim SDL                                      |
## |------------------------------------|----------------------------------------------|
## | `SDL_GetKeyState(&numkeys)`        | `getKeyboardState()` returns `KeyboardState` |
## | Manual array bounds checking       | `isKeyDown()` with bounds safety             |
## | `SDLMod` as int                    | `KeyMods` type-safe bitmask                  |
## | `SDL_EnableUNICODE(1)` returns old | `enableUnicode()` returns bool               |
## | No `KeySym` constructor            | `initKeySym()` for synthetic events          |
##
## ## Key Features
##
## - **Direct state access**: `getKeyboardState()` for real-time input
## - **Type-safe modifiers**: `KeyMods` bitmask with `modShift`, `modCtrl`, etc.
## - **Unicode support**: Enable/disable Unicode translation
## - **Key repeat**: Configure auto-repeat delay and interval
## - **Synthetic events**: Create fake key events for bots or replays
##
## ## Keyboard State
##
## The keyboard state is a snapshot of which keys are currently pressed.
## Call `pumpEvents()` or process events before querying the state.
##
## ```nim
## let keys = getKeyboardState()
## if keys.isKeyDown(K_SPACE):
##   echo "Space is pressed"
## ```
##
## ## Modifier Keys
##
## Modifier keys (Shift, Ctrl, Alt) can be queried as a bitmask.
##
## ```nim
## let mods = getModState()
## if (mods and modCtrl) != 0:
##   echo "Ctrl is pressed"
## if (mods and modAlt) != 0:
##   echo "Alt is pressed"
## ```
##
## ## Unicode Input
##
## Enable Unicode translation to get character codes from key events.
## Costs some CPU, so only enable when the player is typing text.
##
## ```nim
## discard enableUnicode(true)
## # Now key events will have valid `unicode` field
## ```
##
## ## Key Repeat
##
## Configure automatic key repeat for text input.
##
## ```nim
## discard enableKeyRepeat(500, 30)  # 500ms delay, 30ms interval
## ```
##
## ## See Also
##
## - `sdl/events` - Event processing system
## - `sdl/keysym` - Key symbol definitions

import private/utils
import keysym

# =========================================================
# 1. STANDARD CONSTANTS (NEP-1)
# =========================================================

const
  allHotkeys* = 0xFFFFFFFF'u32
    ## Mask for all hotkeys (all keys enabled).
  defaultRepeatDelay* = 500'i32
    ## Default delay before key repeat starts (milliseconds).
  defaultRepeatInterval* = 30'i32
    ## Default interval between key repeats (milliseconds).

# =========================================================
# 2. C STRUCTURES AND FFI (Strict Typing, No Generic Pointers)
# =========================================================
{.push header: "SDL_keyboard.h", bycopy, cdecl.}

type
  KeySym* {.importc: "SDL_keysym".} = object
    ## Represents a key event with symbol, scancode, modifiers, and Unicode.
    ## scanCode: The physical hardware key code (layout-independent).
    scanCode* {.importc: "scancode".}: uint8
    ## key: The translated virtual key (e.g., Key.enter). Use this 99% of the time.
    key* {.importc: "sym".}: Key
    ## mods: Modifier keys pressed with the key (e.g., Shift + A).
    mods* {.importc: "mod".}: KeyMods
    ## unicode: The generated text character (if enableUnicode is on).
    unicode*: uint16

{.pop.}

{.push header: "SDL_keyboard.h", importc, cdecl.}

proc SDL_EnableUNICODE(enable: cint): cint
proc SDL_EnableKeyRepeat(delay, interval: cint): cint
proc SDL_GetKeyRepeat(delay, interval: ptr cint)

proc SDL_GetKeyState(numkeys: ptr cint): ptr UncheckedArray[uint8]

proc SDL_GetModState(): KeyMods
proc SDL_SetModState(modstate: KeyMods)
proc SDL_GetKeyName(key: Key): cstring

{.pop.}

# =========================================================
# 3. PUBLIC API
# =========================================================

type KeyboardState* = object
  ## Ultra-lightweight wrapper that holds the pointer to SDL's RAM.
  ## Protects against out-of-bounds access at zero cost.
  arrayPtr: ptr UncheckedArray[uint8]
  numKeys: cint

# ---------------------------------------------------------
# KEY READING
# ---------------------------------------------------------

proc getKeyboardState*(): KeyboardState {.inline.} =
  ## Returns a "snapshot" of the keyboard memory. Call ONCE per need,
  ## and reuse the object to check multiple keys.
  ##
  ## **Example:**
  ## ```nim
  ## let keys = getKeyboardState()
  ## if keys.isKeyDown(K_SPACE):
  ##   echo "Space is pressed"
  ## ```
  var numKeys: cint
  let ptrArray = SDL_GetKeyState(addr numKeys)
  result = KeyboardState(arrayPtr: ptrArray, numKeys: numKeys)

proc isKeyDown*(state: KeyboardState, key: Key): bool {.inline.} =
  ## Checks if a key is currently pressed by accessing memory directly,
  ## WITHOUT calling the C API. Maximum speed your CPU can read RAM.
  ##
  ## **Example:**
  ## ```nim
  ## let keys = getKeyboardState()
  ## if keys.isKeyDown(K_LEFT):
  ##   player.moveLeft()
  ## ```
  if state.arrayPtr != nil and cint(key) < state.numKeys:
    result = sdlNonZero(state.arrayPtr[cint(key)])

# ---------------------------------------------------------
# MODIFIERS (Shift, Ctrl, Alt)
# ---------------------------------------------------------

proc getModState*(): KeyMods {.inline.} =
  ## Bitmask of all currently pressed modifiers.
  ##
  ## **Example:**
  ## ```nim
  ## let mods = getModState()
  ## if (mods and modShift) != 0:
  ##   echo "Shift is pressed"
  ## ```
  SDL_GetModState()

proc setModState*(modState: KeyMods) {.inline.} =
  ## Forces the modifier state (useful for simulating input via code).
  ##
  ## **Example:**
  ## ```nim
  ## setModState(modShift)  # Simulate Shift being pressed
  ## ```
  SDL_SetModState(modState)

# ---------------------------------------------------------
# INTERNATIONAL TEXT AND REPEAT
# ---------------------------------------------------------

proc enableUnicode*(enable: bool): bool {.inline.} =
  ## Enables/disables translation of keys to Unicode characters.
  ## Costs some CPU. Only enable when the player is typing text.
  ## Returns previous state.
  ##
  ## **Example:**
  ## ```nim
  ## discard enableUnicode(true)
  ## # Now key events will have valid `unicode` field
  ## ```
  sdlTrue SDL_EnableUNICODE(cint(enable))

proc isUnicodeEnabled*(): bool {.inline.} =
  ## Queries if Unicode translation is active using SDL's -1 flag.
  sdlTrue SDL_EnableUNICODE(-1)

proc enableKeyRepeat*(delay: int32 = defaultRepeatDelay, interval: int32 = defaultRepeatInterval): bool {.inline.} =
  ## Enables key repeat (if the player holds a key, it repeats the input).
  ##
  ## **Example:**
  ## ```nim
  ## discard enableKeyRepeat(500, 30)  # 500ms delay, 30ms interval
  ## ```
  sdlOk SDL_EnableKeyRepeat(cint(delay), cint(interval))

proc disableKeyRepeat*(): bool {.inline.} =
  ## Completely disables key repeat.
  sdlOk SDL_EnableKeyRepeat(0, 0)

proc getKeyRepeat*(): tuple[delay, interval: int32] {.inline.} =
  ## Current key repeat settings in a clean tuple.
  ##
  ## **Example:**
  ## ```nim
  ## let (delay, interval) = getKeyRepeat()
  ## echo "Delay: ", delay, "ms, Interval: ", interval, "ms"
  ## ```
  var d, i: cint
  SDL_GetKeyRepeat(addr d, addr i)
  result.delay = int32(d)
  result.interval = int32(i)

# =========================================================
# GETTERS (Zero Cost Access)
# =========================================================

proc scanCode*(k: KeySym): uint8 {.inline.} =
  ## Physical hardware key code (layout-independent).
  k.scanCode

proc key*(k: KeySym): Key {.inline.} =
  ## Translated virtual key (e.g., Key.enter). Use this 99% of the time.
  k.key

proc mods*(k: KeySym): KeyMods {.inline.} =
  ## Modifier keys pressed with the key (e.g., Shift + A).
  k.mods

proc unicode*(k: KeySym): uint16 {.inline.} =
  ## Generated text character (if enableUnicode is on).
  k.unicode

# --- SYNTHETIC CONSTRUCTOR (Replaces Setters) ---
proc initKeySym*(
    key: Key;
    scanCode: uint8 = 0;
    mods: KeyMods = cast[KeyMods](0);
    unicode: uint16 = 0
  ): KeySym {.inline.} =
  ## Constructs a synthetic KeySym.
  ## Extremely useful for creating artificial events (Bots, Replays, Macros).
  ##
  ## **Example:**
  ## ```nim
  ## # Create a synthetic key event for bots or replays
  ## let sym = initKeySym(K_SPACE, mods = modShift)
  ## ```
  result.key = key
  result.scanCode = scanCode
  result.mods = mods
  result.unicode = unicode

# ---------------------------------------------------------
# UTILITIES
# ---------------------------------------------------------

proc getKeyName*(key: Key): cstring {.inline.} =
  ## Converts a virtual key to a user-readable string.
  ##
  ## **Example:**
  ## ```nim
  ## let name = getKeyName(K_SPACE)
  ## echo "Key name: ", $name  # "space"
  ## ```
  SDL_GetKeyName(key)
