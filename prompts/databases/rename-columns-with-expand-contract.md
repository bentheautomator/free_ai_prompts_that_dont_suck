---
title: Rename Columns With Expand and Contract
slug: rename-columns-with-expand-contract
category: databases
tags: [universal, databases, migrations]
works_with: all
severity: critical
one_liner: "Renaming a column in one migration while live code still uses the old name"
---

# Rename Columns With Expand and Contract

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents single-step column and table renames that break every running instance still using the old name.

**[Copy-paste ready version](../../install/rename-columns-with-expand-contract.md)** — just the instruction block, no explanation.

## The Problem

"Rename `user_id` to `customer_id`" sounds like a refactor, so the AI performs it like one: `ALTER TABLE orders RENAME COLUMN user_id TO customer_id;` plus a find-and-replace across the codebase, all in one PR. In an editor, renames are atomic. In production, they aren't even close. The migration runs at some point during the rollout; every instance still running old code immediately starts throwing `column "user_id" does not exist`, and if the migration runs late in the deploy instead, the new code crashes on the missing `customer_id`. There is no ordering of a one-step rename that avoids a breakage window, and rolling back re-breaks it in the other direction.

The AI makes this mistake because its training is saturated with refactoring norms where renames are free. A column rename is not a refactor; it's a breaking API change to a shared interface with multiple concurrent consumers, including, during every deploy, two versions of your own application at once.

The boring, correct answer is expand/contract: add the new name, mirror writes, migrate readers, backfill, then drop the old name deploys later. It's several steps, which is exactly why the AI won't do it unless instructed.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Rename Columns With Expand and Contract

NEVER rename a column or table in a single migration on a system with live traffic. During any rollout, old code and new schema overlap; a one-step rename guarantees one side crashes, and rollback crashes the other.

A rename is a breaking change to a shared interface, not a refactor. Do it as expand/contract:

1. **Expand:** add the new column (`ALTER TABLE orders ADD COLUMN customer_id bigint;`). Deploy code that writes both columns and still reads the old one. A trigger or ORM-level dual-write both work.
2. **Backfill:** copy old values to the new column in batches.
3. **Migrate reads:** deploy code that reads the new column (still writing both).
4. **Contract:** stop writing the old column, and only after that deploy is fully live, drop it in a final migration.

Additional rules:

- If asked to "just rename it," state the plan and the reason: "a one-step rename breaks running instances; doing this as expand/contract across N deploys."
- The same applies to renaming tables; if a one-step cutover is unavoidable, a view with the old name (`CREATE VIEW orders_v AS SELECT ...`) can bridge readers, but say it's a bridge.
- On a pre-production system with no live traffic and no other consumers, a direct rename is fine; confirm that's the situation before choosing it.
- Never pair a direct rename with "we'll deploy quickly so the window is small." The window always finds traffic.

**Red flags that you're about to violate this:**

- "It's just a rename, the find-and-replace covers everything..."
- "The migration and code deploy together..."
- "The window will only be a few seconds..."
- "Expand/contract is overkill for one column..."
- "Rollback is fine, I'd just rename it back..."

---

## Why It Works

1. **It recategorizes the operation.** "Rename = refactor = free" is the broken premise. Calling it a breaking change to a shared interface activates the AI's API-compatibility behavior instead of its refactoring behavior.

2. **It provides the full ritual, numbered.** Expand/contract fails when steps are merged or reordered; an explicit sequence prevents the AI from "optimizing" two steps into one, which recreates the original bug.

3. **It kills the small-window gambit.** "We'll be fast" is the rationalization that survives the first correction; banning it by name removes the last exit.

## Origin

An assistant was asked to rename a confusingly-named `status` column to `fulfillment_status` and did it in one tidy PR. The migration applied at minute two of a fifteen-minute rolling deploy; every old pod crash-looped on the missing column, autoscaling replaced them with more old pods that crashed faster, and the deploy had to be aborted with the schema already renamed, which meant the rollback target was also broken. Recovery required a hand-applied rename-back on prod before anything could deploy at all.
