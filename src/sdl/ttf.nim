## # sdl/ttf
##
## TrueType font rendering using SDL_ttf
##
## This module provides high-quality text rendering using TrueType fonts through the SDL_ttf library.
## It supports multiple rendering modes, font styles, and Unicode text.
##
## ## SDL 1.2 Reference
##
## SDL_ttf extends SDL 1.2 with TrueType font rendering. It uses FreeType to render text
## with anti-aliasing and supports multiple font sizes and styles.
##
## **Key C functions:**
## ```c
## int TTF_Init(void);
## TTF_Font *TTF_OpenFont(const char *file, int ptsize);
## SDL_Surface *TTF_RenderUTF8_Blended(TTF_Font *font, const char *text, SDL_Color fg);
## void TTF_CloseFont(TTF_Font *font);
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
##   initTtf()
##   defer: quitTtf()
##
##   let screen = setVideoMode(640, 480, 32, sdlSwSurface)
##
##   # Load a font
##   let font = loadFont("arial.ttf", 24)
##   if font.isSome:
##     var f = font.get
##
##     # Set font style
##     f.style = {fontBold, fontItalic}
##
##     # Render text
##     let text = f.renderBlended("Hello, SDL!", (255, 255, 255))
##     if text.isSome:
##       var textSurface = text.get
##
##       # Draw to screen
##       discard textSurface.blit(screen, 100, 100)
##
##       # Get text size
##       let (w, h) = f.calcSize("Test")
##       echo "Text size: ", w, "x", h
##
##   var running = true
##   while running:
##     for event in pollEvents():
##       if event.kind == quit:
##         running = false
##
##     screen.flip()
## ```
##
## ## Advantages over C SDL_ttf
##
## | C SDL_ttf                     | Nim SDL                        |
## |-------------------------------|--------------------------------|
## | `TTF_Font *font` manual close | `Font` RAII auto-close         |
## | `SDL_Surface *` manual free   | `Surface` RAII auto-free       |
## | Manual color struct creation  | Tuple syntax: `(r, g, b)`      |
## | Integer return codes          | `Option[T]` for error handling |
##
## ## Rendering Modes
##
## - **Solid**: Fast, 1-bit color (no anti-aliasing)
## - **Shaded**: Medium quality, 2 colors with background
## - **Blended**: High quality, anti-aliased with alpha blending (recommended)
##
## ## Requirements
##
## Compile with `-d:ttf` flag. Requires SDL_ttf library installed.
##
## ## See Also
##
## - `sdl/image` - Image loading
## - `sdl/video` - Surface management

when defined(ttf):
  import std/options
  import private/macros
  import version
  import rwops
  import video

  # =========================================================
  # 1. SAFE TYPES AND RAII
  # =========================================================

  type
    RawFontPtr* = pointer
      ## Raw pointer to the underlying C TTF_Font.

    Font* = object
      ## RAII wrapper for a TrueType font. Closes the font on scope exit.
      raw*: RawFontPtr

    SdlColor {.importc: "SDL_Color", header: "SDL.h".} = object
      r*, g*, b*, unused*: uint8

    Color* = tuple[r, g, b: int]
      ## An RGB color for text rendering.

  proc `=copy`*(dest: var Font, source: Font) {.error: "Font cannot be copied! Use move() instead".}

  proc TTF_CloseFont(font: RawFontPtr) {.importc, header: "SDL_ttf.h", cdecl.}

  proc `=destroy`*(f: var Font) =
    if f.raw != nil:
      TTF_CloseFont(f.raw)
      f.raw = nil

  type
    FontStyleFlag* {.size: sizeof(cint).} = enum
      ## Font style flags for bold, italic, underline, and strikethrough.
      fontNormal        = 0x00
      fontBold          = 0x01
      fontItalic        = 0x02
      fontUnderline     = 0x04
      fontStrikethrough = 0x08

    FontStyles* = set[FontStyleFlag]
      ## A set of font style flags.

    FontHinting* {.size: sizeof(cint).} = enum
      ## Font hinting mode for controlling glyph rendering quality.
      hintNormal = 0
      hintLight  = 1
      hintMono   = 2
      hintNone   = 3

  {.push header: "SDL_ttf.h", cdecl.}

  proc TTF_Linked_Version(): ptr Version {.importc.}
  proc TTF_Init(): cint {.importc.}
  proc TTF_WasInit(): cint {.importc.}
  proc TTF_Quit() {.importc.}

  proc TTF_ByteSwappedUNICODE(swapped: cint) {.importc.}
  proc TTF_OpenFont(file: cstring, ptsize: cint): RawFontPtr {.importc.}
  proc TTF_OpenFontRW(src: RawRWopsPtr, freesrc: cint, ptsize: cint): RawFontPtr {.importc.}

  proc TTF_GetFontStyle(font: RawFontPtr): cint {.importc.}
  proc TTF_SetFontStyle(font: RawFontPtr, style: cint) {.importc.}
  proc TTF_GetFontOutline(font: RawFontPtr): cint {.importc.}
  proc TTF_SetFontOutline(font: RawFontPtr, outline: cint) {.importc.}
  proc TTF_GetFontHinting(font: RawFontPtr): cint {.importc.}
  proc TTF_SetFontHinting(font: RawFontPtr, hinting: cint) {.importc.}

  proc TTF_FontHeight(font: RawFontPtr): cint {.importc.}
  proc TTF_FontAscent(font: RawFontPtr): cint {.importc.}
  proc TTF_FontDescent(font: RawFontPtr): cint {.importc.}
  proc TTF_FontLineSkip(font: RawFontPtr): cint {.importc.}
  proc TTF_FontFaces(font: RawFontPtr): cint {.importc.}
  proc TTF_SizeUTF8(font: RawFontPtr, text: cstring, w: ptr cint, h: ptr cint): cint {.importc.}

  proc TTF_RenderUTF8_Solid(font: RawFontPtr, text: cstring, fg: SdlColor): RawSurfacePtr {.importc.}
  proc TTF_RenderUTF8_Shaded(font: RawFontPtr, text: cstring, fg: SdlColor, bg: SdlColor): RawSurfacePtr {.importc.}
  proc TTF_RenderUTF8_Blended(font: RawFontPtr, text: cstring, fg: SdlColor): RawSurfacePtr {.importc.}

  proc TTF_RenderText_Solid(font: RawFontPtr, text: cstring, fg: SdlColor): RawSurfacePtr {.importc.}
  proc TTF_RenderText_Shaded(font: RawFontPtr, text: cstring, fg: SdlColor, bg: SdlColor): RawSurfacePtr {.importc.}
  proc TTF_RenderText_Blended(font: RawFontPtr, text: cstring, fg: SdlColor): RawSurfacePtr {.importc.}

  proc TTF_RenderUNICODE_Solid(font: RawFontPtr, text: ptr uint16, fg: SdlColor): RawSurfacePtr {.importc.}
  proc TTF_RenderUNICODE_Shaded(font: RawFontPtr, text: ptr uint16, fg: SdlColor, bg: SdlColor): RawSurfacePtr {.importc.}
  proc TTF_RenderUNICODE_Blended(font: RawFontPtr, text: ptr uint16, fg: SdlColor): RawSurfacePtr {.importc.}

  proc TTF_RenderGlyph_Solid(font: RawFontPtr, ch: uint16, fg: SdlColor): RawSurfacePtr {.importc.}
  proc TTF_RenderGlyph_Shaded(font: RawFontPtr, ch: uint16, fg: SdlColor, bg: SdlColor): RawSurfacePtr {.importc.}
  proc TTF_RenderGlyph_Blended(font: RawFontPtr, ch: uint16, fg: SdlColor): RawSurfacePtr {.importc.}

  {.pop.}

  template toSdl(c: Color): SdlColor = SdlColor(r: uint8(c.r), g: uint8(c.g), b: uint8(c.b), unused: 0)

  proc initTtf*() {.inline.} =
    ## Initializes the SDL_ttf library. Must be called before using fonts.
    discard sdlCheck TTF_Init()

  proc quitTtf*() {.inline.} =
    ## Shuts down the SDL_ttf library.
    TTF_Quit()

  proc ttfLinkedVersion*(): Option[Version] {.inline.} =
    ## Returns the runtime version of the linked SDL_ttf library.
    let p = TTF_Linked_Version()
    if p.isNil: none(Version) else: some(p[])

  proc ttfWasInit*(): bool {.inline.} =
    ## Returns `true` if the SDL_ttf library has been initialized.
    TTF_WasInit() != 0

  proc byteSwappedUnicode*(swapped: bool) {.inline.} =
    ## Controls UNICODE byte swapping. Enable when reading big-endian UCS-2 data.
    TTF_ByteSwappedUNICODE(cint(swapped))

  proc fontFaces*(font: Font): int {.inline.} =
    ## Returns the number of available font faces in the font file.
    int(TTF_FontFaces(font.raw))

  proc loadFont*(file: string, size: int): Option[Font] {.inline.} =
    ## Loads a TrueType font from a file.
    ##
    ## **Example:**
    ## ```nim
    ## let font = loadFont("arial.ttf", 24)
    ## if font.isSome:
    ##   var f = font.get
    ##   echo "Font loaded: height=", f.height
    ## ```
    let raw = TTF_OpenFont(file.cstring, cint(size))
    if raw.isNil: none(Font) else: some(Font(raw: raw))

  proc loadFont*(stream: var RWops, size: int): Option[Font] {.inline.} =
    ## Loads a TrueType font from an RWops stream.
    assert not stream.unsafeRaw().isNil
    let raw = TTF_OpenFontRW(stream.unsafeRaw(), 0, cint(size))
    if raw.isNil: none(Font) else: some(Font(raw: raw))

  proc `style=`*(font: var Font, style: FontStyles) {.inline.} =
    ## Sets the font style (bold, italic, underline, strikethrough).
    TTF_SetFontStyle(font.raw, cast[cint](style))

  proc style*(font: Font): FontStyles {.inline.} =
    ## Returns the current font style flags.
    cast[FontStyles](TTF_GetFontStyle(font.raw))

  proc `outline=`*(font: var Font, outline: int) {.inline.} =
    ## Sets the font outline width in pixels.
    TTF_SetFontOutline(font.raw, cint(outline))

  proc outline*(font: Font): int {.inline.} =
    ## Returns the current font outline width in pixels.
    int(TTF_GetFontOutline(font.raw))

  proc `hinting=`*(font: var Font, hint: FontHinting) {.inline.} =
    ## Sets the font hinting mode.
    TTF_SetFontHinting(font.raw, cast[cint](hint))

  proc hinting*(font: Font): FontHinting {.inline.} =
    ## Returns the current font hinting mode.
    cast[FontHinting](TTF_GetFontHinting(font.raw))

  proc height*(font: Font): int {.inline.} =
    ## Returns the font height in pixels.
    int(TTF_FontHeight(font.raw))

  proc ascent*(font: Font): int {.inline.} =
    ## Returns the font ascent (distance from baseline to top) in pixels.
    int(TTF_FontAscent(font.raw))

  proc descent*(font: Font): int {.inline.} =
    ## Returns the font descent (distance from baseline to bottom) in pixels.
    int(TTF_FontDescent(font.raw))

  proc lineSkip*(font: Font): int {.inline.} =
    ## Returns the recommended line spacing in pixels.
    int(TTF_FontLineSkip(font.raw))

  proc calcSize*(font: Font, text: string): tuple[width, height: int] {.inline.} =
    ## Calculates the rendered dimensions of a text string without rendering it.
    var w, h: cint
    discard TTF_SizeUTF8(font.raw, text.cstring, addr w, addr h)
    (int(w), int(h))

  proc renderSolid*(font: Font, text: string, color: Color): Option[Surface] {.inline.} =
    ## Renders text in solid mode (fast, no anti-aliasing, 1-bit color).
    let raw = TTF_RenderUTF8_Solid(font.raw, text.cstring, color.toSdl)
    if raw.isNil: none(Surface)
    else: some(assumeRaw[Surface](raw))

  proc renderShaded*(font: Font, text: string, fgColor, bgColor: Color): Option[Surface] {.inline.} =
    ## Renders text in shaded mode (medium quality, 2 colors with background).
    let raw = TTF_RenderUTF8_Shaded(font.raw, text.cstring, fgColor.toSdl, bgColor.toSdl)
    if raw.isNil: none(Surface)
    else: some(assumeRaw[Surface](raw))

  proc renderBlended*(font: Font, text: string, color: Color): Option[Surface] {.inline.} =
    ## Renders UTF-8 text with high-quality anti-aliasing and alpha blending.
    ##
    ## **Example:**
    ## ```nim
    ## let text = font.renderBlended("Hello!", (255, 255, 255))
    ## if text.isSome:
    ##   discard text.get.blit(screen, 100, 100)
    ## ```
    ##
    ## **Note:** This is the recommended rendering mode for most applications.
    let raw = TTF_RenderUTF8_Blended(font.raw, text.cstring, color.toSdl)
    if raw.isNil: none(Surface)
    else: some(assumeRaw[Surface](raw))

  proc renderTextSolid*(font: Font, text: string, color: Color): Option[Surface] {.inline.} =
    ## Renders Latin-1 text in solid mode (fast, 1-bit color, no anti-aliasing).
    ##
    ## **Note:** For Unicode text, use `renderSolid()` or `renderBlended()` (UTF-8).
    let raw = TTF_RenderText_Solid(font.raw, text.cstring, color.toSdl)
    if raw.isNil: none(Surface)
    else: some(assumeRaw[Surface](raw))

  proc renderTextShaded*(font: Font, text: string, fgColor, bgColor: Color): Option[Surface] {.inline.} =
    ## Renders Latin-1 text in shaded mode (2 colors with background).
    let raw = TTF_RenderText_Shaded(font.raw, text.cstring, fgColor.toSdl, bgColor.toSdl)
    if raw.isNil: none(Surface)
    else: some(assumeRaw[Surface](raw))

  proc renderTextBlended*(font: Font, text: string, color: Color): Option[Surface] {.inline.} =
    ## Renders Latin-1 text with anti-aliased alpha blending.
    let raw = TTF_RenderText_Blended(font.raw, text.cstring, color.toSdl)
    if raw.isNil: none(Surface)
    else: some(assumeRaw[Surface](raw))

  proc renderUnicodeSolid*(font: Font, text: openArray[uint16], color: Color): Option[Surface] {.inline.} =
    ## Renders UCS-2 text in solid mode. The text must be null-terminated.
    let raw = TTF_RenderUNICODE_Solid(font.raw, cast[ptr uint16](unsafeAddr text[0]), color.toSdl)
    if raw.isNil: none(Surface)
    else: some(assumeRaw[Surface](raw))

  proc renderUnicodeShaded*(font: Font, text: openArray[uint16], fgColor, bgColor: Color): Option[Surface] {.inline.} =
    ## Renders UCS-2 text in shaded mode.
    let raw = TTF_RenderUNICODE_Shaded(font.raw, cast[ptr uint16](unsafeAddr text[0]), fgColor.toSdl, bgColor.toSdl)
    if raw.isNil: none(Surface)
    else: some(assumeRaw[Surface](raw))

  proc renderUnicodeBlended*(font: Font, text: openArray[uint16], color: Color): Option[Surface] {.inline.} =
    ## Renders UCS-2 text with anti-aliased alpha blending.
    let raw = TTF_RenderUNICODE_Blended(font.raw, cast[ptr uint16](unsafeAddr text[0]), color.toSdl)
    if raw.isNil: none(Surface)
    else: some(assumeRaw[Surface](raw))

  proc renderGlyphSolid*(font: Font, ch: uint16, color: Color): Option[Surface] {.inline.} =
    ## Renders a single 16-bit glyph in solid mode.
    let raw = TTF_RenderGlyph_Solid(font.raw, ch, color.toSdl)
    if raw.isNil: none(Surface)
    else: some(assumeRaw[Surface](raw))

  proc renderGlyphShaded*(font: Font, ch: uint16, fgColor, bgColor: Color): Option[Surface] {.inline.} =
    ## Renders a single 16-bit glyph in shaded mode.
    let raw = TTF_RenderGlyph_Shaded(font.raw, ch, fgColor.toSdl, bgColor.toSdl)
    if raw.isNil: none(Surface)
    else: some(assumeRaw[Surface](raw))

  proc renderGlyphBlended*(font: Font, ch: uint16, color: Color): Option[Surface] {.inline.} =
    ## Renders a single 16-bit glyph with anti-aliased alpha blending.
    let raw = TTF_RenderGlyph_Blended(font.raw, ch, color.toSdl)
    if raw.isNil: none(Surface)
    else: some(assumeRaw[Surface](raw))
