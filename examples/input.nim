import sdl
import std/options

runMain:
  echo "[Input Example] Starting dual input test (Keyboard + Mouse)..."

  var guard = sdlInit(InitFlag.video or InitFlag.timer)
  defer: guard.quit()

  let screenOpt = setVideoMode(640, 240, ColorDepth.bpp16, SurfaceFlag.swSurface)
  if screenOpt.isNone: quit("Error: Video mode failed.")
  let screen = screenOpt.get()

  var
    running = true

    player = initRect(300, 100, 40, 40)

    cursor = initRect(0, 0, 15, 15)
    touching = false

    bgColor = screen.toPixel(20, 20, 30)
    playerColor = screen.toPixel(0, 150, 255)
    cursorColor = screen.toPixel(255, 200, 0)
    touchColor = screen.toPixel(255, 50, 50)

  while running:
    for event in pollEvents():
      case event.kind:
      of EventType.quit:
        running = false

      of EventType.keyDown:
        let key = event.key.keyInfo.key
        if key == Key.escape: running = false
        elif key == Key.up:    player.y -= 15
        elif key == Key.down:  player.y += 15
        elif key == Key.left:  player.x -= 15
        elif key == Key.right: player.x += 15

      of EventType.mouseMotion:
        cursor.x = int16(event.motion.x)
        cursor.y = int16(event.motion.y)

      of EventType.mouseButtonDown:
        touching = true
        cursor.x = int16(event.button.x)
        cursor.y = int16(event.button.y)

      of EventType.mouseButtonUp:
        touching = false

      else: discard

    discard screen.fill(initRect(0, 0, 640, 240), bgColor)
    discard screen.fill(player, playerColor)

    if touching:
      discard screen.fill(cursor, touchColor)
    else:
      discard screen.fill(cursor, cursorColor)

    discard screen.flip()
    delay(16)