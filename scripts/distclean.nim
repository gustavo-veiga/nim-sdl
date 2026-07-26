import std/os

const
  prefix = "[DISTCLEAN] "

proc removeIfExists(path: string) =
  if dirExists(path):
    removeDir(path)
    echo prefix & "Removed directory: " & path
  elif fileExists(path):
    removeFile(path)
    echo prefix & "Removed file: " & path

proc findAndRemoveNimcache() =
  var count = 0
  
  # Check common locations for nimcache
  const nimcacheLocations = [
    ".", "tests", "examples", "src"
  ]
  
  for baseDir in nimcacheLocations:
    if dirExists(baseDir):
      for kind, path in walkDir(baseDir):
        if kind == pcDir and lastPathPart(path) == "nimcache":
          removeDir(path)
          echo prefix & "Removed nimcache: " & path
          inc count
  
  # Also recursively search for nested nimcache directories
  for path in walkDirRec(".", {pcDir}):
    if lastPathPart(path) == "nimcache" and dirExists(path):
      removeDir(path)
      echo prefix & "Removed nimcache: " & path
      inc count
  
  if count > 0:
    echo prefix & "Removed " & $count & " nimcache director" & (if count == 1: "y" else: "ies")
  else:
    echo prefix & "No nimcache directories found"

proc main() =
  echo prefix & "Starting distclean..."
  
  removeIfExists("build")
  removeIfExists("coverage_html")
  removeIfExists("coverage.info")
  removeIfExists("generated_not_to_break_here")
  
  findAndRemoveNimcache()
  
  echo prefix & "Project cleaned successfully!"

when isMainModule:
  main()
