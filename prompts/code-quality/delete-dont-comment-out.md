---
title: Delete, Don't Comment Out
slug: delete-dont-comment-out
category: code-quality
tags: [universal, dead-code]
works_with: all
severity: medium
one_liner: "AI leaving commented-out code corpses instead of deleting dead code"
---

# Delete, Don't Comment Out

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from entombing dead code in comments instead of removing it.

**[Copy-paste ready version](../../install/delete-dont-comment-out.md)** — just the instruction block, no explanation.

## The Problem

When an AI replaces or removes logic, there's a strong pull to comment the old lines out instead of deleting them — sometimes with a eulogy attached: `// old implementation, keeping for reference`. The model does this because commenting feels reversible and deletion feels destructive, and because training data is full of exactly this habit from human developers who never learned to trust version control.

But the project *has* version control. Every deleted line is one `git log -p` away, forever. The commented corpse, meanwhile, costs rent every day it stays: readers must determine whether it's documentation, a warning, a soon-to-return feature, or garbage. Search results match it (`grep sendInvoice` finds the dead copy first). It drifts out of sync with the live code until "uncommenting to restore" produces something that no longer compiles. And it breeds — one tolerated corpse signals that this file is where dead code is stored, and the next editor adds another.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Delete, Don't Comment Out

When code is no longer needed, ALWAYS delete it. NEVER comment it out as a soft delete. Version control is the archive; the source file is for code that runs.

Commenting out feels safer than deleting. It isn't — it's deferred deletion with interest, paid by every future reader who must figure out why the corpse is there.

**Rules:**
- Replacing logic? Delete the old lines in the same edit. Don't leave them commented above, below, or beside the replacement
- Never write `// keeping this for reference`, `# old version`, `/* previous implementation */`, or commented blocks "in case we need to revert" — reverting is what git is for
- Don't disable code by commenting it out as a way to make something pass; if code shouldn't run, remove it (and its tests, imports, and registrations), or surface the question if removal is in doubt
- The exception is genuinely explanatory dead code: a short snippet whose *presence as a comment* documents a non-obvious decision (e.g., "we tried X; it deadlocks under Y — don't"). Such comments must say *why* they exist, not just *what* they were
- Found existing commented-out corpses adjacent to your edit? Leave them unless asked — your job is to not add new ones, not to bulldoze history uninvited

**Red flags that you're about to violate this:**
- "I'll comment this out in case they want it back..."
- "Keeping the old version visible makes the change easier to review..."
- "I'm not 100% sure this is unused, so I'll comment rather than delete..."
- "I'll leave it commented and let them decide..." (without actually telling them)
- "It's only a few lines, it's not hurting anyone..."
- Writing `//` in front of a line instead of removing it

---

## Why It Works

1. **It reframes which action is risky.** The AI maps deletion to danger and commenting to caution. Pointing at version control inverts that: deletion is fully recoverable; the comment's costs are real and recurring.

2. **It converts uncertainty into a question instead of a corpse.** "Not sure it's unused" is the honest case — and the instruction routes it to the user rather than letting the comment serve as a way to avoid deciding.

3. **It carves out the one legitimate use precisely.** Explanatory dead code ("we tried X, it deadlocks") is real and valuable. Requiring the *why* distinguishes documentation from procrastination, so the exception can't be stretched to cover everything.

4. **It scopes the rule to the AI's own additions.** Without the last clause, the AI over-rotates and strips a file's existing commented history unprompted — trading one mess for an unreviewable diff.

## Origin

A pricing module accumulated three generations of commented-out discount logic across successive AI sessions, each model politely preserving its predecessor's corpse. A developer debugging a discount bug uncommented what looked like the "previous working version" to compare behavior — it was two generations stale, referenced a renamed field, and its partial restoration corrupted the very calculation under investigation. The fix for the original bug took an hour; untangling the resurrection took the rest of the day.
