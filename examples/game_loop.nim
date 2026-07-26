import sdl
import std/options

echo "[Game Loop Example] Starting..."

let screenOpt = setVideoMode(640, 240, ColorDepth.bpp16, SurfaceFlag.swSurface)
if screenOpt.isNone:
  quit("Fatal: Could not set video mode.")

let screen = screenOpt.get()

var
  running = true
  evt: Event

  playerRect = initRect(300, 100, 40, 40)

  bgColor = screen.mapRGB(0, 0, 128)
  playerColor = screen.mapRGB(255, 0, 0)

while running:
  while pollEvent(evt):
    case evt.kind:
    of EventType.quit:
      running = false

    of EventType.keyDown:
      let key = evt.key.keyInfo.key
      if key == Key.escape: running = false
      elif key == Key.up:    playerRect.y -= 10
      elif key == Key.down:  playerRect.y += 10
      elif key == Key.left:  playerRect.x -= 10
      elif key == Key.right: playerRect.x += 10

    else: discard

  if playerRect.x < 0: playerRect.x = 0
  if playerRect.y < 0: playerRect.y = 0
  if playerRect.x > int16(640 - 40): playerRect.x = int16(640 - 40)
  if playerRect.y > int16(240 - 40): playerRect.y = int16(240 - 40)

  discard screen.fill(initRect(0, 0, 640, 240), bgColor)
  discard screen.fill(playerRect, playerColor)
  discard screen.flip()

  delay(16)

echo "[Game Loop Example] Done."