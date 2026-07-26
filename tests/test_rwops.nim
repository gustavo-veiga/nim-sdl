import std/unittest
import std/options
import sdl/rwops

suite "RWops":
  test "openMemory":
    var buf: array[64, uint8]
    var stream = openMemory(addr buf, buf.len)
    check stream.isSome
    check addr(stream.get()) != nil

  test "write/read int32":
    var buf: array[64, uint8]
    var stream = openMemory(addr buf, buf.len)
    check stream.isSome
    var s = addr stream.get()
    var v42 = 42'i32
    check s[].write(v42) == 1
    check s[].seek(0) == 0
    var value: int32
    check s[].read(value) == 1
    check value == 42

  test "seek/tell":
    var buf: array[64, uint8]
    var stream = openMemory(addr buf, buf.len)
    check stream.isSome
    var s = addr stream.get()
    check s[].tell() == 0
    var v1 = 1'i32; var v2 = 2'i32
    discard s[].write(v1)
    discard s[].write(v2)
    check s[].tell() == 8
    check s[].seek(0) == 0
    check s[].tell() == 0

  test "endianness":
    var buf: array[64, uint8]
    var stream = openMemory(addr buf, buf.len)
    check stream.isSome
    var s = addr stream.get()
    check s[].writeBE32(0x01020304'u32) == true
    check s[].seek(0) == 0
    check s[].readBE32() == 0x01020304'u32

  test "openConstMemory":
    let data = [1'u8, 2, 3, 4]
    let stream = openConstMemory(unsafeAddr data[0], data.len)
    check stream.isSome

  test "writeArray/readArray":
    var buf: array[256, uint8]
    var stream = openMemory(addr buf, buf.len)
    check stream.isSome
    var s = addr stream.get()
    var src = [1'i16, 2, 3, 4]
    check s[].writeArray(src) == 4
    check s[].seek(0) == 0
    var dst: array[4, int16]
    check s[].readArray(dst) == 4
    check dst == src
