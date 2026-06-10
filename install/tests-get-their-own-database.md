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
