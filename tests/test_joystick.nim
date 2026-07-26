import std/unittest
import sdl/joystick

suite "Joystick":
  test "DPadDirection enum":
    check ord(DPadDirection.centered) == 0x00
    check ord(DPadDirection.up)       == 0x01
    check ord(DPadDirection.right)    == 0x02
    check ord(DPadDirection.down)     == 0x04
    check ord(DPadDirection.left)     == 0x08

  test "dPad directions":
    check uint8(DPadDirection.rightUp) == (0x01'u8 or 0x02'u8)
    check uint8(DPadDirection.rightDown) == (0x02'u8 or 0x04'u8)
