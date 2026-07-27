## # sdl/gfxfilter
##
## MMX-accelerated byte-image filter routines using SDL_gfx
##
## This module provides hardware-optimized (MMX) image filtering operations on
## continuous byte buffers — typically greyscale images, raw pixel data, or
## framegrabber output. All functions operate on raw byte arrays and support
## operations like addition, subtraction, convolution, and binarization.
##
## Functions with MMX acceleration fall back to C implementations on systems
## without MMX support. Convolution routines do not have C fallbacks.
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
##   var src1: array[1024, uint8]
##   var src2: array[1024, uint8]
##   var dest: array[1024, uint8]
##
##   # Add two buffers with saturation
##   discard filterAdd(src1, src2, dest)
##
##   # Compute absolute difference
##   discard filterAbsDiff(src1, src2, dest)
## ```
##
## ## Advantages over C SDL_gfx
##
## | C SDL_gfx                          | Nim SDL                      |
## |------------------------------------|------------------------------|
## | Raw `Uint8 *` with manual length   | `openArray[uint8]` safe API  |
## | No bounds checking                 | Automatic buffer length check|
## | `int` return codes                 | `bool` via `sdlOk` template  |
## | Convolution: `assert` on size      | `false` return on mismatch   |
##
## ## API Highlights
##
## - **Safe:** All functions check buffer lengths, return `false` on empty/mismatch
## - **`openArray` API:** Works with `seq[uint8]`, `array[N, uint8]`, or slices
## - **Consistent return:** All operations return `bool` via `sdlOk`
## - **MMX control:** `mmxFilterDetect()`, `mmxFilterOn()`, `mmxFilterOff()`
##
## ## Requirements
##
## Compile with `-d:gfx` flag. Requires SDL_gfx library installed.
##
## ## See Also
##
## - `sdl/gfxprimitives` - Drawing primitives
## - `sdl/rotozoom` - Surface rotation and scaling

when defined(gfx) or defined(nimdoc):
  import private/utils

  {.push header: "SDL_imageFilter.h", importc, cdecl.}

  proc SDL_imageFilterMMXdetect(): cint
  proc SDL_imageFilterMMXoff()
  proc SDL_imageFilterMMXon()

  proc SDL_imageFilterAdd(src1, src2, dest: ptr uint8, length: cuint): cint
  proc SDL_imageFilterMean(src1, src2, dest: ptr uint8, length: cuint): cint
  proc SDL_imageFilterSub(src1, src2, dest: ptr uint8, length: cuint): cint
  proc SDL_imageFilterAbsDiff(src1, src2, dest: ptr uint8, length: cuint): cint
  proc SDL_imageFilterMult(src1, src2, dest: ptr uint8, length: cuint): cint
  proc SDL_imageFilterMultNor(src1, src2, dest: ptr uint8, length: cuint): cint
  proc SDL_imageFilterMultDivby2(src1, src2, dest: ptr uint8, length: cuint): cint
  proc SDL_imageFilterMultDivby4(src1, src2, dest: ptr uint8, length: cuint): cint
  proc SDL_imageFilterBitAnd(src1, src2, dest: ptr uint8, length: cuint): cint
  proc SDL_imageFilterBitOr(src1, src2, dest: ptr uint8, length: cuint): cint
  proc SDL_imageFilterDiv(src1, src2, dest: ptr uint8, length: cuint): cint
  proc SDL_imageFilterBitNegation(src1, dest: ptr uint8, length: cuint): cint
  proc SDL_imageFilterAddByte(src1, dest: ptr uint8, length: cuint, value: uint8): cint
  proc SDL_imageFilterAddUint(src1, dest: ptr uint8, length: cuint, value: uint32): cint
  proc SDL_imageFilterAddByteToHalf(src1, dest: ptr uint8, length: cuint, value: uint8): cint
  proc SDL_imageFilterSubByte(src1, dest: ptr uint8, length: cuint, value: uint8): cint
  proc SDL_imageFilterSubUint(src1, dest: ptr uint8, length: cuint, value: uint32): cint
  proc SDL_imageFilterShiftRight(src1, dest: ptr uint8, length: cuint, bits: uint8): cint
  proc SDL_imageFilterShiftRightUint(src1, dest: ptr uint8, length: cuint, bits: uint8): cint
  proc SDL_imageFilterMultByByte(src1, dest: ptr uint8, length: cuint, value: uint8): cint
  proc SDL_imageFilterShiftRightAndMultByByte(src1, dest: ptr uint8, length: cuint, shift: uint8, multiplier: uint8): cint
  proc SDL_imageFilterShiftLeftByte(src1, dest: ptr uint8, length: cuint, bits: uint8): cint
  proc SDL_imageFilterShiftLeftUint(src1, dest: ptr uint8, length: cuint, bits: uint8): cint
  proc SDL_imageFilterShiftLeft(src1, dest: ptr uint8, length: cuint, bits: uint8): cint
  proc SDL_imageFilterBinarizeUsingThreshold(src1, dest: ptr uint8, length: cuint, t: uint8): cint
  proc SDL_imageFilterClipToRange(src1, dest: ptr uint8, length: cuint, tMin: uint8, tMax: uint8): cint
  proc SDL_imageFilterNormalizeLinear(src, dest: ptr uint8, length: cuint, cMin, cMax, nMin, nMax: cint): cint
  proc SDL_imageFilterConvolveKernel3x3Divide(src, dest: ptr uint8, rows, columns: cint, kernel: ptr int16, divisor: uint8): cint
  proc SDL_imageFilterConvolveKernel5x5Divide(src, dest: ptr uint8, rows, columns: cint, kernel: ptr int16, divisor: uint8): cint
  proc SDL_imageFilterConvolveKernel7x7Divide(src, dest: ptr uint8, rows, columns: cint, kernel: ptr int16, divisor: uint8): cint
  proc SDL_imageFilterConvolveKernel9x9Divide(src, dest: ptr uint8, rows, columns: cint, kernel: ptr int16, divisor: uint8): cint
  proc SDL_imageFilterConvolveKernel3x3ShiftRight(src, dest: ptr uint8, rows, columns: cint, kernel: ptr int16, nRightShift: uint8): cint
  proc SDL_imageFilterConvolveKernel5x5ShiftRight(src, dest: ptr uint8, rows, columns: cint, kernel: ptr int16, nRightShift: uint8): cint
  proc SDL_imageFilterConvolveKernel7x7ShiftRight(src, dest: ptr uint8, rows, columns: cint, kernel: ptr int16, nRightShift: uint8): cint
  proc SDL_imageFilterConvolveKernel9x9ShiftRight(src, dest: ptr uint8, rows, columns: cint, kernel: ptr int16, nRightShift: uint8): cint
  proc SDL_imageFilterSobelX(src, dest: ptr uint8, rows, columns: cint): cint
  proc SDL_imageFilterSobelXShiftRight(src, dest: ptr uint8, rows, columns: cint, nRightShift: uint8): cint

  {.pop.}

  # --- Internal helper templates ---

  template sdlOp(fn: untyped; src, dest: var openArray[uint8]): bool =
    let bufLen = min(src.len, dest.len); if bufLen == 0: return false
    sdlOk fn(addr src[0], addr dest[0], cuint(bufLen))

  template sdlOp(fn: untyped; src, dest: var openArray[uint8]; args: varargs[untyped]): bool =
    let bufLen = min(src.len, dest.len); if bufLen == 0: return false
    sdlOk fn(addr src[0], addr dest[0], cuint(bufLen), args)

  template sdlOp2(fn: untyped; src1, src2, dest: var openArray[uint8]): bool =
    let bufLen = min(min(src1.len, src2.len), dest.len); if bufLen == 0: return false
    sdlOk fn(addr src1[0], addr src2[0], addr dest[0], cuint(bufLen))

  template imgOp(fn: untyped; src, dest: var openArray[uint8]; rows, columns: int; args: varargs[untyped]): bool =
    sdlOk fn(addr src[0], addr dest[0], cint(rows), cint(columns), args)

  template convCall(
      fn: untyped;
      src, dest: var openArray[uint8];
      rows, columns: int;
      kernel: openArray[int16];
      lastArg: uint8
    ): bool =
    imgOp(fn, src, dest, rows, columns, cast[ptr int16](addr kernel[0]), lastArg)

  # --- MMX control ---

  proc mmxFilterDetect*(): bool {.inline.} =
    ## Queries the CPU for MMX instruction set support.
    ## **Note:** Use this before calling MMX filter routines on
    ## unknown hardware to avoid illegal instruction faults.
    sdlNonZero SDL_imageFilterMMXdetect()

  proc mmxFilterOff*() {.inline.} =
    ## Disables MMX-accelerated filter routines.
    ## **Note:** Subsequent filter calls use C fallback implementations.
    SDL_imageFilterMMXoff()

  proc mmxFilterOn*() {.inline.} =
    ## Re-enables MMX-accelerated filter routines after `mmxFilterOff()`.
    ## **Note:** MMX is enabled by default if the CPU supports it.
    SDL_imageFilterMMXon()

  # --- Binary arithmetic (S1 op S2) ---

  proc filterAdd*(src1, src2, dest: var openArray[uint8]): bool {.inline.} =
    ## Element-wise addition of two byte buffers with saturation.
    ## **Formula:** `D = saturation255(S1 + S2)`.
    sdlOp2(SDL_imageFilterAdd, src1, src2, dest)

  proc filterMean*(src1, src2, dest: var openArray[uint8]): bool {.inline.} =
    ## Element-wise average of two buffers.
    ## **Formula:** `D = S1/2 + S2/2`.
    sdlOp2(SDL_imageFilterMean, src1, src2, dest)

  proc filterSub*(src1, src2, dest: var openArray[uint8]): bool {.inline.} =
    ## Element-wise subtraction with floor at zero.
    ## **Formula:** `D = saturation0(S1 - S2)`.
    sdlOp2(SDL_imageFilterSub, src1, src2, dest)

  proc filterAbsDiff*(src1, src2, dest: var openArray[uint8]): bool {.inline.} =
    ## Element-wise absolute difference.
    ## **Formula:** `D = |S1 — S2|`.
    sdlOp2(SDL_imageFilterAbsDiff, src1, src2, dest)

  proc filterMult*(src1, src2, dest: var openArray[uint8]): bool {.inline.} =
    ## Element-wise multiplication with saturation.
    ## **Formula:** `D = saturation255(S1 * S2)`.
    sdlOp2(SDL_imageFilterMult, src1, src2, dest)

  proc filterMultNor*(src1, src2, dest: var openArray[uint8]): bool {.inline.} =
    ## Element-wise multiplication without saturation (non-MMX, non-accelerated).
    ## **Formula:** `D = S1 * S2`.
    sdlOp2(SDL_imageFilterMultNor, src1, src2, dest)

  proc filterMultDiv2*(src1, src2, dest: var openArray[uint8]): bool {.inline.} =
    ## Element-wise multiply with divide-by-2 pre-scaling.
    ## **Formula:** `D = saturation255(S1/2 * S2)`.
    sdlOp2(SDL_imageFilterMultDivby2, src1, src2, dest)

  proc filterMultDiv4*(src1, src2, dest: var openArray[uint8]): bool {.inline.} =
    ## Element-wise multiply with divide-by-4 pre-scaling.
    ## **Formula:** `D = saturation255(S1/2 * S2/2)`.
    sdlOp2(SDL_imageFilterMultDivby4, src1, src2, dest)

  proc filterBitAnd*(src1, src2, dest: var openArray[uint8]): bool {.inline.} =
    ## Element-wise bitwise AND.
    ## **Formula:** `D = S1 & S2`.
    sdlOp2(SDL_imageFilterBitAnd, src1, src2, dest)

  proc filterBitOr*(src1, src2, dest: var openArray[uint8]): bool {.inline.} =
    ## Element-wise bitwise OR.
    ## **Formula:** `D = S1 | S2`.
    sdlOp2(SDL_imageFilterBitOr, src1, src2, dest)

  proc filterDiv*(src1, src2, dest: var openArray[uint8]): bool {.inline.} =
    ## Element-wise integer division (non-MMX, non-accelerated).
    ## **Formula:** `D = S1 / S2`.
    sdlOp2(SDL_imageFilterDiv, src1, src2, dest)

  proc filterBitNegation*(src, dest: var openArray[uint8]): bool {.inline.} =
    ## Element-wise bitwise NOT.
    ## **Formula:** `D = ~S`.
    sdlOp(SDL_imageFilterBitNegation, src, dest)

  # --- Scalar operations (S op C) ---

  proc filterAddByte*(src, dest: var openArray[uint8]; value: uint8): bool {.inline.} =
    ## Adds a constant byte to all elements with saturation.
    ## **Formula:** `D = saturation255(S + C)`.
    sdlOp(SDL_imageFilterAddByte, src, dest, value)

  proc filterAddUint*(src, dest: var openArray[uint8]; value: uint32): bool {.inline.} =
    ## Adds a constant 32-bit value re-interpreted as four bytes.
    ## **Formula:** `D = saturation255(S + C)`.
    sdlOp(SDL_imageFilterAddUint, src, dest, value)

  proc filterAddByteToHalf*(src, dest: var openArray[uint8]; value: uint8): bool {.inline.} =
    ## Adds a constant to half of each element with saturation.
    ## **Formula:** `D = saturation255(S/2 + C)`.
    sdlOp(SDL_imageFilterAddByteToHalf, src, dest, value)

  proc filterSubByte*(src, dest: var openArray[uint8]; value: uint8): bool {.inline.} =
    ## Subtracts a constant byte from all elements with floor at zero.
    ## **Formula:** `D = saturation0(S — C)`.
    sdlOp(SDL_imageFilterSubByte, src, dest, value)

  proc filterSubUint*(src, dest: var openArray[uint8]; value: uint32): bool {.inline.} =
    ## Subtracts a constant 32-bit value re-interpreted as four bytes.
    ## **Formula:** `D = saturation0(S — C)`.
    sdlOp(SDL_imageFilterSubUint, src, dest, value)

  # --- Bit shifts ---

  proc filterShiftRight*(src, dest: var openArray[uint8]; bits: uint8): bool {.inline.} =
    ## Right shift with saturation (floor at zero).
    ## **Formula:** `D = saturation0(S >> N)`.
    sdlOp(SDL_imageFilterShiftRight, src, dest, bits)

  proc filterShiftRightUint*(src, dest: var openArray[uint8]; bits: uint8): bool {.inline.} =
    ## Right shift treating bytes as a 32-bit word.
    ## **Formula:** `D = saturation0((uint32)S >> N)`.
    sdlOp(SDL_imageFilterShiftRightUint, src, dest, bits)

  proc filterShiftLeft*(src, dest: var openArray[uint8]; bits: uint8): bool {.inline.} =
    ## Left shift with saturation (cap at 255).
    ## **Formula:** `D = saturation255(S << N)`.
    sdlOp(SDL_imageFilterShiftLeft, src, dest, bits)

  proc filterMultByByte*(src, dest: var openArray[uint8]; value: uint8): bool {.inline.} =
    ## Multiplies all elements by a constant byte with saturation.
    ## **Formula:** `D = saturation255(S * C)`.
    sdlOp(SDL_imageFilterMultByByte, src, dest, value)

  proc filterShiftRightAndMultByByte*(src, dest: var openArray[uint8]; shift, multiplier: uint8): bool {.inline.} =
    ## Right shift then multiply by constant.
    ## **Formula:** `D = saturation255((S >> N) * C)`.
    sdlOp(SDL_imageFilterShiftRightAndMultByByte, src, dest, shift, multiplier)

  proc filterShiftLeftByte*(src, dest: var openArray[uint8]; bits: uint8): bool {.inline.} =
    ## Left shift (byte-level, same as `filterShiftLeft`).
    ## **Formula:** `D = saturation255(S << N)`.
    sdlOp(SDL_imageFilterShiftLeftByte, src, dest, bits)

  proc filterShiftLeftUint*(src, dest: var openArray[uint8]; bits: uint8): bool {.inline.} =
    ## Left shift treating bytes as a 32-bit word.
    ## **Formula:** `D = saturation255((uint32)S << N)`.
    sdlOp(SDL_imageFilterShiftLeftUint, src, dest, bits)

  # --- Threshold / Normalization ---

  proc filterBinarize*(src, dest: var openArray[uint8]; threshold: uint8): bool {.inline.} =
    ## Binarizes the buffer at a given threshold.
    ## **Formula:** `D = S >= T ? 255 : 0`.
    sdlOp(SDL_imageFilterBinarizeUsingThreshold, src, dest, threshold)

  proc filterClipToRange*(
      src, dest: var openArray[uint8];
      thresholdMin, thresholdMax: uint8
    ): bool {.inline.} =
    ## Clips values to 0 outside the range [thresholdMin, thresholdMax], 255 inside.
    ## **Formula:** `D = (S >= thresholdMin and S <= thresholdMax) ? 255 : 0`.
    sdlOp(SDL_imageFilterClipToRange, src, dest, thresholdMin, thresholdMax)

  proc filterNormalizeLinear*(
      src, dest: var openArray[uint8];
      currentMin, currentMax: int;
      newMin, newMax: int
    ): bool {.inline.} =
    ## Linear contrast stretch from [`currentMin`, `currentMax`] to [`newMin`, `newMax`].
    sdlOp(SDL_imageFilterNormalizeLinear, src, dest, cint(currentMin), cint(currentMax), cint(newMin), cint(newMax))

  # --- Convolution kernels ---

  proc filterConvolve3x3*(
      src, dest: var openArray[uint8];
      kernel: openArray[int16];
      rows, columns: int;
      divisor: uint8
    ): bool {.inline.} =
    ## 3x3 convolution with integer division. No C fallback; requires MMX.
    ##
    ## **Note:** `kernel` must have at least 9 elements. The convolution is
    ## boundary-terminated (no edge handling). Use `divisor` to normalize
    ## (e.g., divisor = sum of kernel weights).
    if kernel.len < 9: return false
    convCall(SDL_imageFilterConvolveKernel3x3Divide, src, dest, rows, columns, kernel, divisor)

  proc filterConvolve5x5*(
      src, dest: var openArray[uint8];
      kernel: openArray[int16];
      rows, columns: int;
      divisor: uint8
    ): bool {.inline.} =
    ## 5x5 convolution with integer division. No C fallback; requires MMX.
    ##
    ## **Note:** `kernel` must have at least 25 elements.
    if kernel.len < 25: return false
    convCall(SDL_imageFilterConvolveKernel5x5Divide, src, dest, rows, columns, kernel, divisor)

  proc filterConvolve7x7*(
      src, dest: var openArray[uint8];
      kernel: openArray[int16];
      rows, columns: int;
      divisor: uint8
    ): bool {.inline.} =
    ## 7x7 convolution with integer division. No C fallback; requires MMX.
    ##
    ## **Note:** `kernel` must have at least 49 elements.
    if kernel.len < 49: return false
    convCall(SDL_imageFilterConvolveKernel7x7Divide, src, dest, rows, columns, kernel, divisor)

  proc filterConvolve9x9*(
      src, dest: var openArray[uint8];
      kernel: openArray[int16];
      rows, columns: int;
      divisor: uint8
    ): bool {.inline.} =
    ## 9x9 convolution with integer division. No C fallback; requires MMX.
    ##
    ## **Note:** `kernel` must have at least 81 elements.
    if kernel.len < 81: return false
    convCall(SDL_imageFilterConvolveKernel9x9Divide, src, dest, rows, columns, kernel, divisor)

  proc filterConvolve3x3ShiftRight*(
      src, dest: var openArray[uint8];
      kernel: openArray[int16];
      rows, columns: int;
      rightShift: uint8
    ): bool {.inline.} =
    ## 3x3 convolution using arithmetic shift-right instead of division.
    ## No C fallback; requires MMX.
    ##
    ## **Note:** Shift-right is faster than division for power-of-two normalization.
    if kernel.len < 9: return false
    convCall(SDL_imageFilterConvolveKernel3x3ShiftRight, src, dest, rows, columns, kernel, rightShift)

  proc filterConvolve5x5ShiftRight*(
      src, dest: var openArray[uint8];
      kernel: openArray[int16];
      rows, columns: int;
      rightShift: uint8
    ): bool {.inline.} =
    ## 5x5 convolution using arithmetic shift-right. No C fallback; requires MMX.
    if kernel.len < 25: return false
    convCall(SDL_imageFilterConvolveKernel5x5ShiftRight, src, dest, rows, columns, kernel, rightShift)

  proc filterConvolve7x7ShiftRight*(
      src, dest: var openArray[uint8];
      kernel: openArray[int16];
      rows, columns: int;
      rightShift: uint8
    ): bool {.inline.} =
    ## 7x7 convolution using arithmetic shift-right. No C fallback; requires MMX.
    if kernel.len < 49: return false
    convCall(SDL_imageFilterConvolveKernel7x7ShiftRight, src, dest, rows, columns, kernel, rightShift)

  proc filterConvolve9x9ShiftRight*(
      src, dest: var openArray[uint8];
      kernel: openArray[int16];
      rows, columns: int;
      rightShift: uint8
    ): bool {.inline.} =
    ## 9x9 convolution using arithmetic shift-right. No C fallback; requires MMX.
    if kernel.len < 81: return false
    convCall(SDL_imageFilterConvolveKernel9x9ShiftRight, src, dest, rows, columns, kernel, rightShift)

  # --- Edge detection ---

  proc filterSobelX*(
      src, dest: var openArray[uint8];
      rows, columns: int
    ): bool {.inline.} =
    ## Sobel X (horizontal) edge detection. No C fallback; requires MMX.
    ##
    ## **Note:** Emphasises vertical edges in the input image.
    imgOp(SDL_imageFilterSobelX, src, dest, rows, columns)

  proc filterSobelXShiftRight*(
      src, dest: var openArray[uint8];
      rows, columns: int;
      rightShift: uint8
    ): bool {.inline.} =
    ## Sobel X edge detection with arithmetic shift-right. No C fallback; requires MMX.
    ##
    ## **Note:** Use `rightShift` to control output intensity
    ## (higher shift = darker edges).
    imgOp(SDL_imageFilterSobelXShiftRight, src, dest, rows, columns, rightShift)
else:
  {.fatal: "sdl/gfxfilter requires -d:gfx compile flag (SDL_gfx library)".}
