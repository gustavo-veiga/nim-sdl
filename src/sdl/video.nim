import std/options
import private/utils
import private/macros
import rwops

# =========================================================
# 1. CONSTANTS, ENUMS AND FLAGS
# =========================================================

type
  AlphaState* {.pure, size: sizeof(uint8).} = enum
    ## Alpha transparency state for surfaces.
    transparent = 0'u8
    opaque      = 255'u8

  RefreshRate* {.pure, size: sizeof(cint).} = enum
    ## Display refresh rate presets.
    defaultRate = 0 # 'default' is a Nim reserved word, we use 'defaultRate'

# ---------------------------------------------------------
# SURFACE FLAGS AND BITMASKS
# ---------------------------------------------------------
type
  SurfaceFlag* {.pure, size: sizeof(uint32).} = enum
    ## Flags for surface creation and display behavior.
    swSurface   = 0x00000000'u32
    hwSurface   = 0x00000001'u32
    openGl      = 0x00000002'u32
    asyncBlit   = 0x00000004'u32
    openGlBlit  = 0x0000000A'u32
    resizable   = 0x00000010'u32
    noFrame     = 0x00000020'u32
    hwAccel     = 0x00000100'u32
    srcColorKey = 0x00001000'u32
    rleAccelOk  = 0x00002000'u32
    rleAccel    = 0x00004000'u32
    srcAlpha    = 0x00010000'u32
    preAlloc    = 0x01000000'u32
    anyFormat   = 0x10000000'u32
    hwPalette   = 0x20000000'u32
    doubleBuf   = 0x40000000'u32
    tripleBuf   = 0x40000100'u32
    fullscreen  = 0x80000000'u32

  SurfaceFlags* = distinct uint32
    ## Bitmask type for combining SurfaceFlag values.

operatorBitmask(SurfaceFlag, SurfaceFlags)

proc `and`*(x, y: SurfaceFlags): SurfaceFlags {.borrow.}
  ## Bitwise AND for SurfaceFlags.
proc `or`*(x, y: SurfaceFlags): SurfaceFlags {.borrow.}
  ## Bitwise OR for SurfaceFlags.
proc `==`*(x, y: SurfaceFlags): bool {.borrow.}
  ## Equality comparison for SurfaceFlags.

# ---------------------------------------------------------
# YUV, PALETTES AND OPENGL
# ---------------------------------------------------------
type
  YuvFormat* {.pure, size: sizeof(uint32).} = enum
    ## YUV pixel format FourCC codes.
    yv12 = 0x32315659'u32
    iyuv = 0x56555949'u32
    yuy2 = 0x32595559'u32
    uyvy = 0x59565955'u32
    yvyu = 0x55595659'u32

  PaletteFlag* {.pure, size: sizeof(cint).} = enum
    ## Flags for palette operations.
    logical   = 0x01
    physical  = 0x02

  GLAttr* {.importc: "SDL_GLattr", pure, size: sizeof(cint).} = enum
    ## OpenGL context attributes that can be set before creating the window.
    redSize, greenSize, blueSize, alphaSize, bufferSize, doubleBuffer,
    depthSize, stencilSize, accumRedSize, accumGreenSize, accumBlueSize,
    accumAlphaSize, stereo, multisampleBuffers, multisampleSamples,
    acceleratedVisual, swapControl

  GrabMode* {.pure, size: sizeof(cint).} = enum
    ## Input grab mode for confining the mouse to the window.
    query       = -1
    off         = 0
    on          = 1
    fullscreen  = 2

# =========================================================
# 2. C STRUCTURES AND FFI
# =========================================================
{.push header: "SDL_video.h", bycopy, cdecl.}

type
  Rect* {.importc: "SDL_Rect".} = object
    ## A rectangle, used for clipping, blitting, and screen updates.
    x*, y*: int16
    width* {.importc: "w".}: uint16
    height* {.importc: "h".}: uint16

  Color* {.importc: "SDL_Color".} = object
    ## An RGBA color value.
    r*, g*, b*: uint8
    unused: uint8

  RawPalette* {.importc: "SDL_Palette".} = object
    ## A palette of colors for indexed surfaces.
    ncolors: cint
    colors: ptr UncheckedArray[Color]

  Palette* = ptr RawPalette
    ## Pointer to a RawPalette.

  RawPixelFormat {.importc: "SDL_PixelFormat".} = object
    palette: Palette
    bitsPerPixel {.importc: "BitsPerPixel".}: uint8
    bytesPerPixel {.importc: "BytesPerPixel".}: uint8
    rLoss {.importc: "Rloss".}: uint8
    gLoss {.importc: "Gloss".}: uint8
    bLoss {.importc: "Bloss".}: uint8
    aLoss {.importc: "Aloss".}: uint8
    rShift {.importc: "Rshift".}: uint8
    gShift {.importc: "Gshift".}: uint8
    bShift {.importc: "Bshift".}: uint8
    aShift {.importc: "Ashift".}: uint8
    rMask {.importc: "Rmask".}: uint32
    gMask {.importc: "Gmask".}: uint32
    bMask {.importc: "Bmask".}: uint32
    aMask {.importc: "Amask".}: uint32
    colorKey {.importc: "colorkey".}: uint32
    alpha: uint8

  PixelFormat = ptr RawPixelFormat

  RawSurface {.importc: "SDL_Surface".} = object
    flags: uint32
    format: PixelFormat
    width {.importc: "w".}: cint
    height {.importc: "h".}: cint
    pitch: uint16
    pixels: ptr UncheckedArray[byte]
    offset: cint
    hwData {.importc: "hwdata".}: pointer
    clipRect {.importc: "clip_rect".}: Rect
    unused1: uint32
    locked: uint32
    map: pointer
    formatVersion {.importc: "format_version".}: cuint
    refCount {.importc: "refcount".}: cint

  RawSurfacePtr* = ptr RawSurface
    ## Pointer to a RawSurface (the underlying C SDL_Surface).

  RawOverlay {.importc: "SDL_Overlay".} = object
    format: uint32
    width {.importc: "w".}: cint
    height {.importc: "h".}: cint
    planes: cint
    pitches: ptr UncheckedArray[uint16]
    pixels: ptr UncheckedArray[ptr UncheckedArray[byte]]
    hwFunctions {.importc: "hwfunctions".}: pointer
    hwData {.importc: "hwdata".}: pointer
    hwOverlay {.importc: "hw_overlay".}: uint32

  RawOverlayPtr* = ptr RawOverlay
    ## Pointer to a RawOverlay (the underlying C SDL_Overlay).

  RawVideoInfo {.importc: "SDL_VideoInfo".} = object
    hwAvailable {.importc: "hw_available".}: uint32
    wmAvailable {.importc: "wm_available".}: uint32
    blitHw {.importc: "blit_hw".}: uint32
    blitHwCc {.importc: "blit_hw_CC".}: uint32
    blitHwA {.importc: "blit_hw_A".}: uint32
    blitSw {.importc: "blit_sw".}: uint32
    blitSwCc {.importc: "blit_sw_CC".}: uint32
    blitSwA {.importc: "blit_sw_A".}: uint32
    blitFill {.importc: "blit_fill".}: uint32
    videoMemory {.importc: "video_mem".}: uint32
    videoFormat {.importc: "videoformat".}: ptr PixelFormat
    currentWidth {.importc: "current_w".}: cint
    currentHeight {.importc: "current_h".}: cint

  VideoInfoPtr* = ptr RawVideoInfo
    ## Pointer to a RawVideoInfo (the underlying C SDL_VideoInfo).

{.pop.}

{.push header: "SDL_video.h", importc, cdecl.}

# Core, Info and Resolutions
proc SDL_VideoInit(driver_name: cstring, flags: uint32): cint
proc SDL_VideoQuit()
proc SDL_VideoDriverName(namebuf: cstring, maxlen: cint): cstring
proc SDL_GetVideoSurface(): RawSurfacePtr
proc SDL_GetVideoInfo(): VideoInfoPtr
proc SDL_VideoModeOK(width, height, bpp: cint, flags: uint32): cint
proc SDL_ListModes(format: PixelFormat, flags: uint32): ptr ptr Rect
proc SDL_SetVideoMode(width, height, bpp: cint, flags: uint32): RawSurfacePtr

# Drawing and Surfaces
proc SDL_CreateRGBSurface(flags: uint32, width, height, depth: cint, rMask,gMask, bMask, aMask: uint32): RawSurfacePtr
proc SDL_CreateRGBSurfaceFrom(pixels: pointer, width, height, depth, pitch: cint, rMask, gMask, bMask, aMask: uint32): RawSurfacePtr
proc SDL_FreeSurface(surface: RawSurfacePtr)
proc SDL_LockSurface(surface: RawSurfacePtr): cint
proc SDL_UnlockSurface(surface: RawSurfacePtr)
proc SDL_LoadBMP_RW(src: RawRWopsPtr, freesrc: cint): RawSurfacePtr
proc SDL_SaveBMP_RW(surface: RawSurfacePtr, dst: RawRWopsPtr, freedst: cint): cint

# Clipping
proc SDL_SetClipRect(surface: RawSurfacePtr, rect: ptr Rect): cint # Returns SDL_bool
proc SDL_GetClipRect(surface: RawSurfacePtr, rect: ptr Rect)

# Blitting and Fill
proc SDL_ConvertSurface(src: RawSurfacePtr, fmt: PixelFormat, flags: uint32): RawSurfacePtr
proc SDL_UpperBlit(src: RawSurfacePtr, srcrect: ptr Rect, dst: RawSurfacePtr, dstrect: ptr Rect): cint
proc SDL_LowerBlit(src: RawSurfacePtr, srcrect: ptr Rect, dst: RawSurfacePtr, dstrect: ptr Rect): cint
proc SDL_FillRect(dst: RawSurfacePtr, dstrect: ptr Rect, color: uint32): cint
proc SDL_DisplayFormat(surface: RawSurfacePtr): RawSurfacePtr
proc SDL_DisplayFormatAlpha(surface: RawSurfacePtr): RawSurfacePtr

# Screen Update
proc SDL_UpdateRects(screen: RawSurfacePtr, numrects: cint, rects: ptr Rect)
proc SDL_UpdateRect(screen: RawSurfacePtr, x, y: int32, w, h: uint32)
proc SDL_Flip(screen: RawSurfacePtr): cint
proc SDL_SetRefreshRate(rate: cint)

# Colors, Palettes and Gamma
proc SDL_SetGamma(red, green, blue: cfloat): cint
proc SDL_SetGammaRamp(red, green, blue: ptr uint16): cint
proc SDL_GetGammaRamp(red, green, blue: ptr uint16): cint
proc SDL_SetColors(surface: RawSurfacePtr, colors: ptr Color, firstcolor, ncolors: cint): cint
proc SDL_SetPalette(surface: RawSurfacePtr, flags: cint, colors: ptr Color, firstcolor, ncolors: cint): cint
proc SDL_MapRGB(format: PixelFormat, r, g, b: uint8): uint32
proc SDL_MapRGBA(format: PixelFormat, r, g, b, a: uint8): uint32
proc SDL_GetRGB(pixel: uint32, fmt: PixelFormat, r, g, b: ptr uint8)
proc SDL_GetRGBA(pixel: uint32, fmt: PixelFormat, r, g, b, a: ptr uint8)
proc SDL_SetColorKey(surface: RawSurfacePtr, flag, key: uint32): cint
proc SDL_SetAlpha(surface: RawSurfacePtr, flag: uint32, alpha: uint8): cint

# Hardware YUV Overlays
proc SDL_CreateYUVOverlay(width, height: cint, format: uint32, display: RawSurfacePtr): RawOverlayPtr
proc SDL_LockYUVOverlay(overlay: RawOverlayPtr): cint
proc SDL_UnlockYUVOverlay(overlay: RawOverlayPtr)
proc SDL_DisplayYUVOverlay(overlay: RawOverlayPtr, dstrect: ptr Rect): cint
proc SDL_FreeYUVOverlay(overlay: RawOverlayPtr)

# OpenGL Context
proc SDL_GL_LoadLibrary(path: cstring): cint
proc SDL_GL_GetProcAddress(procName: cstring): pointer
proc SDL_GL_SetAttribute(attr: GLAttr, value: cint): cint
proc SDL_GL_GetAttribute(attr: GLAttr, value: ptr cint): cint
proc SDL_GL_SwapBuffers()

# Window Manager
proc SDL_WM_SetCaption(title, icon: cstring)
proc SDL_WM_GetCaption(title, icon: ptr cstring)
proc SDL_WM_SetIcon(icon: RawSurfacePtr, mask: ptr uint8)
proc SDL_WM_IconifyWindow(): cint
proc SDL_WM_ToggleFullScreen(surface: RawSurfacePtr): cint
proc SDL_WM_GrabInput(mode: GrabMode): GrabMode

{.pop.}

# ---------------------------------------------------------
# Custom structures
# ---------------------------------------------------------
type
  PixelView* = object
    ## A safe view into a surface's pixel buffer, with bounds checking.
    data: ptr UncheckedArray[byte]
    maxLen: int

  ColorDepth* {.pure, size: sizeof(cint).} = enum
    ## Color depth (bits per pixel) presets.
    desktop = 0 # SDL uses 0 for "use the current desktop bit depth"
    bpp8    = 8
    bpp15   = 15
    bpp16   = 16
    bpp24   = 24
    bpp32   = 32

  VideoModeResult* = object
    ## Purely stack-allocated structure.
    anyDimension*: bool
    rawModes: ptr ptr Rect

  # SDL requires the Gamma ramp to have exactly 256 elements (0 to 255).
  # Using a specific type prevents passing an array of the wrong size and crashing the OS.
  GammaRamp* = array[256, uint16]
    ## A 256-entry gamma ramp table for each color channel.

  ColorMask* = tuple[r, g, b, a: uint32]
    ## RGBA bit masks for pixel format creation.

  Pixel* = distinct uint32
    ## A pixel value in a surface's native pixel format.
    ## Returned by `toPixel` and accepted by `fill`, `rgb`, and `rgba`.

## Compares two pixel values for equality.
proc `==`*(x, y: Pixel): bool {.borrow.}

## Converts a pixel value to its string representation.
proc `$`*(x: Pixel): string {.borrow.}

const maskZero*: ColorMask = (0'u32, 0'u32, 0'u32, 0'u32)  ## All-zero color mask (creates a default pixel format).

# ---------------------------------------------------------
# 16-bit masks
# (Bit positions are fixed in the 16-bit word, rarely affected by CPU endianness)
# ---------------------------------------------------------
const maskRgb565*: ColorMask   = (0xF800'u32, 0x07E0'u32, 0x001F'u32, 0'u32)      ## Standard 16-bit (High performance on legacy hardware)
const maskArgb1555*: ColorMask = (0x7C00'u32, 0x03E0'u32, 0x001F'u32, 0x8000'u32) ## 16-bit with 1-bit Alpha (binary transparency)
const maskArgb4444*: ColorMask = (0x0F00'u32, 0x00F0'u32, 0x000F'u32, 0xF000'u32) ## 16-bit with 4-bit Alpha (lower color quality)

# ---------------------------------------------------------
# 24 and 32 bit masks
# (Highly sensitive to MIPS vs x86 architecture)
# ---------------------------------------------------------
when cpuEndian == bigEndian:
  const maskRgb24*: ColorMask  = (0x00ff0000'u32, 0x0000ff00'u32, 0x000000ff'u32, 0'u32)
  const maskRgba32*: ColorMask = (0xff000000'u32, 0x00ff0000'u32, 0x0000ff00'u32, 0x000000ff'u32)
else:
  const maskRgb24*: ColorMask  = (0x000000ff'u32, 0x0000ff00'u32, 0x00ff0000'u32, 0'u32)
  const maskRgba32*: ColorMask = (0x000000ff'u32, 0x0000ff00'u32, 0x00ff0000'u32, 0xff000000'u32)


# =========================================================
# 3. SMART POINTERS (RAII Wrappers)
# =========================================================
type
  Surface* {.requiresInit.} = object
    ## RAII wrapper for an SDL_Surface. Frees the surface on scope exit.
    raw: RawSurfacePtr

  DisplaySurface* = object
    ## RAII wrapper for the display (screen) surface. Does NOT free on exit.
    raw: RawSurfacePtr

  YuvOverlay* {.requiresInit.} = object
    ## RAII wrapper for a YUV video overlay. Frees the overlay on scope exit.
    raw: RawOverlayPtr

  VideoInfo* = object
    ## RAII wrapper for video display capabilities information.
    raw: VideoInfoPtr

  AnySurface* = Surface | DisplaySurface
    ## Type alias for either a managed Surface or a DisplaySurface.

proc `=destroy`*(s: var Surface) =
  ## Frees the underlying SDL_Surface when the Surface goes out of scope.
  destroyImpl(s, SDL_FreeSurface)

proc `=destroy`*(o: var YuvOverlay) =
  ## Frees the underlying SDL_Overlay when the YuvOverlay goes out of scope.
  destroyImpl(o, SDL_FreeYUVOverlay)

proc `=destroy`*(s: var DisplaySurface) = discard
  ## No-op: the display surface is owned by SDL and must not be freed.

proc `=sink`*(dest: var Surface; source: Surface) = sinkImpl(dest, source)
  ## Move semantics for Surface: transfers ownership without double-free.

proc `=sink`*(dest: var YuvOverlay; source: YuvOverlay) = sinkImpl(dest, source)
  ## Move semantics for YuvOverlay: transfers ownership without double-free.

proc `=sink`*(dest: var DisplaySurface; source: DisplaySurface) = dest.raw = source.raw
  ## Move semantics for DisplaySurface: copies the raw pointer (no ownership).

proc `=copy`*(dest: var Surface; source: Surface) = copyImpl(dest, source, refCount)
  ## Copy semantics for Surface: increments the reference count.

proc `=copy`*(dest: var YuvOverlay, source: YuvOverlay) {.error.}
  ## Copying YuvOverlay is disabled to prevent double-free. Use move() instead.

proc `=copy`*(dest: var DisplaySurface; source: DisplaySurface) = dest.raw = source.raw
  ## Copy semantics for DisplaySurface: copies the raw pointer (no ownership).

proc unsafeRaw*(s: Surface): RawSurfacePtr {.inline.} = s.raw
  ## Extracts the raw SDL_Surface pointer from a Surface wrapper.

proc unsafeRaw*(o: YuvOverlay): RawOverlayPtr {.inline.} = o.raw
  ## Extracts the raw SDL_Overlay pointer from a YuvOverlay wrapper.

proc unsafeRaw*(s: DisplaySurface): RawSurfacePtr {.inline.} = s.raw
  ## Extracts the raw SDL_Surface pointer from a DisplaySurface wrapper.

proc assumeRaw*[T: AnySurface](p: RawSurfacePtr): T {.inline.} = T(raw: p)
  ## Wraps a raw SDL_Surface pointer into a Surface or DisplaySurface. Assumes ownership for Surface.

proc assumeRaw*(p: RawOverlayPtr): YuvOverlay {.inline.} = YuvOverlay(raw: p)
  ## Wraps a raw SDL_Overlay pointer into a YuvOverlay. Assumes ownership.

# =========================================================
# 4. PUBLIC API
# =========================================================

## Rect

proc initRect*(x, y: int16; width, height: uint16): Rect {.inline.} =
  ## Convenience helper to create a Rect quickly.
  Rect(x: x, y: y, width: width, height: height)

## Color

proc initColor*(r, g, b: uint8): Color {.inline.} =
  ## Convenience helper to create a Color from RGB components.
  Color(r: r, g: g, b: b, unused: 0)

proc initColor*(color: tuple[r, g, b: uint8]): Color {.inline.} =
  ## Convenience helper to create a Color from a tuple.
  Color(r: color.r, g: color.g, b: color.b, unused: 0)

## Palette

proc len*(p: Palette): int {.inline.} = int(p.ncolors)
  ## Returns the number of colors in the palette.

proc `[]`*(p: Palette, index: int): Color {.inline.} =
  ## Returns the color at a specific palette index.
  assert index >= 0 and index < p.len, "Palette index out of bounds!"

  p.colors[index]

proc `[]=`*(p: Palette, index: int, color: Color) {.inline.} =
  ## Sets the color at a specific palette index.
  assert index >= 0 and index < p.len, "Palette index out of bounds!"
  p.colors[index] = color

## PixelFormat

proc palette*(p: PixelFormat): Option[Palette] {.inline.} =
  ## Returns the palette if the pixel format is indexed (<= 8 bits per pixel).
  if p.palette == nil:
    none(Palette)
  else:
    some(p.palette)

proc alpha*(p: PixelFormat): uint8 {.inline.} = p.alpha
  ## Returns the per-surface alpha value.
proc colorKey*(p: PixelFormat): uint32 {.inline.} = p.colorKey
  ## Returns the color key (transparent color) for the pixel format.
proc bitsPerPixel*(p: PixelFormat): uint8 {.inline.} = p.bitsPerPixel
  ## Returns the number of bits per pixel.
proc bytesPerPixel*(p: PixelFormat): uint8 {.inline.} = p.bytesPerPixel
  ## Returns the number of bytes per pixel.

proc loss*(p: PixelFormat): tuple[r, g, b, a: uint8] {.inline.} =
  ## Returns the bit loss for each RGBA channel.
  (p.rLoss, p.gLoss, p.bLoss, p.aLoss)

proc shift*(p: PixelFormat): tuple[r, g, b, a: uint8] {.inline.} =
  ## Returns the bit shift for each RGBA channel.
  (p.rShift, p.gShift, p.bShift, p.aShift)

proc mask*(p: PixelFormat): tuple[r, g, b, a: uint32] {.inline.} =
  ## Returns the bit mask for each RGBA channel.
  (p.rMask, p.gMask, p.bMask, p.aMask)

## PixelView

proc len*(v: PixelView): int {.inline.} = v.maxLen
  ## Returns the maximum safe length of the pixel buffer.

proc `[]`*(v: PixelView, index: int): byte {.inline.} =
  assert index >= 0 and index < v.len, "Pixel buffer read out of bounds!"
  v.data[index]

proc `[]=`*(v: PixelView, index: int, val: byte) {.inline.} =
  assert index >= 0 and index < v.len, "Pixel buffer write out of bounds!"
  v.data[index] = val

## Surface

proc format*(s: AnySurface): PixelFormat {.inline.} = s.raw.format
  ## Returns the pixel format of the surface.
proc width*(s: AnySurface): uint16 {.inline.} = uint16(s.raw.width)
  ## Returns the width of the surface in pixels.
proc height*(s: AnySurface): uint16 {.inline.} = uint16(s.raw.height)
  ## Returns the height of the surface in pixels.
proc pitch*(s: AnySurface): uint16 {.inline.} = s.raw.pitch
  ## Returns the pitch (bytes per row) of the surface.
proc offset*(s: AnySurface): int {.inline.} = s.raw.offset
  ## Returns the pixel offset of the surface.
proc clipRect*(s: AnySurface): Rect {.inline.} = s.raw.clipRect
  ## Returns the current clipping rectangle.
proc isLocked*(s: AnySurface): bool {.inline.} = s.raw.locked == 1
  ## Whether the surface is currently locked for direct pixel access.

proc pixels*(s: AnySurface): PixelView {.inline.} =
  ## Returns a safe PixelView for direct pixel access.
  PixelView(
    data: s.raw.pixels,
    maxLen: int(s.pitch * s.height)
  )

## Overlay
proc format*(o: YuvOverlay): uint32 {.inline.} = o.raw.format
  ## Returns the FourCC format code of the overlay.
proc width*(o: YuvOverlay): uint16 {.inline.} = uint16(o.raw.width)
  ## Returns the width of the overlay in pixels.
proc height*(o: YuvOverlay): uint16 {.inline.} = uint16(o.raw.height)
  ## Returns the height of the overlay in pixels.
proc planes*(o: YuvOverlay): int {.inline.} = int(o.raw.planes)
  ## Returns the number of color planes in the overlay.

# --- PLANE ACCESS ---

proc pitch*(o: YuvOverlay, planeIndex: int): uint16 {.inline.} =
  ## Returns the pitch (row width in bytes) for a specific color plane.
  assert planeIndex >= 0 and planeIndex < o.raw.planes, "Plane index out of bounds!"
  o.raw.pitches[planeIndex]

proc pixels*(o: YuvOverlay, planeIndex: int): PixelView {.inline.} =
  ## Returns a safe PixelView for the requested plane.
  assert planeIndex >= 0 and planeIndex < o.raw.planes, "Plane index out of bounds!"

  let planePitch = int(o.pitch(planeIndex))

  # In YUV formats, chroma planes typically have half the height of the luma plane.
  # Using (pitch * global height) as a safe upper bound.
  let maxSafeLen = planePitch * int(o.height)

  PixelView(
    data: o.raw.pixels[planeIndex],
    maxLen: maxSafeLen
  )

# ---------------------------------------------------------
# CAPABILITY GETTERS (BOOLEANS)
# ---------------------------------------------------------

proc hwAvailable*(info: VideoInfo): bool {.inline.} =
  ## Whether the hardware has video acceleration available.
  sdlNonZero info.raw.hwAvailable

proc wmAvailable*(info: VideoInfo): bool {.inline.} =
  ## Whether a window manager is available (always true on WinCE).
  sdlNonZero info.raw.wmAvailable

proc videoMemory*(info: VideoInfo): uint32 {.inline.} =
  ## Total available video memory in Kilobytes (KB).
  info.raw.videoMemory

# ---------------------------------------------------------
# BLITTING (HARDWARE ACCELERATION)
# ---------------------------------------------------------

proc canBlitHw*(info: VideoInfo): bool {.inline.} =
  ## Hardware to Hardware acceleration (VRAM -> VRAM).
  sdlNonZero info.raw.blitHw

proc canBlitHwColorkey*(info: VideoInfo): bool {.inline.} =
  ## Hardware acceleration with ColorKey (simple transparency).
  sdlNonZero info.raw.blitHwCc

proc canBlitHwAlpha*(info: VideoInfo): bool {.inline.} =
  ## Hardware acceleration with Alpha Blending (gradual transparency).
  ## Note: On some embedded hardware this may be false, requiring software fallback.
  sdlNonZero info.raw.blitHwA

proc canBlitSw*(info: VideoInfo): bool {.inline.} =
  ## Software to Hardware acceleration (RAM -> VRAM).
  sdlNonZero info.raw.blitSw

proc canBlitSwColorkey*(info: VideoInfo): bool {.inline.} =
  ## Software acceleration with ColorKey.
  sdlNonZero info.raw.blitSwCc

proc canBlitSwAlpha*(info: VideoInfo): bool {.inline.} =
  ## Software acceleration with Alpha Blending.
  sdlNonZero info.raw.blitSwA

proc canFill*(info: VideoInfo): bool {.inline.} =
  ## Whether color fill (FillRect) is hardware-accelerated.
  sdlNonZero info.raw.blitFill


# ---------------------------------------------------------
# CORE, INFO AND RESOLUTIONS
# ---------------------------------------------------------

proc initVideo*(driverName: string = ""; flags: uint32 = 0) {.inline.} =
  ## Initializes the video subsystem explicitly.
  ## On failure, displays the error and halts the program.
  let d = if driverName == "": nil else: driverName.cstring
  discard sdlCheck SDL_VideoInit(d, flags)

proc quitVideo*() {.inline.} =
  ## Shuts down and cleans up only the video subsystem.
  SDL_VideoQuit()

proc videoDriverName*(): Option[string] {.inline.} =
  ## Returns the name of the current video driver (e.g. "x11", "windib").
  ## Returns `none` if the video subsystem is not initialized.
  var buf: array[64, char]

  let res = SDL_VideoDriverName(buf.cBuf, buf.cLen)
  if res.isNil: none(string) else: some($res)

proc videoSurface*(): Option[DisplaySurface] {.inline.} =
  ## Returns the current video surface (the display), or `none` if not initialized.
  SDL_GetVideoSurface().toOption(DisplaySurface)

proc checkVideoMode*(
    width, height: uint16;
    bpp: ColorDepth = ColorDepth.default;
    flags: SurfaceFlag | SurfaceFlags = SurfaceFlag.swSurface
  ): Option[ColorDepth] {.inline.} =
  ## Checks if a video mode is supported. Returns the closest bpp or `none`.
  let supportedBpp = SDL_VideoModeOK(cint(width), cint(height), cint(bpp), uint32(flags))
  if supportedBpp == 0:
    none(ColorDepth)
  else:
    some(ColorDepth(supportedBpp))

# --- ListModes (Zero-Cost Iterator) ---
proc listModes*(
    format: ptr PixelFormat = nil;
    flags: SurfaceFlag | SurfaceFlags = SurfaceFlag.fullscreen
  ): VideoModeResult {.inline.} =
  ## Queries the hardware for supported resolutions. No memory allocation.
  let p = SDL_ListModes(format, uint32(flags))

  if p == nil:
    VideoModeResult(anyDimension: false, rawModes: nil)
  elif p == cast[ptr ptr Rect](-1):
    VideoModeResult(anyDimension: true, rawModes: nil)
  else:
    VideoModeResult(anyDimension: false, rawModes: p)

iterator items*(res: VideoModeResult): Rect =
  ## Iterates over the modes returned by listModes().
  ## Example: `for mode in listModes(): echo mode.w`
  if not res.anyDimension and res.rawModes != nil:
    var arr = cast[ptr UncheckedArray[ptr Rect]](res.rawModes)
    var i = 0
    while arr[i] != nil:
      yield arr[i][] # Zero-cost dereference on the stack
      inc i

proc setVideoMode*(
    width, height: uint16;
    bpp: ColorDepth = ColorDepth.default;
    flags: SurfaceFlag | SurfaceFlags = SurfaceFlag.swSurface
  ): Option[DisplaySurface] {.inline.} =
  ## Creates the display surface (the screen/window). Returns `none` on failure.
  let p = SDL_SetVideoMode(cint(width), cint(height), cint(bpp), uint32(flags))

  if p == nil:
    none(DisplaySurface)
  else:
    some(DisplaySurface(raw: p))

# ---------------------------------------------------------
# VIDEO INFO
# ---------------------------------------------------------

proc videoInfo*(): Option[VideoInfo] {.inline.} =
  ## Returns video display capabilities, or `none` if not initialized.
  SDL_GetVideoInfo().toOption(VideoInfo)

# ---------------------------------------------------------
# RESOLUTION AND FORMAT
# ---------------------------------------------------------

proc currentRes*(info: VideoInfo): tuple[w, h: int] {.inline.} =
  ## Returns the current desktop (or primary display) resolution.
  if info.raw != nil: (int(info.raw.currentWidth), int(info.raw.currentHeight))
  else: (0, 0)

proc format*(info: VideoInfo): ptr PixelFormat {.inline.} =
  ## Returns the current screen pixel format.
  if info.raw != nil: info.raw.videoFormat else: nil

# ---------------------------------------------------------
# SURFACE MANAGEMENT
# ---------------------------------------------------------

proc createRgbSurface*(
    width, height: uint16;
    depth: ColorDepth = ColorDepth.bpp32;
    flags: SurfaceFlag | SurfaceFlags = SurfaceFlag.swSurface;
    mask: ColorMask = maskZero
  ): Option[Surface] {.inline.} =
  ## Creates a new surface in system memory. Returns `none` on failure.
  let p = SDL_CreateRGBSurface(uint32(flags), cint(width), cint(height), cint(depth), mask.r, mask.g, mask.b, mask.a)

  if p.isNil: none(Surface)
  else: some(Surface(raw: p))

proc createRgbSurfaceFrom*(
    pixels: pointer;
    width, height: uint16;
    depth: ColorDepth;
    pitch: int;
    mask: ColorMask = maskZero
  ): Option[Surface] {.inline.} =
  ## Creates a surface from an existing pixel buffer. Returns `none` on failure.
  let p = SDL_CreateRGBSurfaceFrom(pixels, cint(width), cint(height), cint(depth), cint(pitch), mask.r, mask.g, mask.b, mask.a)

  if p.isNil: none(Surface)
  else: some(Surface(raw: p))

proc lock*(surface: AnySurface): bool {.inline.} =
  ## Locks the surface for direct pixel access. Returns `true` on success.
  sdlOk SDL_LockSurface(surface.raw)

proc unlock*(surface: AnySurface) {.inline.} =
  ## Unlocks the surface after pixel manipulation.
  SDL_UnlockSurface(surface.raw)

template withLock*(surface: AnySurface; body: untyped): bool =
  ## Locks the surface, executes the block, and guarantees unlock on exit.
  ## Returns `true` if the block executed successfully, `false` on hardware error.
  let success = surface.lock()
  if success:
    defer: surface.unlock()
    block: body
  success

# --- BMP Manipulation ---

proc loadBmp*(src: RWops; freeSrc: bool = true): Option[Surface] {.inline.} =
  ## Loads a BMP image from an RWops stream.
  let p = SDL_LoadBMP_RW(src.unsafeRaw, if freeSrc: 1 else: 0)
  if p == nil: result = none(Surface)
  else: result = some(Surface(raw: p))

proc saveBmp*(surface: Surface; dst: RWops; freeDst: bool = true): bool {.inline.} =
  ## Saves the surface as a BMP to an RWops stream. Returns `true` on success.
  sdlOk SDL_SaveBMP_RW(surface.raw, dst.unsafeRaw, if freeDst: 1 else: 0)

# ---------------------------------------------------------
# CLIPPING
# ---------------------------------------------------------

proc clearClipRect*(surface: AnySurface): bool {.inline.} =
  ## Removes the clipping rectangle, allowing drawing on the entire surface again.
  sdlNonZero SDL_SetClipRect(surface.raw, nil)

proc `clipRect=`*(surface: AnySurface; rect: Rect): bool {.inline.} =
  ## Sets the clipping area. Only pixels inside the rectangle will be drawn.
  ## Returns `true` if the rectangle intersects the surface.
  var r = rect # Mutable copy on the stack to take its address
  result = sdlNonZero SDL_SetClipRect(surface.raw, addr r)

# ---------------------------------------------------------
# FORMAT OPTIMIZATION AND CONVERSION
# ---------------------------------------------------------

proc displayFormat*(surface: Surface): Option[Surface] {.inline.} =
  ## Converts the surface to the native screen pixel format.
  ## SDL Golden Rule: Always call this after loading a BMP.
  ## Blitting an optimized surface can be tens of times faster.
  let p = SDL_DisplayFormat(surface.raw)
  if p == nil: result = none(Surface)
  else: result = some(Surface(raw: p))

proc displayFormatAlpha*(surface: Surface): Option[Surface] {.inline.} =
  ## Same as displayFormat, but preserves the Alpha channel (transparency).
  let p = SDL_DisplayFormatAlpha(surface.raw)
  if p == nil: result = none(Surface)
  else: result = some(Surface(raw: p))

proc convertSurface*(
    surface: Surface;
    fmt: ptr PixelFormat;
    flags: SurfaceFlag | SurfaceFlags = SurfaceFlag.swSurface
  ): Option[Surface] {.inline.} =
  ## Converts a surface to a different pixel format. Returns `none` on failure.
  let p = SDL_ConvertSurface(surface.raw, fmt, uint32(flags))
  if p == nil: result = none(Surface)
  else: result = some(Surface(raw: p))

# ---------------------------------------------------------
# COLOR FILL
# ---------------------------------------------------------

proc fill*(surface: AnySurface; color: Pixel): bool {.inline.} =
  ## Fills the entire surface with a pixel color value.
  result = sdlOk SDL_FillRect(surface.raw, nil, uint32(color))

proc fill*(surface: AnySurface; rect: Rect; color: Pixel): bool {.inline.} =
  ## Fills a rectangular area with a pixel color value.
  var r = rect
  result = sdlOk SDL_FillRect(surface.raw, addr r, uint32(color))

# ---------------------------------------------------------
# BLITTING
# ---------------------------------------------------------

# Overload 1: Simple blit (draws the entire image at coordinates X, Y)
proc blit*(source: AnySurface; target: AnySurface; x: int16 = 0; y: int16 = 0): bool {.inline.} =
  ## Copies the entire 'source' surface to 'target' at the specified coordinates.
  var dRect = initRect(x, y, 0, 0)
  result = sdlOk SDL_UpperBlit(source.raw, nil, target.raw, addr dRect)

# Overload 2: Specific region (copies a rect from source to destination X, Y)
proc blit*(source: AnySurface; target: AnySurface; rect: Rect; x: int16 = 0; y: int16 = 0): bool {.inline.} =
  ## Useful for spritesheets: copies a 'rect' region from the source and blits it to the target.
  var sRect = rect
  var dRect = initRect(int16(x), int16(y), 0, 0)
  result = sdlOk SDL_UpperBlit(source.raw, addr sRect, target.raw, addr dRect)

proc blitRaw*(source: AnySurface; target: AnySurface; x, y: int): bool {.inline.} =
  ## Raw copy of the ENTIRE surface to the target.
  ## Ignores SDL clipping. Maximum speed for backgrounds or fixed HUDs.
  var dRect = initRect(int16(x), int16(y), 0, 0)
  result = sdlOk SDL_LowerBlit(source.raw, nil, target.raw, addr dRect)

proc blitRaw*(source: AnySurface; target: AnySurface; rect: Rect; x: int = 0; y: int = 0): bool {.inline.} =
  ## **Warning** (Low Level Access):
  ## Raw memory copy that skips SDL clipping checks.
  ## Only use in custom engines where you guarantee coordinates are within bounds.
  var sRect = rect
  var dRect = initRect(int16(x), int16(y), 0, 0)
  result = sdlOk SDL_LowerBlit(source.raw, addr sRect, target.raw, addr dRect)

# ---------------------------------------------------------
# SCREEN UPDATE AND SYNC
# ---------------------------------------------------------

proc flip*(screen: AnySurface): bool {.inline.} =
  ## Swaps the invisible backbuffer with the visible frontbuffer.
  ## Used in games with Double Buffering to prevent screen tearing.
  sdlOk SDL_Flip(screen.raw)

# Overload 1: Update by coordinates (with full-screen auto support)
proc update*(
    screen: AnySurface;
    x: int16 = 0;
    y: int16 = 0;
    w: uint16 = 0;
    h: uint16 = 0
  ) {.inline.} =
  ## Updates a specific region of the screen.
  ## Note: Called with no arguments (0, 0, 0, 0), SDL updates the entire screen.
  SDL_UpdateRect(screen.raw, int32(x), int32(y), uint32(w), uint32(h))

# Overload 2: Passing a Rect directly
proc update*(screen: AnySurface; rect: Rect) {.inline.} =
  ## Convenience overload: extracts coordinates from the Rect and updates the area.
  SDL_UpdateRect(screen.raw, int32(rect.x), int32(rect.y), uint32(rect.width), uint32(rect.height))

# Overload 3: openArray of Rects (Zero-Cost)
proc update*(screen: AnySurface; rects: openArray[Rect]) {.inline.} =
  ## Sends a list of dirty rectangles to SDL to update at once.
  ## Nim handles the count (len) and pointers automatically.
  if rects.len > 0:
    SDL_UpdateRects(screen.raw, cint(rects.len), unsafeAddr rects[0])

# Hardware Configuration
proc setRefreshRate*(rate: uint16) {.inline.} =
  ## Sets the display refresh rate.
  ## Usually only available on embedded hardware or specific ports.
  SDL_SetRefreshRate(cint(rate))

# ---------------------------------------------------------
# COLOR PALETTES (RETRO EFFECTS AND PALETTE SWAPPING)
# ---------------------------------------------------------

proc setColors*(
    surface: AnySurface;
    colors: openArray[Color];
    firstColor: int = 0
  ): bool {.inline.} =
  ## Applies a new palette to an 8-bit surface.
  ## Nim handles the count (ncolors) automatically at zero cost.
  if colors.len == 0: return false
  result = sdlTrue SDL_SetColors(surface.raw, unsafeAddr colors[0], cint(firstColor), cint(colors.len))

proc setPalette*(
    surface: AnySurface;
    flags: PaletteFlag;
    colors: openArray[Color];
    firstColor: int = 0
  ): bool {.inline.} =
  ## Advanced palette control (Logical Memory vs Physical Hardware).
  if colors.len == 0: return false
  result = sdlNoErr SDL_SetPalette(
    surface.raw,
    cint(flags),
    unsafeAddr colors[0],
    cint(firstColor),
    cint(colors.len)
  )

# ---------------------------------------------------------
# GAMMA CONTROL (MONITOR BRIGHTNESS)
# ---------------------------------------------------------

proc setGamma*(red, green, blue: float32): bool {.inline.} =
  ## Sets the Gamma multiplier (1.0 is original color, 2.0 is very bright).
  ## Note: Only works in fullscreen on supported hardware.
  sdlNoErr SDL_SetGamma(cfloat(red), cfloat(green), cfloat(blue))

proc setGammaRamp*(red, green, blue: ptr GammaRamp): bool {.inline.} =
  ## Allows remapping each of the 256 tones per color channel individually.
  ## Passing `nil` for a channel leaves it unchanged.
  sdlNoErr SDL_SetGammaRamp(
    cast[ptr uint16](red),
    cast[ptr uint16](green),
    cast[ptr uint16](blue)
  )

proc getGammaRamp*(red, green, blue: ptr GammaRamp): bool {.inline.} =
  ## Retrieves the current gamma ramp from the display hardware.
  sdlNoErr SDL_GetGammaRamp(
    cast[ptr uint16](red),
    cast[ptr uint16](green),
    cast[ptr uint16](blue)
  )

# ---------------------------------------------------------
# PIXEL CONVERSION
# ---------------------------------------------------------

proc toPixel*(surface: AnySurface; r, g, b: uint8): Pixel {.inline.} =
  ## Converts RGB to a pixel value for the surface's pixel format.
  Pixel(SDL_MapRGB(surface.raw.format, r, g, b))

proc toPixel*(surface: AnySurface; color: tuple[r, g, b: uint8]): Pixel {.inline.} =
  ## Converts an RGB tuple to a pixel value for the surface's pixel format.
  Pixel(SDL_MapRGB(surface.raw.format, color.r, color.g, color.b))

proc toPixel*(format: PixelFormat; r, g, b: uint8): Pixel {.inline.} =
  ## Converts RGB to a pixel value for a specific pixel format.
  Pixel(SDL_MapRGB(format, r, g, b))

proc toPixel*(format: PixelFormat; color: tuple[r, g, b: uint8]): Pixel {.inline.} =
  ## Converts an RGB tuple to a pixel value for a specific pixel format.
  Pixel(SDL_MapRGB(format, color.r, color.g, color.b))

proc toPixel*(surface: AnySurface; r, g, b, a: uint8): Pixel {.inline.} =
  ## Converts RGBA to a pixel value for the surface's pixel format.
  Pixel(SDL_MapRGBA(surface.raw.format, r, g, b, a))

proc toPixel*(surface: AnySurface; color: tuple[r, g, b, a: uint8]): Pixel {.inline.} =
  ## Converts an RGBA tuple to a pixel value for the surface's pixel format.
  Pixel(SDL_MapRGBA(surface.raw.format, color.r, color.g, color.b, color.a))

proc toPixel*(format: PixelFormat; r, g, b, a: uint8): Pixel {.inline.} =
  ## Converts RGBA to a pixel value for a specific pixel format.
  Pixel(SDL_MapRGBA(format, r, g, b, a))

proc toPixel*(format: PixelFormat; color: tuple[r, g, b, a: uint8]): Pixel {.inline.} =
  ## Converts an RGBA tuple to a pixel value for a specific pixel format.
  Pixel(SDL_MapRGBA(format, color.r, color.g, color.b, color.a))

# ---------------------------------------------------------
# COLOR READING (NIM TUPLES)
# ---------------------------------------------------------

proc rgb*(surface: AnySurface; pixel: Pixel): tuple[r, g, b: uint8] {.inline.} =
  ## Extracts RGB components from a pixel value into a tuple.
  SDL_GetRGB(uint32(pixel), surface.raw.format, addr result.r, addr result.g, addr result.b)

proc rgba*(surface: AnySurface; pixel: Pixel): tuple[r, g, b, a: uint8] {.inline.} =
  ## Extracts RGBA components from a pixel value into a tuple.
  SDL_GetRGBA(uint32(pixel), surface.raw.format, addr result.r, addr result.g, addr result.b, addr result.a)

# ---------------------------------------------------------
# TRANSPARENCY (COLOR KEY & ALPHA)
# ---------------------------------------------------------

proc clearColorKey*(surface: AnySurface): bool {.inline.} =
  ## Disables surface transparency.
  result = sdlOk SDL_SetColorKey(surface.raw, 0'u32, 0'u32)

proc `colorKey=`*(surface: AnySurface; color: tuple[r, g, b: uint8]): bool {.inline.} =
  ## Enables transparency using the specified RGB color as color key.
  let keyPixel = surface.toPixel(color.r, color.g, color.b)
  result = sdlOk SDL_SetColorKey(surface.raw, uint32(SurfaceFlag.srcColorKey), uint32(keyPixel))

proc `alpha=`*(surface: AnySurface; alpha: uint8): bool {.inline.} =
  ## Sets the global image opacity (0 = Invisible, 255 = Solid).
  ## Note: Alpha blending is CPU-intensive on some embedded hardware. Use sparingly.
  let flag = if alpha == 255'u8: SurfaceFlag.swSurface else: SurfaceFlag.srcAlpha
  result = sdlOk SDL_SetAlpha(surface.raw, uint32(flag), alpha)

# ---------------------------------------------------------
# HARDWARE YUV OVERLAYS (VIDEO AND FMV)
# ---------------------------------------------------------

proc createYuvOverlay*(display: AnySurface; width, height: int; format: uint32): Option[YuvOverlay] =
  ## Creates a YUV overlay tied to the display surface.
  let p = SDL_CreateYUVOverlay(cint(width), cint(height), format, display.raw)
  if p.isNil: none(YuvOverlay) else: some(YuvOverlay(raw: p))

proc isValid*(overlay: YuvOverlay): bool {.inline.} =
  ## Since the hardware may refuse creation, it is vital to check for success.
  sdlValid overlay.raw

# ---------------------------------------------------------
# STATE CONTROL
# ---------------------------------------------------------

proc lock*(overlay: YuvOverlay): bool {.inline.} =
  ## Locks the overlay for CPU write access. Returns `true` on success.
  sdlOk SDL_LockYUVOverlay(overlay.raw)

proc unlock*(overlay: YuvOverlay) {.inline.} =
  ## Unlocks the overlay after CPU write access.
  SDL_UnlockYUVOverlay(overlay.raw)

template lock*(overlay: YuvOverlay, body: untyped): bool =
  ## Locks the overlay in memory so the CPU can write video pixels.
  block:
    let success = overlay.lock()
    if success:
      defer: overlay.unlock()
      body
    success

# ---------------------------------------------------------
# RENDERING
# ---------------------------------------------------------

proc display*(overlay: YuvOverlay; rect: Rect): bool {.inline.} =
  ## Sends the overlay to the screen. The hardware will stretch it
  ## automatically to fit the destination Rect.
  var dst = rect # Mutable copy on the stack to take its address
  sdlOk SDL_DisplayYUVOverlay(overlay.raw, addr dst)

# ---------------------------------------------------------
# OPENGL CONTEXT (RAW / C-ABI)
# ---------------------------------------------------------

proc loadLibrary*(): bool {.inline.} =
  ## Loads the OpenGL library. Passing `nil` loads the default system driver.
  sdlOk SDL_GL_LoadLibrary(nil)

proc loadLibrary*(path: string): bool {.inline.} =
  ## Loads a specific OpenGL library from the given path.
  sdlOk SDL_GL_LoadLibrary(path.cstring)

proc procAddress*(procName: string): pointer {.inline.} =
  ## Looks up the memory address of an OpenGL function/extension.
  SDL_GL_GetProcAddress(procName.cstring)

proc `attribute=`*(attr: GLAttr; value: int): bool {.inline.} =
  ## Sets a 3D context attribute. MUST be called BEFORE creating the screen.
  sdlOk SDL_GL_SetAttribute(attr, cint(value))

proc attribute*(attr: GLAttr): Option[int] {.inline.} =
  ## Retrieves a 3D context attribute. Returns `some(value)` on success, `none` on failure.
  var val: cint
  if sdlOk SDL_GL_GetAttribute(attr, addr val):
    result = some(int(val))
  else:
    result = none(int)

proc swapBuffers*() {.inline.} =
  ## Swaps the hardware-accelerated screen buffers.
  SDL_GL_SwapBuffers()

# ---------------------------------------------------------
# WINDOW MANAGER
# ---------------------------------------------------------

proc setCaption*(title: string; icon: string = "") {.inline.} =
  ## Sets the window title.
  ## The 'icon' is the window name when minimized (rarely used today, default is empty).
  let iconStr = if icon == "": nil else: icon.cstring
  SDL_WM_SetCaption(title.cstring, iconStr)

proc caption*(): tuple[title, icon: cstring] =
  ## Gets the current window title and icon text.
  ## Nim handles the C double-pointer safely, extracting clean cstrings.
  var cTitle, cIcon: cstring
  SDL_WM_GetCaption(addr cTitle, addr cIcon)

  (cTitle, cIcon)

proc setIcon*(icon: AnySurface) {.inline.} =
  ## Sets the game window icon.
  ## Tip: Set ColorKey transparency on the Surface BEFORE calling this function.
  SDL_WM_SetIcon(icon.raw, nil)

proc setIcon*(icon: AnySurface; mask: openArray[uint8]) {.inline.} =
  ## Sets the game window icon with a transparency mask.
  ## The mask is a 1-bit-per-pixel bitmap (row-padded to 32 bits).
  if mask.len > 0:
    SDL_WM_SetIcon(icon.raw, cast[ptr uint8](unsafeAddr mask[0]))

proc iconifyWindow*(): bool {.inline.} =
  ## Attempts to minimize the window. Returns `true` on success.
  ## On some embedded hardware (WinCE), this may fail.
  sdlNonZero SDL_WM_IconifyWindow()

proc toggleFullScreen*(surface: AnySurface): bool {.inline.} =
  ## Toggles between fullscreen and windowed mode in real time.
  ## **Warning:** On Windows this often fails in SDL 1.2. On Linux/X11 it works perfectly.
  sdlTrue SDL_WM_ToggleFullScreen(surface.raw)

proc grabInput*(mode: GrabMode): GrabMode {.inline.} =
  ## Grabs the mouse (and stylus) within the game window boundaries.
  ## Useful for 3D shooters or to prevent accidental clicks outside the screen.
  SDL_WM_GrabInput(mode)
