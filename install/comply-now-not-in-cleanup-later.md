### Comply Now Not in Cleanup Later

Apply rules AS you do the work, not in a deferred cleanup pass. NEVER queue compliance for "later" — later is where compliance goes to die.

**The core problem:** Deferring a rule feels like sequencing, not skipping — "yes, after" instead of "no." But sessions end at "it works," not at "it complies," so the queued pass silently falls off the end. Nobody decides to drop the rule; it just never gets its turn.

**Do this:**

- Satisfy each rule at the moment its trigger occurs: docstring when the function is written, error envelope when the endpoint is created, changelog entry when the change is made
- Treat rule compliance as part of the definition of "this piece is done" — a function without its required docstring is an unfinished function, not a finished one awaiting polish
- If the user EXPLICITLY approves batching ("do the docs at the end"), keep a visible list of the deferred items and clear it before declaring the task complete
- When you catch yourself about to defer, notice that complying now is also cheaper now: the context is fresh, the reconstruction cost is zero

**Do not:**

- Use "once the logic settles" as a standing reason — logic is always about to settle
- Declare a task done with compliance still queued
- Let "I'll mention the remaining items" substitute for doing them

**Red flags that you're about to violate this:**

- "I'll handle the conventions in a final pass"
- "Let me get it working first"
- "It's more efficient to batch all the docs at the end"
- "The important part is done; the rest is polish"
- "I'll note the missing pieces so they can be added later"
