---
title: Alter Database Enums Safely
slug: alter-database-enums-safely
category: databases
tags: [universal, databases, migrations]
works_with: all
severity: medium
one_liner: "Enum changes that fail in transactions or strand rows on removed values"
---

# Alter Database Enums Safely

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents enum migrations that fail inside transactions, strand existing rows, or desync the database from app code.

**[Copy-paste ready version](../../install/alter-database-enums-safely.md)** — just the instruction block, no explanation.

## The Problem

Enums look like the simplest type in the schema, which is why the AI handles them carelessly and why they bite in three distinct ways. First: on Postgres versions before 12, `ALTER TYPE order_status ADD VALUE 'refunded'` cannot run inside a transaction block, and nearly every migration framework wraps migrations in one, so the obvious migration fails with a confusing error the AI then "fixes" with something worse. Second: removing or renaming an enum value is not really supported at all; Postgres has no `DROP VALUE`, and the workarounds (create new type, cast column over, drop old type) lock the table and explode if any row still holds the removed value. Third: the AI updates the enum in application code, a Python `Enum`, a Rails enum hash, a TypeScript union, and forgets the database type entirely, or vice versa, so writes start failing for one value of one field.

Underneath all three is the same misunderstanding: the AI treats an enum value list like a constant in code, freely editable. A database enum is schema with data sitting on it. Adding is an append-only operation with transaction quirks; removing is a data migration wearing a type change's clothes.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Alter Database Enums Safely

NEVER treat a database enum like an editable constant list. Enum values have rows sitting on them; adding has transaction quirks, and removing is a full data migration.

**Adding a value:**

- Postgres: `ALTER TYPE ... ADD VALUE` can't run in a transaction block before v12. Confirm the version; if needed, mark the migration non-transactional (`disable_ddl_transaction!`, `atomic = False`).
- Deploy the database value *before* the code that writes it. New code writing 'refunded' against an enum that lacks it is an immediate production error.

**Removing or renaming a value:**

- First check for rows using it: `SELECT count(*) FROM orders WHERE status = 'refunded';` Nonzero means you migrate that data first, deliberately (map to another value, or don't remove).
- Postgres has no DROP VALUE. The real procedure is: create the new type, `ALTER TABLE ... ALTER COLUMN ... TYPE new_type USING status::text::new_type`, drop the old type. This locks the table; treat it like any heavy ALTER on a big table.
- Often the right call is to not remove it: stop writing the value, keep it valid for historical rows, and note it as deprecated.

**Always:**

- Change both sides or neither: database enum and application enum (model enum, union type, validation list) must ship in compatible order; say which deploys first and why.
- Consider whether a lookup table or a CHECK-constrained text column fits better when values change often; suggest it when asked to modify the same enum repeatedly.

**Red flags that you're about to violate this:**

- "Adding an enum value is a one-line migration..."
- "I'll remove the unused status value while I'm in here..."
- "The app enum is updated, the database will accept it..."
- "No rows probably use that old value..."
- "Renaming the value is just cosmetic..."

---

## Why It Works

1. **It splits add from remove.** The AI lumps all enum edits together; separating the append path (quirky but fine) from the removal path (a data migration) applies the right caution level to each instead of either paralysis or recklessness.

2. **It forces the rows-on-value check.** "No rows probably use it" is a guess about data; one count query replaces it with a fact that determines the whole plan.

3. **It makes deploy ordering explicit.** Half the incidents here are sequencing, code writing values the database doesn't know yet; requiring a stated order turns an implicit race into a reviewed decision.

## Origin

A feature added a 'paused' state: the application enum, the UI, and the tests all updated in one PR, with the `ALTER TYPE` migration included. The framework wrapped it in a transaction, the database was Postgres 11, and the migration failed on deploy; the deploy tool retried it twice, then marked the release failed, while the already-built containers were briefly live and writing 'paused' to a column that rejected it. Forty minutes of failed subscription updates traced back to one missing `disable_ddl_transaction!`.
