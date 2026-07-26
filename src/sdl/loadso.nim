## # sdl/loadso
##
## Dynamic library loading and function binding
##
## This module provides utilities for loading shared libraries (DLLs/SOs) at
## runtime and binding their functions. It supports three usage modes:
## auto-load with pragmas, manual bundle creation, and raw function lookup.
##
## ## SDL 1.2 Reference
##
## SDL 1.2 provides `SDL_LoadObject`, `SDL_LoadFunction`, and `SDL_UnloadObject`
## for dynamic library loading. This module wraps these with Nim's metaprogramming
## to provide type-safe function binding.
##
## **Key C functions:**
## ```c
## void *SDL_LoadObject(const char *sofile);
## void *SDL_LoadFunction(void *handle, const char *name);
## void SDL_UnloadObject(void *handle);
## ```
##
## ## Usage Modes
##
## ### Mode 1: Auto-Load with Pragmas
##
## Define an API structure with function pointers and use the `defaultLib` pragma:
##
## ```nim
## type
##   MyApi* = object
##     myFunc*: proc(x: cint): cint {.cdecl.}
##
## MyApi {.defaultLib: "mylib.so".}
##
## let api = load[MyApi]()
## if api.isSome:
##   api.get.api.myFunc(42)
## ```
##
## ### Mode 2: Manual Bundle
##
## Load the library manually and bind functions:
##
## ```nim
## let lib = loadObject("mylib.so")
## if lib.isSome:
##   var api: MyApi
##   lib.get.bindAll(api)
##   api.myFunc(42)
## ```
##
## ### Mode 3: Raw Function Lookup
##
## Load individual functions by name:
##
## ```nim
## let lib = loadObject("mylib.so").get
## let func = lib.get[proc(x: cint): cint {.cdecl.}](cstring("myFunc"))
## func(42)
## ```
##
## ## Advantages over C SDL 1.2
##
## | C SDL 1.2                                     | Nim SDL                       |
## |-----------------------------------------------|-------------------------------|
## | `SDL_LoadObject("lib.so")`                    | `loadObject("lib.so")`        |
## | Manual cast: `(FuncPtr)SDL_LoadFunction(...)` | Type-safe `get[T]()` template |
## | No RAII                                       | `SharedObject` auto-unloads   |
## | Manual error checking                         | Asserts on missing functions  |
##
## ## Pragma Reference
##
## - `{.cname: "function_name".}`: Specifies the C function name to load
## - `{.defaultLib: "library.so".}`: Specifies the default library for auto-load
##
## ## See Also
##
## - `sdl/core` - SDL initialization

import std/options
import std/macros
import private/utils

# =========================================================
# 1. CUSTOM PRAGMAS
# =========================================================
template cname*(name: string) {.pragma.}
  ## Specifies the C function name to load from the library.
  ## Use when the Nim field name differs from the C function name.

template defaultLib*(name: string) {.pragma.}
  ## Specifies the default library path for auto-load mode.

# =========================================================
# 2. FFI
# =========================================================
{.push header: "SDL_loadso.h", importc, cdecl.}
proc SDL_LoadObject(sofile: cstring): pointer
proc SDL_LoadFunction(handle: pointer, name: cstring): pointer
proc SDL_UnloadObject(handle: pointer)
{.pop.}

# =========================================================
# 3. SMART POINTER
# =========================================================
type SharedObject* {.requiresInit.} = object
  ## RAII wrapper for a loaded shared library.
  ## Automatically unloads the library when it goes out of scope.
  raw: pointer

proc `=destroy`*(so: var SharedObject) =
  ## Unloads the shared library automatically when SharedObject goes out of scope.
  destroyImpl(so, SDL_UnloadObject)

proc `=sink`*(dest: var SharedObject, source: SharedObject) =
  ## Move semantics: transfers library ownership without double-free.
  sinkImpl(dest, source)

proc `=copy`*(dest: var SharedObject, source: SharedObject) {.error.}
  ## Copying is disabled to prevent double-unload. Use move() instead.

proc unsafeRaw*(so: SharedObject): pointer {.inline.} = so.raw
  ## Extracts the raw library handle pointer. Only valid while `so` is in scope.

proc assumeRaw*(p: pointer): SharedObject {.inline.} = SharedObject(raw: p)
  ## Wraps a raw library pointer into a SharedObject. Assumes ownership.

proc isOpen*(so: SharedObject): bool {.inline.} =
  ## Returns `true` if the library is loaded.
  so.raw != nil

# =========================================================
# 4. THE BUNDLE (Lifecycle Guarantee)
# =========================================================
type
  LoadedApi*[T: object] = object
    ## A bundle containing both the library handle and the bound API.
    ## The library is automatically unloaded when the bundle is destroyed.
    handle: SharedObject
    api*: T

# =========================================================
# 5. INJECTION ENGINE (Metaprogramming)
# =========================================================

template bindAll*[T: object](so: SharedObject, api: var T) =
  ## Binds all function pointers in the API structure from the loaded library.
  ##
  ## For each field with the `cname` pragma, loads the specified C function.
  ## Otherwise, uses the field name as the function name.
  ##
  ## Raises an assertion error if a function is not found.
  for name, field in api.fieldPairs:
    when hasCustomPragma(field, cname):
      const targetName = getCustomPragmaVal(field, cname)
    else:
      const targetName = name

    let ptrFunc = SDL_LoadFunction(unsafeRaw(so), cstring(targetName))
    assert ptrFunc != nil, "Critical: Function '" & targetName & "' not found!"
    field = cast[typeof(field)](ptrFunc)

# =========================================================
# 6. PUBLIC API
# =========================================================

# --- BASE FUNCTIONS (For modes 2 and 3) ---
proc loadObject*(file: string): Option[SharedObject] {.inline.} =
  ## Loads a shared library from the specified file path.
  ## Returns `some(SharedObject)` on success, `none` on failure.
  ##
  ## **Example:**
  ## ```nim
  ## let lib = loadObject("mylib.so")
  ## if lib.isSome:
  ##   echo "Library loaded"
  ## ```
  SDL_LoadObject(file.cstring).toOption(SharedObject)

proc unload*(so: var SharedObject) {.inline.} =
  ## Manually unloads the shared library.
  ## The library is also automatically unloaded when the `SharedObject` is destroyed.
  `=destroy`(so)

# --- MODE 1: AUTO-LOAD ---
proc load*[T: object](): Option[LoadedApi[T]] =
  ## Auto-loads a library and binds all functions in the API structure.
  ##
  ## The type `T` must have the `{.defaultLib: "library.so".}` pragma.
  ##
  ## **Returns:** `some(LoadedApi[T])` on success, `none` on failure
  ##
  ## ```nim
  ## type MyApi = object
  ##   myFunc: proc(x: cint): cint {.cdecl.}
  ## MyApi {.defaultLib: "mylib.so".}
  ##
  ## let api = load[MyApi]()
  ## ```
  when hasCustomPragma(T, defaultLib):
    const dllName = getCustomPragmaVal(T, defaultLib)
    let optLib = loadObject(dllName)
    if optLib.isNone: return none(LoadedApi[T])

    var bundle = LoadedApi[T](handle: optLib.get())
    bundle.handle.bindAll(bundle.api)
    return some(bundle)
  else:
    {.error: "Type needs the {.defaultLib: \"library.so\".} pragma.".}

# --- MODE 2: MANUAL BUNDLE ---
proc initApi*[T: object](so: SharedObject): T {.inline.} =
  ## Binds all functions in the API structure from the loaded library.
  ##
  ## **Example:**
  ## ```nim
  ## let lib = loadObject("mylib.so").get
  ## var api = initApi[MyApi](lib)
  ## api.myFunc(42)
  ## ```
  so.bindAll(result)

# --- MODE 3: RAW LOOKUP (Templates) ---
template get*[T](so: SharedObject, name: cstring): T =
  ## Loads a single function from the library by name.
  ##
  ## **Example:**
  ## ```nim
  ## let func = lib.get[proc(x: cint): cint {.cdecl.}](cstring("myFunc"))
  ## ```
  assert so.isOpen(), "Cannot read function from an unloaded library!"
  cast[T](SDL_LoadFunction(so.unsafeRaw(), name))

template get*[T](so: SharedObject, fnName: untyped): T =
  ## Loads a single function from the library using the identifier name.
  ##
  ## **Example:**
  ## ```nim
  ## let func = lib.get[proc(x: cint): cint {.cdecl.}](myFunc)
  ## ```
  assert so.isOpen(), "Cannot read function from an unloaded library!"
  cast[T](SDL_LoadFunction(so.unsafeRaw(), cstring(astToStr(fnName))))
