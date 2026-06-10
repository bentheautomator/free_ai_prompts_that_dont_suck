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
