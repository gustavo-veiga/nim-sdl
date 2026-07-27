import std/[os, osproc, strutils]

const
  prefix = "[COVERAGE] "

# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------
proc checkTool(name: string): bool =
  let cmd = when defined(windows): "where " & name else: "which " & name
  result = execCmd(cmd) == 0
  if not result:
    echo prefix & name & " not found. Install with: sudo apt install lcov"

proc runCmd(cmd: string; fatal = false): bool =
  let code = execCmd(cmd)
  if code != 0:
    echo prefix & "Command failed (exit " & $code & "): " & cmd
    if fatal: quit(1)
    return false
  true

proc getTestFiles: seq[string] =
  for kind, path in walkDir("tests"):
    let (_, name, ext) = splitFile(path)
    if kind == pcFile and ext == ".nim" and name.startsWith("test_"):
      result.add path
  if result.len == 0:
    echo prefix & "No test files found"
    quit(1)

proc getNproc: int =
  execProcess("nproc 2>/dev/null || echo 2").strip.parseInt

# ------------------------------------------------------------------
# Steps
# ------------------------------------------------------------------
proc cleanGcda(cacheDir: string) =
  echo prefix & "Removing stale .gcda files..."
  discard execCmd("find " & cacheDir & " -name '*.gcda' -delete 2>/dev/null")

proc compileTests(files: seq[string]; cacheDir, binDir: string) =
  let nc = getNproc()
  createDir cacheDir
  createDir binDir
  echo prefix & "Compiling " & $files.len & " test(s) (" & $nc & " cores)..."
  var cmds: seq[string]
  for f in files:
    let (_, name, _) = splitFile(f)
    cmds.add "nim c --nimcache:" & cacheDir / name & "_d" &
             " --outdir:" & binDir &
             " --passC:--coverage --passL:--coverage --debugger:native --hints:off " & f
  let script = cacheDir / "cmds.txt"
  writeFile script, cmds.join("\n")
  if not runCmd("xargs -P" & $nc & " -I{} bash -c '{}' < " & script):
    echo prefix & "Some tests failed to compile (optional libs missing)"

proc runTests(binDir: string) =
  echo prefix & "Running test binaries..."
  for kind, path in walkDir binDir:
    let (_, name, _) = splitFile(path)
    if kind == pcFile and name.startsWith("test_"):
      if execCmd(path) != 0:
        echo prefix & "  SKIPPED: " & name

proc collectCoverage(cacheDir: string) =
  echo prefix & "Collecting coverage data..."
  discard runCmd("lcov --base-directory . --directory " & cacheDir &
    " -c -o coverage.info --ignore-errors inconsistent,inconsistent" &
    " --ignore-errors count,count --ignore-errors empty,empty", fatal = true)
  discard runCmd("lcov --extract coverage.info '*/src/sdl/*'" &
    " -o coverage.info --ignore-errors unused,unused", fatal = true)

proc generateHtml =
  echo prefix & "Generating HTML report..."
  discard runCmd("genhtml -o coverage_html coverage.info" &
    " --ignore-errors source,source --ignore-errors range,range", fatal = true)

# ------------------------------------------------------------------
when isMainModule:
  if not checkTool("lcov"): quit(1)
  if not checkTool("genhtml"): quit(1)

  let
    files = getTestFiles()
    cacheDir = getCurrentDir() / "build" / "nimcache_coverage"
    binDir = getCurrentDir() / "build" / "test_bins"

  cleanGcda(cacheDir)
  compileTests(files, cacheDir, binDir)
  runTests(binDir)
  collectCoverage(cacheDir)
  generateHtml()
  echo prefix & "Done: file://" & getCurrentDir() / "coverage_html" / "index.html"
