## # sdl/audio
##
## Audio subsystem for SDL 1.2
##
## This module provides audio playback, mixing, and format conversion capabilities.
## Audio in SDL 1.2 is callback-driven: you open the audio device with a desired
## format, and SDL invokes your callback whenever it needs more samples to feed
## the sound card.
##
## ## SDL 1.2 Reference
##
## Audio in SDL 1.2 follows a push model with two modes:
## - **Callback mode** (most common): SDL calls your function on a background thread
##   when it needs more samples.
## - **Queue mode** (`SDL_QueueAudio`, not available in SDL 1.2 natively).
##
## **Key C functions:**
## ```c
## int SDL_OpenAudio(SDL_AudioSpec *desired, SDL_AudioSpec *obtained);
## void SDL_CloseAudio(void);
## void SDL_PauseAudio(int pause_on);
## void SDL_MixAudio(Uint8 *dst, const Uint8 *src, Uint32 len, int volume);
## ```
##
## ## Usage Example
##
## ```nim
## import sdl
##
## proc audioCallback(userdata: pointer, stream: AudioBuffer, len: cint) {.cdecl.} =
##   # Fill the stream with audio samples here
##   discard
##
## runMain:
##   let ctx = sdlInit(sdlInitAudio)
##   defer: ctx.quit()
##
##   initAudio()
##
##   let desired = initAudioSpec(
##     freq = 44100'u32,
##     channels = 2'u8,
##     samples = 1024'u16,
##     format = s16Lsb,
##     callback = audioCallback
##   )
##   let obtained = openAudio(desired)
##   if obtained.isSome:
##     pauseAudio(false)  # Start audio playback
##     # ... game loop ...
##     closeAudio()
## ```
##
## ## Advantages over C SDL 1.2
##
## | C SDL 1.2                              | Nim SDL                          |
## |----------------------------------------|----------------------------------|
## | `SDL_AudioSpec spec;` manual init      | `initAudioSpec(...)` builder     |
## | `SDL_FreeWAV(buffer)` manual free      | `WavData` RAII auto-free         |
## | `Uint16 format = AUDIO_S16SYS;`        | `format = s16Lsb` typed enum     |
## | No bounds checking                     | Asserts catch errors early       |
## | `SDL_MixAudio(...)` with magic numbers | `volume: range[0..128]` enforced |
## | Manual lock/unlock pairing             | `withAudioLock` template         |
##
## ## Key Concepts
##
## - **Buffer size** (`samples`) must be a power of 2 (256, 512, 1024, etc.)
## - **Volume** ranges from 0 (silence) to `mixMaxVolume` (128)
## - The audio callback runs on a **separate thread** — use `lockAudio()` /
##   `unlockAudio()` or `withAudioLock` to synchronize shared state
## - WAV loading returns a `WavData` smart pointer that frees memory automatically
##
## ## See Also
##
## - `sdl/rwops` - Required for `loadWav()` custom stream sources
## - `sdl/mixer` - Higher-level audio mixing library (requires `-d:mixer`)

import private/utils
import private/macros
import std/options
import rwops

# =========================================================
# 1. CONSTANTS AND ENUMS
# =========================================================

type
  AudioBuffer* = distinct ptr byte
    ## Type-safe wrapper around a raw byte pointer for audio data.
    ## Provides pointer arithmetic and array access operations.

proc `+`*(p: AudioBuffer, offset: int): AudioBuffer {.inline.} =
  ## Advances the buffer pointer by `offset` bytes.
  cast[AudioBuffer](cast[uint](p) + cast[uint](offset))

proc `[]`*(p: AudioBuffer, index: int): byte {.inline.} =
  ## Reads a byte at `index` from the buffer.
  cast[ptr UncheckedArray[byte]](p)[index]

proc `[]=`*(p: AudioBuffer, index: int, val: byte) {.inline.} =
  ## Writes `val` at `index` in the buffer.
  cast[ptr UncheckedArray[byte]](p)[index] = val

proc isNil*(p: AudioBuffer): bool {.inline.} =
  ## Returns `true` if the buffer pointer is null.
  cast[ptr byte](p).isNil

proc `==`*(x, y: AudioBuffer): bool {.borrow.}
  ## Compares two AudioBuffer pointers for equality.

proc `==`*(x: AudioBuffer, y: typeof(nil)): bool {.inline.} =
  ## Compares buffer with nil.
  cast[pointer](x) == nil

proc `!=`*(x: AudioBuffer, y: typeof(nil)): bool {.inline.} =
  ## Checks if buffer is not nil.
  not (x == nil)

proc reset*(p: var AudioBuffer) {.inline.} =
  ## Sets the buffer pointer to nil.
  p = cast[AudioBuffer](nil)

const
  mixMaxVolume* = 128
    ## Maximum volume value for audio mixing (0 = silence, 128 = full volume).

type
  AudioFormat* {.pure, size: sizeof(uint16).} = enum
    ## Audio sample formats supported by SDL.
    ## The format encodes bit depth, signedness, and endianness.
    u8     = 0x0008'u16  ## Unsigned 8-bit
    s8     = 0x8008'u16  ## Signed 8-bit
    u16Lsb = 0x0010'u16  ## Unsigned 16-bit (Little Endian)
    s16Lsb = 0x8010'u16  ## Signed 16-bit (Little Endian)
    u16Msb = 0x1010'u16  ## Unsigned 16-bit (Big Endian)
    s16Msb = 0x9010'u16  ## Signed 16-bit (Big Endian)

  AudioStatus* {.pure, size: sizeof(cint).} = enum
    ## Current state of the audio device.
    stopped = 0  ## Audio device is not open or closed
    playing = 1  ## Audio callback is being called
    paused  = 2  ## Audio device is open but paused

# Automatic CPU Endianness Detection
when cpuEndian == littleEndian:
  const audioU16Sys* = AudioFormat.u16Lsb
    ## Native unsigned 16-bit format for the current CPU.
  const audioS16Sys* = AudioFormat.s16Lsb
    ## Native signed 16-bit format for the current CPU.
else:
  const audioU16Sys* = AudioFormat.u16Msb
    ## Native unsigned 16-bit format for the current CPU.
  const audioS16Sys* = AudioFormat.s16Msb
    ## Native signed 16-bit format for the current CPU.

# =========================================================
# 2. STRUCTURES AND FFI
# =========================================================
{.push header: "SDL_audio.h", bycopy, cdecl.}

type
  ## The callback function signature invoked by SDL on the audio thread
  ## whenever more samples are needed.
  AudioCallback* = proc (userData: pointer, stream: AudioBuffer, length: cint) {.cdecl.}

  AudioSpec* {.importc: "SDL_AudioSpec".} = object
    ## Describes the desired audio output format.
    ## Used both for requesting audio device parameters and receiving
    ## the actual obtained parameters from the hardware.
    freq: cint               ## DSP frequency in Hz (e.g. 44100)
    format: AudioFormat      ## Audio data format
    channels: uint8          ## Number of channels (1 = Mono, 2 = Stereo)
    silence: uint8           ## Calculated silence value
    samples: uint16          ## Buffer size in samples (MUST BE A POWER OF 2!)
    padding: uint16          ## Internal alignment padding (not used by applications)
    size: uint32             ## Calculated buffer size in bytes
    callback: AudioCallback  ## Function called by SDL when more audio samples are needed
    userData {.importc: "userdata".}: pointer  ## User data passed to the callback function

  AudioConverter* {.importc: "SDL_AudioCVT".} = object
    ## Audio format conversion state machine.
    ## Created by `createAudioConverter()` to convert between different
    ## sample formats, rates, and channel counts.
    needed: cint                                      ## Non-zero if conversion is needed, 0 otherwise
    sourceFormat {.importc: "src_format".}: uint16    ## Source audio format
    targetFormat {.importc: "dst_format".}: uint16    ## Target audio format
    frequencyRatio {.importc: "rate_incr".}: cdouble  ## Sample rate ratio (target/source)
    originalLength {.importc: "len".}: cint           ## Original audio data length in bytes
    convertedLength {.importc: "len_cvt".}: cint      ## Converted audio data length in bytes
    bufferMultiplier {.importc: "len_mult".}: cint    ## Multiplier for buffer allocation (allocate originalLength * bufferMultiplier)
    conversionRatio {.importc: "len_ratio".}: cdouble ## Ratio of converted length to original length
    buffer {.importc: "buf".}: AudioBuffer            ## Audio data buffer (must be allocated before conversion)
    filters: array[10, proc (cvt: ptr AudioConverter, format: uint16) {.cdecl.}]  ## Internal filter chain (do not modify)
    filterIndex {.importc: "filter_index".}: cint     ## Current filter index (internal use)

{.pop.}

{.push header: "SDL_audio.h", importc, cdecl.}

# --- Internal FFI ---
proc SDL_AudioInit(driverName: cstring): cint
proc SDL_AudioQuit()
proc SDL_AudioDriverName(nameBuf: cstring, maxLen: cint): cstring
proc SDL_OpenAudio(desired, obtained: ptr AudioSpec): cint
proc SDL_GetAudioStatus(): AudioStatus
proc SDL_PauseAudio(pauseOn: cint)
proc SDL_LoadWAV_RW(src: RawRWopsPtr, freeSrc: cint, spec: ptr AudioSpec, audioBuf: ptr ptr uint8, audioLen: ptr uint32): ptr AudioSpec
proc SDL_FreeWAV(audioBuf: AudioBuffer)
proc SDL_BuildAudioCVT(cvt: ptr AudioConverter, srcFormat: uint16, srcChannels: uint8, srcRate: cint, dstFormat: uint16, dstChannels: uint8, dstRate: cint): cint
proc SDL_ConvertAudio(cvt: ptr AudioConverter): cint
proc SDL_MixAudio(dst: AudioBuffer, src: AudioBuffer, length: uint32, volume: cint)
proc SDL_LockAudio()
proc SDL_UnlockAudio()
proc SDL_CloseAudio()

{.pop.}

# =========================================================
# 3. SMART POINTER
# =========================================================

type WavData* {.requiresInit.} = object
  ## RAII wrapper for WAV audio file data.
  ## Automatically frees the SDL-allocated audio buffer when it goes out of scope.
  ## Contains both the audio specification (format, frequency, channels) and
  ## the raw PCM audio data.
  spec*: AudioSpec
  raw: AudioBuffer
  length*: uint32

proc `=destroy`*(w: var WavData) =
  ## Automatically frees the SDL-allocated audio buffer when WavData goes out of scope.
  destroyImpl(w, SDL_FreeWAV)

proc `=sink`*(dest: var WavData; source: WavData) =
  ## Move semantics: transfers ownership of the audio buffer without copying.
  sinkImpl(dest, source)

proc `=copy`*(dest: var WavData; source: WavData) {.error.}
  ## Copying is disabled to prevent double-free errors. Use move() instead.

proc unsafeBuffer*(w: WavData): AudioBuffer {.inline.} =
  ## Returns the raw audio buffer pointer. Only valid while `w` is in scope.
  w.raw

# =========================================================
# 4. PUBLIC API (Playback and Mixing)
# =========================================================

# =========================================================
# AUDIO SPEC FACTORY
# =========================================================

proc initAudioSpec*(
    freq: uint32;
    channels: uint8;
    samples: uint16;
    format: AudioFormat;
    callback: AudioCallback;
    userData: pointer = nil
  ): AudioSpec =
  ## Builds an audio specification request to send to the OS.
  ## The `samples` parameter must be a power of 2 (e.g. 256, 512, 1024).
  ##
  ## **Example:**
  ## ```nim
  ## var spec = initAudioSpec(
  ##   freq = 44100'u32,
  ##   channels = 2'u8,
  ##   samples = 1024'u16,
  ##   format = s16Lsb,
  ##   callback = myAudioCallback
  ## )
  ## ```
  assert freq > 0,
    "Error: Audio frequency (freq) must be greater than zero (e.g. 22050, 44100)."
  assert channels in 1'u8 .. 2'u8,
    "Error: Only 1 (Mono) or 2 (Stereo) channels are supported."
  assert samples > 0 and (samples and (samples - 1'u16)) == 0'u16,
    "Fatal Error: Buffer size (samples) MUST be an exact power of 2! (e.g. 256, 512, 1024, 2048)."

  result.freq = cint(freq)
  result.format = format
  result.channels = channels
  result.samples = samples
  result.callback = callback
  result.userData = userData

proc initAudioSpec*(
    freq: cint;
    channels: uint8;
    samples: uint16;
    format: AudioFormat;
  ): AudioSpec =
  ## Builds an audio specification request without callback (for obtaining format info).
  ## The `samples` parameter must be a power of 2.
  ##
  ## **Example:**
  ## ```nim
  ## var spec = initAudioSpec(22050.cint, 1'u8, 512'u16, AudioFormat.u8)
  ## ```
  result.freq = cint(freq)
  result.format = format
  result.channels = channels
  result.samples = samples

# =========================================================
# GETTERS (Read-Only Access)
# =========================================================

# --- AudioSpec Getters ---

proc freq*(a: AudioSpec): int32 {.inline.} =
  ## DSP frequency in Hz (e.g. 44100).
  int32(a.freq)

proc format*(a: AudioSpec): AudioFormat {.inline.} =
  ## Audio data format (e.g. `s16Lsb`, `u8`).
  a.format

proc channels*(a: AudioSpec): uint8 {.inline.} =
  ## Number of audio channels (1 = Mono, 2 = Stereo).
  a.channels

proc silence*(a: AudioSpec): uint8 {.inline.} =
  ## Calculated silence value (0 for signed formats, 128 for unsigned).
  a.silence

proc samples*(a: AudioSpec): uint16 {.inline.} =
  ## Buffer size in samples (always a power of 2).
  a.samples

proc size*(a: AudioSpec): uint32 {.inline.} =
  ## Calculated buffer size in bytes.
  a.size

proc userData*(a: AudioSpec): pointer {.inline.} =
  ## User data pointer passed to the audio callback.
  a.userData

# --- AudioConverter Getters ---

proc needed*(c: AudioConverter): bool {.inline.} =
  ## Whether audio conversion is needed between source and target formats.
  (c.needed != 0)

proc sourceFormat*(c: AudioConverter): uint16 {.inline.} =
  ## Source audio format.
  c.sourceFormat

proc targetFormat*(c: AudioConverter): uint16 {.inline.} =
  ## Target audio format.
  c.targetFormat

proc frequencyRatio*(c: AudioConverter): float64 {.inline.} =
  ## Frequency ratio between source and target.
  float64(c.frequencyRatio)

proc originalLength*(c: AudioConverter): int32 {.inline.} =
  ## Original audio data length in bytes.
  int32(c.originalLength)

proc convertedLength*(c: AudioConverter): int32 {.inline.} =
  ## Converted audio data length in bytes.
  int32(c.convertedLength)

proc bufferMultiplier*(c: AudioConverter): int32 {.inline.} =
  ## Buffer size multiplier for allocation.
  int32(c.bufferMultiplier)

proc conversionRatio*(c: AudioConverter): float64 {.inline.} =
  ## Size ratio between converted and original data.
  float64(c.conversionRatio)

proc buffer*(c: AudioConverter): AudioBuffer {.inline.} =
  ## Audio data buffer.
  c.buffer

proc `buffer=`*(c: var AudioConverter, buf: AudioBuffer) {.inline.} =
  ## Sets the memory pointer where audio data resides for in-place conversion.
  c.buffer = buf

proc `length=`*(c: var AudioConverter, len: int32) {.inline.} =
  ## Sets the byte length of the original audio data to be converted.
  c.originalLength = cint(len)

# ---------------------------------------------------------
# INITIALIZATION, DRIVERS AND STATUS
# ---------------------------------------------------------

proc initAudio*(driverName: string = "") {.inline.} =
  ## Initializes the audio subsystem with the specified driver.
  ## Terminates the program on failure. Pass empty string for default driver.
  ##
  ## **Example:**
  ## ```nim
  ## initAudio()             # Use default driver
  ## initAudio("pulseaudio") # Use PulseAudio
  ## ```
  let d = if driverName == "": nil else: driverName.cstring
  discard sdlCheck SDL_AudioInit(d)

proc quitAudio*() {.inline.} =
  ## Shuts down only the audio subsystem.
  ##
  ## **Example:**
  ## ```nim
  ## # Shut down audio while keeping other subsystems active
  ## quitAudio()
  ## ```
  ##
  ## **Note:** Use `ctx.quit()` from `sdlInit()` to shut down all subsystems.
  SDL_AudioQuit()

proc audioDriverName*(): Option[cstring] {.inline.} =
  ## Returns the name of the current audio driver, or `none` if no driver is active.
  ##
  ## **Warning:** Uses a single `{.global.}` buffer (64 bytes) shared across all
  ## calls. The returned `cstring` is valid until the next call. Not thread-safe.
  ## Typically called once during initialization.
  ##
  ## **Example:**
  ## ```nim
  ## let name = audioDriverName()
  ## if name.isSome:
  ##   echo "Audio driver: ", name.get
  ## ```
  var buf {.global.}: array[64, char]
  SDL_AudioDriverName(buf.cBuf, buf.cLen).toOption()

proc openAudio*(desired: AudioSpec): Option[AudioSpec] {.inline.} =
  ## Opens the audio device and returns the actual format obtained by the hardware.
  ## Returns `none` on failure.
  ##
  ## **Example:**
  ## ```nim
  ## let desired = initAudioSpec(44100, 2'u8, 1024'u16, s16Lsb, myCallback)
  ## let obtained = openAudio(desired)
  ## if obtained.isSome:
  ##   echo "Opened at ", obtained.get.freq(), " Hz"
  ## ```
  ##
  ## **Warning:** The obtained format may differ from desired if the hardware
  ## doesn't support the requested format. Always check the returned spec.
  var obtained: AudioSpec
  if sdlOk SDL_OpenAudio(unsafeAddr desired, addr obtained):
    result = some(obtained)

proc closeAudio*() {.inline.} =
  ## Closes the audio device and stops audio processing.
  ##
  ## **Example:**
  ## ```nim
  ## # After finishing with audio
  ## closeAudio()
  ## ```
  ##
  ## **Note:** Audio callbacks will no longer be invoked after this call.
  SDL_CloseAudio()

proc audioStatus*(): AudioStatus {.inline.} =
  ## Returns the current audio processing status: `stopped`, `playing`, or `paused`.
  ##
  ## **Example:**
  ## ```nim
  ## case audioStatus()
  ## of playing: echo "Audio is playing"
  ## of paused: echo "Audio is paused"
  ## of stopped: echo "Audio is stopped"
  ## ```
  SDL_GetAudioStatus()

proc pauseAudio*(pause: bool) {.inline.} =
  ## Pauses (`true`) or resumes (`false`) audio callback processing.
  ##
  ## **Example:**
  ## ```nim
  ## pauseAudio(false)  # Resume/start audio playback
  ## pauseAudio(true)   # Pause audio playback
  ## ```
  SDL_PauseAudio(cint(pause))

# ---------------------------------------------------------
# SYNCHRONIZATION (IMPORTANT)
# ---------------------------------------------------------

proc lockAudio*() {.inline.} =
  ## Locks the audio callback to prevent race conditions when accessing shared
  ## state between the main thread and audio thread. Always pair with `unlockAudio()`.
  ##
  ## **Example:**
  ## ```nim
  ## lockAudio()
  ## sharedData.modify()  # Safe to modify shared state
  ## unlockAudio()
  ## ```
  ##
  ## **Note:** Consider using `withAudioLock` template instead for automatic unlock.
  SDL_LockAudio()

proc unlockAudio*() {.inline.} =
  ## Unlocks the audio callback after a `lockAudio()` call.
  ##
  ## **Example:**
  ## ```nim
  ## lockAudio()
  ## sharedData.modify()
  ## unlockAudio()  # Always unlock after locking
  ## ```
  SDL_UnlockAudio()

template withAudioLock*(body: untyped) =
  ## Executes a block with the audio callback locked. Guarantees unlock even if
  ## exceptions occur. Preferred over manual lock/unlock.
  ##
  ## **Example:**
  ## ```nim
  ## withAudioLock:
  ##   sharedData.modify()
  ## ```
  lockAudio()
  defer: unlockAudio()
  body

# ---------------------------------------------------------
# LOADING AND MIXING
# ---------------------------------------------------------

proc loadWav*(stream: var RWops): Option[WavData] =
  ## Loads a WAV audio file from a RWops stream. The returned `WavData` is an
  ## RAII wrapper that automatically frees the SDL-allocated buffer when it goes
  ## out of scope.
  ##
  ## **Example:**
  ## ```nim
  ## var stream = rwFromFile("sound.wav", "rb")
  ## let wavData = loadWav(stream)
  ## if wavData.isSome:
  ##   echo "Loaded ", wavData.get.length, " bytes"
  ## ```
  var spec: AudioSpec
  var bufPtr: ptr byte # SDL requires a raw pointer to fill
  var length: uint32

  # FFI call: We pass 0 for 'freeSrc' because RWops manages the file handle
  let res = SDL_LoadWAV_RW(stream.unsafeRaw(), 0,
    addr spec,
    addr bufPtr,
    addr length
  )

  if res.isNil:
    none(WavData)
  else:
    some(WavData(
      spec: spec,
      raw: cast[AudioBuffer](bufPtr),
      length: length
    ))

proc mixAudio*(
    target, source: AudioBuffer;
    length: uint32;
    volume: range[0 .. mixMaxVolume] = mixMaxVolume
  ) {.inline.} =
  ## Mixes raw PCM audio from `source` into `target` buffer. The `length` must be
  ## the size in **bytes** (not samples). Volume ranges from 0 (silence) to 128
  ## (`mixMaxVolume`, full volume).
  ##
  ## **Example:**
  ## ```nim
  ## # Mix a sound effect into the output buffer at half volume
  ## mixAudio(outputBuffer, soundBuffer, soundLength, 64)
  ## ```

  # Safety guards (zero cost in release builds)
  assert not target.isNil, "Attempted to mix into a nil target AudioBuffer."
  assert not source.isNil, "Attempted to mix from a nil source AudioBuffer."

  # Short-circuit optimization
  # Nothing to do if length is zero or volume is silence.
  if length == 0 or volume == 0: return

  # FFI execution
  SDL_MixAudio(target, source, length, cint(volume))

# ---------------------------------------------------------
# FORMAT CONVERSION
# ---------------------------------------------------------

proc createAudioConverter*(source, target: AudioSpec): Option[AudioConverter] {.inline.} =
  ## Builds a conversion state machine between two audio formats.
  ## Returns `none` if SDL cannot convert between these formats.
  ##
  ## **Example:**
  ## ```nim
  ## let converter = createAudioConverter(sourceSpec, targetSpec)
  ## if converter.isSome:
  ##   var c = converter.get
  ##   if c.needed:
  ##     # Allocate buffer and convert
  ## ```
  var c: AudioConverter

  let res = SDL_BuildAudioCVT(
    addr c,
    uint16(source.format), source.channels, cint(source.freq),
    uint16(target.format), target.channels, cint(target.freq)
  )

  # res == -1 (Error)
  # res == 0 (Success, but needed = false)
  # res == 1 (Success, and needed = true)
  if res < 0: none(AudioConverter)
  else: some(c)

proc convertAudio*(c: var AudioConverter): bool {.inline.} =
  ## Executes the audio data transformation in-place on the buffer.
  ## The `buffer` field must point to already allocated memory with size
  ## `originalLength * bufferMultiplier`.
  ##
  ## **Example:**
  ## ```nim
  ## var converter = createAudioConverter(source, target).get
  ## if converter.needed:
  ##   let bufSize = converter.originalLength * converter.bufferMultiplier
  ##   converter.buffer = allocateBuffer(bufSize)
  ##   converter.length = originalLength
  ##   if converter.convertAudio():
  ##     echo "Converted to ", converter.convertedLength, " bytes"
  ## ```

  assert c.needed(),
    "Logic Error: Attempted to convert audio when 'needed' is false. " &
    "Always check 'if converter.needed:' before processing."

  assert not c.buffer.isNil,
    "Memory Error: AudioConverter buffer is null! Allocate memory first."

  assert c.originalLength > 0,
    "Data Error: 'originalLength' must be set before conversion."

  sdlOk SDL_ConvertAudio(addr c)
