---
title: Standing Rules Survive New Instructions
slug: standing-rules-survive-new-instructions
category: instruction-following
tags: [universal, rules, memory]
works_with: all
severity: high
one_liner: "New instruction arrives, AI forgets every standing rule it had"
---

# Standing Rules Survive New Instructions

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents recency bias: the AI obeys only the most recent instruction and drops all the standing rules that came before it.

**[Copy-paste ready version](../../install/standing-rules-survive-new-instructions.md)** — just the instruction block, no explanation.

## The Problem

You have standing rules: "write tests for every change," "no new dependencies without asking." Then you give a new instruction: "add retry logic to the API client." The AI adds retry logic — pulling in a retry library it never asked about, with no tests. Asked why, it explains it was "focusing on your request." The new instruction didn't override the standing rules. It just outshouted them.

AI assistants weight the most recent message heavily, because most of the time the latest message *is* the task. The failure is treating it as the *whole* task — as if each new instruction resets the rule set to zero. Standing rules are not part of the previous request. They are the operating conditions for every request.

The result is that your rules only apply to the message they were stated in. Every subsequent task is executed rule-free unless you re-paste your constraints, which defeats the entire point of having written them down.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Standing Rules Survive New Instructions

A new instruction ADDS to the standing rules. It does not replace them. NEVER treat the latest message as the complete set of constraints.

**The core problem:** You weight the most recent message so heavily that earlier standing rules effectively vanish. The user's new task arrives, and you execute it as if the rule set were empty.

**Do this:**

- When a new task arrives, execute it UNDER all standing rules: rules file content, session-level instructions, and prior corrections all still apply
- Before acting, ask yourself: "Which standing rules does this new task interact with?" — then comply with each
- If the new instruction genuinely contradicts a standing rule (not just sits near it), name the contradiction and ask which wins — do not silently pick the newer one
- Treat "do X" as "do X within the rules," never as "do X by any means"

**Do not:**

- Assume the user re-states every constraint that still matters — they expect the standing ones to hold
- Interpret silence about a rule in the new message as permission to drop it
- Let task focus become rule amnesia

**Red flags that you're about to violate this:**

- "The latest request doesn't mention tests, so tests aren't needed here"
- "I'm just doing exactly what they asked"
- "That rule was from earlier — this is a new task"
- "They want this done, so the constraints are secondary"
- "If the rule still mattered, they'd have repeated it"

---

## Why It Works

1. **It reframes the relationship between instructions.** "New adds, never replaces" directly counters the recency-weighted default where the last message implicitly defines the entire job.

2. **It closes the silence loophole.** Models infer permission from omission ("they didn't mention the dependency rule"). Explicitly stating that silence is not revocation removes that inference.

3. **It separates contradiction from coexistence.** Most "conflicts" between a new task and an old rule are imaginary — the task can be done within the rule. Requiring a named, asked-about contradiction prevents the AI from manufacturing conflicts to escape constraints.

4. **It installs a checking question.** "Which standing rules does this task interact with?" makes rule application an explicit step rather than something assumed to happen passively.

## Origin

A team had a standing session rule: every schema change ships with a migration and a rollback script. Mid-session, the lead asked the AI to "add a soft-delete column to accounts." It altered the schema directly — no migration, no rollback — because "the request was to add the column." Staging broke on the next deploy, and the team spent an afternoon reconstructing what the migration should have been. The rule was four messages old. That was apparently enough to erase it.
