---
title: Reassess When an Assumption Breaks
slug: reassess-when-an-assumption-breaks
category: planning
tags: [universal, planning]
works_with: all
severity: high
one_liner: "Powering through after the premise dies, patching a plan built on the old one"
---

# Reassess When an Assumption Breaks

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents continuing to execute a plan after discovering a fact that contradicts what the plan was built on.

**[Copy-paste ready version](../../install/reassess-when-an-assumption-breaks.md)** — just the instruction block, no explanation.

## The Problem

Mid-task, the assistant learns something that contradicts the plan's foundation: the table it planned to extend is actually a view; the "unused" function is called via reflection; the service it assumed was internal is hit by mobile clients. A human hits this and feels the floor move — time to step back. The assistant, optimized for forward motion, treats the discovery as a local obstacle. It patches around it ("I'll materialize the view"), keeps the plan, and continues.

But a broken assumption rarely breaks just one step. It was load-bearing for the plan, which means several downstream steps were also built on it — and those steps are still queued, still wrong, and now being executed by an assistant that has stopped questioning them because the immediate obstacle was "handled." The result is a chain of increasingly creative patches, each locally reasonable, collectively assembling a structure no one would have designed on purpose.

The needed behavior is cheap and unnatural: when a premise dies, stop executing and re-derive. Which steps assumed this? Do they survive? Does the approach survive? Sixty seconds of reassessment, versus an afternoon of compounding workarounds.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Reassess When an Assumption Breaks

NEVER respond to a broken assumption by patching the immediate step and continuing. A premise that supported one step almost always supports others — when it dies, stop and re-check the plan against the new fact before executing anything else.

The core problem: forward momentum makes a contradicted premise feel like a local obstacle to route around, when it's actually new information about everything still queued.

- When you discover a fact that contradicts something the plan assumed, halt execution. Don't write the workaround first.
- Run the sixty-second audit: which remaining steps relied on the dead assumption? Which still hold? Does the overall approach survive, or just limp?
- If the approach survives with adjustments, state the adjustments before resuming: "X turned out to be a view, not a table; steps 3 and 5 change as follows."
- If the approach doesn't survive, say so plainly and re-plan. A wrong plan abandoned at 30% beats a wrong plan completed at 100%.
- Count the workarounds. The first patch may be fine; the second patch covering for the same dead assumption means you're building on a corpse.

**Red flags that you're about to violate this:**
- "That's surprising, but I can work around it..."
- "I'll handle this case specially and keep going..."
- "The plan still mostly applies..." (checked, or hoped?)
- "This is the second weird thing, but I'm too far in to reconsider..."
- "I'll note it and deal with the implications later..."

---

## Why It Works

1. **It treats discoveries as global information, not local obstacles.** An assumption lives in the plan, not in a step. Auditing the whole plan against the new fact catches the downstream steps that the patch-and-continue reflex leaves armed.

2. **It bounds the cost of being wrong.** Each workaround built on a dead premise raises the price of eventually facing it. Halting at the first contradiction caps the sunk cost at its minimum.

3. **It uses workaround count as a tripwire.** Assistants can't reliably feel "this is getting weird," but they can count. Two patches for one dead assumption is a mechanical signal that re-planning is overdue.

## Origin

A plan to add soft-delete assumed rows were only read through the repository layer. Midway, the assistant found a reporting job querying the table directly — and patched that one query to filter deleted rows. Then it found a second direct query, and patched it. And a third, in another service. The "repository-only access" premise had been dead since discovery one, and the honest conclusion — soft-delete needed a database view or column-level approach — was reached only after five scattered patches, three of which then had to be reverted.
