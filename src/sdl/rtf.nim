## # sdl/rtf
##
## Rich Text Format (RTF) document rendering using SDL_rtf
##
## This module provides RTF document rendering capabilities through the SDL_rtf library.
## It can load and render .rtf files with basic formatting (bold, italic, underline, fonts).
##
## ## SDL 1.2 Reference
##
## SDL_rtf extends SDL 1.2 with RTF document rendering. It uses a font engine callback
## system to render formatted text documents.
##
## **Key C functions:**
## ```c
## RTF_Context *RTF_CreateContext(RTF_FontEngine *fontEngine);
## int RTF_Load(RTF_Context *context, const char *file);
## void RTF_Render(RTF_Context *context, SDL_Rect *rect, int yOffset);
## void RTF_FreeContext(RTF_Context *context);
## ```
##
## ## Usage Example
##
## ```nim
## import sdl
##
## # Note: You need to implement the font engine callbacks
## runMain:
##   let ctx = sdlInit(sdlInitVideo)
##   defer: ctx.quit()
##
##   let screen = setVideoMode(640, 480, 32, sdlSwSurface)
##
##   # Create font engine (you must implement these callbacks)
##   var fontEngine: RtfFontEngine
##   fontEngine.CreateFont = myCreateFont
##   fontEngine.GetLineSpacing = myGetLineSpacing
##   fontEngine.GetCharacterOffsets = myGetCharacterOffsets
##   fontEngine.RenderText = myRenderText
##   fontEngine.FreeFont = myFreeFont
##
##   let rtfCtx = newRtfContext(fontEngine)
##   if rtfCtx.isSome:
##     var doc = rtfCtx.get
##
##     # Load RTF file
##     if doc.load("document.rtf"):
##       # Get document dimensions
##       let height = doc.calcHeight(600)
##
##       # Render document
##       doc.render(screen, (0, 0, 600, height), 0)
##
##       # Get metadata
##       echo "Title: ", doc.title
##       echo "Author: ", doc.author
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
## ## Advantages over C SDL_rtf
##
## | C SDL_rtf                   | Nim SDL                       |
## |-----------------------------|-------------------------------|
## | `RTF_Context *` manual free | `RtfContext` RAII auto-free   |
## | Manual font engine setup    | Structured callback interface |
## | Raw string returns          | Safe `string` conversion      |
## | Error-prone rect pointers   | Tuple rect parameters         |
##
## ## Requirements
##
## Compile with `-d:rtf` flag. Requires SDL_rtf library installed.
##
## **Note:** You must implement the font engine callbacks yourself, as this module
## only provides the RTF rendering layer.
##
## ## See Also
##
## - `sdl/ttf` - TrueType font rendering
## - `sdl/video` - Surface management

when defined(rtf):
  import std/options
  import rwops
  import video

  const
    RtfMajorVersion* = 0
      ## SDL_rtf major version.

    RtfMinorVersion* = 1
      ## SDL_rtf minor version.

    RtfPatchLevel* = 0
      ## SDL_rtf patch level.

    RtfFontEngineVersion* = 1
      ## Expected version for the font engine structure.

  type
    RtfFontFamily* {.pure, size: sizeof(cint).} = enum
      ## Font family classification for RTF documents.
      default  ## Default system font
      roman    ## Serif / Roman (e.g., Times New Roman)
      swiss    ## Sans-serif (e.g., Arial, Helvetica)
      modern   ## Monospace (e.g., Courier New)
      script   ## Script / cursive
      decor    ## Decorative / display
      tech     ## Technical / symbol
      bidi     ## Bidirectional / special

    RtfFontStyleFlag* {.pure, size: sizeof(cint).} = enum
      ## Individual font style flags for RTF text.
      normal    = 0x00  ## Plain text
      bold      = 0x01  ## Bold text
      italic    = 0x02  ## Italic text
      underline = 0x04  ## Underlined text

    RtfFontStyles* = set[RtfFontStyleFlag]
      ## Set of combined font style flags.

    RtfCreateFontCb* = proc(name: cstring, family: RtfFontFamily, size: cint, style: cint): pointer {.cdecl.}
      ## Callback to create a font from a name, family, size, and style.

    RtfGetLineSpacingCb* = proc(font: pointer): cint {.cdecl.}
      ## Callback to get the line spacing for a font.

    RtfGetCharacterOffsetsCb* = proc(font: pointer, text: cstring, byteOffsets: ptr cint, pixelOffsets: ptr cint, maxOffsets: cint): cint {.cdecl.}
      ## Callback to get character offset arrays for a text string.

    RtfRenderTextCb* = proc(font: pointer, text: cstring, fg: Color): RawSurfacePtr {.cdecl.}
      ## Callback to render a text string into a surface.

    RtfFreeFontCb* = proc(font: pointer) {.cdecl.}
      ## Callback to free a previously created font.

    RtfFontEngine* {.importc: "RTF_FontEngine", header: "SDL_rtf.h".} = object
      ## Font engine callback table for RTF rendering. Implement all callbacks to use RTF.
      version*: cint
      CreateFont*: RtfCreateFontCb
      GetLineSpacing*: RtfGetLineSpacingCb
      GetCharacterOffsets*: RtfGetCharacterOffsetsCb
      RenderText*: RtfRenderTextCb
      FreeFont*: RtfFreeFontCb

    RawRtfContextPtr = pointer

    RtfContext* = object
      ## RAII wrapper for an RTF document context. Automatically freed on scope exit.
      raw*: RawRtfContextPtr

  proc `=copy`*(dest: var RtfContext, source: RtfContext) {.error: "Do not copy RtfContext. Use move()!".}
    ## Copying is disabled to prevent double-free. Use move() instead.

  proc RTF_FreeContext(ctx: RawRtfContextPtr) {.importc, header: "SDL_rtf.h", cdecl.}

  proc `=destroy`*(ctx: var RtfContext) =
    ## Frees the RTF context automatically when RtfContext goes out of scope.
    if ctx.raw != nil:
      RTF_FreeContext(ctx.raw)
      ctx.raw = nil

  {.push header: "SDL_rtf.h", cdecl.}

  proc RTF_CreateContext(fontEngine: ptr RtfFontEngine): RawRtfContextPtr {.importc.}
  proc RTF_Load(ctx: RawRtfContextPtr, file: cstring): cint {.importc.}
  proc RTF_Load_RW(ctx: RawRtfContextPtr, src: RawRWopsPtr, freesrc: cint): cint {.importc.}
  proc RTF_GetTitle(ctx: RawRtfContextPtr): cstring {.importc.}
  proc RTF_GetSubject(ctx: RawRtfContextPtr): cstring {.importc.}
  proc RTF_GetAuthor(ctx: RawRtfContextPtr): cstring {.importc.}
  proc RTF_GetHeight(ctx: RawRtfContextPtr, width: cint): cint {.importc.}
  proc RTF_Render(ctx: RawRtfContextPtr, surface: RawSurfacePtr, rect: ptr Rect, yOffset: cint) {.importc.}
  proc RTF_GetError(): cstring {.importc.}

  {.pop.}

  proc getRtfError*(): string {.inline.} =
    ## Returns the last SDL_rtf error message as a Nim string.
    $RTF_GetError()

  proc newRtfContext*(engine: var RtfFontEngine): Option[RtfContext] {.inline.} =
    ## Creates a new RTF document context with the given font engine callbacks.
    ## Returns `some(RtfContext)` on success, `none` on failure.
    ##
    ## **Example:**
    ## ```nim
    ## var fontEngine: RtfFontEngine
    ## fontEngine.CreateFont = myCreateFont
    ## # ... set up other callbacks ...
    ## let rtfCtx = newRtfContext(fontEngine)
    ## ```
    engine.version = cint(RtfFontEngineVersion)
    let raw = RTF_CreateContext(addr engine)
    if raw.isNil: none(RtfContext) else: some(RtfContext(raw: raw))

  proc load*(ctx: var RtfContext, file: string): bool {.inline, discardable.} =
    ## Loads an RTF document from a file.
    ##
    ## **Example:**
    ## ```nim
    ## if doc.load("document.rtf"):
    ##   echo "Document loaded successfully"
    ## ```
    RTF_Load(ctx.raw, file.cstring) == 0

  proc load*(ctx: var RtfContext, stream: var RWops): bool {.inline, discardable.} =
    ## Loads an RTF document from an RWops stream.
    ##
    ## **Example:**
    ## ```nim
    ## var stream = openFile("document.rtf", "rb").get
    ## if doc.load(stream):
    ##   echo "Loaded from stream"
    ## ```
    assert not stream.unsafeRaw().isNil
    RTF_Load_RW(ctx.raw, stream.unsafeRaw(), 0) == 0

  template safeString(cstr: cstring): string =
    if cstr.isNil: "" else: $cstr

  proc title*(ctx: var RtfContext): string {.inline.} =
    ## Returns the document title from RTF metadata.
    safeString(RTF_GetTitle(ctx.raw))

  proc subject*(ctx: var RtfContext): string {.inline.} =
    ## Returns the document subject from RTF metadata.
    safeString(RTF_GetSubject(ctx.raw))

  proc author*(ctx: var RtfContext): string {.inline.} =
    ## Returns the document author from RTF metadata.
    safeString(RTF_GetAuthor(ctx.raw))

  proc calcHeight*(ctx: var RtfContext, width: int): int {.inline.} =
    ## Calculates the rendering height needed for the document at the given width.
    int(RTF_GetHeight(ctx.raw, cint(width)))

  proc render*(ctx: var RtfContext, dest: var Surface, rect: tuple[x, y, w, h: int], yOffset: int = 0) {.inline.} =
    ## Renders the RTF document to a surface.
    ##
    ## **Example:**
    ## ```nim
    ## let height = doc.calcHeight(600)
    ## doc.render(screen, (0, 0, 600, height), 0)
    ## ```
    var cRect = Rect(x: int16(rect.x), y: int16(rect.y), width: uint16(rect.w), height: uint16(rect.h))
    RTF_Render(ctx.raw, dest.unsafeRaw, addr cRect, cint(yOffset))
