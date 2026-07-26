## # sdl/mutex
##
## Synchronization primitives for multi-threaded programming
##
## This module provides mutexes, semaphores, and condition variables for
## synchronizing access to shared data between threads. These primitives
## prevent race conditions and ensure thread safety.
##
## ## SDL 1.2 Reference
##
## SDL 1.2 provides three synchronization primitives:
## - **Mutex**: Mutual exclusion lock for protecting shared data
## - **Semaphore**: Counter-based synchronization for resource management
## - **Condition**: Signaling mechanism for thread coordination
##
## **Key C functions:**
## ```c
## SDL_mutex *SDL_CreateMutex(void);
## int SDL_mutexP(SDL_mutex *mutex);  // Lock
## int SDL_mutexV(SDL_mutex *mutex);  // Unlock
##
## SDL_sem *SDL_CreateSemaphore(Uint32 initial_value);
## int SDL_SemWait(SDL_sem *sem);
## int SDL_SemPost(SDL_sem *sem);
##
## SDL_cond *SDL_CreateCond(void);
## int SDL_CondSignal(SDL_cond *cond);
## int SDL_CondWait(SDL_cond *cond, SDL_mutex *mutex);
## ```
##
## ## Usage Example
##
## ```nim
## import sdl
##
## # Mutex example
## var mutex = createMutex().get
## defer: mutex.destroy()
##
## proc worker() =
##   withLock mutex:
##     # Critical section - only one thread at a time
##     sharedData.increment()
##
## # Semaphore example
## var sem = createSemaphore(3).get  # Allow 3 concurrent accesses
## defer: sem.destroy()
##
## proc resourceUser() =
##   discard sem.wait()   # Acquire resource
##   # Use resource...
##   discard sem.post()   # Release resource
##
## # Condition example
## var cond = createCondition().get
## defer: cond.destroy()
##
## proc producer() =
##   withLock mutex:
##     dataReady = true
##     discard cond.signal()  # Wake up consumer
##
## proc consumer() =
##   withLock mutex:
##     while not dataReady:
##       discard cond.wait(mutex)  # Wait for signal
##     # Process data...
## ```
##
## ## Advantages over C SDL 1.2
##
## | C SDL 1.2                               | Nim SDL                                 |
## |-----------------------------------------|-----------------------------------------|
## | `SDL_CreateMutex()` returns pointer     | `createMutex()` returns `Option[Mutex]` |
## | Manual `SDL_DestroyMutex()`             | RAII auto-destroy                       |
## | `SDL_mutexP()` / `SDL_mutexV()` cryptic | `lock()` / `unlock()` clear             |
## | No `withLock` template                  | `withLock` ensures unlock               |
## | Manual error checking                   | `WaitResult` enum for clarity           |
##
## ## Key Features
##
## - **RAII**: Automatic cleanup when objects go out of scope
## - **Type-safe**: Distinct types prevent mixing primitives
## - **Clear API**: `lock()`/`unlock()` instead of cryptic `P`/`V`
## - **Wait results**: `WaitResult` enum clarifies success/failure/timeout
## - **Template helpers**: `withLock` ensures proper unlock
##
## ## Mutex
##
## Use a mutex to protect shared data from concurrent access.
##
## ```nim
## var mutex = createMutex().get
## withLock mutex:
##   # Only one thread executes this block at a time
##   sharedCounter += 1
## ```
##
## ## Semaphore
##
## Use a semaphore to limit concurrent access to a resource.
##
## ```nim
## var sem = createSemaphore(5).get  # Allow 5 concurrent accesses
## discard sem.wait()   # Wait for available slot
## # Use resource...
## discard sem.post()   # Release slot
## ```
##
## ## Condition Variable
##
## Use a condition variable to coordinate thread execution.
##
## ```nim
## var cond = createCondition().get
## var mutex = createMutex().get
##
## # Producer thread
## withLock mutex:
##   dataReady = true
##   discard cond.signal()
##
## # Consumer thread
## withLock mutex:
##   while not dataReady:
##     discard cond.wait(mutex)
##   # Process data...
## ```
##
## ## See Also
##
## - `sdl/thread` - Thread creation and management

import std/options
import private/utils

# =========================================================
# 1. CONSTANTS AND SYNCHRONIZATION RESULTS (NEP-1)
# =========================================================

const
  mutexMaxWait* = high(uint32) ## Equivalent to ~(Uint32)0 (Infinite wait)

type
  WaitResult* {.pure, size: sizeof(cint).} = enum
    ## Eliminates the guesswork of C's 0, -1, and 1 returns.
    error    = -1
    success  = 0
    timedOut = 1

# =========================================================
# 2. C STRUCTURES (Opaque Types - Security Pattern)
# =========================================================
{.push header: "SDL_mutex.h", bycopy, cdecl.}

type
  RawMutex {.importc: "SDL_mutex", incompleteStruct.} = object
  RawMutexPtr* = ptr RawMutex
    ## Pointer to the underlying `SDL_mutex` C struct.

  RawSemaphore {.importc: "SDL_semaphore", incompleteStruct.} = object
  RawSemaphorePtr* = ptr RawSemaphore
    ## Pointer to the underlying `SDL_sem` C struct.

  RawCondition {.importc: "SDL_cond", incompleteStruct.} = object
  RawConditionPtr* = ptr RawCondition
    ## Pointer to the underlying `SDL_cond` C struct.

{.pop.}

{.push header: "SDL_mutex.h", importc, cdecl.}

# --- Internal FFI (camelCase for clean autocomplete) ---
proc SDL_CreateMutex(): RawMutexPtr
proc SDL_mutexP(mutex: RawMutexPtr): cint # P = Lock (Probeer)
proc SDL_mutexV(mutex: RawMutexPtr): cint # V = Unlock (Verhoog)
proc SDL_DestroyMutex(mutex: RawMutexPtr)

proc SDL_CreateSemaphore(initialValue: uint32): RawSemaphorePtr
proc SDL_DestroySemaphore(sem: RawSemaphorePtr)
proc SDL_SemWait(sem: RawSemaphorePtr): cint
proc SDL_SemTryWait(sem: RawSemaphorePtr): cint
proc SDL_SemWaitTimeout(sem: RawSemaphorePtr, ms: uint32): cint
proc SDL_SemPost(sem: RawSemaphorePtr): cint
proc SDL_SemValue(sem: RawSemaphorePtr): uint32

proc SDL_CreateCond(): RawConditionPtr
proc SDL_DestroyCond(cond: RawConditionPtr)
proc SDL_CondSignal(cond: RawConditionPtr): cint
proc SDL_CondBroadcast(cond: RawConditionPtr): cint
proc SDL_CondWait(cond: RawConditionPtr, mutex: RawMutexPtr): cint
proc SDL_CondWaitTimeout(cond: RawConditionPtr, mutex: RawMutexPtr, ms: uint32): cint

{.pop.}

# =========================================================
# 3. SMART POINTERS (Absolute RAII against Leaks)
# =========================================================

type Mutex* {.requiresInit.} = object
  ## RAII wrapper for a mutex (mutual exclusion lock).
  ## Automatically destroyed when it goes out of scope.
  raw: RawMutexPtr

type Semaphore* {.requiresInit.} = object
  ## RAII wrapper for a semaphore (counter-based synchronization).
  ## Automatically destroyed when it goes out of scope.
  raw: RawSemaphorePtr

type Condition* {.requiresInit.} = object
  ## RAII wrapper for a condition variable (thread signaling).
  ## Automatically destroyed when it goes out of scope.
  raw: RawConditionPtr

proc `=destroy`*(s: var Mutex) =
  ## Destroys the mutex automatically when Mutex goes out of scope.
  destroyImpl(s, SDL_DestroyMutex)

proc `=destroy`*(s: var Semaphore) =
  ## Destroys the semaphore automatically when Semaphore goes out of scope.
  destroyImpl(s, SDL_DestroySemaphore)

proc `=destroy`*(s: var Condition) =
  ## Destroys the condition variable automatically when Condition goes out of scope.
  destroyImpl(s, SDL_DestroyCond)

proc `=sink`*(dest: var Mutex; source: Mutex) =
  ## Move semantics: transfers mutex ownership without double-free.
  sinkImpl(dest, source)

proc `=sink`*(dest: var Semaphore; source: Semaphore) =
  ## Move semantics: transfers semaphore ownership without double-free.
  sinkImpl(dest, source)

proc `=sink`*(dest: var Condition; source: Condition) =
  ## Move semantics: transfers condition ownership without double-free.
  sinkImpl(dest, source)

proc `=copy`*(dest: var Mutex, source: Mutex) {.error.}
  ## Copying is disabled to prevent double-free. Use move() instead.

proc `=copy`*(dest: var Semaphore, source: Semaphore) {.error.}
  ## Copying is disabled to prevent double-free. Use move() instead.

proc `=copy`*(dest: var Condition, source: Condition) {.error.}
  ## Copying is disabled to prevent double-free. Use move() instead.

proc unsafeRaw*(m: Mutex): RawMutexPtr {.inline.} = m.raw
  ## Extracts the raw SDL_mutex pointer. Only valid while `m` is in scope.

proc unsafeRaw*(s: Semaphore): RawSemaphorePtr {.inline.} = s.raw
  ## Extracts the raw SDL_sem pointer. Only valid while `s` is in scope.

proc unsafeRaw*(c: Condition): RawConditionPtr {.inline.} = c.raw
  ## Extracts the raw SDL_cond pointer. Only valid while `c` is in scope.

proc assumeRaw*(p: RawMutexPtr): Mutex {.inline.} = Mutex(raw: p)
  ## Wraps a raw SDL_mutex pointer into a Mutex. Assumes ownership.

proc assumeRaw*(p: RawSemaphorePtr): Semaphore {.inline.} = Semaphore(raw: p)
  ## Wraps a raw SDL_sem pointer into a Semaphore. Assumes ownership.

proc assumeRaw*(p: RawConditionPtr): Condition {.inline.} = Condition(raw: p)
  ## Wraps a raw SDL_cond pointer into a Condition. Assumes ownership.

# =========================================================
# 4. PUBLIC API
# =========================================================

# ---------------------------------------------------------
# MUTEX (Mutual Exclusion Locks)
# ---------------------------------------------------------

proc createMutex*(): Option[Mutex] {.inline.} =
  ## Creates a new mutex for protecting shared data.
  ##
  ## **Example:**
  ## ```nim
  ## var mutex = createMutex().get
  ## defer: mutex.destroy()
  ##
  ## withLock mutex:
  ##   # Critical section
  ##   sharedData.modify()
  ## ```
  SDL_CreateMutex().toOption(Mutex)

proc lock*(m: Mutex): bool {.inline.} =
  ## Locks the mutex. Maps to the esoteric `SDL_mutexP` in C.
  ##
  ## **Example:**
  ## ```nim
  ## if mutex.lock():
  ##   # Critical section
  ##   mutex.unlock()
  ## ```
  assert m.raw != nil, "Attempted to use a destroyed/moved Mutex!"
  sdlOk SDL_mutexP(m.raw)

proc unlock*(m: Mutex) {.inline.} =
  ## Unlocks the mutex. Maps to the esoteric `SDL_mutexV` in C.
  ##
  ## **Example:**
  ## ```nim
  ## mutex.lock()
  ## # Critical section
  ## mutex.unlock()
  ## ```
  discard SDL_mutexV(m.raw)

template withLock*(m: Mutex; body: untyped): bool =
  ## Executes a block with the mutex locked, ensuring unlock even on exceptions.
  ##
  ## **Example:**
  ## ```nim
  ## withLock mutex:
  ##   # Critical section
  ##   sharedCounter += 1
  ## ```
  block:
    let success = m.lock()
    if success:
      defer: m.unlock()
      body
    success

# ---------------------------------------------------------
# SEMAPHORES (Resource Counters)
# ---------------------------------------------------------

proc createSemaphore*(initialValue: uint32): Option[Semaphore] {.inline.} =
  ## Creates a new semaphore with the specified initial value.
  ##
  ## **Example:**
  ## ```nim
  ## var sem = createSemaphore(3).get  # Allow 3 concurrent accesses
  ## defer: sem.destroy()
  ## ```
  SDL_CreateSemaphore(initialValue).toOption(Semaphore)

proc wait*(s: Semaphore): WaitResult {.inline.} =
  ## Waits for the semaphore to become available (decrements counter).
  ## Returns `success` if acquired, `error` on failure.
  ##
  ## **Example:**
  ## ```nim
  ## case sem.wait()
  ## of success: echo "Resource acquired"
  ## of error: echo "Failed to acquire"
  ## of timedOut: echo "Timed out"  # Never happens with wait()
  ## ```
  assert s.raw != nil, "Attempted to wait on a destroyed/moved Semaphore!"
  cast[WaitResult](SDL_SemWait(s.raw))

proc tryWait*(s: Semaphore): WaitResult {.inline.} =
  ## Tries to acquire the semaphore without blocking.
  ## Returns `success` if acquired, `timedOut` if unavailable.
  ##
  ## **Example:**
  ## ```nim
  ## if sem.tryWait() == success:
  ##   # Resource acquired
  ##   sem.post()
  ## else:
  ##   # Resource unavailable, do something else
  ## ```
  assert s.raw != nil, "Attempted to wait on a destroyed/moved Semaphore!"
  cast[WaitResult](SDL_SemTryWait(s.raw))

proc waitTimeout*(s: Semaphore, ms: uint32): WaitResult {.inline.} =
  ## Waits for the semaphore with a timeout.
  ## Returns `success`, `timedOut`, or `error`.
  ##
  ## **Example:**
  ## ```nim
  ## case sem.waitTimeout(1000)
  ## of success: echo "Resource acquired"
  ## of timedOut: echo "Timed out after 1 second"
  ## of error: echo "Failed"
  ## ```
  assert s.raw != nil, "Attempted to wait on a destroyed/moved Semaphore!"
  cast[WaitResult](SDL_SemWaitTimeout(s.raw, ms))

proc post*(s: Semaphore): bool {.inline.} =
  ## Increments the semaphore counter (releases the turnstile).
  ##
  ## **Example:**
  ## ```nim
  ## discard sem.post()  # Release resource
  ## ```
  assert s.raw != nil, "Attempted to post a destroyed/moved Semaphore!"
  sdlOk SDL_SemPost(s.raw)

proc value*(s: Semaphore): uint32 {.inline.} =
  ## Current value of the semaphore counter.
  SDL_SemValue(s.raw)

# ---------------------------------------------------------
# CONDITION VARIABLES (Inter-Thread Signals)
# ---------------------------------------------------------

proc createCondition*(): Option[Condition] {.inline.} =
  ## Creates a new condition variable for thread signaling.
  ##
  ## **Example:**
  ## ```nim
  ## var cond = createCondition().get
  ## defer: cond.destroy()
  ## ```
  SDL_CreateCond().toOption(Condition)

proc signal*(c: Condition): bool {.inline.} =
  ## Wakes up ONE thread waiting on this condition.
  ##
  ## **Example:**
  ## ```nim
  ## # Producer thread
  ## withLock mutex:
  ##   dataReady = true
  ##   discard cond.signal()  # Wake up one consumer
  ## ```
  assert c.raw != nil, "Attempted to signal a destroyed/moved Condition!"
  sdlOk SDL_CondSignal(c.raw)

proc broadcast*(c: Condition): bool {.inline.} =
  ## Wakes up ALL threads waiting on this condition.
  ##
  ## **Example:**
  ## ```nim
  ## # Producer thread
  ## withLock mutex:
  ##   dataReady = true
  ##   discard cond.broadcast()  # Wake up all consumers
  ## ```
  assert c.raw != nil, "Attempted to signal a destroyed/moved Condition!"
  sdlOk SDL_CondBroadcast(c.raw)

proc wait*(c: Condition, m: Mutex): WaitResult {.inline.} =
  ## Waits for a condition signal, releasing the mutex while waiting.
  ## When signaled, reacquires the mutex before returning.
  ##
  ## **Example:**
  ## ```nim
  ## # Consumer thread
  ## withLock mutex:
  ##   while not dataReady:
  ##     discard cond.wait(mutex)  # Release mutex and wait
  ##   # Process data...
  ## ```
  assert c.raw != nil, "Attempted to wait on a destroyed/moved Condition!"
  assert m.raw != nil, "Attempted to use a destroyed/moved Mutex with Condition!"
  cast[WaitResult](SDL_CondWait(c.raw, m.raw))

proc waitTimeout*(c: Condition, m: Mutex, ms: uint32): WaitResult {.inline.} =
  ## Waits for a condition signal with a timeout.
  ##
  ## **Example:**
  ## ```nim
  ## withLock mutex:
  ##   while not dataReady:
  ##     case cond.waitTimeout(mutex, 1000)
  ##     of success: break  # Signaled
  ##     of timedOut: echo "Still waiting..."
  ##     of error: break  # Failed
  ## ```
  assert c.raw != nil, "Attempted to wait on a destroyed/moved Condition!"
  assert m.raw != nil, "Attempted to use a destroyed/moved Mutex with Condition!"
  cast[WaitResult](SDL_CondWaitTimeout(c.raw, m.raw, ms))
