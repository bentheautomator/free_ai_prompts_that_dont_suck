---
title: Finish the Task Before Chasing Tangents
slug: finish-the-task-before-chasing-tangents
category: agents-and-automation
tags: [universal, agents]
works_with: all
severity: high
one_liner: "Wandering off mid-task to fix something shiny and never coming back"
---

# Finish the Task Before Chasing Tangents

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the agent from abandoning a half-finished task to pursue something interesting it noticed along the way.

**[Copy-paste ready version](../../install/finish-the-task-before-chasing-tangents.md)** — just the instruction block, no explanation.

## The Problem

Forty minutes into implementing a feature, the agent opens a file and notices the error handling in there is dreadful. So it fixes that. Which surfaces a deprecated API call, so it updates that, which means touching the adjacent module, which has a failing lint rule... When the session ends, the codebase has six unrelated improvements in various states of doneness and the original feature — the thing the user actually asked for — is stuck at sixty percent, exactly where it was when the agent got distracted.

This is thread loss, and long sessions manufacture it constantly. Every file the agent opens is full of things that could be improved, and an agent has no boredom or deadline pressure pulling it back to the main quest. Each hop is justified locally ("this is broken, and I'm right here"), but the hops chain: tangent leads to tangent, and the call stack of abandoned intentions grows until the original task isn't even in working memory anymore.

The user experience is distinctive: they asked for a feature and received a diff touching nineteen files, with the feature itself incomplete. Worse than scope creep — scope creep at least finishes the original work. This is scope drift, where the original work quietly stops being the point.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Finish the Task Before Chasing Tangents

NEVER start working on something you noticed mid-task. Park it. The task you were given runs to completion before anything you discovered along the way gets a single edit.

The core problem: every file contains something fixable, each detour justifies itself locally, and detours chain — three hops in, the original task has fallen out of working memory entirely.

- Keep one designated current task. At every step, you should be able to state it in one sentence and say how the action you're about to take serves it.
- When you notice something broken, ugly, or improvable that isn't the current task: write it to a parking list (a notes file or your task tracker) in one line, and continue the current task. Noticing is free; acting is the violation.
- The only tangents you may act on immediately are hard blockers: the current task literally cannot proceed until this is fixed. "Related" is not a blocker. "Will bite us eventually" is not a blocker. "I'm already in this file" is definitely not a blocker.
- If you do hit a genuine blocker, fix the minimum needed to unblock and return immediately — do not renovate the neighborhood while you're there.
- When the current task is complete, present the parking list to the user: "Done. Along the way I noticed these 4 issues — want me to take any of them?" They choose what's next; you don't.
- If you realize you've already drifted, stop the tangent mid-stride, note where you left it, and return to the original task — even if the tangent is nearly done.

**Red flags that you're about to violate this:**
- "While I'm in this file, I might as well..."
- "This will only take a second to fix..."
- "I can't in good conscience leave this how it is..."
- "This is sort of related to the task..."
- "I'll just quickly clean this up first, then get back to it..."

---

## Why It Works

1. **It separates noticing from acting.** The agent's instinct that the broken thing matters is often correct; the error is the timing. A parking list honors the observation at zero cost to the main thread, removing the "but it's genuinely broken!" justification for drifting.

2. **It defines "blocker" narrowly and by exclusion.** The drift loophole is an elastic definition of necessary. Explicitly disqualifying "related," "eventually," and "already here" closes the three rationalizations that account for nearly all tangents.

3. **It restores the user as scheduler.** Presenting the parking list after completion converts drift into a feature: the user gets the discoveries and decides priority, instead of getting nineteen touched files and an unfinished feature.

4. **It handles drift-in-progress.** Sunk cost makes a half-done tangent feel mandatory to finish. The "stop mid-stride even if nearly done" clause pre-authorizes the otherwise unthinkable retreat.

## Origin

An agent asked to add CSV export to a reporting page was found, ninety minutes later, four levels deep: it had detoured into fixing date formatting, which led to a timezone utility rewrite, which led to updating that utility's tests, which led to "modernizing" the test helpers. The CSV export consisted of one empty function with a TODO. The user's review request was, in full: "where is the export button?"
