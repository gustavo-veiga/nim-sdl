import std/unittest
import sdl/image

suite "Image":
  test "ImgInitFlag enum":
    check uint32(ImgInitFlag.imgJpg)  == 0x00000001'u32
    check uint32(ImgInitFlag.imgPng)  == 0x00000002'u32
    check uint32(ImgInitFlag.imgTif)  == 0x00000004'u32
    check uint32(ImgInitFlag.imgWebp) == 0x00000008'u32
