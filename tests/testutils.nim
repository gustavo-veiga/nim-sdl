import std/macros

macro checkPkg*(name: static string): untyped =
  ## Returns `true` at compile time if pkg-config finds the given package.
  let cmd = "pkg-config --exists " & name & " 2>/dev/null && echo 1 || echo 0"
  result = newLit(staticExec(cmd) == "1")
