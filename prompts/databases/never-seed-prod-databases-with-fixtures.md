---
title: Never Seed Production Databases With Fixtures
slug: never-seed-prod-databases-with-fixtures
category: databases
tags: [universal, databases, seeds]
works_with: all
severity: critical
one_liner: "Running seed or fixture scripts against production data"
---

# Never Seed Production Databases With Fixtures

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents seed and fixture loaders, many of which wipe before they write, from running against production.

**[Copy-paste ready version](../../install/never-seed-prod-databases-with-fixtures.md)** — just the instruction block, no explanation.

## The Problem

Seed commands look harmless because their name says "add." Many of them delete first. A typical seeds file opens with `Category.destroy_all` or `TRUNCATE products CASCADE` to guarantee a clean slate before inserting the fixtures. Run that against a development database and it's exactly right. Run it against production, because the deploy script calls `db:seed`, because someone's `DATABASE_URL` pointed the wrong way, or because the AI added seeding to a setup script "for completeness", and the clean slate is your product catalog.

AI assistants cause this in two ways. First, they wire seeding into places that execute everywhere: deploy pipelines, container entrypoints, `postinstall` hooks, a `make setup` that ops later runs on a prod box. Second, when asked to "set up the data," they run the seed command against whatever connection is ambient without classifying the environment first. Fixture loaders in test frameworks are even more aggressive, many truncate every table they touch by design.

Even when nothing is deleted, seeding prod plants fake records, `test@example.com` users, demo orders, placeholder products, into real data, where they pollute analytics, trigger real emails, and occasionally get shipped to real customers.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It breaks the "seed = additive" assumption.** The word "seed" smuggles in harmlessness; stating that seeds commonly wipe first makes the AI evaluate the script's contents instead of its name.

2. **It targets the wiring, not just the running.** Most prod-seeding incidents are indirect: the AI put the command somewhere that later executed in prod. Banning the wiring closes the path that doesn't look like a violation at the time.

3. **It installs a guard that outlives the session.** The in-file environment check protects against every future invoker, human or AI, not just the current conversation.

## Origin

An assistant improving a Dockerfile added the seed command to the container entrypoint so "the app starts with usable data." The image worked beautifully in dev. When the same image rolled to production, every container start re-ran the seeds, whose first line truncated and reloaded the plans table; customers were intermittently shown the three demo pricing plans from the fixtures. It took two days to connect the symptom to the entrypoint, because nobody thinks of a deploy as "running the seeds."
