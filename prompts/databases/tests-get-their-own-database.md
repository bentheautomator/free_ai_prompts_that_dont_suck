---
title: Tests Get Their Own Database
slug: tests-get-their-own-database
category: databases
tags: [universal, databases, testing]
works_with: all
severity: critical
one_liner: "Pointing tests at a dev or shared database that the suite then wipes"
---

# Tests Get Their Own Database

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents test suites from running against dev, staging, or shared databases, which they truncate by design.

**[Copy-paste ready version](../../install/tests-get-their-own-database.md)** — just the instruction block, no explanation.

## The Problem

Test suites are destructive on purpose. Between tests they truncate tables, roll back transactions, drop and recreate schemas, that's how isolation works. Which means the question "which database do the tests point at" is really the question "which database gets wiped every time someone runs the suite." The AI, trying to get a failing setup working, answers it badly: it sets `DATABASE_URL` to the only connection that works, the dev database with a week of carefully arranged local state, or worse, the shared staging instance the whole team and the QA process depend on. The tests pass. The data is gone. Nobody connects "I ran the tests" to "staging is empty" until the third time.

The AI lands here through small, reasonable-looking moves: copying the dev config to the test config to fix a connection error; "temporarily" pointing tests at staging because it has realistic data to test against; writing a conftest or test helper that falls back to `DATABASE_URL` when `TEST_DATABASE_URL` is unset. Each one wires the suite's truncation routines to a database that matters. The realistic-data temptation is the most seductive and the most destructive: the value of staging data is exactly what the suite's cleanup destroys.

The rule is structural, not behavioral: tests must be *unable* to reach a database anyone cares about, not merely expected not to.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It leads with the mechanism.** "Tests truncate by design" makes the danger intrinsic to the suite, so the AI evaluates the connection choice as "what gets wiped" rather than "what connects successfully."

2. **It outlaws the fallback specifically.** The `|| DATABASE_URL` pattern is the single most common path to this incident and looks like robustness; naming it converts it from defensive code to recognized hazard.

3. **It redirects the realistic-data desire.** The staging temptation is genuine, so the rule supplies the legitimate satisfactions (factories, anonymized snapshots into disposable instances) instead of just refusing.

4. **It pushes for a structural guard.** A name-check that refuses non-`_test` databases protects against every future misconfiguration, including ones made by humans, long after this session ends.

## Origin

To get integration tests passing in a new repo, an assistant set the test environment's database URL to the team's shared staging instance, which had the only schema with realistic data. The suite ran green, and its setup hook truncated all 40 tables first, as it was built to do. QA lost two days of carefully staged release-validation state, twice, because the first wipe was blamed on a bad deploy and the config survived to run again.
