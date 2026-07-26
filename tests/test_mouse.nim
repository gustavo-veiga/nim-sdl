import std/unittest
import sdl/mouse

suite "Mouse":
  test "MouseButton enum":
    check ord(MouseButton.left)      == 1
    check ord(MouseButton.middle)    == 2
    check ord(MouseButton.right)     == 3
    check ord(MouseButton.wheelUp)   == 4
    check ord(MouseButton.wheelDown) == 5
    check ord(MouseButton.x1)        == 6
    check ord(MouseButton.x2)        == 7

  test "buttonMask":
    check buttonMask(MouseButton.left)   == 0x01'u8
    check buttonMask(MouseButton.middle) == 0x02'u8
    check buttonMask(MouseButton.right)  == 0x04'u8

  test "isPressed":
    check isPressed(0x01'u8, MouseButton.left) == true
    check isPressed(0x01'u8, MouseButton.right) == false
    check isPressed(0x05'u8, MouseButton.left) == true
    check isPressed(0x05'u8, MouseButton.right) == true
