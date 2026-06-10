---
title: Keep Shared Config Keys Stable
slug: keep-shared-config-keys-stable
category: collaboration
tags: [universal, teamwork, contracts]
works_with: all
severity: high
one_liner: "Stops renaming env vars and config keys that other deployments still set"
---

# Keep Shared Config Keys Stable

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from renaming or restructuring environment variables and config keys that deployments, scripts, and other teams still set by the old name.

**[Copy-paste ready version](../../install/keep-shared-config-keys-stable.md)** — just the instruction block, no explanation.

## The Problem

Config keys live a double life. In the repo, `DATABASE_URL` or `payments.retry.max_attempts` is just an identifier, renameable like any other. Outside the repo, that exact string is set in places the AI will never see: Kubernetes manifests in another repository, a secrets manager, CI variable groups, a platform team's Terraform, six developers' `.env` files, a deploy runbook. When the AI renames the key — clearer name, consistent prefix, restructured config schema — it updates the code and `.env.example` and calls it done. Every environment that sets the old name is now setting a variable nothing reads.

What follows depends on defaults, and both branches are bad. No default: the service crashes on next deploy, which is at least loud. A default: the service silently runs with it — the production database URL is ignored in favor of localhost, retries drop to a default of zero, the feature flag endpoint falls back to off. Silent fallback to defaults is one of the sneakiest production failure modes there is, because the deploy "succeeds" and the misbehavior surfaces later, disguised as an application bug. And the blast radius is organizational: whoever owns each deployment environment has to discover, independently, that a name changed under them.

The AI does this because the rename is complete within everything it can observe. The settings of staging, production, CI, and teammates' machines are precisely the references grep cannot find.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep Shared Config Keys Stable

NEVER rename, restructure, or change the meaning of an existing environment variable or config key as a side effect of other work. The key's name is set in deployment environments, secret stores, CI, and teammates' machines — none of which are in this repo, and none of which grep can find.

A renamed key with a default fails silently: deploys succeed while the service ignores its real configuration.

- Existing key names are frozen by default. This includes casing, prefixes, nesting (`db.pool_size` to `database.pool.size`), and file format moves that change how keys are addressed.
- Changing a key's meaning or unit (timeout seconds to milliseconds, count to percentage) is worse than renaming — every environment now supplies a wrong-by-1000x value with the right name. Never do this in place; introduce a new key.
- New configuration: name it freely, follow the existing scheme, add it to `.env.example` and config docs with its default and meaning.
- If a rename is truly required, migrate: read the new key, fall back to the old one with a deprecation warning when used, and flag in your summary that every environment setting the old name must be updated — listing the likely places (deploy manifests, secret stores, CI, local `.env` files).
- Never silently add a default to a previously required variable; failing loud on missing config is often the safety feature.
- Treat keys in shared config templates, Helm values, and `.env.example` as the interface other people's environments are built against.

**Red flags that you're about to violate this:**
- "This env var name is unclear; renaming it is a quick win."
- "I updated .env.example, so the rename is handled."
- "I'll restructure the config file while adding my one option."
- "A sensible default makes the variable optional now."
- "Anyone deploying this will read the diff and update their env."

---

## Why It Works

1. **It defines the reference set correctly**: the consumers of a config key are environments, not code, so repo-complete renames are structurally incomplete — the rule encodes that grep's silence means nothing here.
2. **It ranks meaning changes above renames in danger**, because a wrong value under a right name defeats even careful operators, while a missing name at least can crash loudly.
3. **It provides the fallback-and-warn migration**, which keeps every existing environment working while creating pressure, in logs humans read, to move.
4. **It protects loud failure as a feature** — required-with-no-default is often deliberate operational design, and "make it optional" quietly removes a tripwire someone installed on purpose.

## Origin

An assistant standardizing config renamed `REDIS_URL` to `CACHE_REDIS_URL` for namespace consistency, updated all code references and the example env file, and shipped. The code had a localhost fallback for development convenience. Staging and production manifests, owned by the platform team in another repo, still set `REDIS_URL`. The next production deploy connected the service to a localhost Redis that didn't exist, caching silently degraded to no-ops, database load quadrupled, and the on-call engineer spent four hours hunting an application bug before anyone compared the variable names in the manifest against the ones the code now read.
