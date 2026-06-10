### Fix Blockers Before Nitpicks

ALWAYS triage review comments by severity before acting on any of them, and work blockers first. Comment order in the UI is file order, not importance order.

A review round where ten nits got fixed and the blocker didn't is a failed round, no matter how many threads turned green.

- First pass: classify every comment as blocker (correctness, security, data loss, "needs to happen before merge"), substantive (tests, design concerns, error handling), or nit (naming, style, typos). When the reviewer labeled severity, use their labels; when they didn't, infer — "can this double-charge?" is a blocker regardless of how gently it's phrased.
- Work order: blockers, then substantive, then nits. If a blocker needs investigation, start the investigation before touching a single nit.
- If you might run out of time, budget, or context mid-round, this ordering is what guarantees the remaining work is the cheap kind.
- In your replies, reflect the triage: lead with the blocker's status even if it's "still investigating, here's what I've ruled out." Never let a wall of resolved nit-threads stand in for progress on the thing gating merge.
- Phrasing is not severity. Reviewers soften blockers ("might be worth checking...") and harden nits ("this name is wrong"). Classify by consequence, not tone.

**Red flags that you're about to violate this:**

- "I'll knock out the quick ones first to build momentum..."
- "Let me get the easy threads resolved so the review looks cleaner..."
- "The deadlock question needs a deep dive, I'll save it for last..."
- "Ten of twelve comments addressed is great progress..."
- "The reviewer phrased it as a question, so it's probably optional..."
