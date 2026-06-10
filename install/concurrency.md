### Acquire Locks in One Global Order

ALWAYS acquire multiple locks in a single, globally consistent order — everywhere, on every code path. Two code paths that take the same two locks in opposite orders will deadlock the first time they overlap; no test will catch it and no log will explain it.

- When locking two objects of the same type (two accounts, two rows, two files), sort by a stable key first: lock `min(a.id, b.id)` then `max(a.id, b.id)` — never in argument order.
- When locking objects of different types, define a fixed hierarchy (e.g., always user → account → ledger) and document it next to the lock definitions. Never lock "upward."
- Before adding a lock acquisition inside code that may already hold a lock, trace what's held at that point. Calling a function that locks B while holding A silently creates an A→B edge.
- Never call out to unknown code (callbacks, virtual methods, event handlers) while holding a lock — you can't know what it locks.
- If a consistent order is impossible, use try-lock with timeout and back off by releasing everything and retrying, and log loudly when it happens.
- Prefer designs needing one lock over designs needing two; a single coarser lock that's obviously correct beats two fine ones that deadlock.

**Red flags that you're about to violate this:**
- "These two locks are never held at the same time." (You checked every path?)
- "I'll lock them in the order the parameters came in."
- "This helper takes its own lock; the caller doesn't need to know."
- "Deadlock is unlikely; this code path is rare."
- "Sorting the lock order makes the code less readable."

### Await Every Promise You Create

ALWAYS `await` (or explicitly handle) every promise at the moment you create it. A bare call to an async function is not a statement that ran — it is work you started and then abandoned, with its errors detached from the caller.

- Never call an async function as a bare statement: `saveUser(user);` → `await saveUser(user);`. If you genuinely intend fire-and-forget, say so explicitly with a named error handler: `void saveUser(user).catch(reportError);` — never an implicit drop.
- Never branch on a promise: `if (isValid(x))` where `isValid` is async is always true. Await it first.
- Never return or serialize a collection of promises: `items.map(fetchDetail)` needs `await Promise.all(...)` around it.
- When you change a function from sync to async, immediately update every call site in the same edit. Search for the function name; do not assume the type checker or tests will catch bare calls.
- In languages with explicit futures/tasks (Python asyncio, C#, Rust), the same rule applies: a coroutine you never awaited never ran; a Task you never observed hides its exception.

**Red flags that you're about to violate this:**
- "This call doesn't return anything I need, so I don't need to await it."
- "The tests pass, so the timing must be fine."
- "It's just a log/audit/notification write — it can happen whenever."
- "I made the function async but the callers don't really depend on completion."
- "The linter didn't flag it, so the promise is handled."

### Cancel Spawned Tasks on Error Paths

Every task you spawn needs an owner, and every exit path — success, failure, early return, timeout — must either join or cancel it. NEVER let a function exit while tasks it spawned keep running unsupervised.

A rejected `gather` or thrown error stops the *waiting*, not the *work*; the survivors run on with no consumer for their results or errors.

- Use structured-concurrency tools where they exist: Python `asyncio.TaskGroup` (cancels siblings on failure, joins on exit), Go `errgroup.WithContext` (one failure cancels the shared context), Kotlin `coroutineScope`. Prefer these over hand-managed task lists.
- With raw `Promise.all`: on rejection the other promises keep executing. If they must stop, pass an `AbortSignal` into the work and abort in the catch; if they can't be stopped, at least attach a handler so late rejections don't become unhandled.
- Keep handles to everything you spawn. A task you can't reference is a task you can't cancel, await, or even observe failing — fire-and-track, never fire-and-forget.
- In try/finally terms: spawn inside `try`, and in `finally` cancel-and-await anything not yet joined. Cancellation without awaiting the cancelled task skips its cleanup.
- Cancellation must propagate: long-running spawned work should check its signal/context at await points and loop iterations, or "cancelled" is a flag nobody reads.
- On timeouts, the same rule: abandoning a timed-out task means it's still running. Cancel it, then handle the timeout.

**Red flags that you're about to violate this:**
- "If something throws, the whole operation just ends." (The spawned parts don't.)
- "The other tasks are harmless; let them finish on their own."
- "I don't need the handle; I'm not going to await it."
- "Promise.all handles the coordination for me."
- "Adding cancellation plumbing doubles the size of this function."

### Capture Loop Variables Before Spawning

When spawning any deferred work in a loop — tasks, threads, goroutines, callbacks, timers — ALWAYS bind the current iteration's values explicitly into the work. Never let deferred code read the loop variable later.

The closure runs after the loop has moved on; it sees the variable's final value, not the value you meant.

- Pass values as arguments, not captures: `executor.submit(deploy, cfg)` not `executor.submit(lambda: deploy(cfg))`; `setTimeout(fn, ms, value)` or a wrapper invoked with the value; default-argument pinning in Python (`lambda cfg=cfg: deploy(cfg)`) when a lambda is unavoidable.
- Go before 1.22 (and any codebase that must support it): shadow inside the loop, `s := s`, before `go func(){ ... }()`, or take the parameter form `go func(s Server){...}(s)`. Check the toolchain version before assuming the new semantics.
- JavaScript: `let`/`const` loop bindings are per-iteration; `var` is not. But a *mutable object* reused across iterations is the same bug regardless of binding — if you build-then-mutate a shared object, clone or construct fresh per iteration before handing it to deferred work.
- The rule covers all deferral, not just threads: event handlers registered in a loop, promise `.then` chains built in a loop, queued jobs whose payload references loop state.
- After writing any spawn-in-loop, verify with one question: "if every spawned body ran only after the loop completed, would it still be correct?" If not, a capture is wrong.
- Suspect this bug whenever N parallel results look identical or only the last item seems processed.

**Red flags that you're about to violate this:**
- "The lambda uses `cfg`, so it gets each iteration's config."
- "It worked when I tested with one item." (One iteration has no wrong value to capture.)
- "Go closures capture by value." (They capture the variable; pre-1.22 there's one per loop.)
- "I'll reuse this options object across iterations to avoid allocations."
- "The tasks start immediately, the loop variable won't have changed yet." (Starting isn't running.)

### Don't Mix Sync and Async Completion

A function that is ever asynchronous must be ALWAYS asynchronous: same completion timing, same error channel, on every path including cache hits and input validation.

Sometimes-sync functions give callers two execution orders for one call site; code that works on the slow path breaks on the fast path, or the reverse.

- Callback APIs: never invoke the callback synchronously on any path. Defer the fast path: `process.nextTick(() => cb(cached))` / `queueMicrotask` / `setImmediate`, so hit and miss have identical ordering.
- Promise-returning functions: deliver *all* failures through the promise. Wrong: `function f(x) { if (!valid(x)) throw Err; return fetch(x); }` — the throw skips every `.catch`. Make the function `async` (sync throws become rejections automatically) or return `Promise.reject(Err)`.
- Don't do heavy or blocking work before the first await in an async function; the caller scheduled a task, not an inline call. Yield first or move the work inside.
- Cached-value fast paths still return a promise: `return Promise.resolve(cached)`, never the raw value from a function that returns promises elsewhere (and never a raw value from one branch and a promise from another).
- Events: never emit synchronously from inside the constructor/subscribe call, before the caller has had a chance to attach listeners.
- One error channel per function. Pick sync or async; mixing means callers need try/catch *and* `.catch` to be safe, and nobody writes both.

**Red flags that you're about to violate this:**
- "I already have the cached value, deferring it is wasted latency."
- "Throwing early on bad input is fail-fast, that's good practice." (In a promise API it's a second error channel.)
- "Callers should handle both sync and async errors anyway."
- "Both paths are tested and both pass."
- "It returns the value directly on this branch, which is simpler."

### Don't Parallelize Ordered Writes

NEVER make sequential operations concurrent without first proving they are order-independent. Treat existing sequence as a claim about ordering until you've shown otherwise; absence of a comment is not absence of a dependency.

Parallelizing dependent writes replaces a deterministic order with a coin flip that lands wrong only under production timing.

- Before moving anything into `Promise.all` / `asyncio.gather` / a goroutine fan-out, check each pair: does B read, reference, or assume the effects of A? Foreign keys, file-then-index, debit-then-credit, create-then-notify are all hard orderings.
- Reads of independent data may overlap freely. Writes may overlap only when they touch disjoint state *and* no observer assumes an order between them.
- Mixed batches are a trap: parallelizing three reads and one write puts the write at a random position among the reads. Keep the write sequenced.
- "It must happen after" includes external observers: if a webhook, queue consumer, or user can see B's effect, A must already be visible by then.
- If order matters for some pairs and not others, parallelize within stages and sequence the stages: `await Promise.all(reads); await write;`
- When you genuinely can't tell whether order matters, keep it sequential and say so. Slow and right beats fast and intermittently corrupt.

**Red flags that you're about to violate this:**
- "These can obviously run in parallel, they're separate calls."
- "I ran it five times and the order came out fine."
- "The original author probably just didn't think to parallelize."
- "The database will sort out the ordering."
- "It's only a notification/index/cache update, order can't matter."

### Don't Share One Connection Across Tasks

NEVER let multiple concurrent tasks use a single connection, session, or cursor unless its documentation explicitly guarantees concurrent use. Default assumption: stateful clients are single-task objects.

A connection is a protocol state machine; two concurrent users interleave commands and read each other's results.

- Share the *pool*, not a connection: acquire per task/request, release when done. Wrong: `conn = pool.acquire()` at module scope. Right: acquire inside the handler, in a `with`/`try-finally` that guarantees release.
- Never fan out on one connection: `gather(q1(conn), q2(conn), q3(conn))` interleaves three queries on one wire. Either run them sequentially on that connection or acquire one connection per concurrent query.
- ORM sessions (SQLAlchemy `Session`, EF `DbContext`, Hibernate `Session`) are single-task objects, full stop. One per request/task; never a module-level or singleton session.
- Check the contract before sharing anything stateful: HTTP clients are usually designed for concurrent use; DB connections, cursors, SMTP/IMAP/FTP clients, and serial ports usually are not. "It has async methods" is not the same claim as "it supports concurrent calls."
- Transactions bind to connections: everything in one transaction must run on the one connection that opened it, and *only* that work runs there until commit/rollback.
- If a connection must be shared (a single websocket, a serial line), serialize access through one owner task and a queue — others submit messages, never touch the socket.

**Red flags that you're about to violate this:**
- "One connection for the whole app is more efficient than a pool."
- "The client has async methods, so concurrent calls must be fine."
- "I'll cache the acquired connection so I don't pay acquisition cost per request."
- "These three queries are read-only, they can't conflict." (They share one result stream.)
- "It's worked fine so far." (Requests haven't overlapped yet.)

### Drop Stale Responses in UI State

ALWAYS guard response handlers that write UI state: before applying a response, verify it belongs to the *latest* request for that piece of state. Responses arrive in any order; last-write-wins means slowest-write-wins.

- Abort the previous request when issuing a new one for the same state: keep an `AbortController` per fetch target, `abort()` it on re-fetch, and ignore `AbortError`. Cancellation beats checking, because it also stops wasted work.
- Where you can't abort, version-check: capture a request ID or the query value when the request starts; in the handler, `if (requestId !== latestRequestId) return;` before any `setState`.
- In effect-based frameworks, use the cleanup function: set a `cancelled` flag in React's `useEffect` cleanup and check it before applying the response. A fetch in an effect without a cleanup guard is a race by default.
- The guard must cover *all* the state the handler writes — results, loading flags, and error banners. A stale request's error overwriting a fresh success is the same bug in a trench coat.
- Don't debounce as a substitute. Debouncing reduces how often the race runs; it doesn't make any ordering guarantee. You can have both; you can't have only debounce.
- Prefer a data-fetching layer that handles this (query libraries with key-based caching and cancellation) over hand-rolling the guard in every component.

**Red flags that you're about to violate this:**
- "Responses will come back in the order I sent them."
- "The debounce means there's only ever one request in flight."
- "This effect refetches on every keystroke; the latest render wins anyway."
- "It works perfectly in dev." (Localhost never reorders.)
- "Adding request tracking to this little component is overkill."

### Guard Against Double Submit

Every state-creating submit MUST be idempotent at the server, enforced by something atomic. Client-side button disabling is a courtesy, not a defense; retries, refreshes, and second tabs go around it.

Two identical requests will arrive concurrently. The server must turn them into one effect.

- Generate an idempotency key client-side when the *form is shown* (not when clicked — both clicks must share the key), send it with the request, and enforce it server-side with a unique constraint or atomic insert. Second arrival gets the first result back, not an error and not a second effect.
- The enforcement must be atomic: a unique index on the key, `INSERT ... ON CONFLICT`, or an atomic set-if-absent. "Check if a request with this key exists, then insert" is itself a race and will pass both concurrent duplicates.
- Pass idempotency keys through to payment and third-party APIs that support them; otherwise your one order can still become their two charges.
- Client side, still do the courtesy: disable on submit, show progress, re-enable on failure. It prevents most duplicates from existing; the server prevents the rest from mattering.
- Retries must reuse the original key. A retry with a fresh key is just a duplicate with paperwork.
- Make the duplicate path return success with the original result. Surfacing "duplicate request" as an error teaches clients to retry harder.

**Red flags that you're about to violate this:**
- "The submit button is disabled while pending, so duplicates can't happen."
- "I check whether the order already exists before inserting." (Both requests check first.)
- "Our users wouldn't double-click a payment button." (They will. Especially that one.)
- "The network layer handles retries transparently." (That's the threat, not the defense.)
- "I'll dedupe by user + timestamp." (Two clicks in the same second share both.)

### Keep CPU Work Off the Event Loop

NEVER run heavy synchronous work — CPU-bound computation or blocking I/O — directly inside an async handler on a single-threaded event loop. While it runs, every other request in the process is frozen.

`async` marks where a function *can* yield, not a guarantee that it does; everything between awaits blocks the world.

- Offload CPU-bound work: Node `worker_threads` or a job queue; Python `loop.run_in_executor` / `ProcessPoolExecutor` (threads don't help CPU-bound Python; processes do); never inline in the handler.
- Ban sync I/O in async contexts: `fs.*Sync`, `execSync`, `child_process.spawnSync`, Python `requests`/`time.sleep`/blocking DB drivers inside `async def`. Use the async equivalents (`asyncio.sleep`, async clients) or push to an executor.
- Watch for hidden CPU: parsing/serializing large JSON or XML, compression, encryption and password hashing, image processing, regex over big inputs (catastrophic backtracking blocks too), sorting or transforming very large arrays.
- Big-input loops that must stay inline need explicit yield points (chunk the work, `await setImmediate()` / `await asyncio.sleep(0)` per chunk) — and that's the fallback, not the plan.
- Treat input size as attacker-controlled: a parse that's fine at 100KB is an outage at 100MB. Bound it or offload it.

**Red flags that you're about to violate this:**
- "The function is async, so it won't block anything."
- "It's only ~50ms of CPU." (Times every request, on the only thread you have.)
- "The sync version is simpler and the async one needs a worker."
- "It ran instantly when I tested it." (Alone, with a small input.)
- "Hashing/zipping/parsing isn't really 'heavy computation.'"

### Keep Signal Handlers Reentrant-Safe

A signal handler does ONE thing: record that the signal happened, then return. All real work — logging, cleanup, closing resources, exiting — happens in normal code that notices the record.

Handlers interrupt arbitrary code mid-operation; anything non-reentrant they touch (allocators, loggers, locks, most of your program) may be in a torn state.

- The pattern: handler sets a `sig_atomic_t`/atomic flag or writes one byte to a self-pipe / wakes an event (`asyncio`'s `add_signal_handler`, Go's `signal.Notify` channel are this pattern built-in). The main loop checks the flag and performs shutdown in a sane context.
- Inside the handler, never: allocate, log, print, take locks, call into your database/network clients, or call anything not explicitly async-signal-safe. In C that's a short documented list; in higher-level languages, behave as if the list were just as short.
- Never touch shared mutable program state from a handler beyond the single flag. The code you interrupted will resume and assumes its invariants held while it was gone.
- Don't raise exceptions from handlers into arbitrary interrupted code as your shutdown mechanism (Python's default KeyboardInterrupt mid-`finally` is the canonical mess); convert the signal to an event your loop consumes deliberately.
- Make second signals meaningful: first SIGINT requests graceful shutdown via the flag; a second one, or a timeout, force-exits. A graceful path that hangs must not be the only path.
- Register handlers early and once; re-registering or registering from threads invites platform-specific surprises.

**Red flags that you're about to violate this:**
- "It's just one log line to say we're shutting down."
- "Python/Node handles signals safely, so the handler can do anything."
- "The handler needs the lock to clean up the shared state properly."
- "Cleanup must happen *in* the handler or the process might die first."
- "It's worked every time I've Ctrl+C'd it."

### Make Lazy Initialization Thread-Safe

NEVER write bare `if (not initialized) → initialize` for shared resources. Concurrent first callers will all pass the check; the initializer must run exactly once no matter how many arrive at once.

The window is widest exactly when it matters: at cold start, when the initializer is slow and the callers are many.

- Async runtimes: memoize the *promise*, not the result. `if (!clientPromise) clientPromise = createClient(); return clientPromise;` — the assignment happens synchronously before any await, so late arrivals share the same in-flight initialization. (Python: store the Task; guard creation with a lock if there are real threads.)
- Threaded runtimes: use the platform's once-primitive — Go `sync.Once`, Python `threading.Lock` around check-and-create, Java holder idiom or a static initializer, C++ function-local static, Rust `OnceLock`/`lazy_static`. Do not hand-roll double-checked locking; most hand-rolled versions are wrong about memory visibility.
- Simplest fix when startup cost allows: initialize eagerly at startup and delete the laziness. A resource always needed isn't lazy, it's just late.
- If the memoized initialization can *fail*, decide what happens: clear the stored promise on rejection so the next caller retries, or every future caller inherits the cached failure forever.
- The same rule covers any "create if missing" on shared maps: use the atomic get-or-create your structure offers (`computeIfAbsent`, `setdefault` under lock), not check-then-insert.

**Red flags that you're about to violate this:**
- "Initialization happens once at startup, there's no race."
- "The check-then-create window is a few nanoseconds." (There's an `await` in it.)
- "Worst case it initializes twice; the second one wins, no harm."
- "Double-checked locking, I remember roughly how it goes."
- "It's only a cache/client/logger; duplicates are harmless."

### Make Read-Modify-Write Atomic

NEVER read a shared value, modify it locally, and write it back as separate steps. Express the mutation as a single atomic operation at the layer that owns the data.

Read-modify-write across concurrent callers loses updates silently; the result is plausible numbers that are wrong.

- Counters and balances: wrong: `v = get(); set(v + 1)`. Right: `UPDATE t SET count = count + 1 WHERE ...`, Redis `INCR`, `AtomicInteger.incrementAndGet()`, `fetch_add`.
- Conditional mutation belongs in the same atom: `UPDATE inventory SET qty = qty - 1 WHERE id = ? AND qty > 0` and check rows-affected, instead of select-check-update.
- In-memory shared state: use atomics or take a lock around the *entire* read-modify-write, not around the read and the write separately.
- UI/state frameworks: use the functional form, `setCount(c => c + 1)`, never `setCount(count + 1)` from a possibly stale closure.
- Collections and JSON blobs count too: load-array, push, save-array is the same bug with a bigger payload. Use an append/array-push operation the store executes atomically, or version-check the write.
- If no atomic primitive exists at that layer, that's a design smell: move the mutation to a layer that has one (DB, single-writer task, actor) rather than hoping callers won't overlap.

**Red flags that you're about to violate this:**
- "Two requests won't realistically hit this at the same time."
- "It's just a view counter; close enough is fine."
- "I already have the value in a variable, might as well use it."
- "The whole handler is fast, the window is tiny."
- "I'll wrap it in a transaction" (a transaction without the right semantics still reads stale and overwrites).

### Never Check Then Act

NEVER write code that checks a condition and then acts on it as two separate steps when concurrent callers could interleave between them. The check is stale the instant it returns. Replace the check-then-act pair with a single atomic operation and handle its failure.

- Don't check existence then create: `if not exists: insert` → use a unique constraint plus insert-and-catch-conflict, or an upsert (`INSERT ... ON CONFLICT`, `putIfAbsent`, `setdefault`).
- Don't check a file then open it: `if (!fs.existsSync(p)) fs.writeFileSync(p)` → open with exclusive-create flags (`'wx'`, `O_CREAT|O_EXCL`) and handle `EEXIST`.
- Don't check a balance/quota/inventory then deduct: read-check-write → a conditional atomic write: `UPDATE account SET balance = balance - :amt WHERE id = :id AND balance >= :amt`, then check rows affected.
- Don't check "is this slot free" then claim it (usernames, seats, locks, job leases). Claim it atomically and treat rejection as the normal path, not an error.
- When no atomic primitive exists, hold a lock around both the check and the act — the same lock for every code path that touches that state.
- Treat the conflict outcome as expected control flow: catch it, report it cleanly, retry where appropriate. "It would have already failed the check" is not a reason to skip handling it.

**Red flags that you're about to violate this:**
- "I already checked that it doesn't exist two lines up."
- "This endpoint won't get concurrent calls for the same user."
- "The window between check and act is tiny."
- "I'll validate in the app layer; the database doesn't need a constraint."
- "Adding conflict handling complicates the happy path."

### Never Mutate a Collection You're Iterating

NEVER add to or remove from a collection while iterating it — neither in the loop body, nor in anything the loop body calls, nor from another task while the iteration runs.

Iterators assume a frozen structure; mutation mid-walk yields skipped elements, runtime exceptions, or silent garbage depending on the language's mood.

- Filter, don't remove-in-place: `items = items.filter(keep)` / a new list comprehension, instead of deleting inside the loop.
- If you must mutate the original, collect the changes first: gather `toRemove` during iteration, apply after the loop ends.
- Iterating shared state in concurrent code: take a snapshot first — `for s of [...sessions]`, `list(d.items())`, copy under a brief lock — then iterate the snapshot. Accept that the snapshot can be momentarily stale; that's the contract, make the body tolerate it (an entry may be gone by the time you touch it).
- Watch the indirect path: the loop body calls `handleError()`, which calls `unsubscribe()`, which mutates the collection. Mutation through three frames of helpers still counts.
- Async loops over shared collections: every `await` inside the loop is an opportunity for another task to mutate it. Snapshot before the loop, or use a structure designed for it (a proper queue/channel, `ConcurrentHashMap` with its documented weakly-consistent iteration).
- Language-specific safe tools exist — `iterator.remove()` in Java, `retain`/`drain_filter`-style APIs — use them only when they're explicitly documented for the job.

**Red flags that you're about to violate this:**
- "I'll just remove it right here, it's one element."
- "Nothing else touches this list." (The cleanup task does.)
- "It worked on my test data." (Detection is probabilistic; small inputs rarely trip it.)
- "The remove happens in a callback, not in the loop itself."
- "Copying the collection first is wasteful."

### Never Sleep to Synchronize

NEVER use a sleep, delay, or pause to wait for another operation to complete. Wait on the operation itself: its promise, its completion event, its readiness check. A sleep is a guess about timing; under load the guess is wrong, and when it's right you paid for it in latency.

- If you can await it, await it: the task's promise/future/join handle. The need to sleep usually means a handle was dropped — recover the handle, don't paper over its absence.
- If completion is signaled, wait on the signal: condition variables, events, channels, `waitForSelector`, readiness probes — wait *for the condition*, with a timeout as failure detection.
- If you can only observe state, poll the condition with backoff and a deadline: `until(() => jobStatus() === 'done', { timeout })`. Polling a real condition is honest; sleeping a fixed time is hoping.
- In tests, the rule is absolute: wait for the element/state/event with the framework's built-in waiting, never `sleep(2000)`. Sleep-based tests are flaky on CI by design and slow everywhere by construction.
- A retry loop with backoff around the *dependent operation* beats a pre-sleep: attempt, and on "not ready," back off and retry. The system tells you when it's ready by succeeding.
- The only legitimate sleeps are ones where the duration itself is the requirement: rate limiting, backoff between retries, scheduled cadence. If removing the sleep would cause a *correctness* failure rather than a pacing change, it's synchronization in disguise.

**Red flags that you're about to violate this:**
- "Two seconds is plenty of time for that to finish."
- "Adding a sleep fixed the flaky test."
- "There's no way to know when it's done." (There's status, an event, or a retry — look harder.)
- "I'll make the sleep longer to be safe." (Now it's slow *and* still a guess.)
- "It's just for the demo/CI/this one script."

### Parallelize Independent Awaits

When you write two or more awaits in sequence, ALWAYS check whether the later operation uses the earlier one's result. If it doesn't, start both before awaiting either.

Sequential awaits on independent operations sum their latencies for no benefit; this is the single most common self-inflicted slowness in async code.

- Wrong: `const user = await getUser(id); const orders = await getOrders(id);`. Right: `const [user, orders] = await Promise.all([getUser(id), getOrders(id)]);` (Python: `asyncio.gather`; C#: `Task.WhenAll`; Go: errgroup or goroutines + WaitGroup).
- A loop of `for (const id of ids) { await fetchItem(id) }` over independent items is the same bug at scale. Map to tasks, then await the batch, with a concurrency bound if the list is large or the target is rate-limited.
- Only parallelize genuinely independent operations. If B reads what A wrote, or B must not happen when A fails, keep them sequential and say nothing more.
- When you parallelize, handle the new failure semantics deliberately: `Promise.all` rejects on first failure; use `Promise.allSettled` / `gather(..., return_exceptions=True)` when you need every result regardless.
- Don't interleave a write with reads "for speed." Writes order the world; reads merely observe it.

**Red flags that you're about to violate this:**
- "I'll just await each one; it's cleaner to read."
- "These calls are fast, sequencing them doesn't matter."
- "Parallelizing means restructuring the error handling, so I'll skip it."
- "The tests run in milliseconds either way."
- "I'll optimize this later if it's slow." (Nobody measures it later.)

### Release Locks Before You Await

NEVER hold a lock, mutex, or semaphore across an `await`, a network call, a disk read, or any operation whose duration you don't control. A critical section must contain only fast, local, in-memory work.

Locks held across I/O serialize the entire service behind the slowest caller, and deadlock outright when the awaited work re-enters the same lock.

- Structure code as: acquire → read/copy what you need → release → do the slow work → acquire → write the result. Two short critical sections, not one long one.
- Wrong: `async with lock: data = await fetch(url); cache[key] = data`. Right: read inputs under the lock, `await fetch` with no lock held, write the result under the lock (and re-validate before writing, since the world moved while you were away).
- Never call user-provided callbacks, emit events, or log to remote sinks while holding a lock. You can't see what they acquire.
- If the slow work genuinely must be exclusive (one refresh at a time), use a dedicated flag or single-flight pattern around the work, not the data lock across the I/O.
- In Java/C#/Go, the same rule applies to blocking I/O inside `synchronized`/`lock`/`mu.Lock()` regions: I/O does not belong inside.

**Red flags that you're about to violate this:**
- "Wrapping the whole function in the lock is simpler and definitely safe."
- "The fetch is fast, the lock won't be held long."
- "Releasing and re-acquiring is more code and more chances for bugs."
- "Nothing else uses this lock right now."
- "It's async, so the lock isn't really blocking anyone."

### Single-Flight Concurrent Cache Fills

A cache fill MUST be deduplicated per key: when callers miss concurrently, exactly one computes the value and the rest await that same computation. Check-compute-store with no in-flight tracking sends every concurrent miss to the backend at once.

A cache without single-flight protects the backend only between expirations, and attacks it at every one.

- In-process: keep a map of in-flight promises/futures per key. On miss, atomically check it — found means await it; absent means insert your promise *before* starting the fetch (insert-then-fetch, or the second caller slips through). Remove the entry when the fill completes.
- Clean up on failure: remove the in-flight entry and decide whether waiters get the error or a retry — but never leave a rejected promise as the permanent answer for the key, and never let a failed fill keep new callers queued behind a corpse.
- Use the built-in where one exists: Go's `singleflight` package, caching libraries with `getOrCompute`/loader semantics that document fill deduplication. Don't hand-roll what the platform provides.
- Cross-instance stampedes (many servers, one Redis, one hot key) need more than in-process tracking: a short-TTL fill lock, probabilistic early refresh, or serving the stale value while one worker revalidates (stale-while-revalidate). Pick one deliberately for genuinely hot keys.
- Expiry policy is part of the fix: refreshing a hot key *before* expiry (background refresh) means concurrent misses never happen on it at all.
- Don't confuse this with lazy init: singletons fill once per process; caches fill per key, repeatedly, under TTL — the dedup must be keyed and must reset after each fill.

**Red flags that you're about to violate this:**
- "Check cache, on miss compute and store — that's just what a cache is."
- "Duplicate fills are wasteful but harmless; same value either way." (Two hundred copies of the same expensive query is the outage.)
- "The TTL is long, misses are rare." (Rare and synchronized: every caller misses at the same moment.)
- "Our load tests passed." (Did one warm the cache first?)
- "I'll lock the whole cache during fills." (Now every key waits on one key's slow fetch.)

### Stop Timers From Overlapping Themselves

NEVER schedule periodic work with a fixed-rate timer that can fire while the previous run is still executing. Schedule the next run only after the current run finishes.

`setInterval` and bare cron start work on a clock, not on completion; one slow run means two concurrent runs, and concurrent runs of a job built to run alone means duplicates and contention.

- Use the recursive form: run the job, and in its completion path (success *and* failure), `setTimeout(loop, delay)`. In Python: `while True: await job(); await asyncio.sleep(delay)` in a single task. This makes overlap impossible by construction.
- `setInterval(asyncFn, ms)` is always wrong for async work: the interval doesn't await the callback, so the timer and the work are unrelated schedules.
- Wrap the body in try/catch/finally; an unhandled rejection that skips the rescheduling line kills the loop forever, silently. A periodic job that can stop must also be observable (log each run, alert on absence).
- If the schedule genuinely must be fixed-rate (run at :00 exactly), add an explicit overlap policy: an in-process running flag at minimum, a distributed lock or lease if multiple instances run the schedule — skip or queue, but decide.
- Cron jobs need the same: `flock`, a lock table, or your scheduler's concurrency policy (e.g. forbid). Assume the job will someday outlive its period.
- On shutdown, cancel the timer and wait for an in-flight run before tearing down what it uses.

**Red flags that you're about to violate this:**
- "The job takes 2 seconds and runs every 5 minutes; overlap is impossible."
- "setInterval is the standard way to do something periodically."
- "If it overlaps occasionally, the runs are independent anyway." (They share the same pending rows.)
- "The interval callback is async, so it'll just await naturally."
- "I'll keep the interval and make the body faster."

### Version-Check Concurrent Updates

Every read-edit-save flow MUST carry a version: reads return it, writes assert it. A write based on stale data must fail visibly, never overwrite silently.

Blind last-write-wins means concurrent editors destroy each other's work with no error anywhere.

- Add a version (integer or timestamp) to mutable records. Update with `UPDATE t SET ..., version = version + 1 WHERE id = ? AND version = ?` and check rows-affected; zero rows means conflict, and conflict is a result to handle, not a row to assume.
- Thread the version through the full loop: API responses include it (field or ETag), edit forms carry it, save requests send it back, the server asserts it (`If-Match` for HTTP APIs). A version checked only server-side against a server-side read guards the wrong gap — the race is across the *user's* edit session.
- On conflict, do something honest: return 409/412 with the current state, let the caller re-fetch, re-apply, or merge. Never auto-retry by re-reading and re-saving the same payload — that's last-write-wins with extra steps.
- Partial updates reduce collisions but don't eliminate them: PATCHing one field still needs a version when the validity of the change depends on state the editor saw.
- Same rule outside databases: document stores (use the native CAS/sequence number), config files, object storage (conditional puts), in-memory stores (compare-and-set). Anywhere two writers can hold copies of one record.
- Background jobs editing records that humans also edit need versions most of all; the job won't file a ticket when its update evaporates.

**Red flags that you're about to violate this:**
- "Two people editing the same record at once basically never happens."
- "Last write wins is a reasonable default; the newest edit is probably right." (Newest *save*, not newest *information*.)
- "Adding version plumbing through the API is a lot of ceremony for a CRUD form."
- "We can add conflict handling later if users complain." (They can't tell what happened, so they won't complain — they'll just lose data.)
- "The ORM's save() handles concurrency." (Check. Most write all fields, unconditionally.)
