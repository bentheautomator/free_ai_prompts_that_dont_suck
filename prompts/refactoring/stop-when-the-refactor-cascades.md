---
title: Stop When the Refactor Cascades
slug: stop-when-the-refactor-cascades
category: refactoring
tags: [universal, refactoring]
works_with: all
severity: high
one_liner: "Stops refactors that ripple outward until half the codebase is in the diff"
---

# Stop When the Refactor Cascades

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from chasing a refactor's ripple effects outward, edit after forced edit, instead of stopping to reassess when the change starts cascading.

**[Copy-paste ready version](../../install/stop-when-the-refactor-cascades.md)** — just the instruction block, no explanation.

## The Problem

Some refactors are landmines disguised as chores. Changing one function's signature forces updates to its eight callers; two of those callers can't absorb the change without altering *their* signatures; that breaks an interface, which has four implementations, one of which is mocked in thirty tests. A human feels the dread at hop two and backs out. An AI assistant feels nothing: each forced edit is locally reasonable, so it keeps going, hop after hop, and presents a 60-file diff for what was scoped as a 3-file cleanup. The summary cheerfully notes that "some additional updates were required."

The cascade is information, and the model discards it. When a "small" refactor recruits half the codebase, the codebase is telling you the change is fighting the current design, that the approach is wrong, or that the work needs phasing. Plowing through converts that signal into pure risk: a giant diff nobody scoped, nobody can review, and nobody can revert without losing days of entangled edits. Models plow through because stopping mid-task feels like failure and because each next edit is, in isolation, obviously necessary. That's how cascades work; necessity is local, madness is global.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Stop When the Refactor Cascades

Set a blast-radius expectation before starting a refactor, and STOP when reality exceeds it. When a refactor forces changes that force further changes (a second hop of ripple, or a file count well past the estimate), pause and report rather than chasing the cascade to completion.

A cascade is the codebase telling you the change is bigger than its description. Plowing through converts that signal into an unreviewable diff.

- Before starting, state the expected footprint: roughly which files and how many. That estimate is the tripwire, so make it honestly.
- Track hops: hop 1 is the planned change plus directly forced caller updates; hop 2 is when those updates force changes elsewhere. Hop 2 means stop. Forced changes to other modules' interfaces, public types, or test infrastructure are automatic stops.
- Default tripwire when no scope was given: more than 2x the estimated files, or more than ~10 files for a "small" refactor, whichever comes first.
- Stop at a coherent point: revert or finish the current step so the tree is green, then report what cascaded, why, the realistic full footprint, and 2-3 options (proceed at full scope, phase it via a compatibility shim, or pick a narrower refactor that doesn't ripple).
- Compatibility shims are the standard cascade-breaker: keep the old signature as a thin adapter over the new one, ship the refactor without touching distant callers, and migrate them later in their own changes.
- NEVER present a cascaded diff for a small-scoped request without having checked in. "It required more changes than expected" in a final summary means you knew at hop 2 and kept going.

**Red flags that you're about to violate this:**

- "This caller also needs updating, and then just a few more."
- "I'm too deep to stop now; finishing is the fastest way out."
- "Each of these changes is individually necessary, so the total is fine."
- "The user wanted the refactor; the extra forty files come with it."
- "It'll be easier to explain after everything compiles again."

---

## Why It Works

1. **It reframes the cascade as data instead of obstacle.** The model treats forced edits as terrain to traverse; "the codebase is telling you the change is bigger than its description" gives the ripple semantic content that warrants a decision, not just effort.
2. **The hop count and file tripwire make "too far" computable.** Models can't feel dread, but they can count hops and files; converting the human's gut signal into arithmetic puts the stop within reach of what a model actually monitors.
3. **The sunk-cost rationalization is named at its strongest moment.** "Too deep to stop, finishing is fastest" is precisely the thought at hop three; pre-marking it flips momentum from a reason to continue into a reason to halt.
4. **The shim option makes stopping productive.** A pause that offers a compatibility adapter and a phased plan delivers more value than a completed cascade; giving the model a good move at the stop point keeps "stop" from feeling like task failure.

## Origin

A request to make one repository class's methods async, scoped as a small refactor, cascaded through every caller, then their callers, then a shared interface and its mocks. The assistant followed the ripple to its conclusion: 74 changed files for a change requested in one. The diff was unreviewable, conflicted with two open branches within a day, and was ultimately closed unmerged. The redo used an async adapter alongside the sync interface: 5 files, merged that afternoon, callers migrated over the following weeks.
