---
title: Read the Schema Before Citing Columns
slug: read-the-schema-before-citing-columns
category: context
tags: [universal, verification, assumptions]
works_with: all
severity: high
one_liner: "AI writing queries against table and column names it inferred instead of read"
---

# Read the Schema Before Citing Columns

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from inventing this project's database schema from how schemas usually look.

**[Copy-paste ready version](../../install/read-the-schema-before-citing-columns.md)** — just the instruction block, no explanation.

## The Problem

Ask for a query against "the users table" and the AI produces one immediately — `SELECT id, email, created_at FROM users WHERE deleted_at IS NULL` — without reading a single schema file. Every name in that query is a guess. Maybe the table is `accounts`, or `app_users` (the `users` name was taken by an old system), the primary key is `user_id` or a UUID named `guid`, timestamps are `createdAt` because an ORM made them, and soft deletion is an `is_active` boolean, not a `deleted_at` timestamp. The query is fluent SQL against an imagined database.

Schema guesses fail across a spectrum. The kind ones error: `column "deleted_at" does not exist`. The cruel ones run: a join on the wrong column pair returns plausible-but-wrong rows; a `WHERE status = 'active'` matches nothing because this schema spells it `ACTIVE` or uses an integer enum; a query that ignores the real soft-delete column happily includes every deleted record. Wrong-but-running queries produce wrong reports, wrong migrations, and wrong code built on their results.

No project keeps its schema secret. Migrations, ORM models, `schema.rb`/`schema.prisma`/SQL dumps, or one `\d table` away — the real names are always written down somewhere in the repo.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Read the Schema Before Citing Columns

NEVER write a query, migration, or data-access code using table or column names you haven't read from this project's actual schema. Schema names you produce from convention — `users`, `id`, `created_at`, `deleted_at` — are guesses wearing a DBA's confidence.

The dangerous schema guess isn't the one that errors; it's the one that runs and returns wrong rows.

**Before referencing any table or column:**
- Read the schema from its source of truth: ORM models/entities, `schema.prisma`, `schema.rb`, migration files (latest state, not just the first migration), `.sql` dumps, or introspect the live dev database if available
- Verify the names you're about to use specifically: exact table name, exact column spelling and casing, the actual primary/foreign key columns — not "the obvious ones"
- Check the semantics conventions hide: how soft deletion works here (timestamp? boolean? status enum?), how enums are stored (strings? integers? native enums? what casing?), which timestamps exist and what they're called
- Confirm join paths from real foreign keys or ORM relations, not from "these tables would obviously relate via user_id"
- For migrations, diff against the *current* schema state — adding a column that exists or indexing one that doesn't are both schema-guess failures
- When code and schema use different names (ORM field mapping), be precise about which layer you're writing for

**Red flags that you're about to violate this:**
- "The users table will have an email column..."
- "Standard timestamps — created_at, updated_at..."
- "Soft deletes mean there's a deleted_at column..."
- "I'll join these on user_id, the obvious key..."
- "The status values will be lowercase strings..."
- Writing a column name that appears in no schema file or model you've read this session

---

## Why It Works

1. **It ranks the silent failure above the loud one.** "Errors are the kind ones" recalibrates the AI's risk model: a query that runs is not a query that's right, so verification can't be skipped just because execution succeeded.

2. **It targets semantic conventions, not just spelling.** Soft-delete mechanisms and enum storage are where verified *names* still produce wrong *queries*; calling them out extends the check from vocabulary to meaning.

3. **It pins migrations to current state.** Migration-writing against an imagined schema is the highest-stakes variant; requiring a diff against the latest state catches it before it becomes a failed (or worse, succeeded) deploy.

4. **It names the layer-mapping trap.** ORM field names and database column names diverge by design; making the AI declare which layer it's writing for prevents correct names used in the wrong place.

## Origin

An AI wrote a cleanup query for a support team: remove test accounts, defined as `WHERE email LIKE '%test%' AND deleted_at IS NOT NULL`. The schema had no `deleted_at` — soft deletion was a `state` column where `state = 4` meant deleted. The planner happily evaluated `deleted_at IS NOT NULL` as an error... in production it would have. In staging, where someone had added a `deleted_at` column during an abandoned experiment, the query ran perfectly and validated the approach. The near-miss was caught by a DBA who read the query, squinted, and asked: "whose schema is this for?"
