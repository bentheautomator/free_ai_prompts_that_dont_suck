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
