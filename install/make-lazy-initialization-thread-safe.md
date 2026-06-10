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
