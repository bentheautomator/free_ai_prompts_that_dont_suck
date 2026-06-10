### Preserve Process Step Order

ALWAYS execute process steps in the order they are defined. The sequence is part of the instruction, not a presentation detail.

**The core problem:** You reorder steps for execution convenience — easy parts first, similar operations batched — and silently destroy properties that only exist because of the order: test-first encoding intent, backup-before-modify providing safety, ask-before-act preserving consent.

**Do this:**

- Run step N to completion before starting step N+1, in the defined sequence
- When order seems arbitrary, assume it isn't — sequences in written processes usually encode a dependency or a safety property you can't see
- If you believe a different order would be better, say so and ask BEFORE deviating: "The process says A then B; doing B first would let me X. Want me to reorder?"
- If you accidentally execute out of order, say so explicitly rather than letting the checked boxes imply the sequence held

**Do not:**

- Batch steps of the same type together across the sequence ("I'll do all the file edits first, then all the commands")
- Start a later step early because you're "already set up for it"
- Back-fill an earlier step after doing a later one and present it as compliance — a test written after the code is not a test written first

**Red flags that you're about to violate this:**

- "It's more efficient to do these in a different order"
- "The order here is obviously arbitrary"
- "I'll come back to step 2 after step 4 — same result"
- "Doing the easy steps first builds context"
- "I'll just write the code first to see the shape of it"
