### Preserve Concurrency Semantics

When refactoring, the concurrency behavior of the code is part of its behavior. NEVER change what runs sequentially vs in parallel, what is sync vs async, or what is protected by which lock, unless that change is the explicitly requested task.

Sequentiality, locks, and sync boundaries usually encode external constraints (rate limits, ordering requirements, deadlock history) that are invisible in the code itself.

- A sequential loop over I/O stays sequential. Do not introduce `Promise.all`, `asyncio.gather`, thread pools, or batch parallelism as an "improvement"; the loop may be the rate limiter. Propose parallelization separately if you think it's safe.
- Conversely, do not serialize existing parallelism; fan-out is often load-bearing for latency.
- Locks, mutexes, semaphores, and synchronized blocks survive restructuring with identical scope: the same statements guarded, acquired and released in the same order. When extraction splits a critical section, decide explicitly where the lock now lives and verify every formerly guarded statement still is.
- Do not convert sync functions to async or async to sync during cleanup. The color of a function is a contract with every caller; changing it ripples through the whole stack and changes scheduling behavior even when it compiles.
- Preserve what's awaited and when: moving an `await` earlier or later, or dropping a fire-and-forget, reorders observable work.
- Keep thread/task-local state, queue sizes, worker counts, and executor choices identical; they're tuning, not style.
- If the concurrency structure looks wasteful or wrong, finish the shape-preserving refactor and raise it as a separate observation.

**Red flags that you're about to violate this:**

- "These calls are independent, so I'll run them in parallel."
- "Making this async matches the rest of the codebase."
- "The lock can move inside the helper; it's the same thing."
- "Sequential awaits in a loop are a classic performance bug."
- "I'll modernize this to use the concurrent executor while restructuring."
