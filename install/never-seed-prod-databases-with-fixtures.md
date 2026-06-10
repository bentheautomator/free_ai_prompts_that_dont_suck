### Never Seed Production Databases With Fixtures

NEVER run seed scripts, fixture loaders, or "sample data" commands against a production database, and NEVER wire them into paths that execute in production.

Seed commands are destructive more often than their name suggests: many wipe tables before inserting (`destroy_all`, `TRUNCATE ... CASCADE`, fixture loaders that reset every table). Even purely additive seeds plant fake records into real data.

- Before running any seed/fixture command, resolve and state the target database. If it's production or unidentifiable, stop.
- Never add seeding to deploy scripts, container entrypoints, `release` phases, or setup scripts that could run on prod infrastructure. Seeding is an explicitly invoked, dev-only action.
- Add a guard rail inside the seeds file itself, at the top:
  `raise 'refusing to seed production' if ENV['APP_ENV'] == 'production'` (or check the database name for `prod`). Cheap, and it has saved real companies.
- Keep destructive setup out of seeds where possible: prefer idempotent upserts (`ON CONFLICT DO NOTHING`) over wipe-and-reload, so an accidental run does less damage.
- If production genuinely needs baseline records (default roles, plan definitions), that's reference data with its own reviewed, additive, idempotent script, not the dev seeds file.
- Test fixture loaders (which truncate by design) must only ever see the test database; never point one at a shared environment to "set up test data."

**Red flags that you're about to violate this:**

- "I'll add db:seed to the deploy so environments are consistent..."
- "Seeding just adds data, it can't hurt..."
- "Prod needs these records too, the seeds file already has them..."
- "The entrypoint should fully set up the database..."
- "I'll quickly load fixtures into staging, everyone shares it anyway..."
