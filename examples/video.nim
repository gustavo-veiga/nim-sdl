import sdl
import std/options

proc runExample() =
  echo "[Video Example] Initializing video subsystem..."

  initVideo()
  defer: quitVideo()

  echo "[Video Example] Requesting 640x240 @ 16-bit..."
  let screenOpt = setVideoMode(640, 240, ColorDepth.bpp16, SurfaceFlag.swSurface)

  if screenOpt.isNone:
    quit("Fatal: Hardware does not support requested video mode.")

  var screen = screenOpt.get()
  setCaption("Video Example - Pixel Access")

  let bgColor = screen.mapRGB(0, 0, 128)
  if screen.fill(bgColor):
    echo "[Video Example] Blue background drawn via fill()."

  let lockSuccess = screen.withLock:
    var pixels = screen.pixels()
    echo "[Video Example] Surface locked. Video memory exposed: ", pixels.len, " bytes."

    let lineBytes = int(screen.width) * 2
    for i in 0 ..< lineBytes:
      pixels[i] = 255'u8

  if lockSuccess:
    echo "[Video Example] Direct pixel manipulation completed safely."
  else:
    echo "[Video Example] Failed to lock surface."

  screen.update()
  echo "[Video Example] Screen rendered. Waiting for input..."

  var running = true

  while running:
    for event in pollEvents():
      case event.kind:
      of EventType.quit:
        echo "[Video Example] Window close received."
        running = false

      of EventType.keyDown:
        let key = event.key.keyInfo.key
        if key == Key.escape:
          echo "[Video Example] ESC pressed. Exiting."
          running = false

      else: discard

  echo "[Video Example] Shutting down safely."

runExample()