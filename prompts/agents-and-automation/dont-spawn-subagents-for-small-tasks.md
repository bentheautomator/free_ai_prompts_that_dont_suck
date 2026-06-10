---
title: Don't Spawn Subagents for Small Tasks
slug: dont-spawn-subagents-for-small-tasks
category: agents-and-automation
tags: [universal, agents, multi-agent]
works_with: all
severity: medium
one_liner: "Five-agent fan-outs for jobs a single grep would finish"
---

# Don't Spawn Subagents for Small Tasks

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the agent from delegating trivial work to subagents, paying coordination tax and token cost on jobs it should just do.

**[Copy-paste ready version](../../install/dont-spawn-subagents-for-small-tasks.md)** — just the instruction block, no explanation.

## The Problem

Once an agent has a delegation tool, everything starts looking delegable. Need to find where a function is defined? Spawn a search agent. Need to check four files for a pattern? Four parallel subagents, obviously. Each subagent boots with its own system prompt, re-derives context the parent already had, does thirty seconds of actual work, and writes a report longer than the work. The parent then reads four reports. Total cost: maybe twenty times the tokens of just running grep, plus the latency of four cold starts, plus whatever got garbled in translation.

Delegation feels like leverage, which is why agents overuse it — distributing work reads as sophistication, and the cost is hidden in subagent sessions the parent doesn't experience. But a subagent is not a cheap thread; it's a whole new context window that starts from zero, needs the task explained, can misunderstand the task, and returns a summary that must be trusted or re-verified. That overhead is worth paying in exactly two cases: the work is genuinely large, or its bulky intermediate output (reading many files, long exploration) would trash the parent's context. A grep is neither.

The compounding version is worse: subagents that themselves spawn subagents, fan-outs of fan-outs, where a one-line question fans into a dozen sessions and the bill arrives as real money.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It reprices the subagent.** The agent models delegation as forking a thread. Describing the true cost structure — cold start, explanation, misunderstanding risk, report-reading — makes the twenty-times-grep price visible at decision time.

2. **It installs a five-call threshold.** "Don't over-delegate" is vibes; "five or fewer tool calls, do it yourself" is a test the agent can run before every spawn.

3. **It preserves the legitimate cases precisely.** Big tasks and context-protection are named as valid reasons, so the rule can't be read as "never delegate" — which would just get it ignored at the first genuine need.

4. **It bounds the recursive blowup.** Fan-out caps and the no-grandchildren default prevent the exponential failure mode, which is where this stops being friction and starts being a bill.

## Origin

Reviewing a surprisingly expensive automation run, a team found the agent had spawned thirty-one subagents over one session — including one to check whether a package was in package.json, one to read a 40-line config file, and six in parallel to each verify a different import path. Subagent overhead accounted for the majority of the run's token spend. The same session's actual work product: edits to three files, which the parent agent had done itself.
