import std/unittest
import sdl/cdrom

suite "CD-ROM":
  test "framesToMSF / msfToFrames":
    let (m, s, f) = framesToMSF(150)
    check m == 0
    check s == 2
    check f == 0
    let frames = msfToFrames(0, 2, 0)
    check frames == 150
