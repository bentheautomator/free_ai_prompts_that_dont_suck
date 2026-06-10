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
