## # sdl/thread
##
## Thread creation and management
##
## This module provides functions for creating and managing threads in SDL 1.2.
## Threads allow you to run code in parallel, which is useful for background
## tasks like audio processing, asset loading, or AI calculations.
##
## ## SDL 1.2 Reference
##
## SDL 1.2 provides basic threading primitives through `SDL_CreateThread`,
## `SDL_WaitThread`, and `SDL_KillThread`. Threads are identified by unique IDs.
##
## **Key C functions:**
## ```c
## SDL_Thread *SDL_CreateThread(int (SDLCALL *fn)(void *), void *data);
## void SDL_WaitThread(SDL_Thread *thread, int *status);
## void SDL_KillThread(SDL_Thread *thread);
## Uint32 SDL_ThreadID(void);
## Uint32 SDL_GetThreadID(SDL_Thread *thread);
## ```
##
## ## Usage Example
##
## ```nim
## import sdl
## import sdl/thread
##
## proc workerThread(data: pointer): int32 {.cdecl.} =
##   echo "Worker thread started!"
##   # Do work...
##   echo "Worker thread finished!"
##   return 0  # Exit code
##
## runMain:
##   let ctx = sdlInit()
##   defer: ctx.quit()
##
##   # Create and start a thread
##   var thread = initThread(workerThread).get
##   let exitCode = thread.wait()
##   echo "Thread exited with code: ", exitCode
## ```
##
## ## C API Mapping
##
## | C SDL 1.2                       | Nim SDL                                   |
## |---------------------------------|-------------------------------------------|
## | `SDL_CreateThread(fn, data)`    | `initThread()` returns `Option[Thread]`   |
## | `SDL_WaitThread(thread, &st)`   | `thread.wait()` returns `int32`           |
## | `SDL_KillThread(thread)`        | `thread.kill()`                           |
## | `SDL_ThreadID()`                | `currentThreadId()` returns `ThreadId`    |
## | `SDL_GetThreadID(thread)`       | `thread.id()` returns `ThreadId`          |
##
## ## Key Features
##
## - **RAII threads**: Automatic `SDL_WaitThread` when `Thread` goes out of scope
## - **Type-safe callbacks**: `ThreadFunc` signature enforces correct usage
## - **Thread IDs**: Unique identifiers for each thread
## - **Safe termination**: `kill()` ensures proper cleanup
##
## ## Thread Function Signature
##
## Thread functions must follow the `ThreadFunc` signature and return an exit code.
##
## ```nim
## proc myThread(data: pointer): int32 {.cdecl.} =
##   # Do work...
##   return 0  # Exit code
## ```
##
## ## Warning: Thread Safety
##
## - Threads share the same memory space
## - Use `Mutex` or `Semaphore` to protect shared data
## - `SDL_KillThread` is dangerous and can cause deadlocks
## - Prefer cooperative termination over `kill()`
##
## ## See Also
##
## - `sdl/mutex` - Synchronization primitives
## - `sdl/timer` - Async timers (alternative to threads)

import std/options
import private/utils

# =========================================================
# 1. SIGNATURES AND TYPES
# =========================================================

type
  ThreadId* = distinct uint32
    ## Unique identifier for a thread.

proc `==`*(x, y: ThreadId): bool {.borrow.}
  ## Compares two ThreadId values for equality.

proc `$`*(x: ThreadId): string {.borrow.}
  ## Converts a ThreadId to its string representation.

type
  ThreadFunc* = proc(data: pointer): int32 {.cdecl.}
    ## The strict signature for functions that run in parallel threads.
    ## MUST use the cdecl calling convention and return a 32-bit integer.

# =========================================================
# 2. C STRUCTURES (Opaque Types) AND FFI
# =========================================================
{.push header: "SDL_thread.h", bycopy, cdecl.}
type
  RawThread {.importc: "SDL_Thread", incompleteStruct.} = object
    ## Opaque C struct from SDL_thread.h. Never accessed directly.
  RawThreadPtr* = ptr RawThread
    ## Pointer to a raw SDL_Thread for FFI interop.
{.pop.}

{.push header: "SDL_thread.h", importc, cdecl.}
proc SDL_CreateThread(fn: proc(data: pointer): cint {.cdecl.},
                      data: pointer): RawThreadPtr
proc SDL_ThreadID(): uint32
proc SDL_GetThreadID(thread: RawThreadPtr): uint32
proc SDL_WaitThread(thread: RawThreadPtr, status: ptr cint)
proc SDL_KillThread(thread: RawThreadPtr)
{.pop.}

# =========================================================
# 3. SMART POINTER (RAII with Relentless Auto-Join)
# =========================================================
type Thread* {.requiresInit.} = object
  ## RAII wrapper for a thread.
  ## Automatically waits for the thread to finish when it goes out of scope.
  raw: RawThreadPtr

proc `=destroy`*(t: var Thread) =
  ## RAII destructor — waits for the thread to finish and frees the resource.
  if t.raw != nil:
    SDL_WaitThread(t.raw, nil)
    t.raw = nil

proc `=sink`*(dest: var Thread; source: Thread) =
  ## RAII move hook — transfers thread ownership from source to dest.
  sinkImpl(dest, source)

proc `=copy`*(dest: var Thread; source: Thread) {.error.}
  ## RAII copy hook — threads are move-only, copying is forbidden.

proc unsafeRaw*(t: Thread): RawThreadPtr {.inline.} =
  ## Returns the raw SDL_Thread pointer. Use only for FFI interop.
  t.raw

proc assumeRaw*(p: RawThreadPtr): Thread {.inline.} =
  ## Wraps a raw SDL_Thread pointer into a Thread, assuming ownership.
  Thread(raw: p)

# =========================================================
# 4. PUBLIC API (High Abstraction and Synchronization)
# =========================================================

proc initThread*(fn: ThreadFunc; data: pointer = nil): Option[Thread] {.inline.} =
  ## Creates and immediately starts a new parallel thread.
  ##
  ## **C API comparison:** `SDL_CreateThread` returns a raw `SDL_Thread*` (NULL
  ## on failure) and requires manual `SDL_WaitThread`. `initThread` wraps the
  ## result in `Option[Thread]` and destroys the thread automatically via RAII.
  ##
  ## **Example:**
  ## ```nim
  ## proc worker(data: pointer): int32 {.cdecl.} =
  ##   echo "Working..."
  ##   return 0
  ##
  ## var thread = initThread(worker).get
  ## discard thread.wait()  # Wait for completion
  ## ```
  let p = SDL_CreateThread(cast[proc(data: pointer): cint {.cdecl.}](fn), data)
  if p == nil: none(Thread) else: some(Thread(raw: p))

proc currentThreadId*(): ThreadId {.inline.} =
  ## Unique ID of the currently executing thread.
  ##
  ## **Example:**
  ## ```nim
  ## echo "Current thread ID: ", currentThreadId()
  ## ```
  ThreadId(SDL_ThreadID())

proc id*(t: Thread): ThreadId {.inline.} =
  ## Unique ID of a specific thread.
  ##
  ## **Example:**
  ## ```nim
  ## let thread = initThread(worker).get
  ## echo "Thread ID: ", thread.id()
  ## ```
  assert t.raw != nil, "Attempted to read ID of a dead/joined thread!"
  ThreadId(SDL_GetThreadID(t.raw))

proc wait*(t: var Thread): int32 {.inline.} =
  ## Blocks until the specified thread finishes (joins the thread).
  ## Returns the exit code. After waiting, the thread is destroyed.
  ##
  ## **Example:**
  ## ```nim
  ## var thread = initThread(worker).get
  ## let exitCode = thread.wait()
  ## echo "Thread exited with code: ", exitCode
  ## ```
  assert t.raw != nil, "Thread has already been joined or destroyed!"
  var status: cint
  SDL_WaitThread(t.raw, addr status)
  t.raw = nil
  result = int32(status)

proc kill*(t: var Thread) {.inline.} =
  ## FORCIBLY terminates a thread immediately. EXTREMELY DANGEROUS.
  ## Can leave mutexes locked forever (deadlocks) and corrupt shared state.
  ## Only use as a last resort when cooperative termination is impossible.
  ##
  ## **Warning:** This can cause deadlocks and resource leaks.
  ##
  ## **Example:**
  ## ```nim
  ## var thread = initThread(worker).get
  ## # ... if thread is stuck ...
  ## thread.kill()  # Force termination
  ## ```
  if t.raw != nil:
    SDL_KillThread(t.raw)
    SDL_WaitThread(t.raw, nil)
    t.raw = nil
