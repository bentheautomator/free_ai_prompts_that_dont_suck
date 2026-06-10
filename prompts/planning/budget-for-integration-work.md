---
title: Budget for Integration Work
slug: budget-for-integration-work
category: planning
tags: [universal, planning]
works_with: all
severity: medium
one_liner: "All the parts built, '90% done' declared, and the hardest half still ahead"
---

# Budget for Integration Work

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents plans that account for building the pieces and treat connecting them as a footnote.

**[Copy-paste ready version](../../install/budget-for-integration-work.md)** — just the instruction block, no explanation.

## The Problem

The plan has five steps: build the parser, build the transformer, build the writer, build the CLI — and then step five, two words long: "wire up." Each component gets built and unit-tested. The assistant announces 90% completion. Then wiring begins, and reality files its objections: the parser emits streams but the transformer wants arrays; errors that were exceptions in one module are result types in another; the CLI's config shape matches nobody's; and the whole pipeline has never once run end to end. The two-word step quietly contains a third of the project.

This is planning's oldest accounting error, and assistants inherit it in concentrated form because components are clean, self-contained generations — each one a satisfying artifact with its own tests — while integration is where the differing assumptions of separate generations meet. Every boundary between independently-built parts is a place where two locally-reasonable decisions can disagree, and the number of those boundaries is precisely what "wire up" is hiding.

The fix is twofold: name integration as real steps with real verification, and shrink the amount of it that happens at once by connecting parts as they're built instead of saving all the joining for the end.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Budget for Integration Work

NEVER write a plan where building the parts gets five detailed steps and connecting them gets the word "integrate." The seams between components are work — usually a third of it — and a plan that doesn't itemize them is a plan that's lying about its length.

The core problem: components are clean, separately satisfying units to build, while integration is where their differing assumptions collide — so it gets compressed to a final two-word step that contains the surprises.

- For every boundary between components in the plan, write what crosses it: the data shape, the error contract, who owns retries, sync or async. Disagreements found at this stage are sentences; found at wiring time, they're rewrites.
- Integrate incrementally: connect each component to its neighbor as it's built and run data through the joined section, rather than building all parts then joining all parts.
- Make "runs end to end" an explicit, early milestone — even with stub components. A skeleton pipeline that passes one real record through is worth more than four polished modules that have never met.
- Report progress in integrated terms. "Four of five components built" is not 80%; nothing works yet. Say what actually runs.
- When estimating, give the seams their own line items. If the integration steps look trivial when written down, good — writing them down cost nothing.

**Red flags that you're about to violate this:**
- "Then I'll just wire everything together..."
- "All components done, so it's basically finished..."
- "Each piece is tested, the combination will work..."
- "Integration is mostly boilerplate..."
- "I'll define the interfaces as I connect them..." (that's the collision, scheduled)

---

## Why It Works

1. **It counts the boundaries.** Integration effort scales with the number of seams, not the size of components. Itemizing each boundary's contract makes the hidden third of the project visible at estimation time instead of at "90% done."

2. **It moves assumption collisions to paper.** Two modules disagreeing about error handling costs one sentence to resolve in a plan and one refactor to resolve in code. Writing what crosses each boundary is the cheap venue for the same inevitable argument.

3. **It redefines progress as connection.** "Components built" measures generation, which assistants are good at; "records flowing end to end" measures the thing the user asked for. Reporting the second prevents the 90%-done illusion entirely.

## Origin

A data-export feature was planned as four components and a "hook it all up" step. The four components took three days and the announcement said "just integration left." Hooking it up took four more days: the extractor produced snake_case, the formatter expected camelCase, the uploader's chunk size didn't match the formatter's output buffering, and end-to-end auth had never been exercised because every module was tested with mocks. None of these were bugs in any component. All of them were the plan's missing line items.
