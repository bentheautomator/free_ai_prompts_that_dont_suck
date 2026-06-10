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
