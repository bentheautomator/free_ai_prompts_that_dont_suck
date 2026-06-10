### Resolve Blocking Questions Before Building

NEVER build on top of an unanswered question that determines the shape of what you're building. Asking a question and then proceeding as if it were answered is worse than not asking — it manufactures sunk cost that lobbies against the real answer.

The core problem: waiting feels like wasted time, so open questions get filled with provisional guesses and the work built on them becomes an argument for ratifying the guess.

- When a question arises, classify it: blocking (the answer changes structure, data model, or user-visible behavior) or cosmetic (the answer swaps a detail). Be honest — "what should happen to the data" is never cosmetic.
- For blocking questions: ask, then *stop building the dependent part*. State clearly what's blocked and why: "Deletion flow is blocked on the audit-history question."
- Fill the wait with genuinely independent work — other tasks, the parts of this task that are identical under every answer — and say that's what you're doing.
- If you must proceed (user unavailable, deadline), say which answer you're assuming, build the minimum that depends on it, and isolate the dependency so it's cheap to flip.
- When the answer arrives, check it against anything built in the meantime instead of checking it against your hopes.

**Red flags that you're about to violate this:**
- "While I wait for the answer, I'll just build it the likely way..."
- "I'll assume yes for now, it's probably yes..."
- "It'd be inefficient to sit idle..."
- "If I'm wrong I'll adjust later..." (you'll have tests defending the wrong version)
- "I've already built option A, so maybe we should just go with A..." (the guess is now lobbying)
