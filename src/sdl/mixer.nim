## # sdl/mixer
##
## Audio mixing and music playback using SDL_mixer
##
## This module provides high-level audio mixing capabilities through the SDL_mixer library.
## It supports multiple simultaneous sound effects (chunks), background music, fading,
## and 3D positional audio.
##
## ## SDL 1.2 Reference
##
## SDL_mixer extends SDL 1.2 with audio mixing, supporting multiple formats like WAV, MP3,
## OGG, FLAC, and MOD. It provides 8 mixing channels by default (configurable).
##
## **Key C functions:**
## ```c
## int Mix_Init(int flags);
## int Mix_OpenAudio(int frequency, Uint16 format, int channels, int chunksize);
## Mix_Chunk *Mix_LoadWAV_RW(SDL_RWops *src, int freesrc);
## int Mix_PlayChannelTimed(int channel, Mix_Chunk *chunk, int loops, int ticks);
## ```
##
## ## Usage Example
##
## ```nim
## import sdl
##
## runMain:
##   let ctx = sdlInit(sdlInitAudio)
##   defer: ctx.quit()
##
##   initMixer(mp3)
##   defer: quitMixer()
##
##   openAudio(44100'u32, s16Lsb, 2'u8, 1024)
##
##   # Load and play a sound effect
##   let explosion = loadWav("explosion.wav")
##   if explosion.isSome:
##     discard explosion.get.play()
##
##   # Load and play background music
##   let music = loadMus("theme.mp3")
##   if music.isSome:
##     discard music.get.play(loops = -1)  # Loop forever
##
##   # Main loop
##   var running = true
##   while running:
##     for event in pollEvents():
##       if event.kind == quit:
##         running = false
## ```
##
## ## Advantages over C SDL_mixer
##
## | C SDL_mixer                    | Nim SDL                        |
## |--------------------------------|--------------------------------|
## | `Mix_Chunk *chunk` manual free | `Chunk` RAII auto-free         |
## | `Mix_Music *music` manual free | `Music` RAII auto-free         |
## | Magic numbers for loops        | `infiniteLoops` constant       |
## | Integer return codes           | `Option[T]` for error handling |
##
## ## Requirements
##
## Compile with `-d:mixer` flag. Requires SDL_mixer library installed.
##
## ## See Also
##
## - `sdl/audio` - Core SDL audio subsystem
## - `sdl/rwops` - File I/O abstraction

when defined(mixer):
  import audio
  import rwops
  import version
  import std/options
  import private/utils
  import private/macros

  type
    AudioChannel* = distinct cint
      ## A mixing channel identifier (0 to 7 by default, or -1 for any/all).

    AudioGroup* = distinct cint
      ## A group of audio channels for batch operations (-1 for no group).

    Volume* = range[0 .. mixMaxVolume]
      ## Audio volume level ranging from 0 (silent) to 128 (max).

  proc `==`*(x, y: AudioChannel): bool {.borrow.}
    ## Compares two AudioChannel values for equality.

  proc `==`*(x, y: AudioGroup): bool {.borrow.}
    ## Compares two AudioGroup values for equality.

  proc `$`*(x: AudioChannel): string {.borrow.}
    ## Converts an AudioChannel to its string representation.

  proc `$`*(x: AudioGroup): string {.borrow.}
    ## Converts an AudioGroup to its string representation.

  converter toAudioChannel*(x: range[-2 .. 256]): AudioChannel = AudioChannel(x)
    ## Implicitly converts an integer to AudioChannel for convenience.

  converter toAudioGroup*(x: range[-1 .. 65535]): AudioGroup = AudioGroup(x)
    ## Implicitly converts an integer to AudioGroup for convenience.

  const
    mixChannels* = 8
      ## Default number of mixing channels.

    mixDefaultFrequency* = 22050
      ## Default audio sample rate in Hz.

    mixDefaultFormat* = audioS16Sys
      ## Default audio sample format (signed 16-bit, system byte order).

    mixDefaultChannels* = 2
      ## Default number of audio channels (stereo).

    mixMaxVolume* = 128
      ## Maximum volume level.

    infiniteLoops* = -1
      ## Pass to `play()` to loop a sound or music forever.

    noTimeout* = -1
      ## Pass to `play()` to disable playback timeout.

    defaultFadeMs* = 1000
      ## Default fade duration in milliseconds.

    anyChannel* = AudioChannel(-1)
      ## Refers to the first available channel.

    allChannels* = AudioChannel(-1)
      ## Refers to all channels simultaneously.

    mixChannelPost* = AudioChannel(-2)
      ## Special channel for post-mix effects.

    noGroup* = AudioGroup(-1)
      ## No group assigned.

    anyGroup* = AudioGroup(-1)
      ## Any group available.

  {.push header: "SDL_mixer.h", bycopy, cdecl.}

  type
    MixInitFlag* {.importc: "MIX_InitFlags", pure, size: sizeof(cint).} = enum
      ## Flags for initializing SDL_mixer audio format support.
      flac       = 0x00000001  ## FLAC format support
      modType    = 0x00000002  ## MOD format support
      mp3        = 0x00000004  ## MP3 format support
      ogg        = 0x00000008  ## OGG Vorbis format support
      fluidSynth = 0x00000010  ## FluidSynth MIDI support

    MixFading* {.importc: "Mix_Fading", pure, size: sizeof(cint).} = enum
      ## Fade state of a channel or music stream.
      noFading = 0 ## Not currently fading
      fadingOut    ## Currently fading out
      fadingIn     ## Currently fading in

    MixMusicType* {.importc: "Mix_MusicType", pure, size: sizeof(cint).} = enum
      ## Identifies the format of a loaded music file.
      none = 0   ## No music loaded / unknown format
      cmd        ## Command-based music
      wav        ## WAV file
      modType    ## MOD tracker file
      midi       ## MIDI file
      ogg        ## OGG Vorbis file
      mp3        ## MP3 file
      mp3Mad     ## MP3 via libmad
      flac       ## FLAC file
      modPlug    ## MOD via libmodplug

    MixFunc* = proc(udata: pointer, stream: AudioBuffer, len: cint) {.cdecl.}
      ## Callback for custom audio mixing.

    MusicFinishedFunc* = proc() {.cdecl.}
      ## Callback invoked when music playback finishes.

    ChannelFinishedFunc* = proc(channel: cint) {.cdecl.}
      ## Callback invoked when a channel finishes playback.

    EffectFunc* = proc(chan: cint, stream: AudioBuffer, len: cint, udata: pointer) {.cdecl.}
      ## Callback for applying audio effects to a channel.

    EffectDoneFunc* = proc(chan: cint, udata: pointer) {.cdecl.}
      ## Callback invoked when an effect is removed from a channel.

    SoundFontIterFunc* = proc(path: cstring, data: pointer): cint {.cdecl.}
      ## Callback for iterating SoundFont paths.

    RawChunk {.importc: "Mix_Chunk"} = object
      allocated: cint
      abuf: AudioBuffer
      alen: uint32
      volume: uint8
    RawChunkPtr* = ptr RawChunk
      ## Pointer to the underlying `Mix_Chunk` C struct.

    RawMusic {.importc: "Mix_Music", incompleteStruct.} = object
    RawMusicPtr* = ptr RawMusic
      ## Pointer to the underlying `Mix_Music` C struct.

  {.pop.}

  {.push header: "SDL_mixer.h", importc, cdecl.}

  proc Mix_Linked_Version(): ptr Version
  proc Mix_Init(flags: cint): cint {.importc.}
  proc Mix_Quit() {.importc.}
  proc Mix_OpenAudio(frequency: cint, format: uint16, channels: cint, chunksize: cint): cint {.importc.}
  proc Mix_CloseAudio() {.importc.}
  proc Mix_AllocateChannels(numchans: cint): cint {.importc.}
  proc Mix_QuerySpec(frequency: ptr cint, format: ptr uint16, channels: ptr cint): cint {.importc.}

  proc Mix_GetNumChunkDecoders(): cint {.importc.}
  proc Mix_GetChunkDecoder(index: cint): cstring {.importc.}
  proc Mix_GetNumMusicDecoders(): cint {.importc.}
  proc Mix_GetMusicDecoder(index: cint): cstring {.importc.}
  proc Mix_GetMusicType(music: RawMusicPtr): MixMusicType {.importc.}

  proc Mix_LoadWAV_RW(src: RawRWopsPtr, freesrc: cint): RawChunkPtr {.importc.}
  proc Mix_LoadMUS(file: cstring): RawMusicPtr {.importc.}
  proc Mix_LoadMUS_RW(rw: RawRWopsPtr, freesrc: cint): RawMusicPtr {.importc.}
  proc Mix_LoadMUSType_RW(rw: RawRWopsPtr, mtype: MixMusicType, freesrc: cint): RawMusicPtr {.importc.}
  proc Mix_QuickLoad_WAV(mem: AudioBuffer): RawChunkPtr {.importc.}
  proc Mix_QuickLoad_RAW(mem: AudioBuffer, len: uint32): RawChunkPtr {.importc.}
  proc Mix_FreeChunk(chunk: RawChunkPtr) {.importc.}
  proc Mix_FreeMusic(music: RawMusicPtr) {.importc.}

  proc Mix_PlayChannelTimed(channel: cint, chunk: RawChunkPtr, loops: cint, ticks: cint): cint {.importc.}
  proc Mix_FadeInChannelTimed(channel: cint, chunk: RawChunkPtr, loops: cint, ms: cint, ticks: cint): cint {.importc.}
  proc Mix_Volume(channel: cint, volume: cint): cint {.importc.}
  proc Mix_VolumeChunk(chunk: RawChunkPtr, volume: cint): cint {.importc.}
  proc Mix_HaltChannel(channel: cint): cint {.importc.}
  proc Mix_ExpireChannel(channel: cint, ticks: cint): cint {.importc.}
  proc Mix_FadeOutChannel(which: cint, ms: cint): cint {.importc.}
  proc Mix_FadingChannel(which: cint): MixFading {.importc.}
  proc Mix_Pause(channel: cint) {.importc.}
  proc Mix_Resume(channel: cint) {.importc.}
  proc Mix_Paused(channel: cint): cint {.importc.}
  proc Mix_Playing(channel: cint): cint {.importc.}

  proc Mix_PlayMusic(music: RawMusicPtr, loops: cint): cint {.importc.}
  proc Mix_FadeInMusic(music: RawMusicPtr, loops: cint, ms: cint): cint {.importc.}
  proc Mix_FadeInMusicPos(music: RawMusicPtr, loops: cint, ms: cint, position: float64): cint {.importc.}
  proc Mix_VolumeMusic(volume: cint): cint {.importc.}
  proc Mix_HaltMusic(): cint {.importc.}
  proc Mix_FadeOutMusic(ms: cint): cint {.importc.}
  proc Mix_FadingMusic(): MixFading {.importc.}
  proc Mix_PauseMusic() {.importc.}
  proc Mix_ResumeMusic() {.importc.}
  proc Mix_RewindMusic() {.importc.}
  proc Mix_PausedMusic(): cint {.importc.}
  proc Mix_SetMusicPosition(position: float64): cint {.importc.}
  proc Mix_PlayingMusic(): cint {.importc.}
  proc Mix_SetMusicCMD(command: cstring): cint {.importc.}

  proc Mix_ReserveChannels(num: cint): cint {.importc.}
  proc Mix_GroupChannel(which: cint, tag: cint): cint {.importc.}
  proc Mix_GroupChannels(fromChan: cint, toChan: cint, tag: cint): cint {.importc.}
  proc Mix_GroupAvailable(tag: cint): cint {.importc.}
  proc Mix_GroupCount(tag: cint): cint {.importc.}
  proc Mix_GroupOldest(tag: cint): cint {.importc.}
  proc Mix_GroupNewer(tag: cint): cint {.importc.}
  proc Mix_HaltGroup(tag: cint): cint {.importc.}
  proc Mix_FadeOutGroup(tag: cint, ms: cint): cint {.importc.}

  proc Mix_SetPostMix(mix_func: MixFunc, arg: pointer) {.importc.}
  proc Mix_HookMusic(mix_func: MixFunc, arg: pointer) {.importc.}
  proc Mix_HookMusicFinished(music_finished: MusicFinishedFunc) {.importc.}
  proc Mix_GetMusicHookData(): pointer {.importc.}
  proc Mix_ChannelFinished(channel_finished: ChannelFinishedFunc) {.importc.}

  proc Mix_RegisterEffect(chan: cint, f: EffectFunc, d: EffectDoneFunc, arg: pointer): cint {.importc.}
  proc Mix_UnregisterEffect(channel: cint, f: EffectFunc): cint {.importc.}
  proc Mix_UnregisterAllEffects(channel: cint): cint {.importc.}
  proc Mix_SetPanning(channel: cint, left: uint8, right: uint8): cint {.importc.}
  proc Mix_SetPosition(channel: cint, angle: int16, distance: uint8): cint {.importc.}
  proc Mix_SetDistance(channel: cint, distance: uint8): cint {.importc.}
  proc Mix_SetReverseStereo(channel: cint, flip: cint): cint {.importc.}

  proc Mix_SetSynchroValue(value: cint): cint {.importc.}
  proc Mix_GetSynchroValue(): cint {.importc.}
  proc Mix_SetSoundFonts(paths: cstring): cint {.importc.}
  proc Mix_GetSoundFonts(): cstring {.importc.}
  proc Mix_EachSoundFont(function: SoundFontIterFunc, data: pointer): cint {.importc.}
  proc Mix_GetChunk(channel: cint): RawChunkPtr {.importc.}

  {.pop.}

  type Chunk* {.requiresInit.} = object
    ## RAII wrapper around a loaded sound effect (`Mix_Chunk`).
    ## Automatically frees the chunk when it goes out of scope.
    raw: RawChunkPtr

  type Music* {.requiresInit.} = object
    ## RAII wrapper around loaded background music (`Mix_Music`).
    ## Automatically frees the music when it goes out of scope.
    raw: RawMusicPtr

  proc `=destroy`*(c: var Chunk) =
    ## Frees the sound chunk automatically when Chunk goes out of scope.
    destroyImpl(c, Mix_FreeChunk)

  proc `=destroy`*(m: var Music) =
    ## Frees the music automatically when Music goes out of scope.
    destroyImpl(m, Mix_FreeMusic)

  proc `=sink`*(dest: var Chunk; source: Chunk) =
    ## Move semantics: transfers chunk ownership without double-free.
    sinkImpl(dest, source)

  proc `=sink`*(dest: var Music; source: Music) =
    ## Move semantics: transfers music ownership without double-free.
    sinkImpl(dest, source)

  proc `=copy`*(dest: var Chunk, source: Chunk) {.error: "Chunk cannot be copied! Use move()".}
    ## Copying is disabled to prevent double-free. Use move() instead.

  proc `=copy`*(dest: var Music, source: Music) {.error: "Music cannot be copied! Use move()".}
    ## Copying is disabled to prevent double-free. Use move() instead.

  proc unsafeRaw*(c: Chunk): RawChunkPtr {.inline.} = c.raw
    ## Extracts the raw Mix_Chunk pointer. Only valid while `c` is in scope.

  proc unsafeRaw*(m: Music): RawMusicPtr {.inline.} = m.raw
    ## Extracts the raw Mix_Music pointer. Only valid while `m` is in scope.

  proc assumeRaw*(p: RawChunkPtr): Chunk {.inline.} = Chunk(raw: p)
    ## Wraps a raw Mix_Chunk pointer into a Chunk. Assumes ownership.

  proc assumeRaw*(p: RawMusicPtr): Music {.inline.} = Music(raw: p)
    ## Wraps a raw Mix_Music pointer into a Music. Assumes ownership.

  proc initMixer*(flags: MixInitFlag) {.inline.} =
    ## Initializes SDL_mixer with the specified format support flags.
    ## Call before `openAudio()` and any loading/playback operations.
    ##
    ## **Example:**
    ## ```nim
    ## initMixer(mp3)
    ## initMixer(mp3 or ogg)
    ## ```
    discard sdlCheckZero Mix_Init(cint(flags))

  proc quitMixer*() {.inline.} =
    ## Shuts down SDL_mixer and releases all associated resources.
    Mix_Quit()

  proc mixerLinkedVersion*(): Option[Version] {.inline.} =
    ## Returns the runtime version of the linked SDL_mixer library.
    ## Returns `none` if the version cannot be determined.
    ##
    ## **Example:**
    ## ```nim
    ## let ver = mixerLinkedVersion()
    ## if ver.isSome:
    ##   echo "SDL_mixer version: ", ver.get
    ## ```
    let p = Mix_Linked_Version()
    if p.isNil: none(Version) else: some(p[])

  proc openAudio*(
      frequency: uint32 = mixDefaultFrequency,
      format: AudioFormat = mixDefaultFormat,
      channels: uint8 = mixDefaultChannels,
      chunksize: int = 1024
    ) {.inline.} =
    ## Opens the audio device for mixing with the given parameters.
    ## Must be called after `initMixer()` and before loading/playing sounds.
    ##
    ## **Example:**
    ## ```nim
    ## openAudio(44100, s16Lsb, 2, 1024)
    ## ```
    discard sdlCheck Mix_OpenAudio(cint(frequency), uint16(format), cint(channels), cint(chunksize))

  proc closeMixAudio*() {.inline.} =
    ## Closes the audio device opened by `openAudio()`.
    Mix_CloseAudio()

  proc allocateChannels*(numChannels: int): cint {.inline.} =
    ## Allocates the number of mixing channels. Can be called multiple times.
    ## Returns the actual number allocated.
    Mix_AllocateChannels(cint(numChannels))

  proc querySpec*(frequency: var cint, format: var AudioFormat, channels: var cint): bool {.inline.} =
    ## Queries the current audio device specifications.
    ## Returns `true` if audio is open.
    var rawFormat: uint16
    let res = Mix_QuerySpec(addr frequency, addr rawFormat, addr channels) != 0
    format = cast[AudioFormat](rawFormat)
    return res

  proc numChunkDecoders*(): int {.inline.} =
    ## Returns the number of available sound effect decoders.
    Mix_GetNumChunkDecoders()

  proc chunkDecoder*(index: int): cstring {.inline.} =
    ## Returns the name of the chunk decoder at the given index.
    Mix_GetChunkDecoder(cint(index))

  proc numMusicDecoders*(): int {.inline.} =
    ## Returns the number of available music decoders.
    Mix_GetNumMusicDecoders()

  proc musicDecoder*(index: int): cstring {.inline.} =
    ## Returns the name of the music decoder at the given index.
    Mix_GetMusicDecoder(cint(index))

  proc loadWav*(file: string): Option[Chunk] {.inline.} =
    ## Loads a WAV file from disk into a `Chunk`. Returns `none` on failure.
    ##
    ## **Example:**
    ## ```nim
    ## let sound = loadWav("explosion.wav")
    ## if sound.isSome:
    ##   discard sound.get.play()
    ## ```
    var fileOpt = openFile(file, "rb")
    if fileOpt.isNone:
      return none(Chunk)
    Mix_LoadWAV_RW(fileOpt.get().unsafeRaw(), 0).toOption(Chunk)

  proc loadWav*(stream: var RWops): Option[Chunk] {.inline.} =
    ## Loads a WAV file from an open RWops stream into a `Chunk`.
    assert not stream.unsafeRaw().isNil
    Mix_LoadWAV_RW(stream.unsafeRaw(), 0).toOption(Chunk)

  proc loadMus*(file: string): Option[Music] {.inline.} =
    ## Loads a music file from disk into a `Music`. Supports MP3, OGG, FLAC, etc.
    ## Returns `none` on failure.
    ##
    ## **Example:**
    ## ```nim
    ## let bgm = loadMus("theme.mp3")
    ## if bgm.isSome:
    ##   discard bgm.get.play(loops = -1)
    ## ```
    Mix_LoadMUS(file.cstring).toOption(Music)

  proc loadMus*(stream: var RWops, freesrc: cint = 0): Option[Music] {.inline.} =
    ## Loads music from an open RWops stream. Detects format automatically.
    ## `freesrc`: if non-zero, the RWops is closed after loading.
    assert not stream.unsafeRaw().isNil
    Mix_LoadMUS_RW(stream.unsafeRaw(), freesrc).toOption(Music)

  proc loadMus*(stream: var RWops, musicType: MixMusicType): Option[Music] {.inline.} =
    ## Loads music from an RWops stream with explicit format hint.
    assert not stream.unsafeRaw().isNil
    Mix_LoadMUSType_RW(stream.unsafeRaw(), musicType, 0).toOption(Music)

  proc quickLoadWav*(mem: AudioBuffer): Option[Chunk] {.inline.} =
    ## Loads a WAV from raw memory. The buffer must contain valid WAV data.
    Mix_QuickLoad_WAV(mem).toOption(Chunk)

  proc quickLoadRaw*(mem: AudioBuffer, len: uint32): Option[Chunk] {.inline.} =
    ## Loads raw audio samples from memory using the currently open audio format.
    Mix_QuickLoad_RAW(mem, len).toOption(Chunk)

  proc play*(
      c: Chunk;
      channel: AudioChannel = anyChannel;
      loops: int = 0;
      ticks: int = noTimeout
    ): AudioChannel {.inline.} =
    ## Plays a sound effect on the specified channel.
    ##
    ## **Example:**
    ## ```nim
    ## let explosion = loadWav("explosion.wav").get
    ## let channel = explosion.play()  # Play once on first available channel
    ## let channel = explosion.play(loops = 2)  # Play 3 times total
    ## let channel = explosion.play(ticks = 1000)  # Play for 1 second max
    ## ```
    assert c.raw != nil
    let res = Mix_PlayChannelTimed(cint(channel), c.raw, cint(loops), cint(ticks))
    AudioChannel(res)

  proc fadeIn*(
      c: Chunk;
      channel: AudioChannel = anyChannel;
      loops: int = 0;
      ms: int = defaultFadeMs;
      ticks: int = noTimeout
    ): AudioChannel {.inline.} =
    ## Plays a sound effect with a fade-in effect over `ms` milliseconds.
    ## Returns the channel the sound was assigned to.
    ##
    ## **Example:**
    ## ```nim
    ## let channel = explosion.fadeIn(ms = 500)
    ## ```
    assert c.raw != nil
    let res = Mix_FadeInChannelTimed(cint(channel), c.raw, cint(loops), cint(ms), cint(ticks))
    AudioChannel(res)

  proc `volume=`*(channel: AudioChannel, volume: Volume): Volume {.inline, discardable.} =
    ## Sets the volume for a channel (0-128).
    ##
    ## **Example:**
    ## ```nim
    ## channel.volume = 64  # Set to 50% volume
    ## channel.volume = 0   # Mute channel
    ## ```
    Mix_Volume(cint(channel), cint(volume))

  proc `volume=`*(c: Chunk, volume: Volume): Volume {.inline, discardable.} =
    ## Sets the volume for a specific chunk.
    ##
    ## **Example:**
    ## ```nim
    ## explosion.volume = 64
    ## ```
    assert c.raw != nil
    Mix_VolumeChunk(c.raw, cint(volume))

  proc volume*(channel: AudioChannel): Volume {.inline.} =
    ## Returns the current volume of the channel.
    Mix_Volume(cint(channel), -1)

  proc volume*(c: Chunk): Volume {.inline.} =
    ## Returns the current volume of the chunk.
    assert c.raw != nil
    Mix_VolumeChunk(c.raw, -1)

  proc halt*(channel: AudioChannel = allChannels): bool {.inline.} =
    ## Stops playback on the specified channel(s).
    ##
    ## **Example:**
    ## ```nim
    ## discard channel.halt()  # Stop specific channel
    ## discard halt()  # Stop all channels
    ## ```
    Mix_HaltChannel(cint(channel)) == 0

  proc expire*(channel: AudioChannel, ticks: int): int {.inline.} =
    ## Sets a timeout for playback on the given channel.
    ## Returns the number of channels still playing.
    Mix_ExpireChannel(cint(channel), cint(ticks))

  proc fadeOut*(channel: AudioChannel = allChannels, ms: int): int {.inline.} =
    ## Fades out the given channel over `ms` milliseconds.
    Mix_FadeOutChannel(cint(channel), cint(ms))

  proc fading*(channel: AudioChannel): MixFading {.inline.} =
    ## Returns the fade state of the channel.
    Mix_FadingChannel(cint(channel))

  proc pause*(channel: AudioChannel = allChannels) {.inline.} =
    ## Pauses playback on the given channel(s).
    Mix_Pause(cint(channel))

  proc resume*(channel: AudioChannel = allChannels) {.inline.} =
    ## Resumes playback on the given channel(s).
    Mix_Resume(cint(channel))

  proc isPaused*(channel: AudioChannel): bool {.inline.} =
    ## Returns `true` if the channel is paused.
    Mix_Paused(cint(channel)) != 0

  proc isPlaying*(channel: AudioChannel): bool {.inline.} =
    ## Returns `true` if the channel is currently playing.
    Mix_Playing(cint(channel)) != 0

  proc chunk*(channel: AudioChannel): RawChunkPtr {.inline.} =
    ## Returns the chunk currently playing on the given channel (or nil).
    Mix_GetChunk(cint(channel))

  proc musicType*(m: Music): MixMusicType {.inline.} =
    ## Returns the format type of the loaded music.
    if m.raw == nil: return MixMusicType.none
    Mix_GetMusicType(m.raw)

  proc play*(m: Music; loops: int = infiniteLoops): bool {.inline.} =
    ## Plays background music.
    ##
    ## **Example:**
    ## ```nim
    ## let music = loadMus("theme.mp3").get
    ## discard music.play()  # Play once
    ## discard music.play(loops = -1)  # Loop forever
    ## ```
    assert m.raw != nil
    sdlOk Mix_PlayMusic(m.raw, cint(loops))

  proc fadeIn*(m: Music, loops: int = infiniteLoops, ms: int = defaultFadeMs): bool {.inline.} =
    ## Starts playback of music with a fade-in effect.
    ## Returns `true` on success.
    ##
    ## **Example:**
    ## ```nim
    ## discard music.fadeIn(loops = -1, ms = 2000)
    ## ```
    assert m.raw != nil
    sdlOk Mix_FadeInMusic(m.raw, cint(loops), cint(ms))

  proc fadeInPos*(m: Music; loops: int = infiniteLoops; ms: int = defaultFadeMs; position: float64): bool {.inline.} =
    ## Starts playback of music at a given position with fade-in.
    assert m.raw != nil
    sdlOk Mix_FadeInMusicPos(m.raw, cint(loops), cint(ms), position)

  proc `volumeMusic=`*(volume: Volume): Volume {.inline, discardable.} =
    ## Sets the volume for music playback (0-128).
    Mix_VolumeMusic(cint(volume))

  proc volumeMusic*(): Volume {.inline.} =
    ## Returns the current music volume.
    Mix_VolumeMusic(-1)

  proc haltMusic*(): bool {.inline.} =
    ## Stops music playback immediately.
    ##
    ## **Warning:** This stops music abruptly. Consider using `fadeOutMusic()` for a smooth transition.
    ##
    ## **Example:**
    ## ```nim
    ## discard haltMusic()  # Stop immediately
    ## discard fadeOutMusic(2000)  # Fade out over 2 seconds (preferred)
    ## ```
    sdlOk Mix_HaltMusic()

  proc fadeOutMusic*(ms: cint): bool {.inline.} =
    ## Fades out music over `ms` milliseconds.
    Mix_FadeOutMusic(ms) != 0

  proc fadingMusic*(): MixFading {.inline.} =
    ## Returns the current fade state of music playback.
    Mix_FadingMusic()

  proc pauseMusic*() {.inline.} =
    ## Pauses music playback.
    Mix_PauseMusic()

  proc resumeMusic*() {.inline.} =
    ## Resumes paused music playback.
    Mix_ResumeMusic()

  proc rewindMusic*() {.inline.} =
    ## Rewinds music to the beginning.
    Mix_RewindMusic()

  proc isMusicPaused*(): bool {.inline.} =
    ## Returns `true` if music is currently paused.
    Mix_PausedMusic() != 0

  proc isMusicPlaying*(): bool {.inline.} =
    ## Returns `true` if music is currently playing.
    Mix_PlayingMusic() != 0

  proc musicPosition*(position: float64): bool {.inline.} =
    ## Seeks music to the given position in seconds.
    sdlOk Mix_SetMusicPosition(position)

  proc musicCmd*(command: string): bool {.inline.} =
    ## Sets an external music player command.
    sdlOk Mix_SetMusicCMD(command.cstring)

  proc reserveChannels*(num: int): int {.inline, discardable.} =
    ## Reserves the first `num` channels so they are never auto-assigned.
    ## Returns the actual number reserved.
    Mix_ReserveChannels(cint(num))

  proc assign*(channel: AudioChannel, group: AudioGroup): bool {.inline.} =
    ## Assigns a channel to a group for batch operations.
    Mix_GroupChannel(cint(channel), cint(group)) != 0

  proc assign*(fromChannel, toChannel: AudioChannel, group: AudioGroup): int {.inline, discardable.} =
    ## Assigns a range of channels to a group.
    Mix_GroupChannels(cint(fromChannel), cint(toChannel), cint(group))

  proc availableChannel*(group: AudioGroup = anyGroup): AudioChannel {.inline.} =
    ## Returns the first available (inactive) channel in the group.
    AudioChannel(Mix_GroupAvailable(cint(group)))

  proc count*(group: AudioGroup = anyGroup): int {.inline.} =
    ## Returns the number of channels in the group.
    Mix_GroupCount(cint(group))

  proc oldest*(group: AudioGroup = anyGroup): AudioChannel {.inline.} =
    ## Returns the channel in the group that has been playing the longest.
    AudioChannel(Mix_GroupOldest(cint(group)))

  proc newest*(group: AudioGroup = anyGroup): AudioChannel {.inline.} =
    ## Returns the channel in the group that started playing most recently.
    AudioChannel(Mix_GroupNewer(cint(group)))

  proc halt*(group: AudioGroup): int {.inline, discardable.} =
    ## Stops all channels in the specified group.
    Mix_HaltGroup(cint(group))

  proc fadeOut*(group: AudioGroup, ms: int): int {.inline, discardable.} =
    ## Fades out all channels in the specified group over `ms` milliseconds.
    Mix_FadeOutGroup(cint(group), cint(ms))

  proc setPostMix*(mixFunc: MixFunc, arg: pointer = nil) {.inline.} =
    ## Sets a callback that is called after all mixing is done.
    Mix_SetPostMix(mixFunc, arg)

  proc hookMusic*(mixFunc: MixFunc, arg: pointer = nil) {.inline.} =
    ## Hooks a custom mixer function that replaces the standard music mixer.
    Mix_HookMusic(mixFunc, arg)

  proc hookMusicFinished*(musicFinished: MusicFinishedFunc) {.inline.} =
    ## Sets a callback for when music playback finishes.
    Mix_HookMusicFinished(musicFinished)

  proc getMusicHookData*(): pointer {.inline.} =
    ## Returns the user data pointer passed to `hookMusic()`.
    Mix_GetMusicHookData()

  proc channelFinished*(channelFinished: ChannelFinishedFunc) {.inline.} =
    ## Sets a callback for when a channel finishes playback.
    Mix_ChannelFinished(channelFinished)

  proc registerEffect*(channel: AudioChannel, f: EffectFunc, d: EffectDoneFunc, arg: pointer): bool {.inline.} =
    ## Registers an audio effect callback for the given channel.
    ## The effect is applied during mixing.
    Mix_RegisterEffect(cint(channel), f, d, arg) != 0

  proc unregisterEffect*(channel: AudioChannel, f: EffectFunc): bool {.inline.} =
    ## Removes a previously registered effect from the channel.
    Mix_UnregisterEffect(cint(channel), f) != 0

  proc unregisterAllEffects*(channel: AudioChannel): bool {.inline.} =
    ## Removes all effects from the given channel.
    Mix_UnregisterAllEffects(cint(channel)) != 0

  proc `panning=`*(channel: AudioChannel, pan: tuple[left: uint8, right: uint8]): bool {.inline, discardable.} =
    ## Sets stereo panning for a channel (0-255 each).
    ##
    ## **Example:**
    ## ```nim
    ## channel.panning = (left: 255, right: 0)  # Full left
    ## channel.panning = (left: 128, right: 128)  # Center
    ## ```
    Mix_SetPanning(cint(channel), pan.left, pan.right) != 0

  proc clearPanning*(channel: AudioChannel): bool {.inline, discardable.} =
    ## Resets panning to full stereo (both channels at 255).
    Mix_SetPanning(cint(channel), 255, 255) != 0

  proc `position=`*(channel: AudioChannel, pos: tuple[angle: int16, distance: uint8]): bool {.inline, discardable.} =
    ## Sets 3D position: angle (0-360) and distance (0-255).
    ##
    ## **Example:**
    ## ```nim
    ## channel.position = (angle: 90, distance: 100)  # To the right, medium distance
    ## ```
    Mix_SetPosition(cint(channel), pos.angle, pos.distance) != 0

  proc clearPosition*(channel: AudioChannel): bool {.inline, discardable.} =
    ## Resets 3D position to center (angle=0, distance=0).
    Mix_SetPosition(cint(channel), 0, 0) != 0

  proc `distance=`*(channel: AudioChannel, distance: uint8): bool {.inline.} =
    ## Sets the distance attenuation for a channel (0=close, 255=far).
    Mix_SetDistance(cint(channel), distance) != 0

  proc `reverseStereo=`*(channel: AudioChannel, flip: bool): bool {.inline.} =
    ## Reverses the stereo channels if `flip` is true.
    Mix_SetReverseStereo(cint(channel), cint(flip)) != 0

  proc setSynchroValue*(value: int): bool {.inline.} =
    ## Sets a synchronization value for external music players.
    sdlOk Mix_SetSynchroValue(cint(value))

  proc getSynchroValue*(): int {.inline.} =
    ## Gets the current synchronization value.
    Mix_GetSynchroValue()

  proc setSoundFonts*(paths: string): bool {.inline.} =
    ## Sets the SoundFont search paths (colon-separated on Unix, semicolon on Windows).
    Mix_SetSoundFonts(paths.cstring) != 0

  proc getSoundFonts*(): cstring {.inline.} =
    ## Returns the current SoundFont search paths.
    Mix_GetSoundFonts()

  proc eachSoundFont*(fn: SoundFontIterFunc, data: pointer): bool {.inline.} =
    ## Iterates over each SoundFont path, calling `fn` for each.
    Mix_EachSoundFont(fn, data) != 0
