## # sdl/image
##
## Image loading and format detection
##
## This module provides image loading capabilities for various formats using the
## SDL_image library. It supports BMP, PNG, JPG, GIF, TIFF, WebP, and many other
## formats. All loading functions return `Option[Surface]` for safe error handling.
##
## ## SDL 1.2 Reference
##
## SDL_image extends SDL 1.2 with support for multiple image formats beyond the
## built-in BMP loader. It provides both universal loaders (auto-detect format)
## and format-specific loaders for precise control.
##
## **Key C functions:**
## ```c
## int IMG_Init(int flags);
## SDL_Surface *IMG_Load(const char *file);
## SDL_Surface *IMG_Load_RW(SDL_RWops *src, int freesrc);
## int IMG_isPNG(SDL_RWops *src);
## ```
##
## ## Usage Example
##
## ```nim
## import sdl
##
## # Compile with: nim c -d:image game.nim
##
## runMain:
##   let ctx = sdlInit(sdlInitVideo)
##   defer: ctx.quit()
##
##   initImage({imgPng, imgJpg})  # Initialize PNG and JPG support
##   defer: quitImage()
##
##   let screen = setVideoMode(640, 480, 32, sdlHwSurface)
##
##   # Load an image
##   let sprite = loadImage("player.png")
##   if sprite.isSome:
##     let img = sprite.get
##     # Draw sprite to screen
##     screen.blit(img, rect(0, 0, 0, 0), rect(100, 100, 0, 0))
##     screen.flip()
## ```
##
## ## Advantages over C SDL 1.2
##
## | C SDL 1.2                              | Nim SDL                          |
## |----------------------------------------|----------------------------------|
## | `IMG_Load()` returns nullable ptr      | `loadImage()` returns `Option`   |
## | `SDL_Surface*` manual free             | `Surface` RAII auto-free         |
## | `IMG_isPNG(src) != 0` boolean check    | `isPng(src)` returns `bool`      |
## | Bitmask flags as int                   | `set[ImgInitFlag]` type-safe     |
## | No format detection helpers            | `isPng()`, `isJpg()`, etc.       |
##
## ## Supported Formats
##
## - **BMP**: Built-in SDL support
## - **PNG**: Requires libpng
## - **JPG/JPEG**: Requires libjpeg
## - **GIF**: Built-in support
## - **TIFF**: Requires libtiff
## - **WebP**: Requires libwebp
## - **ICO, CUR, PCX, TGA, PNM, XCF, XPM, XV, LBM**: Various support
##
## ## Requirements
##
## This module requires the SDL_image library and compilation with `-d:image` flag.
##
## ## See Also
##
## - `sdl/video` - Surface type and rendering functions
## - `sdl/rwops` - Custom data streams for loading

when defined(image):
  import std/options
  import private/macros
  import version
  import rwops
  import video

  # =========================================================
  # 1. CONSTANTS AND VERSION
  # =========================================================

  type
    ImgInitFlag* {.size: sizeof(cint).} = enum
      ## Image format initialization flags.
      imgJPG  = 0x00000001  ## Initialize JPEG support
      imgPNG  = 0x00000002  ## Initialize PNG support
      imgTIF  = 0x00000004  ## Initialize TIFF support
      imgWEBP = 0x00000008  ## Initialize WebP support

    ImgInitFlags* = set[ImgInitFlag]
      ## Set of image format flags for initialization.

  # =========================================================
  # 2. PRIVATE BINDINGS (FFI)
  # =========================================================

  {.push header: "SDL_image.h", importc, used, cdecl.}

  # Core
  proc IMG_Linked_Version(): ptr Version
  proc IMG_Init(flags: cint): cint
  proc IMG_Quit()

  # General Loaders
  proc IMG_Load(file: cstring): RawSurfacePtr
  proc IMG_Load_RW(src: RawRWopsPtr, freesrc: cint): RawSurfacePtr
  proc IMG_LoadTyped_RW(src: RawRWopsPtr, freesrc: cint, format: cstring): RawSurfacePtr

  # Format Detectors (isX)
  proc IMG_isICO(src: RawRWopsPtr): cint
  proc IMG_isCUR(src: RawRWopsPtr): cint
  proc IMG_isBMP(src: RawRWopsPtr): cint
  proc IMG_isGIF(src: RawRWopsPtr): cint
  proc IMG_isJPG(src: RawRWopsPtr): cint
  proc IMG_isLBM(src: RawRWopsPtr): cint
  proc IMG_isPCX(src: RawRWopsPtr): cint
  proc IMG_isPNG(src: RawRWopsPtr): cint
  proc IMG_isPNM(src: RawRWopsPtr): cint
  proc IMG_isTIF(src: RawRWopsPtr): cint
  proc IMG_isXCF(src: RawRWopsPtr): cint
  proc IMG_isXPM(src: RawRWopsPtr): cint
  proc IMG_isXV(src: RawRWopsPtr): cint
  proc IMG_isWEBP(src: RawRWopsPtr): cint

  # Specific Loaders
  proc IMG_LoadICO_RW(src: RawRWopsPtr): RawSurfacePtr
  proc IMG_LoadCUR_RW(src: RawRWopsPtr): RawSurfacePtr
  proc IMG_LoadBMP_RW(src: RawRWopsPtr): RawSurfacePtr
  proc IMG_LoadGIF_RW(src: RawRWopsPtr): RawSurfacePtr
  proc IMG_LoadJPG_RW(src: RawRWopsPtr): RawSurfacePtr
  proc IMG_LoadLBM_RW(src: RawRWopsPtr): RawSurfacePtr
  proc IMG_LoadPCX_RW(src: RawRWopsPtr): RawSurfacePtr
  proc IMG_LoadPNG_RW(src: RawRWopsPtr): RawSurfacePtr
  proc IMG_LoadPNM_RW(src: RawRWopsPtr): RawSurfacePtr
  proc IMG_LoadTGA_RW(src: RawRWopsPtr): RawSurfacePtr
  proc IMG_LoadTIF_RW(src: RawRWopsPtr): RawSurfacePtr
  proc IMG_LoadXCF_RW(src: RawRWopsPtr): RawSurfacePtr
  proc IMG_LoadXPM_RW(src: RawRWopsPtr): RawSurfacePtr
  proc IMG_LoadXV_RW(src: RawRWopsPtr): RawSurfacePtr
  proc IMG_LoadWEBP_RW(src: RawRWopsPtr): RawSurfacePtr

  # Array Data
  proc IMG_ReadXPMFromArray(xpm: ptr cstring): RawSurfacePtr

  # Misc
  proc IMG_InvertAlpha(): cint

  {.pop.}

  # =========================================================
  # 3. PUBLIC API (Pure Nim)
  # =========================================================

  # --- Universal Loading System ---
  proc initImage*(flags: ImgInitFlags) {.inline.} =
    ## Initializes SDL_image with support for the specified formats.
    ## Call this before loading images.
    ##
    ## ```nim
    ## initImage({imgPng, imgJpg})  # Support PNG and JPG
    ## initImage({})                 # No special initialization
    ## ```
    discard sdlCheckZero IMG_Init(cast[cint](flags))

  proc quitImage*() {.inline.} =
    ## Cleans up SDL_image resources. Call at program end.
    IMG_Quit()

  proc imageLinkedVersion*(): Option[Version] {.inline.} =
    ## Returns the runtime version of the linked SDL_image library.
    ## Returns `none` if the version cannot be determined.
    let p = IMG_Linked_Version()
    if p.isNil: none(Version) else: some(p[])

  proc invertAlpha*(): bool {.inline.} =
    ## Returns `true` if alpha inversion is enabled in SDL_image.
    ## SDL_image inverts alpha values for some formats by default.
    IMG_InvertAlpha() != 0

  proc loadImage*(file: string): Option[Surface] {.inline.} =
    ## Loads an image from a file path. Auto-detects format.
    ## Returns `none` on failure.
    ##
    ## ```nim
    ## let sprite = loadImage("player.png")
    ## if sprite.isSome:
    ##   let img = sprite.get
    ## ```
    let raw = IMG_Load(file.cstring)
    if raw.isNil: none(Surface)
    else: some(assumeRaw[Surface](raw))

  proc loadImage*(stream: var RWops): Option[Surface] {.inline.} =
    ## Loads an image from a RWops stream. Auto-detects format.
    ## Returns `none` on failure.
    let raw = IMG_Load_RW(stream.unsafeRaw(), 0)
    if raw.isNil: none(Surface)
    else: some(assumeRaw[Surface](raw))

  proc loadImageTyped*(stream: var RWops, format: string): Option[Surface] {.inline.} =
    ## Loads an image from a RWops stream with explicit format hint.
    ## Useful when format cannot be auto-detected.
    ##
    ## ```nim
    ## let img = loadImageTyped(stream, "PNG")
    ## ```
    let raw = IMG_LoadTyped_RW(stream.unsafeRaw(), 0, format.cstring)
    if raw.isNil: none(Surface)
    else: some(assumeRaw[Surface](raw))

  template checkFormat(fn: untyped, s: var RWops): bool =
    fn(s.unsafeRaw()) != 0

  proc isIco*(s: var RWops): bool {.inline.} =
    ## Returns `true` if the stream contains an ICO image.
    checkFormat(IMG_isICO, s)
  proc isCur*(s: var RWops): bool {.inline.} =
    ## Returns `true` if the stream contains a CUR (cursor) image.
    checkFormat(IMG_isCUR, s)
  proc isBmp*(s: var RWops): bool {.inline.} =
    ## Returns `true` if the stream contains a BMP image.
    checkFormat(IMG_isBMP, s)
  proc isGif*(s: var RWops): bool {.inline.} =
    ## Returns `true` if the stream contains a GIF image.
    checkFormat(IMG_isGIF, s)
  proc isJpg*(s: var RWops): bool {.inline.} =
    ## Returns `true` if the stream contains a JPG image.
    checkFormat(IMG_isJPG, s)
  proc isLbm*(s: var RWops): bool {.inline.} =
    ## Returns `true` if the stream contains an LBM image.
    checkFormat(IMG_isLBM, s)
  proc isPcx*(s: var RWops): bool {.inline.} =
    ## Returns `true` if the stream contains a PCX image.
    checkFormat(IMG_isPCX, s)
  proc isPng*(s: var RWops): bool {.inline.} =
    ## Returns `true` if the stream contains a PNG image.
    checkFormat(IMG_isPNG, s)
  proc isPnm*(s: var RWops): bool {.inline.} =
    ## Returns `true` if the stream contains a PNM image.
    checkFormat(IMG_isPNM, s)
  proc isTif*(s: var RWops): bool {.inline.} =
    ## Returns `true` if the stream contains a TIFF image.
    checkFormat(IMG_isTIF, s)
  proc isXcf*(s: var RWops): bool {.inline.} =
    ## Returns `true` if the stream contains an XCF (GIMP) image.
    checkFormat(IMG_isXCF, s)
  proc isXpm*(s: var RWops): bool {.inline.} =
    ## Returns `true` if the stream contains an XPM image.
    checkFormat(IMG_isXPM, s)
  proc isXv*(s: var RWops): bool {.inline.} =
    ## Returns `true` if the stream contains an XV image.
    checkFormat(IMG_isXV, s)
  proc isWebp*(s: var RWops): bool {.inline.} =
    ## Returns `true` if the stream contains a WebP image.
    checkFormat(IMG_isWEBP, s)

  template loadSpecific(fn: untyped, s: var RWops): Option[Surface] =
    let raw = fn(s.unsafeRaw())
    if raw.isNil: none(Surface)
    else: some(assumeRaw[Surface](raw))

  proc loadIco*(s: var RWops): Option[Surface] {.inline.} =
    ## Loads an ICO image from stream.
    loadSpecific(IMG_LoadICO_RW, s)
  proc loadCur*(s: var RWops): Option[Surface] {.inline.} =
    ## Loads a CUR (cursor) image from stream.
    loadSpecific(IMG_LoadCUR_RW, s)
  proc loadBmp*(s: var RWops): Option[Surface] {.inline.} =
    ## Loads a BMP image from stream.
    loadSpecific(IMG_LoadBMP_RW, s)
  proc loadGif*(s: var RWops): Option[Surface] {.inline.} =
    ## Loads a GIF image from stream.
    loadSpecific(IMG_LoadGIF_RW, s)
  proc loadJpg*(s: var RWops): Option[Surface] {.inline.} =
    ## Loads a JPG image from stream.
    loadSpecific(IMG_LoadJPG_RW, s)
  proc loadLbm*(s: var RWops): Option[Surface] {.inline.} =
    ## Loads an LBM image from stream.
    loadSpecific(IMG_LoadLBM_RW, s)
  proc loadPcx*(s: var RWops): Option[Surface] {.inline.} =
    ## Loads a PCX image from stream.
    loadSpecific(IMG_LoadPCX_RW, s)
  proc loadPng*(s: var RWops): Option[Surface] {.inline.} =
    ## Loads a PNG image from stream.
    loadSpecific(IMG_LoadPNG_RW, s)
  proc loadPnm*(s: var RWops): Option[Surface] {.inline.} =
    ## Loads a PNM image from stream.
    loadSpecific(IMG_LoadPNM_RW, s)
  proc loadTga*(s: var RWops): Option[Surface] {.inline.} =
    ## Loads a TGA image from stream.
    loadSpecific(IMG_LoadTGA_RW, s)
  proc loadTif*(s: var RWops): Option[Surface] {.inline.} =
    ## Loads a TIFF image from stream.
    loadSpecific(IMG_LoadTIF_RW, s)
  proc loadXcf*(s: var RWops): Option[Surface] {.inline.} =
    ## Loads an XCF (GIMP) image from stream.
    loadSpecific(IMG_LoadXCF_RW, s)
  proc loadXpm*(s: var RWops): Option[Surface] {.inline.} =
    ## Loads an XPM image from stream.
    loadSpecific(IMG_LoadXPM_RW, s)
  proc loadXv*(s: var RWops): Option[Surface] {.inline.} =
    ## Loads an XV image from stream.
    loadSpecific(IMG_LoadXV_RW, s)
  proc loadWebp*(s: var RWops): Option[Surface] {.inline.} =
    ## Loads a WebP image from stream.
    loadSpecific(IMG_LoadWEBP_RW, s)

  proc loadXpm*(data: openArray[string]): Option[Surface] {.inline.} =
    ## Loads an XPM image from an array of strings.
    ## Returns `none` if data is empty or loading fails.
    if data.len == 0: return none(Surface)
    let raw = IMG_ReadXPMFromArray(cast[ptr cstring](data[0].unsafeAddr))
    if raw.isNil: none(Surface)
    else: some(assumeRaw[Surface](raw))
