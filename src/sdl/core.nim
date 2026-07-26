## # sdl/core
##
## Core SDL initialization and subsystem management
##
## This module handles SDL library initialization, subsystem management, and
## proper cleanup. It provides a RAII-based `Context` type that automatically
## calls `SDL_Quit()` when it goes out of scope, ensuring proper resource cleanup.
##
## ## SDL 1.2 Reference
##
## SDL 1.2 requires explicit initialization of subsystems before use. The main
## subsystems are: timer, audio, video, cdrom, and joystick. Initialization is
## done via bitmask flags.
##
## **Key C functions:**
## ```c
## int SDL_Init(Uint32 flags);
## void SDL_Quit(void);
## int SDL_InitSubSystem(Uint32 flags);
## void SDL_QuitSubSystem(Uint32 flags);
## Uint32 SDL_WasInit(Uint32 flags);
## ```
##
## ## Usage Example
##
## ```nim
## import sdl
##
## runMain:
##   let ctx = sdlInit()  # Initialize all subsystems
##   defer: ctx.quit()
##
##   # Your game code here
##   # SDL_Quit() is called automatically when ctx goes out of scope
## ```
##
## ## Advantages over C SDL 1.2
##
## | C SDL 1.2                              | Nim SDL                          |
## |----------------------------------------|----------------------------------|
## | `SDL_Init(flags); ... SDL_Quit();`     | `let ctx = sdlInit()` RAII       |
## | Manual cleanup on all exit paths       | Automatic cleanup via `defer`    |
## | `Uint32` flags with no type safety     | `InitFlags` distinct type        |
## | Easy to forget `SDL_Quit()`            | Impossible to forget             |
##
## ## See Also
##
## - `sdl/timer` - Timer subsystem functions
## - `sdl/video` - Video subsystem functions
## - `sdl/audio` - Audio subsystem functions

import private/utils
import private/macros

# =========================================================
# 1. SUBSYSTEM FLAGS (Strict Typing)
# =========================================================
type
  InitFlag* {.pure, size: sizeof(uint32).} = enum
    ## Individual SDL subsystem flags for initialization.
    timer       = 0x00000001  ## Timer subsystem
    audio       = 0x00000010  ## Audio subsystem
    video       = 0x00000020  ## Video subsystem
    cdrom       = 0x00000100  ## CD-ROM subsystem
    joystick    = 0x00000200  ## Joystick subsystem
    noParachute = 0x00100000  ## Prevents SDL from catching fatal signals (e.g., SIGSEGV)
    eventThread = 0x01000000  ## Runs events in a separate thread (not all OS support this)

  InitFlags* = distinct uint32
    ## Type-safe combination of initialization flags.
    ## Supports bitmask operators (`and`, `or`).

# Inject bitmask operations for type-safe flag combinations
operatorBitmask(InitFlag, InitFlags)

proc `and`*(x, y: InitFlags): InitFlags {.borrow.}
  ## Computes the bitwise AND between two InitFlags.

proc `==`*(x, y: InitFlags): bool {.borrow.}
  ## Compares two InitFlags for equality.

const initEverything* = InitFlags(0x0000FFFF'u32)
  ## Convenience constant to initialize all standard subsystems.

# =========================================================
# 2. FFI
# =========================================================
{.push header: "SDL.h", importc, cdecl.}

proc SDL_Init(flags: uint32): cint
proc SDL_InitSubSystem(flags: uint32): cint
proc SDL_QuitSubSystem(flags: uint32)
proc SDL_WasInit(flags: uint32): uint32
proc SDL_Quit()

{.pop.}

# =========================================================
# 3. RAII GUARD FOR AUTOMATIC CLEANUP
# =========================================================
type
  Context* {.requiresInit.} = object
    ## RAII wrapper for SDL initialization.
    ## Automatically calls `SDL_Quit()` when it goes out of scope.
    initialized*: bool

proc `=destroy`*(c: var Context) =
  ## Calls `SDL_Quit()` to release resources when Context goes out of scope.
  if c.initialized:
    SDL_Quit()
    c.initialized = false

proc quit*(c: var Context) =
  ## Explicitly shuts down SDL before the Context goes out of scope.
  ## Useful when you need to clean up resources early.
  if c.initialized:
    SDL_Quit()
    c.initialized = false

# =========================================================
# 4. PUBLIC API
# =========================================================

proc sdlInit*(flags: InitFlags = initEverything): Context {.inline.} =
  ## Initializes SDL and the specified subsystems.
  ## Returns a Context that automatically calls `SDL_Quit()` on scope exit.
  ## Terminates the program on failure.
  ##
  ## ```nim
  ## let ctx = sdlInit()                    # All subsystems
  ## let ctx = sdlInit(video or audio)      # Only video and audio
  ## ```
  discard sdlCheck SDL_Init(uint32(flags))
  result = Context(initialized: true)

proc initSubSystem*(flags: InitFlags): bool {.inline.} =
  ## Initializes additional subsystems after the main `sdlInit()` call.
  ## Returns `true` on success.
  sdlOk SDL_InitSubSystem(uint32(flags))

proc quitSubSystem*(flags: InitFlags) {.inline.} =
  ## Shuts down specific subsystems without terminating SDL entirely.
  SDL_QuitSubSystem(uint32(flags))

proc wasInit*(flags: InitFlags = InitFlags(0)): InitFlags {.inline.} =
  ## Checks which subsystems are currently initialized.
  ## Pass 0 (default) to get a mask of all initialized subsystems.
  InitFlags(SDL_WasInit(uint32(flags)))

proc exit*() {.inline.} =
  ## Shuts down all subsystems and cleans up SDL resources.
  ## Mandatory at program end if not using `Context`.
  SDL_Quit()
