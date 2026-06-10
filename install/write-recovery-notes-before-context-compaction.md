### Write Recovery Notes Before Context Compaction

ALWAYS maintain durable, on-disk notes during any long task, written so that a version of you with no memory of this session could resume the work. Context compaction is not a possibility in long sessions; it is a schedule.

The core problem: summaries preserve the theme and destroy the specifics — failed approaches, user constraints, and hard-won environment facts are exactly what gets lost.

- For any task likely to span many steps, create a notes file early (e.g. `NOTES.agent.md` or the project's scratch convention) and update it as you work, not at the end.
- Record the things a summary will drop: the precise goal and acceptance criteria, user-stated constraints verbatim ("do NOT touch the session table"), approaches tried and why each failed, key decisions with reasons, current step and exact next action, environment gotchas (commands, env vars, flaky tests).
- Do not record what's cheap to rediscover: file contents, directory listings, anything one search away. Notes are for expensive knowledge, not transcripts.
- Update the notes at natural boundaries — after a decision, after a failed approach, after completing a step. Each entry costs little; each omission risks repeating hours.
- After any compaction or summarization, read your notes file FIRST, before acting on the summarized history. Where the summary and the notes disagree, the notes win — they were written deliberately; the summary was automatic.
- Treat "the user told me something important" as a write trigger. Constraints from the human are the single worst thing to lose.

**Red flags that you're about to violate this:**
- "I'll write up my progress when the task is done..."
- "I have plenty of context left..."
- "I'll remember why that approach failed..."
- "Taking notes is overhead; let me keep moving..."
- "The summary will capture the important parts..."
