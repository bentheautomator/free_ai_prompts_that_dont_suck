---
title: Delete the Old Implementation
slug: delete-the-old-implementation
category: code-quality
tags: [universal, dead-code]
works_with: all
severity: high
one_liner: "AI leaving both old and new implementations behind after replacing code"
---

# Delete the Old Implementation

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from leaving the superseded implementation in place alongside its replacement.

**[Copy-paste ready version](../../install/delete-the-old-implementation.md)** — just the instruction block, no explanation.

## The Problem

You ask the AI to replace the homegrown CSV parser with the library version. It writes `parseCsvV2`, wires the main call site to it, declares victory — and leaves the original `parseCsv` sitting right there, fully intact, still exported, still called from two places the AI didn't look at. The file now contains two parsers with different quoting behavior, and which one runs depends on which import a given caller happens to have.

AI assistants do this because addition feels safe and deletion feels risky. Writing new code can't break anything that exists; removing old code might. So the model optimizes for "my change works" over "the codebase is coherent," and the half-replaced state — the worst of both worlds — is born. Names like `processDataNew`, `handleLegacy`, `_old` suffixes, and `V2` everywhere are the fossil record of this habit.

The cost lands on the next person. They search for the parser, find two, and have to archaeology their way through git history to learn which one is real. Or worse, they fix a bug in the one that's no longer called and ship the fix into the void.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Delete the Old Implementation

When you replace code, ALWAYS remove what it replaces — in the same change. A replacement isn't done until the old version is gone: not renamed to `_old`, not suffixed `V2`-and-abandoned, not kept "for reference." Gone.

Leaving both versions creates a codebase that lies. Future readers can't tell which implementation is live, callers split between the two, and bug fixes land in the dead copy.

**When your change supersedes existing code:**
- Find every caller of the old implementation and migrate all of them, then delete the old function, class, or block
- Delete the old version's now-unused imports, exports, registrations, and feature-flag plumbing along with it
- Never name the replacement `New`, `V2`, or `Improved` to dodge the conflict — give it the original's name once the original is deleted
- If some callers genuinely can't migrate yet, say so explicitly and ask whether to keep both temporarily; don't silently leave a fork
- After the edit, search for the old symbol name to confirm zero references remain

**Red flags that you're about to violate this:**
- "I'll keep the old version around in case they want to revert..."
- "Removing it might break something I can't see..."
- "I'll call this one processDataV2 to be safe..."
- "Migrating the other call sites is out of scope for this change..."
- "The old one isn't hurting anything by staying..."
- Finishing a "replace X" task with X still present in the file

---

## Why It Works

1. **It redefines "done."** The AI's success condition is "new code works." The instruction moves the finish line to "old code is gone," which is what the user actually meant by *replace*.

2. **It names the safety illusion.** Keeping the old version feels like reducing risk; the instruction reframes it as creating a fork where fixes land in dead code. That flips the perceived-safe option into the perceived-dangerous one.

3. **It bans the naming dodges.** `V2` and `_old` are how the model avoids the deletion decision entirely. Outlawing the names forces the decision.

4. **It ends with a verifiable check.** "Search for the old symbol, expect zero hits" converts a fuzzy intention into a pass/fail step the AI can actually execute.

## Origin

A team asked their assistant to swap a hand-rolled rate limiter for a Redis-backed one. The AI added the new limiter, switched the API gateway to it, and left the in-memory version exported from the same module. Two months later, an internal admin service — still importing the old one — got hammered in an incident because its "rate limiter" reset on every deploy. The postmortem's root cause was a single line: both limiters existed, and nobody knew.
