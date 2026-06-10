---
title: Keep Seed Data Out of Migrations
slug: keep-seed-data-out-of-migrations
category: databases
tags: [universal, databases, migrations]
works_with: all
severity: medium
one_liner: "Putting sample/dev data inside migrations that run on every environment"
---

# Keep Seed Data Out of Migrations

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents dev convenience data from being baked into migrations that execute on production.

**[Copy-paste ready version](../../install/keep-seed-data-out-of-migrations.md)** — just the instruction block, no explanation.

## The Problem

While building a feature, the AI needs some rows to work with, so it puts them where the schema already lives: `INSERT INTO categories VALUES ('Test Category 1'), ('Sample'), ('Demo');` right inside the migration that creates the table. Locally this is great, the table appears with data and development flows. Then the migration ships, because migrations always ship, and production now has a category called "Test Category 1" visible in the dropdown of a customer-facing form.

Migrations are the one part of the codebase guaranteed to execute in every environment, exactly once, forever. That makes them the worst possible home for anything environment-specific. Sample users, demo content, "temporary" feature flags, a hardcoded admin account with a default password: all of it rides the migration train straight to prod. And because applied migrations shouldn't be edited, removing the data gracefully requires yet another migration to delete it everywhere it landed.

The distinction the AI misses is between schema, reference data, and sample data. Schema belongs in migrations. Reference data that the app requires to function (a roles table, country codes) can defensibly go in migrations or idempotent seeds. Sample data for development belongs in a seeds file that only runs when invoked, never as a side effect of migrating.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep Seed Data Out of Migrations

NEVER put development or sample data inside a migration. Migrations run in every environment including production; anything you INSERT in one becomes production data.

Distinguish three kinds of data and put each in its place:

- **Schema** (tables, columns, indexes, constraints): migrations. Always.
- **Required reference data** the application cannot function without (role names, statuses, country codes): acceptable in a migration or an idempotent seed, but write it to be safe on re-run (`INSERT ... ON CONFLICT DO NOTHING` / `INSERT IGNORE`) and keep it environment-neutral.
- **Sample/dev/demo data** (test users, example content, placeholder records): a seeds file or fixtures (`db/seeds.rb`, `seeds.sql`, factory scripts) that runs only when explicitly invoked. Never in a migration, never run automatically by deploy.

Additional rules:

- If you need data to develop against, create or extend the seeds file; do not take the shortcut of inserting in the migration "just for now." Migrations don't have a "for now."
- Never create user accounts or credentials in a migration. A migration-created admin with a known default password is a standing breach on every environment.
- Inserts in migrations also run during CI schema builds and on every new developer setup; data with timestamps, randomness, or external IDs makes those builds non-deterministic.
- If reference data must go in a migration, leave a comment saying why it qualifies as required-for-function.

**Red flags that you're about to violate this:**

- "I'll add a few rows in the migration so there's something to develop against..."
- "It's just placeholder data, we'll remove it later..."
- "The table is useless empty, so seeding it here makes sense..."
- "Everyone needs an admin user, the migration can create one..."
- "This insert only matters locally anyway..."

---

## Why It Works

1. **It gives the three-bucket taxonomy.** The AI's confusion is real: some data genuinely belongs near migrations. Separating schema, reference data, and sample data turns a fuzzy judgment into a sorting task.

2. **It states the execution guarantee plainly.** "Migrations run everywhere, once, forever" is the fact that makes the shortcut dangerous; the AI usually models migrations as "the database setup for my current environment."

3. **It singles out the credentials case.** A default admin account in a migration is the variant with security consequences, and it's common enough to deserve its own named prohibition rather than being implied.

## Origin

A migration creating a notifications table also inserted three sample notifications so the dev UI wouldn't be empty, including one reading "TEST PLEASE IGNORE." It deployed on a Thursday; by Friday morning a few thousand users had received "TEST PLEASE IGNORE" through the brand-new notification system, and the cleanup required another migration plus a support macro. The seeds file was right there.
