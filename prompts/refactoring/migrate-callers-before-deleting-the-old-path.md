---
title: Migrate Callers Before Deleting the Old Path
slug: migrate-callers-before-deleting-the-old-path
category: refactoring
tags: [universal, refactoring]
works_with: all
severity: high
one_liner: "Stops delete-and-replace refactors that strand callers mid-migration"
---

# Migrate Callers Before Deleting the Old Path

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from deleting an old implementation in the same breath as introducing its replacement, instead of adding, migrating, then removing.

**[Copy-paste ready version](../../install/migrate-callers-before-deleting-the-old-path.md)** — just the instruction block, no explanation.

## The Problem

When replacing an implementation, AI assistants reach for the most dramatic possible move: delete the old function and drop the new one in its place, updating all callers simultaneously in one cut-over diff. If anything in that diff is wrong (one caller's arguments mistranslated, one behavioral nuance missed) there's no fallback, because the old path no longer exists. The change is also all-or-nothing to review and all-or-nothing to revert, and if the work gets interrupted halfway, the codebase is left in the worst state available: old path gone, new path half-wired.

The safe sequence has been standard practice for decades: add the new path alongside the old, migrate callers to it (in groups, verifying as you go), and delete the old path only when nothing references it. Models skip it because the parallel-paths intermediate state looks like the "duplicate code" they're trained to abhor, and because one atomic swap *feels* more complete than a migration with a temporarily redundant function in it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Migrate Callers Before Deleting the Old Path

When replacing an implementation that has multiple callers, NEVER delete the old one in the same change that introduces the new one. The sequence is: add the new path, migrate callers to it incrementally, then delete the old path once nothing references it.

A cut-over diff has no fallback; if one caller was migrated wrong, the working version it could fall back to is already gone.

- Step 1, add: introduce the new function/class alongside the old. Both exist; nothing is broken; this step is trivially safe.
- Step 2, migrate: move callers to the new path in reviewable groups, running tests after each group. Where practical, make the old path delegate to the new one so behavior converges early.
- Step 3, delete: only after a repo-wide search shows zero remaining references to the old path, remove it, as its own small change.
- The temporary duplication between steps 1 and 3 is correct, not a smell. Mark the old path deprecated (comment or annotation) so its pending death is visible, but do not let "two implementations exist" pressure you into collapsing the steps.
- If you're interrupted mid-migration, the codebase still works at every point. That property is the entire reason for the sequence; protect it.
- For two or three trivially mechanical call sites, a single-step swap can be acceptable, but say you're doing it and why the risk is contained.
- The deletion step is mandatory eventually. Parallel paths are scaffolding, not a destination; finish step 3 or hand the user a clear list of what remains.

**Red flags that you're about to violate this:**

- "I'll replace the function and update all twelve callers in one go."
- "Keeping both versions around temporarily is duplicate code."
- "It's cleaner to do the swap atomically."
- "The migration is straightforward, so the intermediate steps are overhead."
- "I'll delete the old one now and fix any callers that break."

---

## Why It Works

1. **It legitimizes the intermediate state the model is trained to hate.** "Temporary duplication is correct, not a smell" directly counters the DRY reflex that drives the collapse into one diff.
2. **The interruption property gives the model a checkable invariant.** "The codebase works at every point" is a test the model can apply to its own plan, unlike "be careful during the swap."
3. **Zero-references-then-delete makes the dangerous step mechanical.** Deletion stops being a judgment call made optimistically at the start and becomes a verified condition met at the end.
4. **The small-N escape valve preserves proportionality.** Without it, the model would either ignore the rule as bureaucratic or ceremonially three-step a two-line change; a stated exception keeps the rule credible where it matters.

## Origin

An assistant replaced a hand-rolled CSV exporter with a streaming version, deleting the old one and rewriting all nine call sites in a single change. Eight migrations were correct. The ninth passed column ordering differently, and the finance team's weekly export, the one consumed by a downstream reconciliation script, shipped with swapped columns. Rolling back meant reverting the whole replacement, including the eight good migrations, because there was no old path left to route one caller through.
