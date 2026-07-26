## # sdl/dreamcast
##
## Sega Dreamcast platform-specific features
##
## This module provides access to Dreamcast-specific hardware features like
## video driver selection, input mapping, and audio buffer control. All functions
## in this module are only available when compiling with the `-d:dreamcast` flag.
##
## ## SDL 1.2 Reference
##
## The Dreamcast port of SDL 1.2 includes custom functions for hardware-specific
## features that don't exist in the standard SDL API. These include video driver
## selection for the PowerVR2 GPU, button remapping, and direct audio buffer access.
##
## **Key C functions:**
## ```c
## void SDL_DC_SetVideoDriver(SDL_DC_driver driver);
## void SDL_DC_MapKey(int joy, SDL_DC_button button, SDLKey key);
## void SDL_DC_SetSoundBuffer(void *buffer);
## ```
##
## ## Usage Example
##
## ```nim
## import sdl
##
## # Compile with: nim c -d:dreamcast game.nim
##
## when defined(dreamcast):
##   # Configure Dreamcast-specific settings before SDL_Init
##   setVideoDriver(texturedVideo)  # Use PowerVR2 3D acceleration
##   setVerticalWait(true)          # Enable V-Sync
##
##   # Map Dreamcast buttons to keyboard keys
##   mapKey(0, a, K_SPACE)
##   mapKey(0, b, K_LCTRL)
##
## runMain:
##   let ctx = sdlInit()
##   defer: ctx.quit()
##   # Your game code here
## ```
##
## ## Advantages over C SDL 1.2
##
## | C SDL 1.2                              | Nim SDL                          |
## |----------------------------------------|----------------------------------|
## | `SDL_DC_driver` as int                 | `DcDriver` typed enum            |
## | `SDL_DC_button` as int                 | `DcButton` typed enum            |
## | No boolean conversion                  | Native `bool` parameters         |
## | Platform code mixed with portable code | `when defined(dreamcast)` guard  |
##
## ## Hardware Overview
##
## - **GPU**: PowerVR2 (CLX2) with 3D acceleration
## - **Audio**: Yamaha AICA sound chip with ARM7 controller
## - **Input**: Standard gamepad with analog stick, triggers, and 6 buttons

# =========================================================
# PLATFORM GUARD (Zero Overhead)
# =========================================================
# This entire module only exists in the final binary if the user
# compiles with the `-d:dreamcast` flag.
when defined(dreamcast) or defined(nimdoc):
  import keysym

  # =========================================================
  # 1. ENUMS AND CONSTANTS (NEP-1 and 1:1 Mapping)
  # =========================================================
  {.push header: "SDL_dreamcast.h", importc, cdecl.}

  type
    DcDriver* {.importc: "SDL_DC_driver", pure, size: sizeof(cint).} = enum
      ## Video driver options for Dreamcast's PowerVR2 GPU.
      dmaVideo      = 0  ## DMA video mode (fast, no CPU usage)
      texturedVideo = 1  ## 3D acceleration via PowerVR2 (default, recommended)
      directVideo   = 2  ## Direct VRAM write (slow, fallback mode)

    DcButton* {.importc: "SDL_DC_button", pure, size: sizeof(cint).} = enum
      ## Dreamcast controller button identifiers.
      b     = 1   ## B button
      a     = 2   ## A button
      start = 3   ## Start button
      x     = 5   ## X button
      y     = 6   ## Y button
      l     = 7   ## Left trigger
      r     = 8   ## Right trigger
      up    = 9   ## D-pad up
      down  = 10  ## D-pad down
      left  = 11  ## D-pad left
      right = 12  ## D-pad right

  # ---------------------------------------------------------
  # INTERNAL FFI (SDL_bool in C is handled as cint)
  # ---------------------------------------------------------
  proc SDL_DC_SetVideoDriver(value: DcDriver)
  proc SDL_DC_SetWindow(width, height: cint)
  proc SDL_DC_VerticalWait(value: cint)
  proc SDL_DC_ShowAskHz(value: cint)
  proc SDL_DC_Default60Hz(value: cint)

  proc SDL_DC_MapKey(joy: cint, button: DcButton, key: Key)
  proc SDL_DC_EmulateVirtualKeyboard(value: cint)
  proc SDL_DC_EmulateKeyboard(value: cint)
  proc SDL_DC_EmulateMouse(value: cint)

  proc SDL_DC_SetSoundBuffer(buffer: pointer)
  proc SDL_DC_RestoreSoundBuffer()

  {.pop.}

  # =========================================================
  # 2. PUBLIC API
  # =========================================================

  # ---------------------------------------------------------
  # VIDEO AND HARDWARE (PowerVR2)
  # ---------------------------------------------------------

  proc setVideoDriver*(driver: DcDriver) {.inline.} =
    ## Sets the Dreamcast video backend driver.
    ## Must be called BEFORE `sdlInit()`.
    ##
    ## - `dmaVideo`: Fast DMA-based rendering, minimal CPU usage
    ## - `texturedVideo`: 3D acceleration via PowerVR2 (recommended)
    ## - `directVideo`: Slow direct VRAM writes (fallback)
    SDL_DC_SetVideoDriver(driver)

  proc setWindow*(width, height: uint16) {.inline.} =
    ## Sets the internal resolution before upscaling to TV output.
    ## Call this before initializing video.
    SDL_DC_SetWindow(cint(width), cint(height))

  proc setVerticalWait*(wait: bool) {.inline.} =
    ## Enables or disables Dreamcast native V-Sync.
    ## Recommended to enable for smooth, tear-free rendering.
    SDL_DC_VerticalWait(cint(wait))

  proc showAskHz*(show: bool) {.inline.} =
    ## Shows the classic KallistiOS blue menu asking "50Hz or 60Hz?"
    ## at game boot time.
    SDL_DC_ShowAskHz(cint(show))

  proc setDefault60Hz*(default60: bool) {.inline.} =
    ## Forces the game to run at 60Hz (NTSC) without asking the player.
    ## Useful for games that require consistent 60Hz timing.
    SDL_DC_Default60Hz(cint(default60))

  # ---------------------------------------------------------
  # INPUT (PC Emulation Magic)
  # ---------------------------------------------------------

  proc mapKey*(port: uint8, button: DcButton, key: Key) {.inline.} =
    ## Maps a Dreamcast gamepad button to pretend it's a PC keyboard key.
    ## Allows games designed for keyboard input to work with Dreamcast controllers.
    ##
    ## ```nim
    ## mapKey(0, a, K_SPACE)      # A button = Space
    ## mapKey(0, start, K_RETURN) # Start = Enter
    ## ```
    SDL_DC_MapKey(cint(port), button, key)

  proc emulateVirtualKeyboard*(emulate: bool) {.inline.} =
    ## Shows an on-screen virtual keyboard for text input using the controller.
    ## Useful for games that require text entry without a physical keyboard.
    SDL_DC_EmulateVirtualKeyboard(cint(emulate))

  proc emulateKeyboard*(emulate: bool) {.inline.} =
    ## Enables/disables the emulation system that converts gamepad input to keyboard events.
    SDL_DC_EmulateKeyboard(cint(emulate))

  proc emulateMouse*(emulate: bool) {.inline.} =
    ## Allows moving the mouse cursor using the controller's analog stick.
    ## Useful for games that require mouse input.
    SDL_DC_EmulateMouse(cint(emulate))

  # ---------------------------------------------------------
  # AUDIO
  # ---------------------------------------------------------

  proc setSoundBuffer*(buffer: pointer) {.inline.} =
    ## Injects a custom audio buffer directly into the Yamaha AICA sound chip.
    ## Allows bypassing SDL's audio layer for custom audio processing.
    ##
    ## **Warning:** Buffer must not be nil.
    assert buffer != nil, "Audio buffer cannot be null"
    SDL_DC_SetSoundBuffer(buffer)

  proc restoreSoundBuffer*() {.inline.} =
    ## Returns audio control to SDL's default audio handling.
    ## Call this after using a custom sound buffer.
    SDL_DC_RestoreSoundBuffer()
