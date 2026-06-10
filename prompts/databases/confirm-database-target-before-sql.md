---
title: Confirm the Database Target Before Running SQL
slug: confirm-database-target-before-sql
category: databases
tags: [universal, databases, sql]
works_with: all
severity: critical
one_liner: "Running SQL against prod when the user meant local, or vice versa"
---

# Confirm the Database Target Before Running SQL

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents executing SQL against the wrong environment because the default connection happened to point there.

**[Copy-paste ready version](../../install/confirm-database-target-before-sql.md)** — just the instruction block, no explanation.

## The Problem

The user says "wipe the orders table so I can re-test the import." The AI runs `psql $DATABASE_URL -c 'TRUNCATE orders;'`. The user meant their local database. `DATABASE_URL` in this shell was exported an hour ago for a prod debugging session. The command is correct, the intent was understood, and production order data is gone anyway, because nobody checked where the connection actually pointed.

AI assistants inherit whatever connection context exists: the env var that happens to be set, the default profile in `.pgpass` or `~/.my.cnf`, the `database.yml` entry that the framework picks when `RAILS_ENV` is unset, the connection string at the top of the user's most recent script. They treat "the database" as an unambiguous noun. In any real project it names at least three different machines with wildly different blast radii, and the default frequently points at the most dangerous one, because someone was just debugging prod.

The fix costs one query: identify the server before touching it, and say what you found.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Confirm the Database Target Before Running SQL

NEVER execute SQL, migrations, or database scripts without first identifying which database you are connected to, and stating it. "The database" is ambiguous; the default connection is frequently not the one the user means.

- Before the first statement of any session, verify the target:
  `SELECT current_database(), inet_server_addr();` (Postgres) or `SELECT DATABASE(), @@hostname;` (MySQL), or print the resolved connection string with credentials masked.
- Announce it: "Connected to `app_dev` on localhost, proceeding." If the host is not localhost or the name contains `prod`, stop and confirm before any write.
- Do not trust ambient configuration. `$DATABASE_URL`, the default framework environment, and the user's last-used connection profile are all guesses about intent, not statements of it.
- Match the target to the task. "Reset my data," "re-run the seed," "test the migration" imply local/dev; if the resolved connection is anything else, that's a contradiction to raise, not a detail to skip.
- For anything destructive against a non-local database, require the user to name the environment explicitly in their own words before proceeding.
- When writing scripts, take the connection string as an explicit required argument rather than falling back to an env var default, so the script can't silently inherit the wrong target later.

**Red flags that you're about to violate this:**

- "DATABASE_URL is set, so that must be the right database..."
- "They said 'the database,' singular, so there's no ambiguity..."
- "Checking the connection first is paranoid for a simple query..."
- "The config file defaults to this connection, so it's intended..."
- "I'll use the same connection the last script used..."

---

## Why It Works

1. **It separates "configured" from "intended."** The whole failure is the AI treating ambient config as a decision someone made for this task. Stating that env vars are leftovers, not instructions, breaks the inference.

2. **It makes the check observable.** Announcing the resolved target gives the human a chance to catch the mismatch before execution, turning a silent assumption into a reviewable claim.

3. **It defines contradiction triggers.** "Reset my data" plus a remote host is a logical conflict the AI can detect mechanically, without needing judgment about what the user probably meant.

4. **It fixes the script-shaped version too.** Defaulting scripts to `$DATABASE_URL` plants the same landmine for future runs; requiring an explicit argument removes the fallback path entirely.

## Origin

An engineer asked their assistant to "drop and recreate the database so we can test the setup script from scratch." Their shell still had the production read-write URL exported from an incident two days earlier. The assistant ran the drop against it without checking the host. The team had backups and lost only twenty minutes of writes, plus an afternoon of restore work, for want of a single `SELECT current_database()`.
