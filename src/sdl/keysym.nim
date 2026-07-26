## # sdl/keysym
##
## Key symbol definitions and modifier flags
##
## This module defines all keyboard key symbols and modifier flags used in SDL 1.2.
## It provides a comprehensive mapping of physical keys to virtual key codes,
## enabling layout-independent keyboard input handling.
##
## ## SDL 1.2 Reference
##
## SDL 1.2 defines key symbols as an enumeration covering ASCII characters,
## function keys, navigation keys, modifier keys, and international keys.
## Modifier flags indicate which modifier keys (Shift, Ctrl, Alt) are pressed.
##
## **Key C definitions:**
## ```c
## typedef enum {
##   SDLK_UNKNOWN = 0,
##   SDLK_FIRST = 0,
##   SDLK_BACKSPACE = 8,
##   SDLK_TAB = 9,
##   // ... many more keys ...
##   SDLK_LAST
## } SDLKey;
##
## typedef enum {
##   KMOD_NONE = 0x0000,
##   KMOD_LSHIFT = 0x0001,
##   KMOD_RSHIFT = 0x0002,
##   // ... more modifiers ...
## } SDLMod;
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
##   var running = true
##   while running:
##     for event in pollEvents():
##       if event.kind == keyDown:
##         let key = event.key.keySym.key
##         case key
##         of K_ESCAPE:
##           running = false
##         of K_SPACE:
##           echo "Jump!"
##         of K_RETURN:
##           echo "Confirm"
##         else:
##           discard
##
##         # Check modifiers
##         let mods = event.key.keySym.mods
##         if (mods and modShift) != 0:
##           echo "Shift was pressed"
##
##     screen.flip()
## ```
##
## ## Key Categories
##
## ### Control Keys
## - `K_BACKSPACE`, `K_TAB`, `K_CLEAR`, `K_RETURN`, `K_PAUSE`, `K_ESCAPE`
##
## ### Symbols
## - `K_SPACE`, `K_EXCLAIM`, `K_QUOTEDBL`, `K_HASH`, `K_DOLLAR`, etc.
##
## ### Numbers
## - `K_0` through `K_9` (protected from syntax errors)
##
## ### Alphabet
## - `K_a` through `K_z` (lowercase)
##
## ### Navigation
## - `K_UP`, `K_DOWN`, `K_LEFT`, `K_RIGHT`
## - `K_INSERT`, `K_HOME`, `K_ENDNAV`, `K_PAGEUP`, `K_PAGEDOWN`
##
## ### Function Keys
## - `K_F1` through `K_F15`
##
## ### Modifier Keys
## - `K_NUMLOCK`, `K_CAPSLOCK`, `K_SCROLLLOCK`
## - `K_RSHIFT`, `K_LSHIFT`, `K_RCTRL`, `K_LCTRL`
## - `K_RALT`, `K_LALT`, `K_RMETA`, `K_LMETA`
## - `K_LSUPER`, `K_RSUPER` (Windows/Command keys)
##
## ### Keypad
## - `K_KP0` through `K_KP9`
## - `K_KP_PERIOD`, `K_KP_DIVIDE`, `K_KP_MULTIPLY`
## - `K_KP_MINUS`, `K_KP_PLUS`, `K_KP_ENTER`, `K_KP_EQUALS`
##
## ### International
## - `K_WORLD_0` through `K_WORLD_95` (non-US keys)
##
## ## Modifier Flags
##
## Modifier flags can be combined using bitwise OR.
##
## ```nim
## let mods = modCtrl or modShift  # Ctrl+Shift
## if (keyMods and mods) == mods:
##   echo "Ctrl+Shift is pressed"
## ```
##
## ### Predefined Combinations
## - `modCtrl` - Either Ctrl key
## - `modShift` - Either Shift key
## - `modAlt` - Either Alt key
## - `modMeta` - Either Meta (Windows/Command) key
##
## ## Advantages over C SDL 1.2
##
## | C SDL 1.2                  | Nim SDL                     |
## |----------------------------|-----------------------------|
## | `SDLK_*` constants         | `K_*` enum values           |
## | `SDLMod` as int            | `KeyModFlag` typed enum     |
## | Manual bitmask operations  | `KeyMods` type-safe bitmask |
## | No predefined combinations | `modCtrl`, `modShift`, etc. |
##
## ## See Also
##
## - `sdl/keyboard` - Keyboard state and input handling
## - `sdl/events` - Event processing system

import private/utils

# =========================================================
# 1. KEY DICTIONARY
# =========================================================
{.push header: "SDL_keysym.h".}

type
  Key* {.importc: "SDLKey", pure, size: sizeof(cint).} = enum
    ## Comprehensive enumeration of all keyboard keys.
    ## Maps to SDL's `SDLKey` enum with Nim naming conventions.
    unknown = 0

    # Control Keys
    backspace = 8, tab = 9, clear = 12, enter = 13, pause = 19, escape = 27

    # Symbols
    space = 32, exclaim = 33, quotedbl = 34, hash = 35, dollar = 36
    ampersand = 38, quote = 39, leftParen = 40, rightParen = 41, asterisk = 42
    plus = 43, comma = 44, minus = 45, period = 46, slash = 47

    # Numbers (Protected from syntax errors)
    num0 = 48, num1 = 49, num2 = 50, num3 = 51, num4 = 52
    num5 = 53, num6 = 54, num7 = 55, num8 = 56, num9 = 57

    # More Symbols
    colon = 58, semicolon = 59, less = 60, equals = 61, greater = 62
    question = 63, at = 64
    leftBracket = 91, backslash = 92, rightBracket = 93, caret = 94
    underscore = 95, backquote = 96

    # Alphabet
    a = 97,  b = 98,  c = 99,  d = 100, e = 101, f = 102, g = 103, h = 104
    i = 105, j = 106, k = 107, l = 108, m = 109, n = 110, o = 111, p = 112
    q = 113, r = 114, s = 115, t = 116, u = 117, v = 118, w = 119, x = 120
    y = 121, z = 122, delete = 127

    # International Virtual Keys (0xA0 - 0xFF)
    world0 = 160, world1, world2, world3, world4, world5, world6, world7
    world8, world9, world10, world11, world12, world13, world14, world15
    world16, world17, world18, world19, world20, world21, world22, world23
    world24, world25, world26, world27, world28, world29, world30, world31
    world32, world33, world34, world35, world36, world37, world38, world39
    world40, world41, world42, world43, world44, world45, world46, world47
    world48, world49, world50, world51, world52, world53, world54, world55
    world56, world57, world58, world59, world60, world61, world62, world63
    world64, world65, world66, world67, world68, world69, world70, world71
    world72, world73, world74, world75, world76, world77, world78, world79
    world80, world81, world82, world83, world84, world85, world86, world87
    world88, world89, world90, world91, world92, world93, world94, world95

    # Numeric Keypad
    kp0 = 256, kp1 = 257, kp2 = 258, kp3 = 259, kp4 = 260, kp5 = 261
    kp6 = 262, kp7 = 263, kp8 = 264, kp9 = 265
    kpPeriod = 266, kpDivide = 267, kpMultiply = 268, kpMinus = 269
    kpPlus = 270, kpEnter = 271, kpEquals = 272

    # Arrows and Navigation Block
    up = 273, down = 274, right = 275, left = 276, insert = 277
    home = 278, endNav = 279, pageUp = 280, pageDown = 281

    # Function Keys
    f1 = 282, f2 = 283, f3 = 284, f4 = 285, f5 = 286, f6 = 287
    f7 = 288, f8 = 289, f9 = 290, f10 = 291, f11 = 292, f12 = 293
    f13 = 294, f14 = 295, f15 = 296

    # Modifier Keys
    numLock = 300, capsLock = 301, scrollLock = 302
    rShift = 303, lShift = 304, rCtrl = 305, lCtrl = 306
    rAlt = 307, lAlt = 308, rMeta = 309, lMeta = 310
    lSuper = 311, rSuper = 312, mode = 313, compose = 314

    # Miscellaneous Keys
    help = 315, print = 316, sysReq = 317, pauseBreak = 318, menu = 319
    power = 320, euro = 321, undo = 322

    last


# =========================================================
# 2. STATE KEYS (Combinable Modifiers)
# =========================================================

type
  KeyModFlag* {.importc: "SDLMod", pure, size: sizeof(cint).} = enum
    ## Individual modifier key flags.
    ## Can be combined using bitwise OR to represent multiple modifiers.
    none     = 0x0000
    lShift   = 0x0001  ## Left Shift
    rShift   = 0x0002  ## Right Shift
    lCtrl    = 0x0040  ## Left Ctrl
    rCtrl    = 0x0080  ## Right Ctrl
    lAlt     = 0x0100  ## Left Alt
    rAlt     = 0x0200  ## Right Alt
    lMeta    = 0x0400  ## Left Meta (AltGr on some keyboards)
    rMeta    = 0x0800  ## Right Meta
    num      = 0x1000  ## Num Lock
    caps     = 0x2000  ## Caps Lock
    mode     = 0x4000  ## Mode Switch
    reserved = 0x8000

  # The Safe Distinct Type for Bitmasks
  KeyMods* = distinct cint
    ## Type-safe bitmask for modifier keys.
    ## Supports bitwise operations (`and`, `or`) for combining modifiers.

{.pop.}

# We inject your magic macro from utils.nim!
operatorBitmask(KeyModFlag, KeyMods)

proc `and`*(x, y: KeyMods): KeyMods {.borrow.}
  ## Computes the bitwise AND between two KeyMods bitmasks.

proc `==`*(x, y: KeyMods): bool {.borrow.}
  ## Compares two KeyMods bitmasks for equality.

# ---------------------------------------------------------
# COMBINED MODIFIER CONSTANTS
# ---------------------------------------------------------
const
  modCtrl* = KeyMods(cint(KeyModFlag.lCtrl) or cint(KeyModFlag.rCtrl))
    ## Either Ctrl key (left or right).
  modShift* = KeyMods(cint(KeyModFlag.lShift) or cint(KeyModFlag.rShift))
    ## Either Shift key (left or right).
  modAlt* = KeyMods(cint(KeyModFlag.lAlt) or cint(KeyModFlag.rAlt))
    ## Either Alt key (left or right).
  modMeta* = KeyMods(cint(KeyModFlag.lMeta) or cint(KeyModFlag.rMeta))
    ## Either Meta key (left or right).
