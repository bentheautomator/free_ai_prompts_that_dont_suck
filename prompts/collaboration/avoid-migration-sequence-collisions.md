---
title: Avoid Migration Sequence Collisions
slug: avoid-migration-sequence-collisions
category: collaboration
tags: [universal, teamwork, shared-code]
works_with: all
severity: high
one_liner: "Stops claiming migration numbers that collide with teammates' in-flight work"
---

# Avoid Migration Sequence Collisions

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from creating database migrations whose timestamps or sequence numbers collide with migrations other developers have in flight.

**[Copy-paste ready version](../../install/avoid-migration-sequence-collisions.md)** — just the instruction block, no explanation.

## The Problem

Migration sequences are a shared, append-only resource: every developer on the team is claiming numbers from the same line. The AI gets this wrong in several ways. It writes a migration by hand and picks the next number after what it sees locally — but two teammates have unmerged migrations claiming that same number. It backdates a timestamp so its migration "sorts before" another one. It edits an existing migration file instead of adding a new one, even though that migration already ran on the staging database and three teammates' machines. It renames migration files for tidiness, orphaning the rows in the migrations tracking table.

Collisions here are uniquely painful because migration state lives in three places that must agree: the files in the repo, the tracking table in each database, and the actual schema. A duplicate sequence number means two branches merge cleanly and the deploy fails — or worse, applies in different orders on different environments, leaving staging and production with subtly different schemas. An edited already-applied migration means the tracking table says "done" while the schema says otherwise, on every machine and environment that ran the old version.

The AI causes this because from inside one checkout, the migration sequence looks private. It can't see the unmerged branches, the staging database, or the five laptops where the current migration set has already been applied.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Avoid Migration Sequence Collisions

ALWAYS generate migration identifiers with the project's migration tool, and NEVER edit or renumber a migration that may have run anywhere but your machine. The migration sequence is shared with every developer and environment; your local files are not the whole picture.

- Use the framework's generator (`rails g migration`, `alembic revision`, `manage.py makemigrations`, `migrate create`, etc.) to create migrations. It exists largely to mint non-colliding identifiers.
- Never hand-pick "the next number" by looking at the local directory. Unmerged branches are claiming numbers you can't see; current-time timestamps from the generator collide far less than guessed sequences.
- Never backdate or reorder a migration to sort before someone else's. If ordering matters, declare an explicit dependency the tool understands, or coordinate through the human.
- Never modify a migration that has been merged, or that has plausibly run on any shared environment or teammate's machine. Write a new migration that alters the result instead.
- Never rename or delete applied migration files; the tracking table references them by name/ID.
- After pulling or merging, if two migrations share a number or both claim to be "latest," surface the conflict rather than resolving it by editing either file silently.

**Red flags that you're about to violate this:**
- "I'll just create the file myself; the generator is overkill."
- "The last migration is 0042, so mine is 0043."
- "I'll tweak the migration I wrote yesterday instead of adding another."
- "Backdating the timestamp makes it run in the right order."
- "These migration filenames are inconsistent; I'll rename them."

---

## Why It Works

1. **It routes identifier-minting through the one tool that sees the convention** — generators encode the project's collision-avoidance scheme, while hand-picked numbers encode only the local directory.
2. **It builds in the invisible-state model**: merged or plausibly-applied migrations are immutable because their state lives in tracking tables the AI cannot inspect from the repo.
3. **It replaces ordering hacks with declared dependencies**, which survive merges; sort-order tricks do not.
4. **It turns post-merge conflicts into a human decision**, since either silent resolution corrupts someone's environment.

## Origin

Two developers each had an assistant generate a migration the same afternoon; one assistant hand-numbered its file `0057` after eyeballing the directory, colliding with the other branch's tool-generated `0057`. Both merged. Staging applied one and skipped the other; production, deployed from a different branch order, applied both. The schemas diverged by one column, and the resulting "works on staging, fails in prod" bug ate two days before anyone thought to diff the migration tables.
