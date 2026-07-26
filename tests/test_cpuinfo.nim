import std/unittest
import sdl/cpuinfo

suite "CPU Info":
  test "hasRdtsc returns bool":
    let r = hasRdtsc()
    check r is bool

  test "hasMmx returns bool":
    let r = hasMmx()
    check r is bool

  test "hasSse returns bool":
    let r = hasSse()
    check r is bool

  test "hasSse2 returns bool":
    let r = hasSse2()
    check r is bool

  test "has3DNow returns bool":
    let r = has3DNow()
    check r is bool

  test "hasAltiVec returns bool":
    let r = hasAltiVec()
    check r is bool
