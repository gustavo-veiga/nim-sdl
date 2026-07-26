## # sdl/pango
##
## Advanced text rendering with Pango markup support
##
## This module provides advanced text rendering using the Pango library through SDL_Pango.
## It supports rich text markup, right-to-left languages, and complex text layouts.
##
## ## SDL 1.2 Reference
##
## SDL_Pango extends SDL 1.2 with Pango text rendering. It supports Pango markup for
## styled text (bold, italic, colors, sizes) and complex international text layouts.
##
## **Key C functions:**
## ```c
## int SDLPango_Init(void);
## SDLPango_Context *SDLPango_CreateContext(void);
## void SDLPango_SetMarkup(SDLPango_Context *context, const char *markup, int length);
## SDL_Surface *SDLPango_CreateSurfaceDraw(SDLPango_Context *context);
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
##   if initPango():
##     defer: quitPango()
##
##     let screen = setVideoMode(640, 480, 32, sdlSwSurface)
##
##     let pangoCtx = newPangoContext()
##     if pangoCtx.isSome:
##       var pc = pangoCtx.get
##
##       # Set text with Pango markup
##       pc.markup = "<b>Bold</b> <i>Italic</i> <span foreground='red'>Red</span>"
##
##       # Set color matrix
##       pc.defaultColor = MatrixWhiteBack
##
##       # Render to surface
##       let textSurface = pc.renderSurface()
##       if textSurface.isSome:
##         discard textSurface.get.blit(screen, 100, 100)
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
## ## Advantages over C SDL_Pango
##
## | C SDL_Pango                      | Nim SDL                          |
## |----------------------------------|----------------------------------|
## | `SDLPango_Context *` manual free | `PangoContext` RAII auto-free    |
## | Manual color matrix setup        | Predefined `MatrixWhiteBack` etc |
## | Raw markup strings               | `markup =` property syntax       |
## | Integer return codes             | `Option[T]` for error handling   |
##
## ## Pango Markup
##
## Pango supports HTML-like markup for styled text:
## - `<b>Bold</b>` - Bold text
## - `<i>Italic</i>` - Italic text
## - `<span foreground='red'>Red</span>` - Colored text
## - `<span size='24000'>Large</span>` - Sized text (in Pango units)
##
## ## Requirements
##
## Compile with `-d:pango` flag. Requires SDL_Pango library installed.
##
## ## See Also
##
## - `sdl/ttf` - TrueType font rendering (simpler alternative)
## - `sdl/video` - Surface management

when defined(pango):
  import std/options
  import video

  type
    PangoDirection* {.pure, size: sizeof(cint).} = enum
      ## Text direction for international text layout.
      ltr     ## Left-to-right
      rtl     ## Right-to-left
      weakLtr ## Weak left-to-right
      weakRtl ## Weak right-to-left
      neutral ## Neutral direction

    PangoMatrix* {.importc: "SDLPango_Matrix", header: "SDL_Pango.h".} = object
      ## Color matrix for Pango text rendering (4x4 RGBA).
      m*: array[4, array[4, uint8]]

  const
    MatrixWhiteBack* = PangoMatrix(m: [
      [255'u8,   0,   0,   0],
      [255'u8,   0,   0,   0],
      [255'u8,   0,   0,   0],
      [255'u8, 255,   0,   0]
    ])
      ## White text on opaque white background.

    MatrixBlackBack* = PangoMatrix(m: [
      [  0'u8, 255,   0,   0],
      [  0'u8, 255,   0,   0],
      [  0'u8, 255,   0,   0],
      [255'u8, 255,   0,   0]
    ])
      ## Black text on opaque black background.

    MatrixTransparentBackBlackLetter* = PangoMatrix(m: [
      [  0'u8,   0,   0,   0],
      [  0'u8,   0,   0,   0],
      [  0'u8,   0,   0,   0],
      [  0'u8, 255,   0,   0]
    ])
      ## Black text on transparent background.

    MatrixTransparentBackWhiteLetter* = PangoMatrix(m: [
      [255'u8, 255,   0,   0],
      [255'u8, 255,   0,   0],
      [255'u8, 255,   0,   0],
      [  0'u8, 255,   0,   0]
    ])
      ## White text on transparent background.

    MatrixTransparentBackTransparentLetter* = PangoMatrix(m: [
      [255'u8, 255,   0,   0],
      [255'u8, 255,   0,   0],
      [255'u8, 255,   0,   0],
      [  0'u8,   0,   0,   0]
    ])
      ## Invisible text on transparent background (utility matrix).

  type
    RawPangoContextPtr = pointer

    PangoContext* = object
      ## RAII wrapper for a Pango rendering context. Automatically frees on scope exit.
      raw*: RawPangoContextPtr

  proc `=copy`*(dest: var PangoContext, source: PangoContext) {.error: "Do not copy Pango Context. Use move()!".}
    ## Copying is disabled to prevent double-free. Use move() instead.

  proc SDLPango_FreeContext(context: RawPangoContextPtr) {.importc, header: "SDL_Pango.h", cdecl.}

  proc `=destroy`*(ctx: var PangoContext) =
    ## Frees the Pango context automatically when PangoContext goes out of scope.
    if ctx.raw != nil:
      SDLPango_FreeContext(ctx.raw)
      ctx.raw = nil

  {.push header: "SDL_Pango.h", cdecl.}

  proc SDLPango_Init(): cint {.importc.}
  proc SDLPango_WasInit(): cint {.importc.}

  proc SDLPango_CreateContext(): RawPangoContextPtr {.importc.}
  proc SDLPango_SetSurfaceCreateArgs(context: RawPangoContextPtr, flags: uint32, depth: cint, Rmask, Gmask, Bmask, Amask: uint32) {.importc.}

  proc SDLPango_SetDpi(context: RawPangoContextPtr, dpi_x: cdouble, dpi_y: cdouble) {.importc.}
  proc SDLPango_SetMinimumSize(context: RawPangoContextPtr, width: cint, height: cint) {.importc.}
  proc SDLPango_SetDefaultColor(context: RawPangoContextPtr, color_matrix: ptr PangoMatrix) {.importc.}
  proc SDLPango_SetMarkup(context: RawPangoContextPtr, markup: cstring, length: cint) {.importc.}
  proc SDLPango_SetText(context: RawPangoContextPtr, markup: cstring, length: cint) {.importc.}
  proc SDLPango_SetLanguage(context: RawPangoContextPtr, language_tag: cstring) {.importc.}
  proc SDLPango_SetBaseDirection(context: RawPangoContextPtr, direction: cint) {.importc.}

  proc SDLPango_GetLayoutWidth(context: RawPangoContextPtr): cint {.importc.}
  proc SDLPango_GetLayoutHeight(context: RawPangoContextPtr): cint {.importc.}

  proc SDLPango_CreateSurfaceDraw(context: RawPangoContextPtr): RawSurfacePtr {.importc.}
  proc SDLPango_Draw(context: RawPangoContextPtr, surface: RawSurfacePtr, x: cint, y: cint) {.importc.}

  proc SDLPango_CopyFTBitmapToSurface(bitmap: pointer, surface: RawSurfacePtr, matrix: ptr PangoMatrix, rect: pointer) {.importc.}
  proc SDLPango_GetPangoFontMap(context: RawPangoContextPtr): pointer {.importc.}
  proc SDLPango_GetPangoFontDescription(context: RawPangoContextPtr): pointer {.importc.}
  proc SDLPango_GetPangoLayout(context: RawPangoContextPtr): pointer {.importc.}

  {.pop.}

  proc initPango*(): bool {.inline.} =
    ## Initializes the SDL_Pango library. Call before creating Pango contexts.
    ## Returns `true` on success.
    SDLPango_Init() != 0

  proc wasInitPango*(): bool {.inline.} =
    ## Checks if SDL_Pango has been initialized.
    SDLPango_WasInit() != 0

  proc newPangoContext*(): Option[PangoContext] {.inline.} =
    ## Creates a new Pango rendering context. Returns `some(PangoContext)` on success.
    let raw = SDLPango_CreateContext()
    if raw.isNil: none(PangoContext) else: some(PangoContext(raw: raw))

  proc setSurfaceArgs*(ctx: var PangoContext, flags: uint32, depth: int, rMask, gMask, bMask, aMask: uint32) {.inline.} =
    ## Sets surface creation parameters for the Pango context (bit depth, masks).
    SDLPango_SetSurfaceCreateArgs(ctx.raw, flags, cint(depth), rMask, gMask, bMask, aMask)

  proc setDpi*(ctx: var PangoContext, dpiX, dpiY: float) {.inline.} =
    ## Sets the DPI for text rendering in the Pango context.
    SDLPango_SetDpi(ctx.raw, cdouble(dpiX), cdouble(dpiY))

  proc `minSize=`*(ctx: var PangoContext, size: tuple[w, h: int]) {.inline.} =
    ## Sets the minimum surface size for the Pango context.
    SDLPango_SetMinimumSize(ctx.raw, cint(size.w), cint(size.h))

  proc `defaultColor=`*(ctx: var PangoContext, colorMatrix: var PangoMatrix) {.inline.} =
    ## Sets the default color matrix for text rendering.
    SDLPango_SetDefaultColor(ctx.raw, addr colorMatrix)

  proc `language=`*(ctx: var PangoContext, langTag: string) {.inline.} =
    ## Sets the language tag for text layout (e.g., "en", "ar", "he").
    SDLPango_SetLanguage(ctx.raw, langTag.cstring)

  proc `direction=`*(ctx: var PangoContext, dir: PangoDirection) {.inline.} =
    ## Sets the base text direction for layout.
    SDLPango_SetBaseDirection(ctx.raw, cast[cint](dir))

  proc `text=`*(ctx: var PangoContext, text: string) {.inline.} =
    ## Sets plain text (no markup) for the Pango context.
    SDLPango_SetText(ctx.raw, text.cstring, cint(text.len))

  proc `markup=`*(ctx: var PangoContext, markupText: string) {.inline.} =
    ## Sets Pango markup text with formatting (bold, italic, colors, etc).
    ##
    ## **Example:**
    ## ```nim
    ## ctx.markup = "<b>Bold</b> <span foreground='red'>Red</span>"
    ## ```
    SDLPango_SetMarkup(ctx.raw, markupText.cstring, cint(markupText.len))

  proc width*(ctx: var PangoContext): int {.inline.} =
    ## Returns the layout width of the rendered text in pixels.
    int(SDLPango_GetLayoutWidth(ctx.raw))

  proc height*(ctx: var PangoContext): int {.inline.} =
    ## Returns the layout height of the rendered text in pixels.
    int(SDLPango_GetLayoutHeight(ctx.raw))

  proc renderSurface*(ctx: var PangoContext): Option[Surface] {.inline.} =
    ## Renders the current text to a new surface.
    ##
    ## **Example:**
    ## ```nim
    ## ctx.markup = "<b>Hello</b> <i>World</i>"
    ## ctx.defaultColor = MatrixWhiteBack
    ## let surface = ctx.renderSurface()
    ## if surface.isSome:
    ##   discard surface.get.blit(screen, 100, 100)
    ## ```
    let rawSurf = SDLPango_CreateSurfaceDraw(ctx.raw)
    if rawSurf.isNil: none(Surface)
    else: some(assumeRaw[Surface](rawSurf))

  proc drawTo*(ctx: var PangoContext, dest: var Surface, x, y: int) {.inline.} =
    ## Draws the rendered Pango text onto a destination surface at the given position.
    ##
    ## **Example:**
    ## ```nim
    ## ctx.drawTo(screen, 100, 100)
    ## ```
    SDLPango_Draw(ctx.raw, unsafeRaw(dest), cint(x), cint(y))
