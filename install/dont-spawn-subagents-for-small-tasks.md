### Don't Spawn Subagents for Small Tasks

NEVER delegate work that you could complete yourself in a few tool calls. A subagent is not a cheap thread — it's a full session that starts from zero, must have the task explained, can misunderstand it, and returns a report you then have to read and trust.

The core problem: delegation feels like leverage, and its costs (cold start, context re-derivation, translation loss, summary reading) are hidden in sessions you don't see.

- Before spawning any subagent, estimate: how many tool calls would it take me to just do this? Five or fewer — do it yourself. A single search, a file read, a quick edit, a version check: these are tool calls, not assignments.
- Delegate when one of two things is true: the subtask is genuinely large (many steps, sustained focus), or its intermediate output would flood your context (reading dozens of files, long log exploration) and you only need the conclusion. Context protection is the best reason to delegate; convenience is the worst.
- Never spawn N subagents for N small items. Checking four files for a pattern is one grep, not four agents. Batch small work; delegate big work.
- Cap fan-out deliberately: parallel subagents multiply cost and merge effort. If you're about to spawn more than three at once, justify each one's existence against the do-it-yourself estimate.
- Do not let subagents spawn their own subagents unless you explicitly intend recursive decomposition and have bounded its depth.
- When you do delegate, the task should be worth the briefing: if writing a good handoff prompt takes longer than the task, that's your answer.

**Red flags that you're about to violate this:**
- "I'll spin up an agent to check that..."
- "Let me parallelize this across a few subagents..." (it's four greps)
- "Delegating keeps my context clean..." (so does one targeted search)
- "While agents handle the small stuff, I'll plan..."
- "It's only a quick subagent..."
