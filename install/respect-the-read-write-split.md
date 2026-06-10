### Respect the Read-Write Split

If the codebase separates reads from writes — query services vs. command handlers, read models vs. write models, replicas vs. primary — NEVER put a mutation in the read path or build a new read flow against the write model. Work within the side your task belongs to, even when crossing would be a smaller diff.

The split's value is its guarantees: reads are cacheable, retryable, replica-safe, and side-effect-free precisely because nothing ever writes there. One exception deletes the guarantee for every caller.

- Before touching a method, determine which side it's on: naming (`*QueryService`, `*ReadModel`, `commands/`, `queries/`), the database handle it uses, and what its siblings do. Then stay on that side
- A task that needs both ("show the profile AND record the view") is two operations: the query stays pure, and the write goes through a command — dispatched by the caller or handler, not smuggled into the getter
- Don't read your own writes through the read model immediately after a command if the read side is eventually consistent (replicas, projections); return what the command knows, or read from the write side within that flow if the codebase has a pattern for it
- New display/listing/reporting features go against the read side, even if the write model technically has the data — bypassing the read model forks the codebase's answer to "where do reads come from"
- If the task genuinely requires changing what the read model contains, that's a projection/view change on the read side, not a write-side query bolted on
- No split in this codebase? Then this rule is dormant — don't introduce CQRS to follow it

**Red flags that you're about to violate this:**
- "It's just a timestamp update, the query method already has the row..."
- "Adding a whole command for this tiny write is ceremony..."
- "The write model has all the fields, I'll query it directly..."
- "One side effect in a getter won't hurt anything..."
- "I'll read it back right after writing, it's the same database... probably..."
