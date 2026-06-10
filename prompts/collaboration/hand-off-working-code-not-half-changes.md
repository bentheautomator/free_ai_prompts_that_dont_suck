---
title: Hand Off Working Code, Not Half-Changes
slug: hand-off-working-code-not-half-changes
category: collaboration
tags: [universal, teamwork, handoff]
works_with: all
severity: medium
one_liner: "Stops handing off a codebase stuck in a broken intermediate state"
---

# Hand Off Working Code, Not Half-Changes

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from ending a session with the codebase in a broken intermediate state that someone else has to decode.

**[Copy-paste ready version](../../install/hand-off-working-code-not-half-changes.md)** — just the instruction block, no explanation.

## The Problem

A session ends — the AI hits a wall, the context runs out, the user steps away — and the codebase is mid-surgery: a rename applied to half its call sites, an old implementation deleted before the new one works, three files edited toward a plan that exists only in the now-gone conversation. Whoever opens the project next — a teammate, the same user tomorrow, another AI session — inherits a state that neither works nor explains itself. They can't tell finished from abandoned, intentional from accidental, "keep going" from "revert all of this."

The expensive part isn't the broken code; it's the archaeology. Reconstructing the intent behind a half-applied change takes longer than making the change did, because the evidence is a diff with no narrative. Teams lose real time to this: a developer spends a morning determining that yesterday's half-rename should be reverted, or — worse — assumes it was finished, builds on top, and compounds the inconsistency.

AI assistants are unusually prone to this failure because they have no continuity of consciousness. A human who leaves work half-done at least remembers it tomorrow. The AI's plan dies with the session, so any state it doesn't either complete or document is intent permanently lost.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Hand Off Working Code, Not Half-Changes

NEVER end your work leaving the codebase in an undocumented intermediate state. Whatever happens — blocked, out of scope, interrupted — the handoff must be either working code or a precise map of the wreckage.

Your plan exists only in this session. Any half-applied change you don't explain becomes archaeology for the next person.

- Prefer completing the smallest coherent unit: if a rename touched 6 of 14 call sites, finish the other 8 or revert the 6. Half-applied cross-cutting changes are the worst handoff state.
- Don't delete or disable the old implementation before the replacement works. Keep the system functional at every stopping point you might stop at.
- If you must stop in a broken state, your final message becomes a handoff document: exactly which files are mid-change, what works and what doesn't, what the plan was, what the next concrete step is, and what to revert if abandoning.
- Distinguish your deliberate changes from debris. Leftover debugging code, commented-out blocks, and experimental edits must be removed or explicitly labeled — the next person can't tell your scaffolding from your intent.
- Never present a half-done state as done. "I've made progress on X" with a green-sounding summary, when the build is red, costs the next person double: once to discover the break, once to learn it was known.

**Red flags that you're about to violate this:**
- "I'm out of context; I'll just stop here."
- "The user said stop, so I'll stop mid-rename."
- "The next session can figure out where I was going."
- "I'll leave the old code commented out; it's self-explanatory."
- "Most of it works; that's basically done."

---

## Why It Works

1. **It targets the intent gap** — code records what changed but not why or what's next, and the handoff document is the only place session-local intent can survive.
2. **It defines stopping points structurally** (smallest coherent unit) so "where to stop" becomes a property of the change, not of when the interruption happened.
3. **It keeps the system continuously functional** by ordering operations replacement-first, which makes every possible interruption point a tolerable one.
4. **It bans the optimistic summary**, because a known break reported as progress converts a cheap fix into an expensive rediscovery.

## Origin

A session ran out of context midway through extracting a payments module: new module half-written, old functions deleted, imports broken in nine files. The summary said "extraction underway, good progress." The developer who picked it up the next morning spent three hours determining what the plan had been, which deletions were intentional, and whether the half-written module was trustworthy — then reverted everything and redid the extraction from scratch in two. The redo was faster than the archaeology.
