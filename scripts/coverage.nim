import std/[os, osproc]

const
  prefix = "[COVERAGE] "

proc getCacheDir(): string =
  when defined(windows):
    getEnv("LOCALAPPDATA") / "nim" / "cache"
  elif defined(macosx):
    getEnv("HOME") / "Library" / "Caches" / "nim"
  else:
    getEnv("HOME") / ".cache" / "nim"

proc checkTool(name: string): bool =
  let cmd = when defined(windows): "where " & name else: "which " & name
  let output = execProcess(cmd)
  result = output.len > 0
  if not result:
    echo prefix & name & " not found. Install with: sudo apt install lcov / brew install lcov"

proc runCmd(cmd: string): bool =
  let exitCode = execCmd(cmd)
  if exitCode != 0:
    echo prefix & "Command failed with exit code " & $exitCode & ": " & cmd
    return false
  return true

proc collectCoverage() =
  echo prefix & "Collecting coverage data..."
  let cacheDir = getCacheDir()
  let cmd1 = "lcov --base-directory . --directory " & cacheDir &
             " -c -o coverage.info --ignore-errors inconsistent,inconsistent --ignore-errors count,count"
  if not runCmd(cmd1):
    quit(1)
  let cmd2 = "lcov --remove coverage.info nimcache/* lib/* /usr/include/* */asdf/* */tests/* */testutils*" &
             " -o coverage.info --ignore-errors unused,unused"
  if not runCmd(cmd2):
    quit(1)

proc generateHtml() =
  echo prefix & "Generating HTML report..."
  discard execShellCmd("touch generated_not_to_break_here")
  let cmd = "genhtml -o coverage_html coverage.info --ignore-errors source,source --ignore-errors range,range"
  if not runCmd(cmd):
    quit(1)

when isMainModule:
  if not checkTool("lcov"): quit(1)
  if not checkTool("genhtml"): quit(1)
  collectCoverage()
  generateHtml()
  echo prefix & "Done: file://" & getCurrentDir() / "coverage_html" / "index.html"
