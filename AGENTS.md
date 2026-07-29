# AI Agent Instructions for Nim SDL

You are an AI assistant helping to develop `Nim SDL`, a memory-safe, zero-cost abstraction wrapper for SDL 1.2 written in Nim.
When generating, modifying, or reviewing code in this repository, you MUST adhere strictly to the following rules.

## 1. The "Library" Rule (CRITICAL)
- **This is a public library, not an end-user application.**
- You MUST NEVER remove, comment out, or refactor away exported types, constants, variables, or procedures (`proc name*()`) simply because they appear "unused" in the current file or project. They are intended for external consumers of the API.
- Do not attempt to "clean up" dead code if that code is an exported wrapper function.

## 2. Nim Style Guide (NEP-1) Strict Enforcement
AI models frequently hallucinate or violate NEP-1 due to cross-language training. You must explicitly follow these rules:
- **Types/Objects:** Use `PascalCase` (e.g., `Surface`, `AudioSpec`, `Event`).
- **Variables/Procs/Templates:** Use `camelCase` (e.g., `sdlInit`, `pollEvent`, `fillRgb`).
- **Acronyms are Words (Strict):** Treat acronyms as standard words. Only the first letter is capitalized.
  - ✅ `isPng` | ❌ `isPNG`
  - ✅ `parseXml` | ❌ `parseXML`
  - ✅ `mapRgb` | ❌ `mapRGB`
- **Constants:** Use `camelCase` for standard Nim constants. If mapping raw C FFI constants, you may use `PascalCase` wrapped in `distinct` types. Do not use `SCREAMING_SNAKE_CASE` unless mapping direct C `#define` macros in raw FFI files.
- **Indentation:** Exactly 2 spaces. Never use tabs.
- **Exporting:** Use the asterisk `*` immediately after the name to export a symbol (e.g., `type Window* = object`, `proc init*()`).

## 3. Idiomatic Getters and Setters (NEP-1)
- **Getters:** Drop the `get` prefix for simple properties or state-reading C functions.
  - ✅ `proc ticks*(): uint32` | ❌ `proc getTicks*(): uint32`
  - ✅ `proc appState*(): AppState` | ❌ `proc getAppState*(): AppState`
- **Setters:** For simple state updates, use Nim's property setter syntax (`proc `name=`(...)`).
  - ✅ `proc `caption=`*(title: string)`
  - ❌ `proc setCaption*(title: string)`
- **Exceptions (Action Functions):** You MUST keep the `get` and `set` prefixes for functions that represent complex operations, global context changes, or where dropping it would make the verb unclear (e.g., `getError()`, `setError()`, `setVideoMode()`).

## 4. Nim-Idiomatic API Design (Overloading & UFCS)
Do not blindly translate C API function names and signatures 1:1. You MUST exploit Nim's advanced language features to create a modern, ergonomic API:
- **Method Overloading:** Group similar C functions under a single, intuitive Nim name. For example, instead of exposing `mapRGB` and `mapRGBA`, wrap them both under multiple `proc toPixel*()` overloads.
- **Tuples and Ergonomics:** Provide overloads that accept standard Nim constructs like tuples (e.g., `tuple[r, g, b: uint8]`) or objects, rather than strictly flat C-style parameters.
- **UFCS (Uniform Function Call Syntax):** Always place the primary subject/resource (`Surface`, `PixelFormat`, `Window`, etc.) as the **first parameter** in the proc signature. This allows users to write `surface.toPixel(...)` naturally.

## 5. Zero-Cost Abstractions & Mandatory Inlining
- Maximize performance. Nim is compiled to C. Your wrapper must not introduce runtime overhead.
- **Mandatory Inlining:** ALL high-level public wrapper procedures MUST be marked with the `{.inline.}` pragma (or implemented as a `template`). This guarantees that the C compiler will flatten the call stack, making the Nim wrapper truly zero-cost compared to writing raw C.
- Map C structs to Nim `object` types seamlessly. Avoid unnecessary heap allocations (`ref object`) unless strictly required.
- Pass large objects by pointer (`ptr`), `var`, or use `{.byref.}` to avoid expensive memory copying.

## 6. Strong Typing with Distinct Types (Semantic Primitives)
Never expose raw primitive types (like `uint32`, `cint`, or `float`) in the public API if that value has a specific semantic meaning (e.g., a pixel, an ID, a timestamp).
- **Distinct Types:** Wrap C primitives using Nim's `distinct` keyword to enforce strict type safety at compile time, preventing accidental mixing of incompatible primitives.
- **Borrowing:** Use the `{.borrow.}` pragma to explicitly inherit necessary operations (like `==`, `<`, or `$`) from the base primitive without introducing any runtime overhead.
- **Example:**
  ```nim
  type Pixel* = distinct uint32
    ## A pixel value in a surface's native pixel format.

  proc `==`*(x, y: Pixel): bool {.borrow.}
  proc `$`*(x: Pixel): string {.borrow.}
  ```
## 7. Constructor Naming Conventions (`init` vs `new` vs `create`)
Nim has strict semantic conventions for instantiation prefixes based on memory management. Since this wrapper relies heavily on RAII and value types (`object`) rather than the Garbage Collector (`ref object`), you MUST follow these naming rules for constructors:

- **`init` (Default for RAII & POD):** Use the `init` prefix for constructors returning value types (`object`). Since our RAII wrappers (like `Surface`, `Rect`, `Color`) are objects, their high-level constructors must use `init` (even if the underlying C function uses `Create`).
  - ✅ `proc initSurface*(w, h: cint): Surface`
  - ❌ `proc createSurface*(w, h: cint): Surface`
- **`new` (BANNED for Resources):** In Nim, `new` implies heap allocation managed by the Garbage Collector (`ref object`). Because we use deterministic RAII (destructors), you MUST NOT use the `new` prefix for SDL resources.
- **`create` (Raw Pointers Only):** The `create` prefix implies manual, unmanaged raw memory allocation returning a pointer (`ptr`). Only use this if you are explicitly designing a low-level, unsafe function that forces the user to manually free the pointer.
- **`set` (State Mutation):** As per Rule 3, avoid `set` for simple properties (use `proc name=`). Reserve `set` for complex operations or global state mutations (e.g., `proc setVideoMode*()`).

## 8. Global Functions and Namespace Pollution
Because Nim's default `import` statement brings all exported symbols directly into the current scope (unqualified imports), you MUST actively prevent namespace pollution for global or subsystem-level operations.

- **Global Operations (Generic Names):** Functions that manage global state and have overly generic names (like `init`, `quit`, or `getError`) MUST include the `Sdl` context identifier. Place it grammatically correctly (Verb + Target) and adhere to Rule 2 (Acronyms as Words).
  - ✅ `proc initSdl*()` | ❌ `proc init*()`
  - ✅ `proc quitSdl*()` | ❌ `proc quit*()`
  - ✅ `proc getSdlError*()` | ❌ `proc getError*()`
- **Global Operations (Domain-Specific Names):** If the function name is already specific to the domain and unlikely to clash with the standard library or user code, DO NOT force the `Sdl` prefix.
  - ✅ `proc pollEvent*()` | ❌ `proc pollSdlEvent*()`
  - ✅ `proc getTicks*()` | ❌ `proc getSdlTicks*()`
- **Type-Bound Operations (Safe):** This restriction DOES NOT apply to functions where the primary parameter is a strong, distinct SDL type (e.g., `Surface`, `Window`, `Event`). Nim's type system handles overload resolution safely.
  - ✅ `proc pollEvent*(event: var Event): bool`
  - ✅ `proc fill*(surface: AnySurface, color: Pixel)` (Usage: `surface.fill(color)`)

## 9. RAII and Memory Safety
- All SDL resources (Surfaces, AudioSpecs, Joysticks) must be wrapped in custom objects utilizing Nim's destructors (`=destroy`).
- Disable copying for strict resources using `=copy` error pragmas where applicable, and implement `=sink` for move semantics.
- Standard Resource Pattern:
  ```nim
  type Surface* = object
    sdlSurface: ptr SDL_Surface

  proc `=destroy`*(s: var Surface) =
    if s.sdlSurface != nil:
      SDL_FreeSurface(s.sdlSurface)
      s.sdlSurface = nil

  proc `=copy`*(dest: var Surface, source: Surface) {.error.}
  ```

## 10. Smart Pointers and Escape Hatches
When creating RAII wrappers for opaque types, you MUST provide standardized "escape hatches" for interoperability with other modules or external C libraries (like OpenGL or SDL_image).
- **Internal Pointer Name:** Always name the internal pointer field `raw`.
- **Extraction (`unsafeRaw`):** Provide an inline `unsafeRaw` proc that returns the underlying pointer.
  - ✅ `proc unsafeRaw*(s: Surface): RawSurfacePtr {.inline.} = s.raw`
- **Wrapping (`assumeRaw`):** Provide an inline `assumeRaw` proc to wrap a raw pointer into the RAII object, assuming ownership.
  - ✅ `proc assumeRaw*(p: RawSurfacePtr): Surface {.inline.} = Surface(raw: p)`
- **Move and Copy Semantics:** Explicitly implement `=sink` for move semantics (transferring ownership without double-free). If a resource cannot be copied (or if reference counting is not implemented), explicitly disable `=copy` using `{.error.}` to prevent memory leaks or segmentation faults.

## 11. FFI (Foreign Function Interface) Best Practices
- Use `{.cdecl.}` and `{.importc.}` correctly for all SDL 1.2 function imports.
- Use Nim's `distinct` types to map C enums and bitmasks (`Uint32` flags) to ensure type safety, overriding `or`, `and`, `==` operators for them instead of relying on weak integers.

## 12. Strict FFI Type Mapping & Public API Boundaries (CRITICAL)
There must be a strict, impenetrable boundary between the raw C layer and the public Nim API regarding primitive types.

- **Raw FFI Layer:** Always use `cint`, `cuint`, `cfloat`, `cdouble`, `cschar`, etc., for raw FFI imports (`{.importc.}`). Never map C's `int` to Nim's `int` here, as Nim's `int` is pointer-sized (64-bit) while C's `int` is typically 32-bit (causing memory corruption).
- **Public API Layer:** You MUST NEVER expose raw C types (like `cint`, `cfloat`) in exported wrapper functions (`proc name*()`). The public API must accept and return standard Nim types (e.g., `int`, `uint32`, `float`). Cast these safely to C types internally before passing them to the raw FFI.
  - ✅ `proc fillRect*(rect: Rect, color: uint32)`
  - ❌ `proc fillRect*(rect: Rect, color: cuint)`
- **The `cstring` & `string` Overload Rule:** `cstring` is the ONLY C type allowed in the public API (to avoid heap allocations). However, for maximum ergonomics, functions accepting `cstring` MUST provide an inline overload that accepts a standard Nim `string`. The `string` overload should simply forward the call to the `cstring` version.
  - ✅ `proc caption=*(title: cstring)` (Main optimized function)
  - ✅ `proc caption=*(title: string) {.inline.} = `caption=`(title.cstring)` (Ergonomic overload)

## 13. Error Handling & Null Pointers
- C functions that return pointers often return `NULL` on failure.
- Do not let `nil` pointers leak into the safe Nim API. Do not use Nim `Exception` types for standard C errors.
- Wrap functions that can fail using `std/options` (`Option[T]`).
- Example: If `SDL_SetVideoMode` fails, return `none(Surface)`. If it succeeds, return `some(Surface(sdlSurface: ptr))`.

## 14. C Header Pragmas & The `bycopy` Split
When mapping a new SDL header, you MUST separate types and functions into two distinct `{.push.}` blocks. This is required because type-specific pragmas (like `bycopy`) cannot be applied to procedure declarations.

**Block 1: Types and Enums (`bycopy` required)**
Use this block for structs and enums. It MUST include `bycopy` so Nim passes C structs by value. Do not use a global `importc` here; instead, use explicit `{.importc: "C_Name".}` for each type to rename them to strict `PascalCase` (NEP-1).
```nim
{.push header: "<SDL_video.h>", bycopy, cdecl.}
type
  Surface* {.importc: "SDL_Surface", incompleteStruct.} = object
  VideoInfo* {.importc: "SDL_VideoInfo", pure.} = object
{.pop.}
```

**Block 2: Raw Functions (No `bycopy`, global `importc`)**
Use this block strictly for C functions. It MUST NOT include `bycopy`. Include `importc` globally in the push pragma to automatically map the exact C function names without appending `{.importc.}` to each proc.
```nim
{.push header: "<SDL_video.h>", importc, cdecl.}
proc SDL_SetVideoMode*(width: cint, height: cint, bpp: cint, flags: uint32): ptr Surface
proc SDL_FreeSurface*(surface: ptr Surface)
{.pop.}
```

## 15. C Struct Mapping: Transparent vs. Opaque
When mapping C structs, you must correctly identify if it is a "Plain Old Data" (POD) struct or an Opaque Resource Handle:

**A. Transparent Structs (Plain Old Data):**
- These structs MUST be grouped under a `{.push bycopy.}` block so Nim passes them by value.
- Struct names MUST be strict `PascalCase` (e.g., `KeyInfo`, `Surface`).
- Fully implement the fields in Nim if the struct's data needs to be accessed directly.
- Field names MUST be strict `camelCase`. Use `{.importc: "c_name".}` on individual fields when you need to rename them from C's style to Nim's `camelCase`.
- DO NOT use `incompleteStruct`. Export the type directly.
- **Encapsulation:** Keep fields private (no `*`) if they should be read-only from the outside API, exposing them via Nim getters instead.
  ```nim
  {.push header: "<SDL_keyboard.h>", bycopy, cdecl.}
  type KeyInfo* {.importc: "SDL_keysym".} = object
    scanCode {.importc: "scancode".}: uint8
    key {.importc: "sym".}: Key
    mods {.importc: "mod".}: KeyMods
    unicode: uint16
  {.pop.}
  ```

**B. Opaque Types (Resource Handles & Security Pattern):**
- For internal SDL resources manipulated only via pointers (like `SDL_mutex*` or `Mix_Chunk*`), separate the raw C layer from the public API.
- Prefix the C struct with `Raw` and use `incompleteStruct`. **Do not export the object.**
  - ✅ `type RawMutex {.importc: "SDL_mutex", incompleteStruct.} = object`
- Create and export a pointer type using the `Ptr` suffix (e.g., `type RawMutexPtr* = ptr RawMutex`).
- Raw C functions that manipulate these resources MUST NOT be exported.

## 16. Git Workflow: Semantic & Atomic Commits
When generating commit messages or grouping files for commits, you MUST follow these practices:
- **Semantic Commits:** Use standard conventional commit prefixes (e.g., `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`, `style:`).
- **Atomic Commits:** Commits must be scoped to a single context or feature. DO NOT bundle unrelated changes into a single monolithic commit. Stage and commit files logically and separately based on the problem they solve.
