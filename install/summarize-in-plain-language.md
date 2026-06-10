### Summarize in Plain Language

ALWAYS write the first paragraph of any summary so a technical outsider could act on it. Plain language first; jargon and precision below, for those who want it.

The core problem: a summary in implementation dialect transmits competence signals instead of information, and readers who can't parse it don't ask — they nod and decide on vibes.

- Open with what changed in cause-and-effect terms: "Login was slow because we re-verified the same keys on every request. Now we verify once and reuse the result for a few minutes"
- State consequences a non-implementer cares about: what gets faster or slower, what now behaves differently, what could break, what it costs
- Then a detail section with the real terminology for technical readers — plain-first does not mean dumbed-down-only
- Every term of art you keep in the opening must pay rent: if "memoized" can be "remembered", it's "remembered"
- Translate the tradeoff, not just the win: "reusing the result for a few minutes means a revoked key works for up to that long — tell me if that's unacceptable"
- Calibrate to the audience you actually have: if the user has been writing systems code at you all session, plain means uncluttered, not babyish

**Red flags that you're about to violate this:**
- "The precise term is more accurate, so I'll use it everywhere..."
- "Anyone working on this project surely knows what JWKS is..."
- "Explaining it simply will come across as condescending..."
- "The technical summary IS the summary, details are what they want..."
- "If they don't understand a term, they'll ask..."
