# =========================================================
# sdl-nim Build Configuration (NimScript)
# =========================================================
# Usage:
#   nim c -d:release -d:gfx -d:ttf src/sdl.nim
#   nimble build -d:gfx -d:ttf
#
# Optional features (--define:):
#   gfx       - SDL_gfx (framerate, rotozoom)
#   net       - SDL_net
#   ttf       - SDL_ttf
#   image     - SDL_image
#   mixer     - SDL_mixer
#   rtf       - SDL_rtf
#   pango     - SDL_Pango
# =========================================================


# -------------------------------------------------------------------
# Base SDL linking
# -------------------------------------------------------------------
when defined(windows):
  switch("passL", "-lmingw32")
  switch("passL", "-lSDLmain")
  switch("passL", "-lSDL")
  switch("passC", "-I/usr/include/SDL")
else:
  switch("passL", "-lSDL")
  switch("passC", "-I/usr/include/SDL")
  switch("passC", "-I/usr/local/include/SDL")
  switch("passC", "-I/opt/homebrew/include/SDL")

# -------------------------------------------------------------------
# Optional companion libraries
# -------------------------------------------------------------------
# Each companion library is enabled by passing -d:Xxx at compile time.
# The corresponding source module (sdl/xxx.nim) wraps its FFI declarations
# in `when defined(Xxx):` blocks, so missing libraries never cause
# compilation failures.

when defined(gfx):
  echo "  [+] Feature enabled: gfx (SDL_gfx - framerate, rotozoom)"
  switch("passL", "-lSDL_gfx")
when defined(net):
  echo "  [+] Feature enabled: net (SDL_net - TCP/UDP sockets)"
  switch("passL", "-lSDL_net")
when defined(ttf):
  echo "  [+] Feature enabled: ttf (SDL_ttf - TrueType fonts)"
  switch("passL", "-lSDL_ttf")
when defined(image):
  echo "  [+] Feature enabled: image (SDL_image - image loading)"
  switch("passL", "-lSDL_image")
when defined(mixer):
  echo "  [+] Feature enabled: mixer (SDL_mixer - audio mixing)"
  switch("passL", "-lSDL_mixer")
when defined(rtf):
  echo "  [+] Feature enabled: rtf (SDL_rtf - rich text)"
  switch("passL", "-lSDL_rtf")
when defined(pango):
  echo "  [+] Feature enabled: pango (SDL_Pango - text layout)"
  switch("passL", "-lSDL_Pango")

# -------------------------------------------------------------------
# Compiler flags
# -------------------------------------------------------------------
switch("path", "src")
switch("outdir", "build")

when defined(release):
  switch("opt", "speed")
  switch("passC", "-O3")
  switch("passL", "-s")

when defined(debug):
  switch("debuginfo", "on")
  switch("opt", "none")
  switch("passC", "-g")
  switch("passL", "-g")
