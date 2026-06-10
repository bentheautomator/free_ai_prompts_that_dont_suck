---
title: Write Recovery Notes Before Context Compaction
slug: write-recovery-notes-before-context-compaction
category: agents-and-automation
tags: [universal, agents, context]
works_with: all
severity: high
one_liner: "Losing the plan, decisions, and gotchas when the context window rolls over"
---

# Write Recovery Notes Before Context Compaction

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the post-compaction version of the agent from inheriting a half-finished task with no idea what was decided, tried, or ruled out.

**[Copy-paste ready version](../../install/write-recovery-notes-before-context-compaction.md)** — just the instruction block, no explanation.

## The Problem

Long sessions end in compaction the way long hikes end in dark: predictably, and worse if you didn't plan for it. When the context window fills, the transcript gets summarized — and summaries are lossy in exactly the wrong places. The big arc survives ("refactoring the auth module") while the load-bearing specifics die: the user said don't touch the session table, approach two failed because of the circular import, the magic env var that makes tests pass locally. The post-compaction agent knows what it's doing but not what it has learned.

The result is a familiar second act: the agent re-tries the approach that already failed, re-violates the constraint the user stated an hour ago, or re-derives — at full token price — facts it had already established. From the outside it looks like the agent got abruptly dumber mid-task. It did: it lost its working memory and had made no provision for that entirely foreseeable event.

Agents don't prepare for compaction because, in the moment, context feels infinite — there's no fuel gauge in their field of view, and writing notes feels like overhead compared to making progress. But durable state in a file costs a few hundred tokens once; re-learning a failed approach costs thousands, plus the user's patience.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It reframes compaction as scheduled, not hypothetical.** Agents skip preparation for events they treat as unlikely. Stating that long sessions always compact converts note-taking from insurance to logistics.

2. **It specifies what to write by what summaries lose.** "Take notes" produces journals nobody reads. Targeting the categories summarization reliably destroys — failed paths, verbatim constraints, gotchas — makes the notes small and load-bearing.

3. **It sets the precedence rule in advance.** Post-compaction, the agent has a confident summary and a notes file; without a tiebreaker it follows the summary. "Notes win" resolves the conflict before it occurs.

4. **It triggers on events, not moods.** Writing "at natural boundaries" and "when the user states a constraint" attaches the habit to recognizable moments rather than the agent's sense of spare time, which is always zero.

## Origin

Three hours into a gnarly dependency upgrade, an agent's session compacted. The summary retained "upgrading the framework, several tests failing" but dropped both the user's instruction to keep the public API frozen and the finding that the v2 codemod corrupted decorators. The post-compaction agent promptly re-ran the codemod, re-broke the decorators it had spent forty minutes hand-fixing, and shipped an API rename the user had explicitly forbidden. A six-line notes file would have prevented all three.
