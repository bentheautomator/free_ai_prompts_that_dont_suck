---
title: Stop Fix-Revert Oscillation
slug: stop-fix-revert-oscillation
category: agents-and-automation
tags: [universal, agents, loops]
works_with: all
severity: high
one_liner: "Agents undoing their own fix, redoing it, and cycling between two states"
---

# Stop Fix-Revert Oscillation

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the agent from bouncing between two code states, where each "fix" is an undo of the previous fix.

**[Copy-paste ready version](../../install/stop-fix-revert-oscillation.md)** — just the instruction block, no explanation.

## The Problem

The agent changes a timeout from 5000 to 30000 to fix test A. Test B starts failing. It changes the timeout back to 5000 to fix test B. Test A fails again. So it changes it to 30000. Long sessions produce this two-state oscillation constantly — in timeouts, in type signatures, in import styles, in null-handling — and the agent never recognizes that edit four is a byte-for-byte reversal of edit two, because by then the earlier edit has scrolled out of working attention.

What makes oscillation pernicious is that every individual edit is correct in its local frame. Each one genuinely fixes the failure in front of it. The agent isn't being stupid at any single step; it's being memoryless across steps. The two failing tests have contradictory requirements, which is the actual finding — but discovering a contradiction requires comparing your current edit against your own history, and agents don't do that unprompted.

A human pair-programmer would say "wait, didn't we just change that back?" by the second cycle. An agent will happily run six full cycles, narrating each reversal as a fresh insight, until someone reads the diff history and finds the same two hunks alternating like a metronome.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Stop Fix-Revert Oscillation

NEVER apply an edit that reverses a change you made earlier in this session without first stopping to name the contradiction. If fixing B requires undoing your fix for A, that is not a fix — it is the discovery that A and B have conflicting requirements.

The core problem: each edit is locally correct, so oscillation never feels like a loop from the inside. Only comparing against your own edit history reveals it.

- Before editing any line, check whether you have already edited that line or value in this session. If you're about to restore something you previously changed, stop.
- When you detect a reversal, treat it as a finding, not a setback: write down what A needs, what B needs, and why those conflict. The real fix resolves the contradiction (separate configs, a parameter, a refactor) rather than picking a side.
- Never let the same value flip twice. One reversal can be a correction; the second flip of the same line is oscillation by definition, and a third edit to that line is forbidden until you've diagnosed the conflict.
- Watch for oscillation across files too: re-adding an import you removed, re-renaming a symbol back, toggling a config flag. The unit of oscillation is the decision, not the line.
- If you cannot resolve the contradiction yourself, present both sides to the user: "A needs X, B needs not-X, here's why; which constraint wins?"

**Red flags that you're about to violate this:**
- "I'll just change this back to how it was..."
- "Hmm, this value again — let me set it to what worked before..."
- "Fixing this test is easy, I just need to adjust that timeout..." (for the third time)
- "Strange, this looks like something I already fixed..."
- "I'll revert that earlier change, it must have been wrong..." (it fixed something — go check what)

---

## Why It Works

1. **It reframes the reversal as data.** The agent treats undoing its own fix as a correction; the rule redefines it as evidence of a constraint conflict, which redirects effort from picking-a-side to resolving the actual contradiction.

2. **It installs a hard flip limit.** "The same value may not flip twice" is mechanically checkable and catches the loop on cycle two instead of cycle six.

3. **It forces a history check at edit time.** Oscillation survives on forgetting; requiring "have I edited this line before?" before each change makes the agent's own history part of the decision.

4. **It provides the escalation format.** "A needs X, B needs not-X" turns an embarrassing stall into a crisp question a human can answer in one message.

## Origin

An agent stabilizing a flaky integration suite alternated a database pool size between 5 and 50 across six commits in one session — each change fixing the connection-exhaustion test while breaking the resource-limit test, or vice versa. The session log showed it "fixing" the same line six times with full confidence each time. The two tests encoded genuinely conflicting assumptions about the environment, which one parameterized config value resolved in ten minutes once a human spotted the pattern.
