---
title: Inspect the Data After a Migration Runs
slug: inspect-the-data-after-a-migration-runs
category: verification
tags: [universal, verification, data]
works_with: all
severity: critical
one_liner: "Calling a migration successful without looking at the data it actually made"
---

# Inspect the Data After a Migration Runs

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the assistant from declaring a migration or bulk script successful without inspecting what it actually did to the data.

**[Copy-paste ready version](../../install/inspect-the-data-after-a-migration-runs.md)** — just the instruction block, no explanation.

## The Problem

The migration ran without errors. That sentence, which assistants treat as the finish line, is compatible with all of the following: it matched zero rows and changed nothing; it backfilled the new column with nulls instead of values; it transformed half the records and silently skipped the half with unexpected shapes; it wrote the right values into the wrong column; it duplicated rows instead of updating them. "No exceptions" measures whether the script crashed — the task was never "don't crash," it was "leave the data in a specific new state."

Assistants stop at the clean exit because the alternative is opening the patient back up: counting rows, sampling records, comparing before and after. That's real work against real data, and the script's silence feels like permission to skip it. The exit status arrives instantly; the data inspection has to be designed.

And data damage compounds in a way code bugs don't. Broken code fails the same way tomorrow; a bad migration's output becomes the input to everything downstream — reports aggregate the nulls, syncs propagate the duplicates, the backup window slides past — and by discovery time the question isn't "fix the bug" but "reconstruct what the data should have been."

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Inspect the Data After a Migration Runs

NEVER declare a migration, backfill, or bulk data script successful based on a clean exit. The script not crashing is not the goal; the data being in the intended new state is. Inspect the data.

The core problem: "ran without errors" is compatible with zero rows matched, nulls written, records skipped, and values misplaced. Only the data itself can confirm the transformation happened, happened to everything, and happened correctly.

- Before running, record the expectation: how many rows should be affected, and what should a transformed record look like? An expectation written first cannot be retrofitted to whatever happened.
- After running, count: rows affected vs rows expected. Zero affected on a script meant to change thousands is a failure with exit code 0. "Approximately right" counts deserve an explanation, not a shrug.
- Sample actual records — several, not one — and check the transformed values are correct, not merely present. A populated column full of empty strings passes existence checks and fails the point.
- Hunt the leftovers: query for rows still in the old state. The skipped 5% with unusual shapes is the classic silent failure, and only a "what didn't transform?" query finds it.
- Check what shouldn't have changed: total row counts (no duplication, no loss), untouched columns, adjacent tables.
- Report with the receipts: "expected ~12,400 updates; 12,397 affected; 3 remaining in old state, listed; 5 sampled records correct." That sentence cannot be written without doing the work — which is the point.

**Red flags that you're about to violate this:**
- "It completed with no errors, so the data's migrated..."
- "The framework would have raised if something went wrong..."
- "I checked one row and it looked right..."
- "Counting affected rows is overkill for a simple UPDATE..."
- "The skipped records were probably edge cases that don't matter..."
- "It worked on the test database, and prod data is the same shape..."

---

## Why It Works

1. **It severs "didn't crash" from "did the job".** The script's exit status answers a question nobody asked. Restating the actual goal — data in a specific new state — makes the clean exit obviously insufficient evidence.

2. **It requires the expectation before the run.** A row-count prediction written in advance is falsifiable; an expectation formed after seeing the result will always match the result.

3. **It directs attention to the residue.** "Query for rows still in the old state" targets the precise failure shape of bulk scripts — partial application — which affected-row counts alone can miss.

4. **It makes the honest report expensive to fake.** Counts, samples, and a leftovers list are artifacts of inspection; a summary containing them is evidence the inspection occurred.

## Origin

A backfill script for a new `display_name` column ran clean in production and was reported done. It populated the column by parsing a legacy field, and for the 18% of accounts whose legacy field used an older format, the parse returned an empty string — written, without error, as the display name. Support tickets about "blank names" trickled in for a week before anyone connected them; by then the nightly sync had exported the blanks to two downstream systems. A five-minute query for empty values, run right after the script, would have caught all of it.
