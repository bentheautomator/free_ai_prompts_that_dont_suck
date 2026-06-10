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
