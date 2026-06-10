---
title: Treat Untouched Code as Finished, Not Abandoned
slug: treat-untouched-code-as-finished
category: legacy-code
tags: [universal, legacy]
works_with: all
severity: high
one_liner: "Stops rewrites justified by file age when stability means done, not dead"
---

# Treat Untouched Code as Finished, Not Abandoned

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from reading "last modified eight years ago" as a defect that justifies refreshing, rewriting, or churning stable code.

**[Copy-paste ready version](../../install/treat-untouched-code-as-finished.md)** — just the instruction block, no explanation.

## The Problem

Software culture treats change as a vital sign: active repos are healthy, stale ones are dying. AI assistants absorb this and apply it to individual files. A module untouched since 2017 reads as neglected — surely it needs updating, its patterns refreshed, its structure revisited. The assistant proposes a rewrite, or treats the file as a free-fire zone where churn is harmless because "nobody maintains this anyway."

The inference is backwards. Code stops changing for two opposite reasons: nobody dares touch it, or nobody needs to. The second is far more common and is the definition of success — the module does its job, the requirements stopped moving, every bug worth fixing got fixed. Eight years without a commit can mean eight years without a defect worth reporting. That's not a backlog item. That's the asymptote.

The cost of misreading it: stable code is exactly where rewrites are most dangerous (maximum accumulated correctness to lose, minimum institutional memory to consult) and least valuable (the old version was, by observation, not causing problems). A rewrite of a finished module spends real risk to purchase nothing.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Treat Untouched Code as Finished, Not Abandoned

NEVER treat a file's age or commit inactivity as evidence that it needs work. Code that hasn't changed in years is usually code that hasn't *needed* to change — finished, not abandoned. Stability is an achievement, and "old" is not a defect you can fix.

When working in or around long-untouched code:

- Do not propose rewrites, restructures, or "refreshes" justified by age, stale idioms, or commit inactivity. Valid justifications are defects, required features, or measured problems — things the code does wrong, not years it has existed.
- Check the dormancy's character before assuming anything: `git log` the file. A module that went quiet after a burst of bug fixes converged; one abandoned mid-feature is different. The history tells you which.
- Apply *more* caution in old code, not less. "Nobody maintains this" means mistakes here have no owner watching; it is the opposite of a safe place to experiment.
- Don't let age tip unrelated decisions: an old module is not thereby a candidate for deletion, deprioritized review, or drive-by modernization while you're nearby.
- If the user asks for an opinion on old code, evaluate it on behavior: does it have open defects, failing requirements, measured performance problems? "It's old" appears nowhere in that list.

The question to ask of an untouched module is not "why has nobody fixed this?" but "what did this get right that it needed no fixing?"

**Red flags that you're about to violate this:**
- "This hasn't been touched since 2016, it's overdue for an update."
- "Nobody maintains this, so my changes here are low-stakes."
- "Stale code like this is tech debt by definition."
- "While I'm in this dusty corner, I might as well bring it up to date."
- "Surely this old thing wasn't written with current requirements in mind."

---

## Why It Works

1. **It inverts the prior.** The AI's default reads inactivity as decay; supplying the alternative explanation — convergence — with the reasoning behind it changes the conclusion drawn from the same evidence.
2. **It demands defect-based justification.** Rewrites must cite something the code does wrong; "old" is excluded by name from the list of valid reasons, closing the exact loophole used.
3. **The history check separates the two dormancies.** Quiet-after-stabilization and abandoned-mid-flight look identical in `ls -l` and completely different in `git log`, and the AI can tell them apart in one command.
4. **"More caution, not less" fixes the secondary failure:** unowned code invites carelessness precisely because no one will object — until production does.

## Origin

An assistant assessing a codebase flagged a rate-limiting module, unchanged in seven years, as "legacy code requiring modernization" and was allowed to rewrite it with current idioms. The old module's final commits, had anyone read them, were a series of fixes converging on correct behavior across clock skew, leap seconds, and counter overflow — after which it had simply been correct, quietly, for seven years. The rewrite reintroduced the overflow bug within a month of deploy. The module hadn't been waiting for modernization. It had been done.
