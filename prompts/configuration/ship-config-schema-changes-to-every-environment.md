---
title: Ship Config Schema Changes to Every Environment
slug: ship-config-schema-changes-to-every-environment
category: configuration
tags: [universal, config, environments]
works_with: all
severity: high
one_liner: "Stops config schema changes that update dev and forget staging and prod"
---

# Ship Config Schema Changes to Every Environment

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from changing what configuration the app expects while updating only the environment it can see — usually dev — and leaving the rest to find out at deploy time.

**[Copy-paste ready version](../../install/ship-config-schema-changes-to-every-environment.md)** — just the instruction block, no explanation.

## The Problem

The AI restructures config: `redis.url` becomes a `redis: {host, port, db}` block, or a new required `queue.name` key appears, or a list becomes a map. It dutifully updates `config/development.yml` — the file it's testing against — and the change works. What it doesn't update: `config/staging.yml`, `config/production.yml`, the Helm values for three environments, and the test fixtures. Each of those will discover the new schema independently, at its own deploy time, in ascending order of how much the discovery hurts.

This is a fan-out problem the AI structurally underestimates. In code, changing a function signature breaks all callers *at compile time, in one place*. Changing a config schema breaks all environment files at *load* time, one environment per deploy, days apart. Dev works, so the change merges. Staging breaks Thursday. Production breaks during the Friday release, when the deploying engineer has no idea the config schema changed because the PR that changed it was titled "refactor redis client."

The killer detail: an environment file that's *missing* a new key often doesn't crash — it falls back to a default tuned for dev, and production runs with it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Ship Config Schema Changes to Every Environment

When you change the shape of configuration — new required keys, renamed structures, changed types or nesting — update EVERY environment's config in the same change. NEVER update only the environment you're testing against.

A schema change updated in one environment isn't partially done; it's a scheduled breakage for each environment you skipped, detonating one deploy at a time.

- Before changing config structure, enumerate every file that holds an instance of it: `config/*.yml` per environment, env templates, Helm/terraform values, compose files, CI workflow env blocks, test fixtures, seed/sample configs. Grep for an existing key to find them all.
- Apply the structural change to every instance, using each environment's appropriate values. Don't copy dev's values into prod's file just to satisfy the shape — if you don't know prod's correct value, mark it explicitly and call it out, loudly, in the change description.
- If some environment configs live outside this repo (an infra repo, a config service), you can't fix them here — so list them in the change description as required follow-ups, and prefer a backward-compatible reading (accept old and new shape during transition) so their deploys don't break in the meantime.
- New required keys deserve startup validation, so an un-updated environment fails its deploy immediately instead of running on a fallback.
- Update the schema's documentation (example file, README, validation code) in the same change.

**Red flags that you're about to violate this:**
- "Dev config is updated and the app runs, so the migration works."
- "I'll let the staging deploy surface anything I missed."
- "Production config is someone else's file to maintain."
- "The new key has a default, so the other environments don't need it explicitly."
- "Test fixtures aren't real config, they can keep the old shape."

---

## Why It Works

1. **It forces enumeration before mutation.** The breakage comes from instances the AI never listed; requiring the list first makes the skipped environments visible while the change is still cheap.
2. **It bans value-faking.** Copying dev values into prod's file to satisfy the new shape converts a loud missing-key error into a quiet wrong-value bug — the rule keeps unknowns explicit instead.
3. **Backward-compatible reading decouples the code deploy from out-of-repo config updates,** turning a deploy-ordering hazard into an ordinary transition window.
4. **Startup validation gives skipped environments a failure mode you'd want:** immediate, named, at deploy — not a dev-tuned default silently running production.

## Origin

A connection-pool config was restructured from a single URL string into a structured block with explicit pool sizing. Development and staging files were updated; production's file, in a separate ops repo, wasn't. The code's fallback handled the old string format "for compatibility" — with default pool settings sized for a laptop. Production ran for five days on a pool of 5 connections instead of 120, throttling throughput in a way that was misdiagnosed as a database regression, two infrastructure changes, and finally — after someone diffed the environments — one missing config block.
