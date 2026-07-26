## # sdl/cdrom
##
## CD-ROM drive control for SDL 1.2
##
## This module provides access to CD-ROM drives, allowing you to enumerate available
## drives, query their status, and control audio playback of audio CDs. It does **not**
## handle data CDs or CD-DA ripping — only real-time playback through the drive's
## analog/digital audio output.
##
## ## SDL 1.2 Reference
##
## CD-ROM support in SDL 1.2 is built around the `SDL_CD` structure and a set of
## functions for drive enumeration and playback control. Time is measured in **frames**
## (1/75th of a second, i.e., CD-DA sectors).
##
## **Key C functions:**
## ```c
## int SDL_CDNumDrives(void);
## SDL_CD *SDL_CDOpen(int drive);
## CDstatus SDL_CDStatus(SDL_CD *cdrom);
## int SDL_CDPlayTracks(SDL_CD *cdrom, int start_track, int start_frame,
##                      int ntracks, int nframes);
## ```
##
## ## Usage Example
##
## ```nim
## import sdl
##
## runMain:
##   let ctx = sdlInit(sdlInitCDROM)
##   defer: ctx.quit()
##
##   echo "Drives available: ", numDrives()
##
##   let driveOpt = openDrive(0)
##   if driveOpt.isSome:
##     let cd = driveOpt.get
##     case cd.status
##     of trayEmpty: echo "No disc inserted"
##     of stopped:   echo "Drive stopped"
##     of playing:   echo "Already playing"
##     of paused:    echo "Paused"
##     of error:     echo "Error"
##
##     # Play track 2 (1-indexed)
##     discard cd.playTracks(startTrack = 1, nTracks = 1)
## ```
##
## ## Advantages over C SDL 1.2
##
## | C SDL 1.2                              | Nim SDL                          |
## |----------------------------------------|----------------------------------|
## | `SDL_CD *cd = SDL_CDOpen(0);`          | `let cd = openDrive(0)` Option   |
## | `SDL_CDClose(cd)` manual close         | `CdDrive` RAII auto-close        |
## | `frames / 75` manual MSF conversion    | `framesToMSF()` helper           |
## | `CDstatus` as int                      | `CdStatus` typed enum            |
## | No track bounds checking               | `[]` operator with assertions    |
## | `SDL_CDEject` leaves handle dangling   | `eject()` invalidates safely     |
##
## ## Time Conversions
##
## SDL 1.2 measures CD-ROM positions in **frames** at 75 fps. Use the helper
## procedures to convert between frames and MSF (Minutes, Seconds, Frames):
##
## ```nim
## let (m, s, f) = framesToMSF(track.offset)
## echo "Track starts at ", m, ":", s, ":", f
## ```
##
## ## See Also
##
## - `sdl/core` - `sdlInitCDROM` flag for subsystem initialization

import std/options
import private/utils

# =========================================================
# 1. CONSTANTS AND ENUMS
# =========================================================
const
  maxTracks* = 99'u8
    ## Maximum number of tracks on a CD (per Red Book standard).
  audioTrack* = 0x00'u8
    ## Track type constant for audio tracks.
  dataTrack* = 0x04'u8
    ## Track type constant for data tracks.
  cdFps* = 75'u8
    ## CD frames per second (Red Book standard: 75 sectors/second).

type
  CdStatus* {.pure, size: sizeof(cint).} = enum
    ## Current status of a CD-ROM drive.
    error     = -1  ## Error reading drive status
    trayEmpty = 0   ## No disc in the drive
    stopped   = 1   ## Disc present but not playing
    playing   = 2   ## Currently playing audio
    paused    = 3   ## Playback paused

  CdTrackType* {.pure, size: sizeof(uint8).} = enum
    ## Type of CD track.
    audio = 0x00  ## Audio track (Red Book)
    data  = 0x04  ## Data track (Yellow Book)

# =========================================================
# 2. C STRUCTURES
# =========================================================
type
  CdTrack* = object
    ## Describes a single track on a CD.
    ## Track positions and lengths are measured in frames (75 per second).
    id*: uint8
    kind* {.importc: "type".}: CdTrackType
    unused*: uint16
    length*: uint32
    offset*: uint32

# =========================================================
# 3. FFI
# =========================================================
{.push header: "SDL_cdrom.h", importc.}

type
  RawCdDrive {.importc: "SDL_CD".} = object
    id: cint
    status: CdStatus
    numTracks {.importc: "numtracks".}: cint
    curTrack {.importc: "cur_track".}: cint
    curFrame {.importc: "cur_frame".}: cint
    track: array[0'u8 .. maxTracks, CdTrack]

  RawCdDrivePtr* = ptr RawCdDrive

proc SDL_CDNumDrives(): cint
proc SDL_CDName(drive: cint): cstring
proc SDL_CDOpen(drive: cint): RawCdDrivePtr
proc SDL_CDStatus(cdrom: RawCdDrivePtr): CdStatus
proc SDL_CDPlayTracks(cdrom: RawCdDrivePtr, startTrack, startFrame, nTracks, nFrames: cint): cint
proc SDL_CDPlay(cdrom: RawCdDrivePtr, start, length: cint): cint
proc SDL_CDPause(cdrom: RawCdDrivePtr): cint
proc SDL_CDResume(cdrom: RawCdDrivePtr): cint
proc SDL_CDStop(cdrom: RawCdDrivePtr): cint
proc SDL_CDEject(cdrom: RawCdDrivePtr): cint
proc SDL_CDClose(cdrom: RawCdDrivePtr)

{.pop.}

# =========================================================
# 4. SMART POINTER
# =========================================================
type CdDrive* {.requiresInit.} = object
  ## RAII wrapper for a CD-ROM drive handle.
  ## Automatically closes the drive when it goes out of scope.
  ## Provides type-safe access to drive status and playback controls.
  raw: RawCdDrivePtr

proc `=destroy`*(cd: var CdDrive) = destroyImpl(cd, SDL_CDClose)
proc `=sink`*(dest: var CdDrive, source: CdDrive) = sinkImpl(dest, source)
proc `=copy`*(dest: var CdDrive, source: CdDrive) {.error.}

proc unsafeRaw*(cd: CdDrive): RawCdDrivePtr {.inline.} = cd.raw
proc assumeRaw*(p: RawCdDrivePtr): CdDrive {.inline.} = CdDrive(raw: p)

# =========================================================
# 5. PUBLIC API
# =========================================================

# --- GLOBAL ---

proc numDrives*(): uint8 {.inline.} =
  ## Returns the number of CD-ROM drives available on the system.
  ##
  ## ```nim
  ## echo "Found ", numDrives(), " CD-ROM drives"
  ## ```
  let res = SDL_CDNumDrives()
  if res < 0: 0'u8 else: uint8(res)

proc driveName*(drive: uint8): Option[cstring] {.inline.} =
  ## Returns the human-readable name of the CD-ROM drive at `drive` index,
  ## or `none` if invalid.
  ##
  ## ```nim
  ## let name = driveName(0)
  ## if name.isSome:
  ##   echo "Drive 0: ", name.get
  ## ```
  SDL_CDName(cint(drive)).toOption()

proc openDrive*(drive: uint8 = 0): Option[CdDrive] {.inline.} =
  ## Opens a CD-ROM drive for access.
  ##
  ## ```nim
  ## let cd = openDrive(0)
  ## if cd.isSome:
  ##   echo "Opened drive with ", cd.get.numTracks, " tracks"
  ## ```
  SDL_CDOpen(cint(drive)).toOption(CdDrive)

# --- DRIVE STATE GETTERS (Read-Only) ---

proc id*(cd: CdDrive): int32 {.inline.} =
  ## Drive index.
  int32(cd.raw.id)

proc status*(cd: CdDrive): CdStatus {.inline.} =
  ## Current status of the CD-ROM drive: `error`, `trayEmpty`, `stopped`,
  ## `playing`, or `paused`.
  ##
  ## ```nim
  ## case cd.status
  ## of playing: echo "Currently playing"
  ## of trayEmpty: echo "No disc"
  ## else: discard
  ## ```
  SDL_CDStatus(cd.raw)

proc numTracks*(cd: CdDrive): uint8 {.inline.} =
  ## Number of tracks on the disc (0 if no disc).
  uint8(cd.raw.numTracks)

proc currentTrack*(cd: CdDrive): uint8 {.inline.} =
  ## Currently playing track index.
  uint8(cd.raw.curTrack)

proc currentFrame*(cd: CdDrive): uint32 {.inline.} =
  ## Current frame offset within the current track.
  uint32(cd.raw.curFrame)

proc hasDisk*(cd: CdDrive): bool {.inline.} =
  ## Whether a disc is inserted in the drive.
  cint(cd.raw.status) > 0

proc leadOut*(cd: CdDrive): CdTrack {.inline.} =
  ## Returns the lead-out track info (marks the end of the disc).
  cd.raw.track[uint8(cd.raw.numTracks)]

proc `[]`*(cd: CdDrive; index: uint8): CdTrack {.inline.} =
  ## Returns the track at the given 0-based index.
  ##
  ## ```nim
  ## let track = cd[0]  # First track
  ## echo "Track 1 length: ", track.length, " frames"
  ## ```
  assert index < uint8(cd.raw.numTracks), "Track index out of bounds!"
  cd.raw.track[index]

# --- CDTrack Getters ---

proc id*(t: CdTrack): uint8 {.inline.} =
  ## Track number (1-indexed in SDL convention).
  t.id

proc kind*(t: CdTrack): CdTrackType {.inline.} =
  ## Track type (audio or data).
  t.kind

proc length*(t: CdTrack): uint32 {.inline.} =
  ## Track length in frames.
  t.length

proc offset*(t: CdTrack): uint32 {.inline.} =
  ## Track offset from the start of the disc in frames.
  t.offset

proc unused*(t: CdTrack): uint16 {.inline.} =
  ## Reserved field.
  t.unused

# --- PLAYBACK CONTROLS ---

proc playTracks*(
    cd: CdDrive;
    startTrack: uint8, nTracks: uint8 = 1;
    startFrame: uint32 = 0, nFrames: uint32 = 0
  ): bool {.inline.} =
  ## Plays `nTracks` starting from `startTrack`. Can optionally specify a frame
  ## offset in the first track and frame count in the last track.
  ##
  ## ```nim
  ## # Play track 2 (index 1) completely
  ## discard cd.playTracks(startTrack = 1, nTracks = 1)
  ## ```
  assert not cd.raw.isNil, "Fatal Error: Attempted to play CD on an uninitialized drive."
  assert nTracks > 0, "Warning: nTracks must be at least 1 to start playback."

  if nTracks == 0: return false

  sdlOk SDL_CDPlayTracks(cd.raw, cint(startTrack), cint(startFrame), cint(nTracks), cint(nFrames))

proc play*(
    cd: CdDrive;
    start, length: uint32
  ): bool {.inline.} =
  ## Plays from frame `start` for `length` frames.
  ##
  ## ```nim
  ## # Play from frame 1000 for 500 frames
  ## discard cd.play(start = 1000, length = 500)
  ## ```
  sdlOk SDL_CDPlay(cd.raw, cint(start), cint(length))

proc pause*(cd: CdDrive): bool {.inline.} =
  ## Pauses CD playback.
  sdlOk SDL_CDPause(cd.raw)

proc resume*(cd: CdDrive): bool {.inline.} =
  ## Resumes CD playback after a pause.
  sdlOk SDL_CDResume(cd.raw)

proc stop*(cd: CdDrive): bool {.inline.} =
  ## Stops CD playback.
  sdlOk SDL_CDStop(cd.raw)

proc eject*(cd: var CdDrive): bool {.inline.} =
  ## Ejects the disc and closes the drive handle. After calling this, you MUST
  ## call `openDrive()` again to get a new handle.
  ##
  ## ```nim
  ## var cd = openDrive(0).get
  ## if cd.eject():
  ##   echo "Tray opened"
  ## # cd is now invalid, must reopen
  ## ```
  if cd.raw != nil:
    result = sdlOk SDL_CDEject(cd.raw)
    SDL_CDClose(cd.raw) # Prevents double-free crash!
    cd.raw = nil
  else:
    result = false

# ---------------------------------------------------------
# TIME UTILITIES
# ---------------------------------------------------------

proc framesToMSF*(frames: uint32): tuple[m, s, f: uint8] {.inline.} =
  ## Converts frames to Minutes, Seconds, Frames (MSF) format.
  ##
  ## ```nim
  ## let (m, s, f) = framesToMSF(track.offset)
  ## echo "Track starts at ", m, ":", s, ":", f
  ## ```
  var v = frames
  result.f = uint8(v mod uint32(cdFps))
  v = v div uint32(cdFps)
  result.s = uint8(v mod 60)
  result.m = uint8(v div 60)

proc msfToFrames*(m, s, f: uint8): uint32 {.inline.} =
  ## Converts Minutes, Seconds, Frames (MSF) to frame count.
  ##
  ## ```nim
  ## let frames = msfToFrames(2, 30, 50)  # 2:30:50
  ## ```
  result = (uint32(m) * 60'u32 * uint32(cdFps)) + (uint32(s) * uint32(cdFps)) + uint32(f)
