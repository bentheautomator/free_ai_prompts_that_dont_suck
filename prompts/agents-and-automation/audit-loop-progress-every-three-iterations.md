---
title: Audit Real Progress Every Three Iterations
slug: audit-loop-progress-every-three-iterations
category: agents-and-automation
tags: [universal, agents, loops]
works_with: all
severity: high
one_liner: "Edit-test cycles that feel productive while the failure count never moves"
---

# Audit Real Progress Every Three Iterations

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents long edit-test cycles where every iteration produces activity but the actual state of the task never improves.

**[Copy-paste ready version](../../install/audit-loop-progress-every-three-iterations.md)** — just the instruction block, no explanation.

## The Problem

There is a failure mode in long agent sessions that isn't a retry loop and isn't thrashing — it's motion mistaken for progress. The agent edits a file, runs the tests, gets 12 failures, edits again, runs again, gets 12 failures (different ones!), edits again, 12 failures. Every iteration involves a real change and a real result, so nothing trips the obvious loop detectors. But zoom out and the needle hasn't moved in forty minutes.

Agents fall into this because they evaluate each cycle locally: "I made an edit, I learned something, that's progress." There's no step where they compare the current state against the state three cycles ago. Humans doing the same work get a gut feeling of wading through mud; agents don't have the gut feeling, so they need the comparison made explicit.

Left alone, these sessions don't fail loudly — they just convert the entire budget into churn. The worst versions actually regress: fixing two tests while breaking two others, cycle after cycle, with the agent narrating steady improvement the whole way down.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Audit Real Progress Every Three Iterations

ALWAYS stop after every third iteration of any edit-and-check cycle and compare the current state against the state three iterations ago, using a number.

The core problem: each cycle feels productive because something happened, but activity is not progress. Without an explicit checkpoint comparison, you can churn for an hour while the task stands still.

- Pick a concrete metric at the start of the cycle: failing test count, compiler error count, lint violations, number of unmigrated files. Record it.
- Every three iterations, state the metric then and now. "Three cycles ago: 12 failing tests. Now: 12 failing tests" means your strategy isn't working, even if the individual failures changed.
- If the metric is flat or worse across three iterations, do not start iteration four with the same strategy. Step back: re-read the failures as a group, look for a common cause, and either change strategy or report to the user what you've tried.
- Watch for whack-a-mole specifically: if your fixes keep breaking things you previously fixed, the failures are coupled and need one structural fix, not N local ones.
- Improving slowly is fine — 12 to 10 to 9 is progress. The rule triggers on flat or negative, not slow.
- When you report a stall to the user, include the metric history. "Three strategies, failure count pinned at 12" is actionable; "still working on it" is not.

**Red flags that you're about to violate this:**
- "Good, a different set of tests is failing now..."
- "I'm definitely getting closer..." (without a number to back it)
- "Just a few more iterations of this..."
- "Each run teaches me something new..."
- "That fix worked, though two other things broke..."

---

## Why It Works

1. **It replaces felt progress with measured progress.** The agent's per-cycle narration is always optimistic; a recorded number from three cycles ago can't be sweet-talked.

2. **It sets the audit cadence at three, not one.** Auditing every cycle would punish normal exploration; waiting ten cycles wastes the budget. Three iterations is enough signal to detect a stall while cheap enough to act on.

3. **It names whack-a-mole as a distinct pattern.** Coupled failures masquerade as progress ("fixed two!") while the total stays flat. Telling the agent to check whether its fixes break its own earlier fixes exposes the coupling.

4. **It distinguishes slow from stuck.** By triggering only on flat-or-worse, the rule avoids teaching the agent to panic during legitimately gradual work.

## Origin

An agent migrating a codebase to a new ORM ran an edit-test cycle 31 times over two hours. The failing test count went 14, 13, 14, 15, 14, 13, 14 — a random walk around its starting point, because every fix to one model's queries subtly broke another's. The agent's running commentary reported "steady progress" for the entire two hours. The structural cause, a shared base-class method that needed one change, was visible from reading any five failures together.
