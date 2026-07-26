# Nim SDL

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Nim Version](https://img.shields.io/badge/Nim-%3E%3D2.2.4-blue.svg)](https://nim-lang.org)
[![SDL Version](https://img.shields.io/badge/SDL-1.2.15-green.svg)](https://www.libsdl.org/)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)]()

A modern, memory-safe Nim wrapper for **SDL 1.2** — designed for retro hardware, embedded targets, and developers who want the power of C SDL with Nim's expressiveness and safety guarantees.

---

## Why Nim SDL?

| C SDL 1.2                                | Nim SDL                                                                           |
| ---------------------------------------- | --------------------------------------------------------------------------------- |
| Manual `SDL_Init`/`SDL_Quit` pairing     | RAII: `sdlInit()` / automatic `SDL_Quit` on scope exit                            |
| Raw pointers, manual `SDL_FreeSurface`   | Smart pointers with `=destroy`, `=sink`, move semantics                           |
| `SDL_RWops*` + custom callbacks          | `RWops` with `openMemory`, `openFile`, `openConstMemory` + RAII                   |
| Error strings via `SDL_GetError()`       | `setError` / `getError` / `clearError` + `Result[T]` helpers                      |
| Thread/mutex/semaphore: opaque C handles | `Thread`, `Mutex`, `Semaphore`, `Condition` with `=destroy` + `withLock` template |
| No type safety for flags                 | `distinct` bitmask types (`InitFlag`, `AudioFormat`, `KeyMods`, …) with operators |
| Callback hell for audio conversion       | `AudioCVT` with `initAudioSpec(freq, ch, samples, fmt)` — no callback required    |
| Global state, no scoping                 | `let ctx = sdlInit(flags)` / `defer: ctx.quit()`                                  |
| Header-only, no build system             | Single `import sdl` — `nimble` handles `-lSDL` + companion libs                   |
| Write directly in C                      | Write in **Nim**, ship **C99 source** — compiles with any C99 compiler, no Nim needed |

> **No Nim on the target.** Nim compiles down to **C99** — the most portable C standard still in widespread use. You develop the game in Nim, but what you ship is plain C source (or a precompiled binary). On the target side, only a **C99-compatible compiler** (GCC, Clang, MSVC, TinyCC, SDCC, etc.) and the SDL 1.2 libraries are needed. No Nim toolchain required. Ideal for cross-compilation to retro consoles, embedded systems, and platforms where installing Nim isn't feasible.

---

## Installation

### Prerequisites

- **Nim** ≥ 2.2.4 (`choosenim` recommended)

#### 1. For Modern Systems (Development & Playback)
If you are developing or running the game on modern OSs (Windows 10/11, macOS, modern Linux), you should use **`sdl12-compat`**. It is an official drop-in replacement that exposes the exact SDL 1.2 API, but runs it on top of hardware-accelerated SDL2 to prevent compatibility issues on modern displays.

- **Debian/Ubuntu:** `apt install libsdl1.2-compat-dev` (or `libsdl1.2-dev` which often aliases it now)
- **Fedora:** `dnf install sdl12-compat-devel`
- **Arch Linux:** `pacman -S sdl12-compat`
- **macOS (Homebrew):** `brew install sdl12-compat`
- **Windows:** Use MSYS2 `pacman -S mingw-w64-x86_64-sdl12-compat` or grab the latest binaries directly from the [sdl12-compat GitHub repository](https://github.com/libsdl-org/sdl12-compat).

#### 2. For Legacy & Retro Hardware (Target Environments)
If you are cross-compiling for actual legacy systems (MS-DOS, Windows 98, Amiga, Dreamcast, PS2), you cannot use `sdl12-compat`. You must link against the **original SDL 1.2.15** provided by your retro toolchain.

- Rely on the SDL 1.2 libraries included in your specific SDK (e.g., DJGPP for DOS, KallistiOS for Dreamcast).
- Tell the Nim compiler where to find these specific legacy headers and libraries using the compiler flags:
  `--passC:"-I/path/to/your/retro/sdk/include"` and `--passL:"-L/path/to/your/retro/sdk/lib"`

### Via nimble (recommended)

```bash
nimble install sdl
```

### From source

```bash
git clone https://github.com/gustavo-veiga/nim-sdl.git
cd nim-sdl
nimble install
```

This installs the library source into your local Nimble package repository (usually `~/.nimble/pkgs/`), making it globally available to `import sdl` in any of your Nim projects.

---

## Quick Start

```nim
import sdl
import std/options

runMain:
  let guard = sdlInit()
  defer: guard.quit()

  let screenOpt = setVideoMode(640, 480, ColorDepth.bpp16)
  if screenOpt.isNone:
    quit("Failed to set video mode")

  var screen = screenOpt.get()
  setCaption("Hello SDL from Nim!")

  var running = true
  var evt: Event

  while running:
    while pollEvent(evt):
      case evt.kind
      of EventType.quit:
        running = false
      of EventType.keyDown:
        if evt.key.keyInfo.key == Key.escape:
          running = false
      else: discard

    let bg = screen.mapRGB(100, 149, 237)  # cornflower blue
    discard screen.fill(initRect(0, 0, 640, 480), bg)
    discard screen.flip()
    delay(16)

  echo "Done!"
```

Compile & run:

```bash
nim c -r -d:release examples/video.nim
```

---

## Module Overview

```
sdl/
├── active.nim        # SDL_GetAppState, input focus
├── audio.nim         # Audio spec, conversion, device management
├── cdrom.nim         # CD-ROM audio control
├── core.nim          # Init/quit, error handling, version
├── cpuinfo.nim       # CPU feature detection (SSE, 3DNow, etc.)
├── dreamcast.nim     # Dreamcast-specific video modes
├── endian.nim        # Byte swapping (swap16/32/64, LE/BE helpers)
├── error.nim         # Error string helpers
├── events.nim        # Event pump, keyboard/mouse/joystick events
├── framerate.nim     # FPS manager (requires SDL_gfx)
├── gfxfilter.nim     # MMX-accelerated image filters (requires SDL_gfx)
├── gfxprimitives.nim # Drawing primitives — pixel, line, circle, etc. (requires SDL_gfx)
├── image.nim         # IMG_Load, IMG_SavePNG (requires SDL_image)
├── joystick.nim      # Joystick open/close, axis/button/ball/hat
├── keyboard.nim      # Key state, modifiers, key names
├── keysym.nim        # KeySym, Key, KeyMods, KeyModFlag
├── loadso.nim        # Dynamic library loading (SharedObject)
├── main.nim          # SDL_main entry point helper
├── mixer.nim         # SDL_mixer: music, chunks, channels (requires SDL_mixer)
├── mouse.nim         # Mouse state, cursor, warping
├── mutex.nim         # Mutex, Semaphore, Condition, withLock template
├── net.nim           # SDL_net: TCP/UDP sockets (requires SDL_net)
├── pango.nim         # SDL_Pango text rendering (requires SDL_Pango)
├── quit.nim          # Quit event handling
├── rotozoom.nim      # Rotation/zoom/scale (requires SDL_gfx)
├── rtf.nim           # RTF rendering (requires SDL_rtf)
├── rwops.nim         # RWops: memory, file, const memory streams
├── syswm.nim         # System window manager info
├── thread.nim        # Thread creation, join, ID, kill
├── timer.nim         # Ticks, delay, timer callbacks
├── ttf.nim           # TrueType font rendering (requires SDL_ttf)
├── version.nim       # Compiled/linked version detection
├── video.nim         # Window, surface, pixel format, blit, gamma
└── sdl.nim           # Re-exports all modules (import sdl)
```

---

## Key Features in Depth

### RAII Resource Management

Every SDL resource is wrapped in a Nim object with `=destroy` (destructor), `=sink` (move), and `=copy` **disabled** — enforcing **move-only semantics**:

```nim
var surface = createRgbSurface(320, 200).get()
# surface is automatically freed when it goes out of scope

var surface2 = surface  # COMPILE ERROR: =copy is disabled
var surface3 = surface.sink  # OK: explicit move
```

### Error Handling

```nim
import sdl/error

# Set a custom error
setError("Asset not found: ", "player.png")

# Retrieve and clear
let msg = getError()  # "Asset not found: player.png"
clearError()

# SDL_GetError() is also available as raw FFI if needed
```

### Audio Conversion Made Simple

```nim
import sdl/audio

# Source: 44.1 kHz stereo S16
let srcSpec = initAudioSpec(44100, 2, 4096, audioS16Sys)
# Destination: 22.05 kHz mono U8
let dstSpec = initAudioSpec(22050, 1, 2048, AudioFormat.u8)

var cvt = buildAudioCVT(srcSpec, dstSpec)
# cvt.len, cvt.buf, cvt.ratio ready — just feed data and call convertAudio(cvt)
```

No callback required. `initAudioSpec(freq, channels, samples, format)` gives you a valid `AudioSpec` instantly.

### Thread Synchronization

```nim
import sdl/mutex

var mtx = createMutex().get()
var counter = 0

proc worker() =
  for _ in 1..1000:
    mtx.withLock:  # template: lock → body → unlock (exception-safe)
      inc(counter)

var threads = [createThread(worker).get() for _ in 1..4]
for t in threads: t.wait()
echo counter  # 4000
```

### Version Detection (No Hardcoded Constants)

```nim
import sdl/version
let compiled = sdlCompiledVersion()   # reads SDL_MAJOR_VERSION via {.emit.}

let linked   = sdlLinkedVersion().get()  # calls SDL_Linked_Version()

echo "Compiled against: ", compiled.toCstring()
echo "Linked against:   ", linked.toCstring()
```

---

## Optional Dependencies (Companion Libraries)

Optional libraries are activated at compile time using `-d:` flags:

| Module      | Library   | pkg-config  | Compile Flag | Feature                                               |
| ----------- | --------- | ----------- | ------------ | ----------------------------------------------------- |
| `sdl/image` | SDL_image | `SDL_image` | `-d:image`   | Load/save PNG, JPG, BMP, GIF, TIFF, WEBP with RAII    |
| `sdl/mixer` | SDL_mixer | `SDL_mixer` | `-d:mixer`   | Play music/chunks, channel mixing, volume, panning    |
| `sdl/ttf`   | SDL_ttf   | `SDL_ttf`   | `-d:ttf`     | Render TrueType fonts to surfaces with styling        |
| `sdl/net`   | SDL_net   | `SDL_net`   | `-d:net`     | TCP/UDP sockets, host resolution, packet management   |
| `sdl/gfx`   | SDL_gfx   | `SDL_gfx`   | `-d:gfx`     | Framerate control, rotation/zoom, drawing primitives, image filters |
| `sdl/rtf`   | SDL_rtf   | `SDL_rtf`   | `-d:rtf`     | Render Rich Text Format documents to surfaces         |
| `sdl/pango` | SDL_Pango | `SDL_Pango` | `-d:pango`   | Complex text layout with markup and bidi support      |

### Activating Optional Libraries

**With nimble:**

```bash
# Build with a single optional library
nimble build -d:mixer

# Build with multiple optional libraries
nimble build -d:mixer -d:image -d:ttf

# Run tests with optional libraries
nimble test -d:mixer -d:image
```

**With nim directly:**

```bash
nim c -d:mixer -d:image myapp.nim
```

When a companion library is missing, its test suite **skips gracefully** with a clear message:

```
[Suite] Image
  [SKIPPED] SKIP: SDL_image not installed (needed by sdl/image)
```

---

## Development Commands

| Command            | Description                                                |
| ------------------ | ---------------------------------------------------------- |
| `nimble test`      | Compile and run all test suites                            |
| `nimble lint`      | Static analysis (`nim check`) on all source files          |
| `nimble fmt`       | Auto-format all `.nim` files with 2-space indent           |
| `nimble checkfmt`  | Check formatting without modifying (for CI)                |
| `nimble coverage`  | Generate HTML coverage report (requires `lcov`, `genhtml`) |
| `nimble distclean` | Remove all build artifacts and generated files             |

### Test File Convention

Only files matching the pattern `tests/test_*.nim` are considered valid test files and executed by `nimble test`. Files in the `tests/` directory that don't follow this naming convention (such as `testutils.nim`) are treated as helper modules and are not executed as tests.

```bash
nimble test
```

Output:

```
  Compiling /.../tests/test_active (from package sdl) using c backend
[Suite] Active
  [OK] getAppState returns AppState
  Success: Execution finished
  ...
  Compiling /.../tests/test_framerate
[Suite] Framerate
  [SKIPPED] SKIP: SDL_gfx not installed (needed by sdl/framerate)
  Success: Execution finished
```

---

## Project Structure

```
nim-sdl/
├── sdl.nimble          # Package manifest + tasks (lint, fmt, test)
├── config.nims         # Build config (linking, feature flags)
├── src/
│   ├── sdl.nim         # Re-exports all modules
│   └── sdl/            # 33 wrapper modules
├── tests/
│   ├── config.nims     # Path config (src/ + tests/)
│   ├── testutils.nim   # pkg-config detection for optional deps
│   └── test_*.nim      # 30 test files (one per module)
├── examples/           # Ready-to-run example programs
├── build/              # Compiled binaries (gitignored)
├── LICENSE             # MIT
└── README.md           # This file
```

---

## Contributing

1. Fork & clone
2. Create a feature branch
3. Add tests for new functionality
4. Run `nimble test` — all core tests must pass
5. Run `nimble checkfmt` — ensure consistent formatting
6. Open a PR

Code style: `nimble fmt` (uses `nimpretty --indent:2` on all `.nim` files).

---

## Licensing

This project has a **dual licensing structure** that's important to understand:

### Nim Wrapper: MIT License

The Nim wrapper code (`src/sdl/*.nim`) is licensed under the **MIT License** — a permissive open-source license that allows you to:

- Use the wrapper in commercial and non-commercial projects
- Modify and distribute the wrapper code
- Use it without copyleft restrictions

See [LICENSE](LICENSE) for the full MIT license text.

### SDL 1.2 Library: LGPL License

The underlying **SDL 1.2 library** is licensed under the **GNU LGPL (Lesser General Public License)** — a copyleft license with specific requirements:

- **Dynamic linking**: You can use SDL 1.2 in proprietary software if you dynamically link to it
- **Static linking**: If you statically link SDL 1.2, you must provide your application's source code or object files
- **Modifications to SDL**: If you modify SDL 1.2 itself, you must release those modifications under LGPL
- **No restrictions on your code**: Your application code can remain proprietary

For full LGPL terms, see the [GNU LGPL v2.1](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html).

### What This Means for You

| Scenario                               | Requirement                              |
| -------------------------------------- | ---------------------------------------- |
| Use Nim SDL wrapper in proprietary app | ✅ Allowed (MIT)                         |
| Dynamically link to SDL 1.2            | ✅ Allowed (LGPL)                        |
| Statically link to SDL 1.2             | ⚠️ Must provide object files or source   |
| Modify Nim wrapper code                | ✅ Allowed, must keep MIT license        |
| Modify SDL 1.2 library                 | ⚠️ Must release modifications under LGPL |

**Most users**: If you're using Nim SDL with standard SDL 1.2 installations (dynamically linked), you can use it in any project without restrictions.

*Copyright (c) 2026 Gustavo Veiga. See [LICENSE](LICENSE) for details.*

---

## Acknowledgments

- **Sam Lantinga** — Creator and principal architect of SDL (Simple DirectMedia Layer). Sam's vision of a cross-platform multimedia library has powered countless games and applications since 1998.
- **SDL Team** — The ongoing maintainers and contributors of SDL 1.2 and its successor libraries
- **Nim Community** — For a language that makes C interop enjoyable
- **Contributors** — Issues, PRs, and testing on obscure hardware

---

_Built for retro. Designed for modern._
