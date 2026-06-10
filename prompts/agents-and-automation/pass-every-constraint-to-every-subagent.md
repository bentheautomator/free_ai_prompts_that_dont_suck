---
title: Pass Every Constraint to Every Subagent
slug: pass-every-constraint-to-every-subagent
category: agents-and-automation
tags: [universal, agents, multi-agent]
works_with: all
severity: high
one_liner: "Subagents violating rules the parent agent knew but never relayed"
---

# Pass Every Constraint to Every Subagent

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents delegated work from violating user constraints that the parent agent knew about but left out of the handoff.

**[Copy-paste ready version](../../install/pass-every-constraint-to-every-subagent.md)** — just the instruction block, no explanation.

## The Problem

The user tells the agent: refactor the payments module, but do not touch the public API, keep Python 3.9 compatibility, and don't add dependencies. The agent delegates a chunk to a subagent with the prompt "refactor the retry logic in payments/retry.py to use the new backoff pattern." Clean, focused, actionable — and missing all three constraints. The subagent, knowing only what it was told, helpfully adds a dependency, uses 3.10 syntax, and renames a public function. It did excellent work on the task it received. It received the wrong task.

Constraints get dropped in handoffs because the parent summarizes by relevance to the subtask, and constraints feel like ambient context rather than content — they're things the parent knows, not things the subtask says. But subagents start from zero. They don't inherit the conversation, the user's tone, or the list of forbidden moves. Anything not in the handoff prompt does not exist for them. A constraint mentioned once, two hours ago, in the user's first message, has to be physically copied into every delegation or it dies at the boundary.

The damage multiplies with fan-out: five subagents, each missing a different subset of the rules, produce work that has to be reviewed against constraints none of them were told about — which the parent often doesn't do, because it assumes constraint-compliance the way it assumes competence.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It states the boundary's physics.** The parent assumes shared context because it has shared context with the user. Spelling out that nothing crosses the delegation boundary unwritten replaces a false model with the real one.

2. **It forbids relevance filtering.** The dropped constraint is always the one the parent judged irrelevant to the subtask. Requiring the full list every time removes the judgment call that fails.

3. **It mandates a maintained artifact.** Constraints scattered across a long conversation can't be reliably re-collected at delegation time. A running list makes the handoff a paste, not a recall task.

4. **It preserves wording.** Each paraphrase hop weakens a constraint ("do not touch" becomes "minimize" becomes "be thoughtful about"). Verbatim quoting stops the telephone game.

## Origin

A parent agent fanned a large rename out to four subagents, each prompted with its file list and the mechanical rename rule — but not the user's instruction that the database migration files were strictly off-limits. Three subagents had no migrations in their files. The fourth renamed identifiers inside eleven historical migration files, which the parent merged unreviewed. The deploy failed checksum validation in staging, and unwinding the "completed" rename took the team most of a day.
