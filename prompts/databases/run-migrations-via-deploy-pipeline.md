---
title: Run Migrations via the Deploy Pipeline
slug: run-migrations-via-deploy-pipeline
category: databases
tags: [universal, databases, migrations]
works_with: all
severity: high
one_liner: "Running migrations against prod from a laptop instead of the pipeline"
---

# Run Migrations via the Deploy Pipeline

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents migrations from being applied to production from a local machine, ahead of review and out of sync with deploys.

**[Copy-paste ready version](../../install/run-migrations-via-deploy-pipeline.md)** — just the instruction block, no explanation.

## The Problem

The migration is written, the user is impatient, and the AI has a prod-capable connection string within reach. So it runs `rails db:migrate` (or `alembic upgrade head`, or `npx prisma migrate deploy`) pointed at production, from the laptop, right now. Several things just went wrong at once. The migration that ran is whatever's in the local working tree, not what was reviewed and merged, possibly including the uncommitted edit from ten minutes ago. Production's schema is now ahead of production's code, which the running application may or may not tolerate. The deploy pipeline, whose job was to apply migrations in lockstep with code, will either re-detect nothing to do or, in less idempotent setups, behave unpredictably. And if the migration misbehaves, recovery starts with reconstructing what exactly ran, from a machine whose state nobody else can see.

The AI does this because it's the natural completion of the task: migration written, migration applied, done. It models `migrate` as a build step, like compiling, rather than as a production change. Local-against-prod also skips every safeguard the team built, review, CI's schema checks, the pipeline's ordering guarantees, backup timing, and the audit trail of "what changed prod and when."

Local migrations are for local databases. Production migrations ride the same vehicle as production code.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It reclassifies `migrate` as a production change.** The AI runs it like a build step; naming it as a deploy-grade action attaches all the AI's existing don't-touch-prod-casually behavior to the command.

2. **It itemizes what hand-running skips.** "Bypasses safeguards" is abstract; the concrete list (reviewed version, CI, ordering, timing, audit) makes each skipped protection a visible loss the AI must accept knowingly.

3. **It gives urgency a legitimate route.** Most violations are urgency-shaped; an expedited-but-pipelined path means the rule never stands between the AI and a real emergency, which is what keeps rules followed.

4. **It covers the aftermath case.** The reconcile step turns an already-made mistake into a managed state instead of a buried one, which is when desyncs actually get fixed.

## Origin

To unblock a feature demo, an engineer had their assistant apply a new migration straight to production from a laptop; the PR containing it merged two days later with review feedback incorporated, meaning the file that eventually "deployed" differed from what prod had actually run, one index name and one default value apart. The drift surfaced a month later when a new environment built from migrations behaved differently from prod, and took a day of schema diffing to locate. The pipeline would have applied the reviewed version, once, with a record.
