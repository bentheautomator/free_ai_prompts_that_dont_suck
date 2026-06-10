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
