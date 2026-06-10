### One Owner Per Piece of State

NEVER write to state that another module owns. Every table, field, cache, file, or store has exactly one owning module; everyone else reads through its interface and requests changes through its functions.

A second writer bypasses every invariant the owner enforces — validations, transitions, side effects, cache coherence — and creates bugs that only reproduce depending on who wrote last.

- Before writing to any shared state, find who else writes it: grep for updates to that table/field/key. If another module is the established writer, call its function instead of writing directly
- If the owner doesn't expose the operation you need (e.g., no `mark_shipped()`), ADD that function to the owner — that's a smaller change than a second writer, even though it touches another module
- Direct `UPDATE`/`SET` from outside the owning module is a bypass even when the SQL is correct, because the owner's side effects (events, audit rows, cache busts) don't fire
- This applies to in-memory state too: don't mutate another module's exported dict, store, or cached object; call its mutator
- If ownership is genuinely ambiguous (two modules already write it), don't silently become the third — flag the conflict in your summary

**Red flags that you're about to violate this:**
- "It's just one UPDATE, going through the orders module is overkill..."
- "The owning module doesn't have a function for this, so I'll write directly..."
- "Adding a method to their module is out of my task's scope..."
- "I'm setting the same value their code would set anyway..."
- "The field is public/the table is shared, so writing it is allowed..."
