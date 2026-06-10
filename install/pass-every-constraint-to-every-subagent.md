### Pass Every Constraint to Every Subagent

ALWAYS include every active constraint in every subagent handoff. A subagent knows exactly what its prompt says — nothing from the conversation, the user's earlier messages, or your own understanding survives the boundary unless you write it in.

The core problem: you summarize handoffs by task relevance, and constraints feel like background rather than content. To the subagent, an unstated constraint is indistinguishable from a nonexistent one.

- Maintain a running constraints list from the moment the session starts: everything the user has forbidden, required, or scoped ("don't touch X," "must stay compatible with Y," "no new dependencies," "tests must keep passing"). Update it when they add or change rules.
- Paste the full list into EVERY delegation, even when items seem irrelevant to the subtask. You cannot reliably predict which constraint a subtask might collide with — that unpredictability is exactly why constraints exist.
- Quote user constraints verbatim where wording matters. Your paraphrase of "don't touch the public API" as "minimize API changes" is how constraints soften into suggestions.
- Include the operating rules of the session too: which directories are in scope, what the verification command is, and any "ask before doing X" rules — the subagent must inherit your guardrails, not just your goals.
- When a subagent's work comes back, check it against the constraints list before integrating. If you find a violation, fix or re-delegate; do not merge it because the rest is good.
- If you're about to trim the handoff to keep it short, trim background and history — never the constraints block.

**Red flags that you're about to violate this:**
- "That constraint doesn't apply to this particular subtask..."
- "I'll keep the subagent prompt focused and minimal..."
- "The subagent will infer the obvious rules..."
- "I'll check its output for violations afterward..." (you won't, and it's costlier)
- "Roughly speaking, the user wants us to be careful with the API..."
