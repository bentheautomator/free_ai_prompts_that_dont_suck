---
title: Change Column Types via a New Column
slug: change-column-types-via-new-column
category: databases
tags: [universal, databases, migrations]
works_with: all
severity: high
one_liner: "In-place ALTER COLUMN TYPE that locks, rewrites, or truncates data"
---

# Change Column Types via a New Column

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents in-place column type changes that rewrite huge tables under a lock or destroy data in the cast.

**[Copy-paste ready version](../../install/change-column-types-via-new-column.md)** — just the instruction block, no explanation.

## The Problem

The `id` column is about to overflow its integer, or the `price` should have been numeric, or the `status` string deserves to be an enum. The AI's migration is one line: `ALTER TABLE orders ALTER COLUMN id TYPE bigint;`. On a big table that line is a full-table rewrite under an ACCESS EXCLUSIVE lock, hours of blocked reads and writes on exactly the tables (the big, old, important ones) most likely to need type changes in the first place. Indexes on the column rebuild too. The statement looks like a tweak; the engine executes a table-sized project.

Then there's the lossy direction, where the AI's cast quietly eats data. `varchar(255)` down to `varchar(50)` truncates or errors depending on engine and mode; string to integer fails on the one row containing `"N/A"` (best case) or, in permissive MySQL modes, becomes `0` (worst case); float to integer rounds; timestamp casts shift timezones. The AI writes the USING clause that makes the migration *run*, which is not the same as the cast being *correct* on three years of accumulated edge cases it has never seen.

Big tables need the expand-and-switch pattern: new column, dual writes, batched conversion, verified swap. It's more steps, and every step is boring, which is the point.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Change Column Types via a New Column

NEVER change a column's type in place on a large or busy table, and NEVER assume a type cast is lossless without checking the data. `ALTER COLUMN TYPE` is usually a full-table rewrite under an exclusive lock, and casts fail or silently mangle real-world values.

- First, scope it: table row count, and whether the cast can lose data (narrowing varchar, string to number, float to int, precision/timezone changes). State both.
- Small table, lossless widening (e.g. `int` to `bigint` on 10k rows): in-place is fine; say why it qualifies. Note that some engines do some conversions cheaply (Postgres `varchar(50)` to `text` is metadata-only); verify per engine before assuming either way.
- Large table: use expand-and-switch:
  1. `ALTER TABLE orders ADD COLUMN id_new bigint;`
  2. Dual-write: trigger or application code keeps `id_new` in sync with `id`.
  3. Backfill `id_new` in batches.
  4. Verify: `SELECT count(*) FROM orders WHERE id_new IS DISTINCT FROM id::bigint;` must be zero.
  5. Swap in one brief transaction (rename columns, move constraints/indexes/defaults), then drop the old column in a later deploy.
- For any cast, hunt the unconvertible rows before migrating, not after:
  `SELECT price FROM orders WHERE price !~ '^[0-9]+\.?[0-9]*$' LIMIT 20;`
  Decide explicitly what happens to them; a USING clause that "handles" them with NULL or 0 is a data decision needing human sign-off.
- Primary keys and FK-referenced columns multiply the care: every referencing column needs the same treatment, coordinated.

**Red flags that you're about to violate this:**

- "It's just a type change, one ALTER statement..."
- "The USING clause handles the conversion..."
- "All the values should be numeric in that column..."
- "int to bigint is trivial, size doesn't matter..."
- "I'll deal with weird rows if the migration errors..."

---

## Why It Works

1. **It separates the two hazards.** Lock-and-rewrite and lossy-cast are different failures with different checks; bundling them under "be careful with types" lets each hide behind the other. Scoping row count *and* cast safety forces both questions.

2. **It makes "migration errors" the good outcome.** The AI treats a failing cast as the problem; pointing out that permissive modes convert garbage *silently* reframes errors as the lucky case and pre-migration data hunting as the real control.

3. **It demands the verification count before the swap.** Step 4's zero-difference check is what distinguishes a completed conversion from a hopeful one, and it's checkable by anyone reviewing.

4. **It permits the cheap case explicitly.** Requiring a stated justification ("small, lossless, metadata-only on this engine") keeps trivial changes trivial without letting big ones masquerade as trivial.

## Origin

An orders table approached integer overflow on its primary key, and the fix PR was the textbook one-liner to bigint. Staging, with 2% of prod's rows, converted in 40 seconds. Production was still rewriting the table 3 hours into the maintenance window, with the FK-referencing tables not yet started, and the team aborted into a weekend of expand-and-switch work that the original plan should have been. The column overflowed eleven days later; they made it by two.
