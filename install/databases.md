### Add Columns Without Table Rewrites

NEVER assume an ADD COLUMN is cheap. Whether an ALTER TABLE is a metadata-only change or a full-table rewrite under an exclusive lock depends on the default's volatility, the engine, and the version, and the slow version looks identical in the diff.

- Constant defaults are generally safe on modern engines: `ADD COLUMN flags integer DEFAULT 0` is metadata-only on Postgres 11+ and recent MySQL.
- Volatile defaults rewrite the table: `DEFAULT gen_random_uuid()`, `DEFAULT now()` in some contexts, any function evaluated per row. On a large table this is minutes-to-hours under an exclusive lock.
- For a volatile default on a big table, split it:
  1. `ADD COLUMN token uuid;` (no default, instant)
  2. Backfill in batches outside the deploy.
  3. `ALTER COLUMN token SET DEFAULT gen_random_uuid();` (applies to new rows only, instant)
  4. Add NOT NULL afterward if needed, via validated constraint.
- Before shipping any ALTER on a table that might be large: state the engine and version, state whether this specific operation is metadata-only on it, and state the table's approximate row count. If you can't fill in all three, ask or check; don't ship the guess.
- Dev-database speed is evidence of nothing. Every rewrite is instant on 1,000 rows.
- The same verify-don't-assume applies to other ALTERs: changing types, adding generated columns, and altering NULLability each have their own metadata-vs-rewrite rules per engine.

**Red flags that you're about to violate this:**

- "Adding a column is always fast..."
- "It ran instantly on my local database..."
- "The default makes the migration self-contained, no backfill needed..."
- "Postgres handles defaults efficiently now..."
- "I'll worry about table size if it becomes a problem..."

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

### Anonymize Prod Data Before It Becomes Fixtures

NEVER copy real production rows into fixtures, seeds, tests, sample files, commit messages, or PR descriptions. Anything committed to git is permanent, widely replicated, and outside every access control the production database had.

- When a bug needs real-data shapes to reproduce, replicate the *shape*, not the values: same field lengths, same unicode quirks, same null patterns, same edge-case structure, with identifying values replaced:
  Real: `('Jane Foowicz', 'jane.foo@gmail.com', '+44 7700 900123')`
  Fixture: `('Tëst Üserwicz', 'user-7be2@example.com', '+44 7700 900000')`
  Preserve whatever property triggers the bug (the diacritic, the length, the format) and say which property that is.
- PII includes more than names: emails, phone numbers, addresses, IPs, government IDs, payment fragments, internal account IDs that resolve to people, and free-text fields (notes, messages) which are PII until proven otherwise.
- Use reserved fake domains and ranges: `example.com/.org`, `+1 555` numbers, RFC 5737 IPs (`192.0.2.x`).
- Don't dump prod tables to local files or shared dev databases as a working convenience. If a realistic dataset is genuinely needed for development, that's an anonymized-snapshot pipeline, an explicit project with sign-off, not a `COPY TO` in a debugging session.
- Query results pasted into conversations, tickets, or commit messages follow the same rule: mask the identifying columns.
- If you find real PII already sitting in fixtures, flag it immediately; deleting the file doesn't remove it from git history, so the human needs to decide on history rewriting and any notification duties.

**Red flags that you're about to violate this:**

- "The bug only reproduces with the actual record..."
- "It's just one row, and it's only an email address..."
- "This repo is private, so committing it is fine..."
- "I'll use the prod dump locally and delete it after..."
- "The PR description needs the real values for reviewers to verify..."

### Back Up Before Destructive Data Migrations

NEVER run a migration or script that overwrites, transforms, or deletes existing data without first preserving the original values. The input to your transformation is destroyed by the transformation; if the logic has a bug, you cannot re-run it.

- Before any in-place transform, snapshot the affected data:
  `CREATE TABLE users_phone_backup_20260610 AS SELECT id, phone FROM users WHERE phone IS NOT NULL;`
  Verify the backup row count matches, then transform.
- Cheaper alternative when the schema allows it: write transformed values into a new column, verify, then swap which column the app reads. The originals stay where they were.
- "There's a nightly backup" is not a plan. It's hours stale, restoring it is a project, and it loses everything written since. A targeted copy of exactly the affected columns costs one statement.
- Scope the backup to what's at risk: `id` plus the columns being changed. You're insuring a transform, not archiving the table.
- State the cleanup plan: backup tables get dropped after a defined verification period (e.g., one week post-deploy), not immediately and not never.
- Deletion counts as transformation. Before a bulk DELETE of rows that took effort to create, the same snapshot rule applies.
- If the user explicitly declines the backup, proceed, but make the trade-off concrete first: "if `normalize()` has a bug, the original phone strings are unrecoverable."

**Red flags that you're about to violate this:**

- "The transformation logic is straightforward, nothing will go wrong..."
- "There are backups if we really need them..."
- "A backup table is clutter we'd have to clean up..."
- "I tested the function on sample values..."
- "It's a normalization, the data isn't really changing..."

### Batch Large SQL Backfills

NEVER run a backfill, bulk UPDATE, or bulk DELETE as a single statement in a single transaction without first knowing the row count. Above roughly 10,000 affected rows, batch it.

One giant data-change transaction holds locks for its entire runtime, blocks concurrent writes, bloats the WAL/undo log, lags replicas, and loses all progress if interrupted.

- Before writing the statement, check scale: `SELECT count(*) FROM orders WHERE shipped_at IS NOT NULL AND status IS NULL;` State the number out loud in your response.
- Batch by primary key range or with a LIMIT loop, committing each batch:
  `UPDATE orders SET status = 'complete' WHERE id IN (SELECT id FROM orders WHERE shipped_at IS NOT NULL AND status IS NULL LIMIT 5000);`
  Repeat until 0 rows affected.
- Make the loop resumable: the WHERE clause must exclude already-processed rows (`status IS NULL` above), so a crash mid-run resumes instead of restarting.
- Sleep briefly between batches (100-500ms) to let replication catch up and other transactions breathe.
- Bulk DELETEs follow the same rule. For deleting most of a table, prefer copying survivors to a new table or dropping a partition over a giant DELETE.
- Never wrap the whole batched loop in one outer transaction; that defeats the entire point.

**Red flags that you're about to violate this:**

- "One UPDATE statement is the cleanest way to do this..."
- "I don't know how big the table is, but the query is correct..."
- "A single transaction is safer because it's atomic..."
- "Batching adds complexity the user didn't ask for..."
- "It worked instantly on my test data..."

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

### Check Index Usage Before Dropping

NEVER drop an index because the codebase doesn't appear to use it. Query planners don't read your repo; the index may serve other services, admin tools, scheduled jobs, or ORM-generated queries that never appear as literal SQL.

- Check actual usage statistics from the database before proposing a drop:
  Postgres: `SELECT idx_scan, last_idx_scan FROM pg_stat_user_indexes WHERE indexrelname = 'idx_orders_customer_created';`
  MySQL: `SELECT * FROM sys.schema_unused_indexes;`
  Report the numbers in your response.
- Zero scans is necessary but not sufficient: stats may have been reset recently, and some workloads are monthly or quarterly. Ask how long the stats window covers and whether periodic jobs exist before trusting a zero.
- Never drop an index that backs a constraint (unique, primary key, FK support); the constraint, not query speed, is its job.
- Prefer a reversible decommission: note the full `CREATE INDEX` statement in the PR so restoration is copy-paste, and on engines that support it, make the index invisible first (`ALTER INDEX ... INVISIBLE` in MySQL) and watch for regressions before the real drop.
- Drop with `DROP INDEX CONCURRENTLY` (Postgres) on live tables, same locking logic as creation.
- Remember the recovery asymmetry and say it when proposing the drop: dropping is instant, rebuilding on a large table takes hours, under incident pressure.

**Red flags that you're about to violate this:**

- "No query in the codebase uses these columns..."
- "This index is redundant, the other one probably covers it..."
- "Unused indexes just slow down writes, dropping is a free win..."
- "If something needs it, we'll just add it back..."
- "It has a weird name, it's clearly leftover from something old..."

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

### Create Indexes Concurrently on Live Tables

NEVER add or drop an index on a production-sized table with the default locking form. Plain `CREATE INDEX` blocks all writes to the table for the entire build, which on large tables means minutes of write outage.

- Postgres: use `CREATE INDEX CONCURRENTLY idx_orders_user_id ON orders (user_id);` and `DROP INDEX CONCURRENTLY` for removals.
- `CONCURRENTLY` cannot run inside a transaction. Configure the migration accordingly: `disable_ddl_transaction!` (Rails), `atomic = False` (Django), `transaction: false` in the migration tool's terms. A concurrent index migration without this setting will simply fail.
- Handle the failure mode: if a concurrent build dies, it leaves an INVALID index. Make the migration idempotent: drop the invalid index if present, then create.
- MySQL/InnoDB: most secondary index adds are online by default (`ALGORITHM=INPLACE, LOCK=NONE`); state the algorithm explicitly so a silent fallback to a locking rebuild fails loudly instead.
- Before writing the migration, ask or check how big the table is. On genuinely small tables (thousands of rows) the plain form is fine; say that you checked.
- This is about live tables. Brand-new tables created in the same migration can take plain indexes freely.

**Red flags that you're about to violate this:**

- "CREATE INDEX is a standard, safe operation..."
- "The ORM helper generated it this way..."
- "CONCURRENTLY has weird transaction issues, simpler to skip it..."
- "Index creation is fast, the lock won't matter..."
- "I'll use the same pattern as the existing old migrations..."

### Dedupe Before Adding Unique Constraints

NEVER add a unique constraint or unique index without first checking the column for existing duplicates in the environment that matters. Production data contains exactly the duplicates the constraint is meant to prevent; that's why someone is asking for it.

- Check first, and report the result:
  `SELECT email, count(*) FROM users GROUP BY email HAVING count(*) > 1;`
  Zero duplicates: proceed with the constraint. Nonzero: deduplication is now part of the task, and it comes first.
- Deduplication is a data decision, not a code decision. Do not silently pick "keep lowest id." Present the options: keep newest, keep the one with activity (orders, logins), merge records, or escalate to a human per pair. Show sample duplicate pairs before deleting anything.
- Mind the children: duplicates often have dependent rows. Re-point children to the surviving row before removing the loser, in a transaction.
- Plan for duplicates created *between* dedupe and constraint: run the dedupe, then add the constraint promptly, and make the dedupe re-runnable in case the gap let new ones in.
- On large tables, add the unique index `CONCURRENTLY` (it can fail gracefully on a race; retry after re-deduping).
- Soft-deleted rows are a classic snag: a unique index over all rows fights with "deleted" duplicates. Consider a partial index: `CREATE UNIQUE INDEX ... ON users (email) WHERE deleted_at IS NULL;`
- Never resolve a failed unique migration by just dropping the constraint requirement; the duplicates remain and so does the bug producing them.

**Red flags that you're about to violate this:**

- "The column should already be unique, the constraint just formalizes it..."
- "The migration passed locally and in CI..."
- "If there are duplicates, I'll keep the first row and drop the rest..."
- "Dedupe is simple, group by and delete the extras..."
- "Soft-deleted rows don't count, the index won't mind them..."

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

### Down-Migrations Must Actually Restore Data

NEVER write a down-migration that restores the schema but not the data, while presenting it as reversible. A down that recreates an empty column after the up dropped a full one is a trap, not a rollback.

Schema symmetry is not reversibility. The question is: if up runs on real data and then down runs, is the database back to where it started?

- For each down you write, classify it honestly:
  - Truly reversible (added a table/column with no data yet; created an index): write the normal down.
  - Lossy: the up destroyed information (DROP COLUMN with data, destructive UPDATE, merging values). Do not fake it.
- For lossy migrations, prefer making the down refuse loudly: raise `IrreversibleMigration` (Rails), `RuntimeError('cannot restore dropped data')`, or the framework equivalent, with a comment explaining what would be needed to actually restore.
- Better: make the up non-lossy so a real down exists. Copy data aside before destroying it:
  `CREATE TABLE users_middle_name_backup AS SELECT id, middle_name FROM users;` then drop; the down restores from the backup table.
- Data-transforming ups (normalizing, reformatting) need the old values preserved somewhere, or an honest irreversible down. A down that "reverses" a lowercase by doing nothing is a no-op wearing a costume.
- When you write an irreversible down, say so in your summary: "this migration cannot be rolled back; here's why."

**Red flags that you're about to violate this:**

- "The down just mirrors the up, easy..."
- "Re-adding the column reverses dropping it..."
- "Nobody actually runs down-migrations anyway..."
- "The framework requires a down, so I'll write something plausible..."
- "The transform is close enough to reversible..."

### Drop Columns Only After All Readers Are Gone

NEVER drop a column (or table) in the same deploy as the code change that stops using it. Removal is always at least two deploys.

The core problem: migrations and code do not deploy atomically. During any rollout there is a window where old code runs against the new schema, and old code that still selects the dropped column will crash.

- Deploy 1: remove every read and write of the column from application code. Mark the column ignored in the ORM if it supports it (`ignored_columns` in Rails, `deferred`/removed from the model in others) so `SELECT *` style queries stop referencing it.
- Deploy 2 (a later, separate change, after deploy 1 is fully live): the migration with `DROP COLUMN`.
- The same applies to dropping tables, dropping indexes that queries hint at, and removing enum values.
- If asked to "remove feature X" in one PR, split the work and say so explicitly: "code removal now, column drop in a follow-up after this deploys."
- Rollback check: if deploy 2 is reverted, the app must still work. A dropped column makes the *previous* app version unrunnable, which breaks rollback too.

**Red flags that you're about to violate this:**

- "I'll clean up the schema while I'm at it..."
- "The migration and code change belong in the same PR for atomicity..."
- "Nothing references this column anymore after my change..."
- "It deploys together, so there's no window..."
- "Leaving the column would be dead schema, better to drop it now..."

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

### Load ORM Relations Before the Session Closes

ALWAYS load every relation the caller will need before the session/transaction that fetched the object ends. An ORM object's lazy attributes are deferred queries with a lifetime requirement; accessing them after the session closes either crashes (`DetachedInstanceError`, `LazyInitializationException`) or fires hidden queries from presentation code.

- At the data-access boundary, load deliberately: `selectinload`/`joinedload` (SQLAlchemy), `select_related`/`prefetch_related` (Django), `includes` (Active Record), fetch joins (JPA), for exactly the relations the caller uses. Name them; don't guess "all."
- Functions that return ORM objects across a session boundary must document or guarantee what's loaded. Better: return plain data (DTO, dict, dataclass) built inside the session, so the boundary is explicit and nothing lazy escapes.
- Banned fixes for a detached/lazy-load error, propose none of these without flagging the trade-off:
  - Extending session lifetime to wherever the access happens ("open session in view," module-level sessions).
  - Global eager loading of all relations on the model.
  - `expire_on_commit=False` purely to silence the error.
  - Re-querying inside property accessors.
- When you hit a lazy-load error, treat it as a boundary-design message: "this caller needs `items` and `customer`; load them at fetch time." Fix the fetch, not the session scope.
- In templates/serializers, attribute access that triggers queries is a hidden dependency; serialize from data prepared in the handler instead.

**Red flags that you're about to violate this:**

- "I'll just keep the session open until the request finishes..."
- "Setting expire_on_commit=False makes the error disappear..."
- "Eager-load everything so this can never happen again..."
- "The template can fetch what it needs when it renders..."
- "Accessing the attribute again re-queries automatically, problem solved..."

### Migrations Never Import App Models

NEVER import live application models, services, or helpers into a migration. A migration must run correctly forever against the schema as it was when written; app code describes the schema as it is now. The two diverge, and the migration breaks at the worst time, on fresh databases and CI builds, long after anyone remembers why.

- Use raw SQL inside data migrations: `UPDATE users SET score = 0 WHERE score IS NULL;` It depends on nothing that can drift.
- If the framework provides historical models, use those instead of imports: Django's `apps.get_model('app', 'User')` inside `RunPython`, never `from app.models import User`.
- If a framework's migration style puts model classes in scope (e.g., Active Record), define a minimal stub inside the migration file (`class User < ApplicationRecord; end`) so the migration owns its own definition.
- Never call business-logic methods from a migration (`user.recalculate_score()`, service objects, serializers). The migration gets the *result* as literal SQL or inline logic, not a call into code that will change.
- Watch for model side effects: validations, callbacks, default scopes, and signals firing during a migration are bugs even when the import "works." Raw SQL fires none of them.
- The same applies to constants and enums imported from app code; inline the values with a comment noting their source.

**Red flags that you're about to violate this:**

- "The model already has exactly the method I need..."
- "Importing the model is cleaner than raw SQL..."
- "This migration runs once next deploy, then it doesn't matter..."
- "The model isn't going to change..."
- "Using the ORM here keeps the code consistent with the rest of the app..."

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

### Never Edit Applied Migrations

NEVER modify a migration file that may have already been applied to any database (prod, staging, CI, or a teammate's machine). Write a new migration instead.

A migration is an append-only log, not editable source code. Databases track migrations as applied by name/version and will never re-run an edited file, so your edit changes nothing except making the file lie about history.

- To fix a mistake in a previous migration, create a new migration that alters the schema to the corrected state (`ALTER TABLE users ALTER COLUMN email TYPE varchar(320)`), even if the original migration is "obviously wrong."
- Treat a migration as applied unless proven otherwise. Committed and pushed means applied. Merged means applied. Only a migration created in the current working session, never run outside this machine, is safely editable.
- This includes "harmless" edits: renaming the file, reformatting, changing a default, fixing a typo in a column name. Any content change to an applied migration is a violation.
- If asked directly to "fix the migration," say that it has already been applied and propose a corrective follow-up migration instead.
- Exception requires explicit human confirmation that the migration has never run anywhere, including CI.

**Red flags that you're about to violate this:**

- "It's cleaner to fix the mistake at its source..."
- "This migration is only a week old, it probably hasn't run anywhere..."
- "I'll just correct the typo in the original file..."
- "Editing it keeps the migration history tidy..."
- "The user said fix the migration, so they must mean this file..."

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

### Never Truncate Tables Other Systems Read

NEVER truncate or empty a table based on what you can see in the current codebase. "No references in this repo" does not mean "no readers." Databases are integration points; consumers live in other repos, cron jobs, BI dashboards, and pipelines you cannot see.

- Treat TRUNCATE on any non-local database as requiring explicit human confirmation, every time, with the table name and environment stated: "About to TRUNCATE `events` on staging, which removes all 2.1M rows irrecoverably. Confirm?"
- Before proposing it, articulate who might read the table: replication consumers, ETL/analytics jobs, downstream services, reports. If you can't enumerate the readers, you don't know the blast radius.
- Prefer scoped DELETE with a WHERE clause over TRUNCATE; "clean up old events" means `DELETE FROM events WHERE created_at < now() - interval '90 days'` (batched if large), not emptying the table.
- If a full reset is genuinely intended, prefer renaming the table aside (`ALTER TABLE events RENAME TO events_old_20260610`) and creating a fresh one; the data survives until someone confirms nothing broke.
- Remember what TRUNCATE actually does: no row triggers fire, sequences may reset, and there is no row-level undo. Say this when proposing it.
- On local/test databases owned solely by this project, truncate freely.

**Red flags that you're about to violate this:**

- "Nothing in the codebase reads this table..."
- "It's just log data, nobody will miss it..."
- "TRUNCATE is faster and cleaner than DELETE here..."
- "The user said clean up, and this is the cleanest..."
- "We can always regenerate this data later..."

### No Long-Open Database Transactions

NEVER hold a database transaction open across slow or unbounded operations: network calls, file I/O, sleeps, queue publishes, or waiting for human input. A transaction holds locks and pins resources for its entire lifetime; its duration is the duration of the damage.

- Structure code as: gather everything needed (including all external calls) first, then open the transaction, do only database statements, commit. Seconds, not minutes.
- Concretely banned inside a transaction: HTTP/API calls, `sleep()`, sending email, reading user input, large in-memory processing of fetched rows, iterating a slow generator.
- In interactive sessions: do not `BEGIN`, run a statement, and then stop to ask the user a question. If verification needs human eyes, either present the plan before opening the transaction, or use a fast scripted check (row count comparison) inside it.
- If business logic seems to need external calls "inside" the transaction, restructure: write an intent row, commit, perform the call, then record the result in a second short transaction (the outbox pattern). Two short transactions beat one long one.
- Watch for framework-created long transactions: a request-scoped session that stays open while the handler calls three services has this bug without any visible BEGIN.
- Treat `idle in transaction` connections as defects. If your script can be interrupted between BEGIN and COMMIT (debugger, prompt, retry loop), it can strand one.

**Red flags that you're about to violate this:**

- "I'll wrap the whole function in a transaction to be safe..."
- "The API call usually responds quickly..."
- "I'll leave the transaction open so the user can inspect before commit..."
- "Holding locks a bit longer is the price of correctness..."
- "The session manages transactions, I don't need to think about it..."

### No Prod Connection Strings in Code or Configs

NEVER hardcode a database connection string, especially a production one, into source code, scripts, test configs, or notebook cells. And NEVER use a real database URL as a fallback default.

A hardcoded URL is a credential leaked into git history plus a landmine: every future run of that file targets that database, regardless of who runs it or why.

- Read connection info from the environment or a config system, and fail loudly when it's absent:
  `url = os.environ['DATABASE_URL']  # KeyError if unset, which is correct`
  Not: `os.environ.get('DATABASE_URL', '<real url>')`. The right fallback for a missing database URL is an error, never a database.
- If the user pastes a connection string into the conversation, use it for the immediate session if asked, but do not write it into any file. If they ask you to hardcode it, propose the env-var version and note the git-history problem once.
- Test configs must not contain shared or remote database URLs; tests get a local/ephemeral database, configured by environment.
- One-off scripts take the connection as an explicit required argument (`--database-url`), making every run name its target.
- Example/template configs (`.env.example`) get obviously fake values: `postgresql://user:pass@localhost:5432/app_dev`, never a real host.
- If you find an existing hardcoded prod URL while working, flag it: it's a leaked credential needing rotation, not just style debt.

**Red flags that you're about to violate this:**

- "The connection string is right here, easiest to inline it..."
- "It's an internal hostname, not really a secret..."
- "A fallback default makes the script work out of the box..."
- "This script is temporary, it won't be committed..."
- "I'll use the prod URL in the test config just to get the suite running..."

### No Silent Error Handling in Migrations

NEVER swallow errors in a migration. A failing migration is the system working: it stopped a schema transition that wasn't going as written. Wrapping steps in `try/except pass`, `rescue nil`, or reflexive `IF EXISTS` converts a loud, diagnosable failure into silent schema drift recorded as success.

- A migration must either complete exactly as written or fail loudly and leave evidence. "Ran without errors because errors were suppressed" is the worst available outcome: the ledger says applied, the schema says otherwise, on some environments.
- When a migration fails somewhere, diagnose that failure. The fix addresses the cause (ordering, missing precondition, bad assumption about existing state), not the symptom (an exception reaching the runner).
- `IF EXISTS`/`IF NOT EXISTS` are legitimate only when the precondition is *known and intended*, and a comment says why: `DROP INDEX IF EXISTS idx_tmp_backfill; -- created conditionally by 0231 on some envs`. Reflexively adding them "for safety" hides typos (`DROP COLUMN IF EXISTS legacy_socre` succeeds, drops nothing) and masks real divergence.
- Never add blanket exception handling around migration steps. If a specific, expected error must be tolerated, catch exactly that error class, log what happened, and justify it in a comment.
- If environments have genuinely diverged (the migration fails on one machine, succeeds elsewhere), that's the finding, surface it and reconcile the schemas; don't paper over it with guards so the run goes green.
- The same applies to migration runner scripts: a step that fails must halt the sequence, not log-and-continue into migrations that assumed it succeeded.

**Red flags that you're about to violate this:**

- "I'll add IF EXISTS everywhere so the migration is idempotent..."
- "The try/except makes it more robust across environments..."
- "This step fails on some machines, easiest to let it skip..."
- "The error is probably harmless, suppressing it unblocks CI..."
- "Migrations should never crash the deploy, so catch everything..."

### No Surprise Cascade Deletes

NEVER add `ON DELETE CASCADE` (or ORM equivalents: `dependent: :destroy`, `on_delete=CASCADE`, `cascade="all, delete-orphan"`) just to make a foreign key error go away. That error is a question, "what should happen to the child rows?", and cascade answers it with permanent multi-table deletion, forever, for every caller.

- When a delete hits an FK constraint, present the options instead of auto-picking cascade:
  - `RESTRICT` (default): block the delete; caller must handle children deliberately. Safest default.
  - `SET NULL`: orphan the children but keep the data (FK column must be nullable).
  - Soft delete: `deleted_at` timestamp on the parent; nothing is destroyed.
  - `CASCADE`: only when child rows are genuinely meaningless without the parent (line items of a draft, join-table rows) and the human confirms.
- Before adding any cascade edge, trace and state the transitive blast radius: "deleting a `customer` would cascade to `orders`, then `invoices`, then `payments`." If you can't trace it, don't add it.
- Never cascade into tables with financial, audit, or compliance value. Those rows must outlive their parents.
- Audit-on-touch: if you modify a model that already has cascade edges, mention them, the human may not know they exist.
- One-off cleanup deletes should not get a schema change at all: delete the children explicitly in the right order, in a transaction, with row counts checked.

**Red flags that you're about to violate this:**

- "The FK error is blocking the delete, cascade fixes it..."
- "Child rows without a parent are useless anyway..."
- "Adding dependent: :destroy makes the model complete..."
- "This matches the cascade pattern on the other models..."
- "The user wants the delete to work, this makes it work..."

### NOT NULL Columns Need a Default or a Backfill

NEVER add a NOT NULL column without a DEFAULT to a table that contains rows. The migration will fail on existing data, or you'll be tempted into an unbatched backfill inside the deploy to make it pass.

"This field is required" describes new records; the constraint applies to all records ever inserted. Bridge the gap explicitly.

- First, check whether the table has rows. On an empty or brand-new table, plain `NOT NULL` is fine; say that you checked.
- If a sensible default exists, use it: `ALTER TABLE users ADD COLUMN locale varchar NOT NULL DEFAULT 'en';` (Postgres 11+ and modern MySQL handle this without rewriting the table; confirm for the engine and version in use.)
- If no constant default makes sense, split the work:
  1. Migration: add the column nullable.
  2. Backfill existing rows in batches, outside the deploy path.
  3. Later migration: `SET NOT NULL` once a check confirms zero NULLs remain. In Postgres, prefer adding a `CHECK (col IS NOT NULL) NOT VALID` then `VALIDATE CONSTRAINT` to avoid a long lock.
- Do not put the backfill UPDATE inside the same migration as the DDL on a large table.
- Application code must start writing the column at step 1, or step 3 never becomes possible.

**Red flags that you're about to violate this:**

- "The field is required, so the column should be NOT NULL..."
- "It worked fine on my local database..."
- "I'll just add a quick UPDATE in the migration to fill old rows..."
- "The table probably doesn't have that many rows..."
- "The ORM generated this migration, so it must be safe..."

### Prod Data Fixes Are Reviewed Scripts, Not Ad-Hoc SQL

NEVER fix production data by composing SQL interactively in a prod console. Anything beyond reading rows gets written as a script, reviewed, rehearsed on non-prod data, and then executed once, with a record.

Improvised console SQL is a first draft running in production: no review, no rehearsal, no reliable record of what ran.

- Write the fix as a file: the diagnosis query, the change wrapped in a transaction, verification of affected counts, and an explicit COMMIT gated on the counts matching:
  `BEGIN; UPDATE subscriptions SET state='active' WHERE id IN (...); -- expect 3 rows` then verify, then COMMIT or ROLLBACK.
- Rehearse it where it can't hurt: staging, a local restore, or at minimum the same script with COMMIT replaced by ROLLBACK on prod to observe the counts.
- Get review for anything touching more rows than you can individually look at, or any DELETE. Paste the script, the rehearsal output, and the expected counts.
- Record the execution: script content, when it ran, what it reported. The ticket or incident doc is fine; scrollback is not.
- Capture before-state for the affected rows inside the script (`CREATE TABLE fix_20260610_backup AS SELECT ... WHERE <same predicate>`), so the fix is undoable.
- A genuinely single-row, single-column fix with the row inspected first may go through the console; say that's the judgment being made, and paste the statement and result afterward anyway.

**Red flags that you're about to violate this:**

- "It's faster to just fix it in the console while I'm looking at it..."
- "I'll adapt the query as I see what comes back..."
- "Writing a script for a two-statement fix is bureaucracy..."
- "I'm being careful, I don't need a rehearsal..."
- "I'll remember what I ran..."

### Rename Columns With Expand and Contract

NEVER rename a column or table in a single migration on a system with live traffic. During any rollout, old code and new schema overlap; a one-step rename guarantees one side crashes, and rollback crashes the other.

A rename is a breaking change to a shared interface, not a refactor. Do it as expand/contract:

1. **Expand:** add the new column (`ALTER TABLE orders ADD COLUMN customer_id bigint;`). Deploy code that writes both columns and still reads the old one. A trigger or ORM-level dual-write both work.
2. **Backfill:** copy old values to the new column in batches.
3. **Migrate reads:** deploy code that reads the new column (still writing both).
4. **Contract:** stop writing the old column, and only after that deploy is fully live, drop it in a final migration.

Additional rules:

- If asked to "just rename it," state the plan and the reason: "a one-step rename breaks running instances; doing this as expand/contract across N deploys."
- The same applies to renaming tables; if a one-step cutover is unavoidable, a view with the old name (`CREATE VIEW orders_v AS SELECT ...`) can bridge readers, but say it's a bridge.
- On a pre-production system with no live traffic and no other consumers, a direct rename is fine; confirm that's the situation before choosing it.
- Never pair a direct rename with "we'll deploy quickly so the window is small." The window always finds traffic.

**Red flags that you're about to violate this:**

- "It's just a rename, the find-and-replace covers everything..."
- "The migration and code deploy together..."
- "The window will only be a few seconds..."
- "Expand/contract is overkill for one column..."
- "Rollback is fine, I'd just rename it back..."

### Require a WHERE Clause on UPDATE and DELETE

NEVER execute an UPDATE or DELETE without a WHERE clause, and NEVER execute one without first verifying what the WHERE clause matches.

A missing or wrong predicate is invisible until after execution; SQL happily reports success on the statement that just rewrote every row.

- Before any UPDATE or DELETE, run the same predicate as a SELECT first:
  `SELECT count(*), min(id), max(id) FROM users WHERE email = 'bob@test.example';`
- State the expected row count before running the SELECT, then compare. "Expected 1, got 1" proceed; "expected 1, got 31,407" stop and report.
- If the intent genuinely is every row, write the predicate anyway (`WHERE true`) and say explicitly: "this intentionally affects all N rows," and get confirmation outside of local/test databases.
- Be suspicious of broad predicates: `LIKE '%...%'`, date comparisons, `!=` conditions, and predicates on nullable columns all routinely match far more than intended.
- Wrap risky DML in an explicit transaction so the row count can be inspected before COMMIT:
  `BEGIN; DELETE FROM sessions WHERE user_id = 42; -- check count, then COMMIT or ROLLBACK`
- This applies equally to DML generated through ORMs: `User.update_all(...)` and `queryset.update(...)` with no filter are the same bug in nicer clothes.

**Red flags that you're about to violate this:**

- "It's just a quick UPDATE..."
- "The WHERE clause is obviously right, no need to SELECT first..."
- "I'll add the condition after I check the syntax works..."
- "This table only has the rows we want to change anyway..."
- "Running the SELECT first doubles the work..."

### Respect ORM Flush and Autocommit Semantics

NEVER assume when an ORM writes to the database; verify the semantics of the ORM actually in use. Flush, commit, autoflush, and unit-of-work behavior differ between ORMs, and a correct pattern in one is a bug in another.

- Answer these explicitly (from the docs or the project's existing code) before writing persistence logic:
  - Does creating/modifying an object write immediately, on an explicit save, on flush, or on commit?
  - Does querying mid-session trigger an autoflush of staged changes?
  - Is there an implicit transaction per request/session, and who commits it?
- Known traps to check for, not assume:
  - SQLAlchemy: `session.add()` stages; queries autoflush staged changes; nothing is durable until `commit()`. A "dry run" that queries but skips commit still flushed.
  - Django: attribute changes persist only on `.save()`, which by default writes *all* fields (use `update_fields=` to scope); outside `transaction.atomic()`, autocommit makes each save immediately permanent.
  - Active Record: callbacks/hooks on save can write additional rows you didn't ask for.
- For dry-run modes, don't rely on "I just won't commit": disable autoflush or use an explicitly rolled-back transaction, and say which mechanism you used.
- When data must be durable, end with an explicit commit (or document which framework layer commits). "The session probably commits on close" is a guess, and sessions that roll back on close are common.
- If unsure, write a two-line test: change, then read back through a *separate* connection. The second connection tells the truth.

**Red flags that you're about to violate this:**

- "add() saves the object, same as save() does..."
- "Nothing hits the database until commit, so this is a safe dry run..."
- "The session will commit when the request ends, it always does..."
- "save() only writes the field I changed..."
- "This is how the ORM I usually see does it..."

### Run Migrations via the Deploy Pipeline

NEVER run migrations against production (or staging) from a local machine or session. Migrations are production changes; they go through the same pipeline as code: commit, review, merge, deploy.

- Local `migrate` commands are for local and disposable databases only. Before running any migrate command, state the target database; if it isn't local, stop.
- The deploy pipeline applies migrations in lockstep with the code that expects them. A hand-applied migration desyncs schema from code and can confuse the pipeline's own migration step when it runs later.
- Hand-running also bypasses what the pipeline provides: the reviewed version of the file (not your working tree), CI checks, ordering relative to other migrations, deploy-coordinated timing, and an audit trail. List lost on purpose, lost.
- "It's urgent" routes through the fast lane of the same road: a quick PR and an expedited deploy, or the team's documented break-glass procedure with a second person aware. Not silent psql from a laptop.
- If a migration has already been hand-applied (by you or someone else), say so explicitly and reconcile: ensure the applied content exactly matches the committed file and the migration ledger records it, before the next deploy runs.
- Genuine exceptions exist (the migration framework is what's broken; a coordinated maintenance window with the runbook open); they involve a human deciding that, not a default.

**Red flags that you're about to violate this:**

- "The migration is ready, I'll just apply it now and the PR can follow..."
- "Deploys take 30 minutes, running it locally takes 10 seconds..."
- "It's a tiny migration, the pipeline is overkill..."
- "Schema first, then the code deploy catches up, that's safe ordering anyway..."
- "I have the prod credentials right here..."

### Separate Schema and Data Migrations

NEVER bundle a bulk data change into the same migration as a schema change on a table of production size. DDL belongs in the deploy path; backfills don't. They have opposite requirements, and bundling gives you the worst of both.

- Structure the work as three independent steps:
  1. Schema migration: `ALTER TABLE users ADD COLUMN full_name text;` Fast, transactional, deploy-path.
  2. Backfill: a batched, resumable task run *outside* the deploy (background job, rake/management task, ops runbook step), committing per batch. Not blocking the release.
  3. Constraint migration (if needed): a later migration adds NOT NULL/validation once the backfill is verified complete.
- A migration should finish in seconds. If its runtime scales with the table's row count, it's carrying a backfill that wants to be a task.
- Small lookup tables are exempt; updating 50 rows of reference data inline is fine. Say the size when claiming the exemption.
- New code must tolerate the gap between steps 1 and 3: the column exists but is partially NULL. Write the reading code accordingly (coalesce, fallback to the old fields).
- Don't let frameworks blur this: `RunPython`/`execute` blocks inside schema migrations are where bundled backfills hide. The framework allowing it doesn't make the deploy path the right place for it.
- If the team's process genuinely requires data migrations as migration files, keep them in *separate* files from DDL, batched and idempotent, and flag the runtime expectation in the PR.

**Red flags that you're about to violate this:**

- "The migration should fully set up the column, data included..."
- "It's one logical change, so one migration file..."
- "The UPDATE will be quick enough during the deploy..."
- "Splitting it means the column is briefly half-empty..."
- "The framework lets me put Python in the migration, so it belongs there..."

### Set Lock Timeouts for DDL

ALWAYS set a lock timeout before running DDL against a table with live traffic. A waiting ALTER blockades the table: every query issued after it queues behind it, so one long-running query plus your "instant" migration equals an outage that lasts as long as that query.

- Postgres, at the top of any migration touching a busy table:
  `SET lock_timeout = '5s';`
  The ALTER now fails fast if it can't get the lock, instead of freezing the table while it waits. Pair with `SET statement_timeout` for the DDL's own runtime where appropriate.
- Failing fast requires a retry plan: re-run the migration (manually or with backoff). A migration that occasionally needs a second attempt is healthy; one that can blockade prod is not. Many teams wrap this pattern in helpers or use libraries that do timed-retry DDL; use what the project has.
- MySQL: set `lock_wait_timeout` for the session; the same queueing dynamic applies to metadata locks (a forgotten open transaction can hold an MDL that blocks the ALTER, and the ALTER blocks the world).
- Before heavy DDL, check for long-running queries/transactions on the target table (`pg_stat_activity`) and say what you found; deploying DDL into a known 30-minute query is a choice, not luck.
- This complements, not replaces, choosing non-locking forms (`CREATE INDEX CONCURRENTLY`, metadata-only ALTERs). The timeout protects the acquisition; the right DDL form protects the hold.
- Local and CI databases have no contention, so this failure is invisible everywhere except production. Don't conclude safety from quiet environments.

**Red flags that you're about to violate this:**

- "This ALTER is metadata-only, it takes a millisecond..."
- "Lock timeouts are an ops concern, not a migration concern..."
- "If something's holding a lock, the ALTER will just wait politely..."
- "It applied instantly in staging..."
- "Adding retry logic for a one-line migration is over-engineering..."

### Tests Get Their Own Database

NEVER point a test suite at a development, staging, shared, or production database. Test isolation mechanisms truncate tables and reset schemas by design; whatever database the tests see, they will eventually wipe.

- Tests connect to a dedicated, disposable database: `app_test` locally, an ephemeral container in CI (testcontainers, a service in the pipeline), or an in-memory/throwaway instance. Creating it is part of the test setup, not a reason to borrow a real one.
- Never wire a fallback from test config to real config: `TEST_DATABASE_URL || DATABASE_URL` means "wipe dev when the test var is unset." A missing test database URL should fail the suite with a clear message, not borrow a connection.
- Never "borrow" staging for realistic data. If tests need realistic data, generate it with factories/fixtures into the test database, or load an anonymized snapshot into a disposable instance.
- Add a guard where the framework supports it: refuse to run destructive setup if the database name doesn't look like a test database, e.g. fail unless the name ends in `_test`. (Rails does a version of this natively; replicate the idea elsewhere.)
- When fixing a "tests can't connect" error, the fix is to provision the test database, not to point the suite at one that already exists.
- Parallel test runners multiply the requirement: each worker needs its own database or schema, never shared state.

**Red flags that you're about to violate this:**

- "The dev database is already set up, the tests can use it..."
- "Staging has realistic data, perfect for the integration tests..."
- "I'll fall back to DATABASE_URL so the suite works everywhere..."
- "The tests clean up after themselves, so sharing is fine..."
- "It's just temporary until the test container is configured..."

### Use Replicas for Prod SQL Diagnostics

NEVER run ad-hoc diagnostic queries against the production primary with a read-write account. "I'm only going to read" is an intention, not a control; enforce it with the connection itself.

- Prefer, in order: a read replica, the primary with a read-only role, and only then the primary with write credentials, with the human explicitly accepting that and every statement reviewed before running.
- Ask what's available before defaulting: "Is there a replica or read-only user I should use for prod queries?" Most setups have one; the env file just doesn't mention it.
- If forced onto a writable connection, open with a session guard where the engine supports it: `SET default_transaction_read_only = on;` (Postgres) or `SET SESSION TRANSACTION READ ONLY;` so a slip can't write.
- Reads are not free. Exploratory queries are unindexed by nature; bound them: `LIMIT` everything, use `EXPLAIN` before running anything that might scan a big table, and set a `statement_timeout` (e.g. `SET statement_timeout = '5s';`) so a runaway query kills itself instead of the database.
- Don't iterate on prod. Find the rows, copy the relevant slice somewhere safe (local, a scratch schema), and continue the investigation there.
- Record what you ran. Paste the exact queries into the conversation, ticket, or incident doc; ad-hoc plus unrecorded is how the same question gets asked of prod five times.

**Red flags that you're about to violate this:**

- "It's just a SELECT, it can't break anything..."
- "The app's credentials are right here, easiest to use those..."
- "One quick query on the primary won't be noticed..."
- "I don't need a timeout for something this simple..."
- "I'll remember what I ran if anyone asks..."

### Verify SQL Affected Row Counts

ALWAYS state the expected number of affected rows before running an UPDATE, DELETE, or INSERT...SELECT, and ALWAYS compare the actual count against it afterward. "No error" means the syntax was valid; the row count is the only output that says whether the statement did what was intended.

- Before executing, write the expectation: "this should affect exactly 1 row" or "roughly 200, the orders from yesterday's incident window." Exact when possible, bounded when not.
- After executing, compare and report: "expected 1, got 1." On mismatch, stop and investigate before any further statements; do not proceed on top of a wrong-scale change.
- Treat both directions as failures:
  - More than expected: the predicate is broader than intended. If inside an open transaction, ROLLBACK; if not, start incident handling (what changed, can it be restored), not the next task.
  - Zero when expecting nonzero: the fix didn't happen. Find out why (wrong key? already changed? wrong database?) instead of reporting success.
- In scripts, make the check executable: capture `cursor.rowcount` / `result.rowcount` / `ROW_COUNT()` and fail loudly on mismatch:
  `if cur.rowcount != 1: raise RuntimeError(f'expected 1 row, got {cur.rowcount}'); conn.rollback()`
- For risky DML, run inside an explicit transaction so the count arrives while ROLLBACK is still an option, the cheapest undo that exists.
- Batched operations get per-batch expectations (the batch size, until the final partial batch) and a running total compared to the upfront count.

**Red flags that you're about to violate this:**

- "The statement executed without errors, done..."
- "48,000 rows... the table is big, that's probably normal..."
- "Zero rows affected, must have already been fixed..."
- "I don't have a precise expectation, I'll just run it and see..."
- "Checking row counts on every statement is excessive..."

### Wrap Multi-Step Data Fixes in Transactions

ALWAYS wrap related write statements in a single explicit transaction when they must succeed or fail as a unit. With autocommit on, each statement commits immediately, and a failure midway leaves a half-applied state no code path expects.

- The test: if statement 2 failed, would the database be in an acceptable state with only statement 1 applied? If not, they belong in one transaction:
  `BEGIN; INSERT INTO archived_orders SELECT * FROM orders WHERE ...; DELETE FROM orders WHERE ...; COMMIT;`
- Classic shapes that need this: move rows between tables (insert+delete), renumber or re-parent rows (update+update), replace a dataset (delete+insert), anything touching two tables that reference each other.
- In application scripts, use the explicit transaction API (`conn.transaction()`, `with session.begin():`, `DB.transaction do`), not a comment saying the steps are related.
- Add verification inside the transaction before committing: check affected row counts, and `ROLLBACK` if they're not what was predicted. A transaction you can still abort is the cheapest undo you will ever get.
- Know the boundary of this rule: huge bulk operations should be batched in many small transactions instead (one giant transaction is its own failure mode). The unit of atomicity is the logical fix, not the whole dataset.
- DDL caveat: some engines (MySQL) auto-commit on DDL statements, so mixing DDL into your transactional fix silently breaks atomicity. Keep schema changes and data fixes in separate units.

**Red flags that you're about to violate this:**

- "These statements run right after each other, nothing happens in between..."
- "Each statement is simple, what could fail..."
- "I'll run them one at a time so I can watch each succeed..."
- "Autocommit is the default, so it must be fine..."
- "Transactions are for application code, this is just a script..."
