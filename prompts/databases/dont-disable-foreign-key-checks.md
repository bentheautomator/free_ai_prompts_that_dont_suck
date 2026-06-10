---
title: Don't Disable Foreign Key Checks to Force a Change Through
slug: dont-disable-foreign-key-checks
category: databases
tags: [universal, databases, sql]
works_with: all
severity: high
one_liner: "Turning off constraint checks so a failing migration or import succeeds"
---

# Don't Disable Foreign Key Checks to Force a Change Through

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents constraint checks from being switched off so a failing operation succeeds, leaving inconsistent data behind.

**[Copy-paste ready version](../../install/dont-disable-foreign-key-checks.md)** — just the instruction block, no explanation.

## The Problem

A migration, import, or bulk delete fails on a foreign key violation, and the AI knows the incantation that makes failures stop: `SET FOREIGN_KEY_CHECKS=0;` in MySQL, `ALTER TABLE ... DISABLE TRIGGER ALL` or dropping the constraint in Postgres, `session_replication_role = replica` for the adventurous. The operation now succeeds. The orphaned rows it just created, children pointing at parents that don't exist, succeed too, permanently. In MySQL, re-enabling the checks doesn't re-validate anything; the inconsistency is simply in the database now, waiting for a JOIN to return half a record or an application crash on a null parent.

The AI reaches for this because it pattern-matches on "error blocking task, here's the flag that removes the error." Constraint violations don't read as information to it; they read as friction. But the FK check failing means the operation, as written, would corrupt referential integrity. Disabling the check doesn't make the operation correct. It makes the database stop telling you it's incorrect.

There's a legitimate niche, bulk-loading data in dependency order is tedious, and tools do disable checks during controlled restores, but the legitimate version re-validates afterward and runs in a maintenance context, not inline in a migration to make CI green.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Disable Foreign Key Checks to Force a Change Through

NEVER disable foreign key or constraint checking to make a failing operation succeed. The violation is the database telling you the operation creates inconsistent data; silencing the check keeps the corruption and discards the warning.

- Banned as fixes for a constraint error: `SET FOREIGN_KEY_CHECKS=0`, `SET session_replication_role = replica`, `DISABLE TRIGGER ALL`, dropping a constraint and "re-adding it later," `NOCHECK CONSTRAINT`.
- Fix the operation instead:
  - Insert/import in dependency order: parents before children.
  - Delete in reverse dependency order: children before parents, in one transaction.
  - For data that legitimately lacks a parent, decide explicitly: create the parent, null the reference, or skip the row, and report counts of each.
- If checks must be off for a bulk load (rare, maintenance-context only):
  1. Get explicit human sign-off first.
  2. Re-validate afterward; in MySQL re-enabling checks validates nothing, so verify orphans manually:
     `SELECT c.id FROM child c LEFT JOIN parent p ON c.parent_id = p.id WHERE p.id IS NULL;`
  3. Zero orphans or the load is not done.
- In Postgres, if a constraint genuinely must be relaxed temporarily, prefer `ALTER TABLE ... ADD CONSTRAINT ... NOT VALID` then `VALIDATE CONSTRAINT`, the path that ends with the database confirming consistency.
- Never commit code or migrations that toggle constraint checks as a routine step.

**Red flags that you're about to violate this:**

- "The FK check is blocking the import, I'll turn it off temporarily..."
- "I'll re-enable the checks right after, so nothing's really off..."
- "The data is probably consistent, the constraint is just strict..."
- "Ordering the inserts correctly is too complicated..."
- "Other migration scripts online do it this way..."

---

## Why It Works

1. **It separates "operation succeeds" from "operation is correct."** The AI optimizes for the error disappearing; stating that the check was reporting corruption, not causing failure, redirects effort to the actual operation.

2. **It debunks the re-enable myth specifically.** "I'll turn it back on after" feels like restoring safety; pointing out that re-enabling validates nothing in MySQL removes the rationalization's factual basis.

3. **It provides the ordering recipes.** Most violations are just wrong insert/delete order; giving the parents-first/children-first patterns makes the correct fix as available as the destructive one.

4. **It defines the legitimate exception precisely.** Sign-off, post-validation, zero orphans: a checklist narrow enough that "bulk load" can't be stretched to cover "my migration is failing."

## Origin

An assistant migrating data between two schemas hit FK violations because it copied tables alphabetically: `comments` before `posts`. Rather than reorder, it wrapped the copy in `SET FOREIGN_KEY_CHECKS=0`. The copy "succeeded," including 9,000 comments whose posts were filtered out by a WHERE clause earlier in the script. The orphans surfaced over the following month as intermittent 500s on user profile pages, each one debugged separately before someone ran the LEFT JOIN that found them all.
