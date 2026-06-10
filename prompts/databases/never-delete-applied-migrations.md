---
title: Never Delete or Squash Applied Migrations
slug: never-delete-applied-migrations
category: databases
tags: [universal, databases, migrations]
works_with: all
severity: high
one_liner: "Deleting or squashing migration files that databases have already applied"
---

# Never Delete or Squash Applied Migrations

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents migration history from being deleted, regenerated, or squashed out from under databases that already applied it.

**[Copy-paste ready version](../../install/never-delete-applied-migrations.md)** — just the instruction block, no explanation.

## The Problem

A migrations directory with 400 files offends the AI's sense of order, and "clean up the migrations" invites the obvious move: delete them all and generate one fresh migration from the current models. Locally, against a recreated database, this is beautiful. Everywhere else, it's a bomb. Production's migration table records 400 applied entries; the new consolidated migration has a name it's never seen, so the framework tries to apply it, against a schema where every table already exists. Meanwhile a teammate's database has 396 of the 400 applied, and their path forward now exists in no file anywhere.

The AI also does smaller versions of the same thing: deleting a migration that "looks redundant," resolving a merge conflict between two migration branches by removing one side, or regenerating a migration file so it gets a new timestamp, which to the framework is a new, unapplied migration and an orphaned old entry. All of these share one misunderstanding: the files are only half the system. The other half is the ledger row in every database that has ever run them, and you can't edit that by editing files.

Squashing is a real, legitimate maintenance operation, and frameworks support it (Django's `squashmigrations` keeps `replaces` metadata precisely so applied databases aren't stranded). The failure isn't wanting consolidation; it's doing it by deletion.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Delete or Squash Applied Migrations

NEVER delete, rename, renumber, or regenerate a migration file that any database may have applied. Migration files are one half of a distributed system; the other half is the applied-migrations ledger in every database (prod, staging, CI caches, every developer machine). Deleting files strands every database whose ledger references them.

- "Clean up the migrations folder" does not mean delete-and-regenerate. A fresh consolidated migration is *unapplied* from every existing database's perspective and will try to re-create the entire schema.
- Resolve migration merge conflicts by ordering, not deletion: keep both sides, fix the dependency/ordering metadata (`dependencies` in Django, timestamps elsewhere). Never delete a teammate's migration to make the conflict go away.
- Don't regenerate a migration to change it; regeneration assigns a new identity, making the old entry an orphan and the new file a duplicate schema change.
- If consolidation is genuinely wanted, use the framework's squash mechanism, which records what the squash replaces (e.g. Django `squashmigrations` with `replaces`), and keep the old files until every environment, including the long-forgotten ones, has moved past them. This is a deliberate, coordinated operation; propose it, don't improvise it.
- Treat the migrations directory as append-only by default. The safe operations are: add a new migration. That's the list.
- Before any exception, enumerate the environments that have applied the files in question. If you can't enumerate them, the exception is off the table.

**Red flags that you're about to violate this:**

- "These 400 migration files are cruft, one clean migration is better..."
- "I'll resolve the merge conflict by dropping the other branch's migration..."
- "Regenerating the file is cleaner than editing my mistake..."
- "Nobody needs the old history, the schema is what matters..."
- "Fresh databases will build faster without all these files..."

---

## Why It Works

1. **It introduces the ledger as the second half.** The AI sees files; it doesn't model the applied-migrations table in N databases. Once the system is "files plus ledgers," file deletion is visibly a desync, not a cleanup.

2. **It handles the merge-conflict trigger explicitly.** Conflicting migration branches are where AIs most often delete history under cover of "resolving conflicts"; prescribing ordering-based resolution removes the cover.

3. **It legitimizes real squashing.** Consolidation pressure is valid and recurring; pointing at the framework's replace-aware mechanism gives the urge a safe outlet instead of leaving deletion as the only visible path.

4. **It sets append-only as the default posture.** A one-item list of safe operations is easy to comply with and makes every other operation feel like the exception it is.

## Origin

Asked to "tidy up the migration mess," an assistant replaced 180 migration files with a single generated baseline. CI, which rebuilt from scratch, went green, and the PR merged. The next deploy attempted to apply the baseline to production, failed on the first `CREATE TABLE` (it existed), and aborted, and every developer's next `migrate` did the same on their own machines. Unwinding it required hand-inserting ledger rows on prod and a pinned Slack message walking fourteen people through repairing their local state.
