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
