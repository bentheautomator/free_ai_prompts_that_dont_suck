---
title: Cap Exploration Before Acting
slug: cap-exploration-before-acting
category: agents-and-automation
tags: [universal, agents, context]
works_with: all
severity: medium
one_liner: "Recon spirals that read forty files before touching the actual task"
---

# Cap Exploration Before Acting

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the agent from spending the whole session "understanding the codebase" and arriving at the actual work with no budget left.

**[Copy-paste ready version](../../install/cap-exploration-before-acting.md)** — just the instruction block, no explanation.

## The Problem

Given a two-line fix, some agents will first read the router, then the middleware the router references, then the config that middleware loads, then three test files, then the docs directory, then — forty files and half a context window later — make the two-line fix. Or worse: arrive at the fix with the window so full of recon that the session compacts during the actual edit. Exploration didn't serve the task; it consumed it.

Recon spirals happen because understanding is open-ended and every file mentions other files. There is always one more reference to chase, and reading feels both safe and productive — no risk of breaking anything, steady sensation of learning. But exploration without a driving question doesn't converge; it random-walks the import graph. The agent isn't building a map, it's wandering with a flashlight.

The failure is timing as much as volume. Up-front exhaustive recon front-loads cost before you know which knowledge the task actually requires. Most of what a task needs is discovered cheaply at the moment of need — when the edit in front of you raises a specific question that one targeted read answers.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Cap Exploration Before Acting

ALWAYS explore with a question, and stop exploring when it's answered. Initial recon for a task is capped at roughly ten file reads or fifteen minutes — whichever comes first — before you start the actual work.

The core problem: every file references other files, so exploration without a stopping rule random-walks the import graph until the budget is gone, and you arrive at the real task with a full context window and no room to work.

- Before each read during recon, state the question this read answers. "General context" and "to understand the codebase" are not questions. No question, no read.
- Start work at sufficient understanding, not complete understanding. Sufficient means: you know where the change goes, what it touches directly, and how you'll check it. Everything else can be learned when the work raises it.
- Explore lazily after that: when the edit in front of you raises a specific question, do one targeted read or search to answer it, then return to the edit. Need-driven reads are almost always the right reads.
- Use cheap maps before expensive reads: directory listings, file outlines, grep hits. Read full regions only where the map shows the task lives.
- If you hit the recon cap and still feel lost, that's information — the task may be underspecified. Tell the user what you've learned and what specific question is blocking you, instead of reading another ten files in the hope of enlightenment.
- Re-justify continued recon out loud if you pass the cap for a genuinely sprawling task: name what's still unknown and why the work can't start without it.

**Red flags that you're about to violate this:**
- "Let me get a full picture of the architecture first..."
- "I should understand how everything connects before changing anything..."
- "Just a few more files and I'll have proper context..."
- "It can't hurt to look at this too..."
- "I'm not ready to start yet..." (after the twelfth read)

---

## Why It Works

1. **It attaches a question to every read.** The recon spiral runs on reads justified by vague benefit. Requiring a stated question converts "it can't hurt to look" into a test that vague reads fail.

2. **It sets a numeric cap as a tripwire.** Ten files isn't a magic number — it's a checkpoint that forces the agent to notice it's been exploring, which the spiral otherwise prevents. Passing the cap requires an explicit, stated reason.

3. **It legitimizes lazy learning.** Agents over-explore partly from fear of acting under-informed. Promising that need-driven reads during the work are sanctioned — and usually better targeted — removes the pressure to know everything up front.

4. **It converts persistent lostness into a signal.** If the cap is hit and the agent is still lost, the problem is usually the task spec, not insufficient reading. Routing that to the user stops the doom-loop of reading toward clarity that won't come.

## Origin

Asked to change a default page size from 20 to 50, an agent spent the first hour of its session reading 47 files — the full request pipeline, the ORM layer, two unrelated services, and a design doc — before making the one-line change. The change was correct. The session then compacted while writing the test for it, lost the user's instruction about which test file to use, and put the test in the wrong suite. Total recon required for the task, measured afterward: one grep and two file reads.
