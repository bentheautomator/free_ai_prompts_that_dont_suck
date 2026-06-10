---
title: Verify Env Vars Before Referencing Them
slug: verify-env-vars-before-referencing-them
category: context
tags: [universal, config, verification]
works_with: all
severity: high
one_liner: "AI reading process.env.DATABASE_URL in a project that calls it DB_CONN"
---

# Verify Env Vars Before Referencing Them

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from referencing environment variables by their conventional names instead of the names this project actually uses.

**[Copy-paste ready version](../../install/verify-env-vars-before-referencing-them.md)** — just the instruction block, no explanation.

## The Problem

Environment variable names feel standardized — `DATABASE_URL`, `API_KEY`, `NODE_ENV`, `REDIS_URL` — and the AI writes them from that feeling. But env vars are the least standardized layer in software. This project calls it `DB_CONN`. Or `POSTGRES_DSN`. Or `APP_DATABASE__CONNECTION` because the config library uses double-underscore nesting. The AI's `process.env.DATABASE_URL` reads `undefined`, and what happens next depends on the code: a crash if you're lucky, a silent fallback to a default connection string if you're not.

The silent path is the killer. Env access rarely validates: `os.environ.get("API_KEY", "")` happily proceeds with an empty key; a missing `REDIS_URL` falls back to localhost and the cache quietly serves nothing; an unread feature flag means the feature is just... off, everywhere, with no error. The AI also fails in the other direction — telling users to "set `NODE_ENV=production`" when the project's behavior is keyed off a custom `APP_ENV`, or documenting setup steps with variable names that exist in no `.env.example`.

Every project that uses env vars also documents them, implicitly: `.env.example`, the config module that reads them, docker-compose `environment:` blocks, CI variable lists. The real names are greppable in seconds.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Verify Env Vars Before Referencing Them

NEVER read, set, or instruct anyone to set an environment variable without confirming its exact name from this project's files. Env var names are not standardized — `DATABASE_URL` is a convention, not a law, and this project may call it anything.

A wrong env var name rarely errors: code falls back to defaults, proceeds with empty strings, and behaves like the variable was never set — because for the name you used, it wasn't.

**Before referencing any environment variable:**
- Find the real names where they're declared or consumed: `.env.example`/`.env.sample`, the config module (`config.ts`, `settings.py`, `env.go`), `docker-compose.yml` environment blocks, Dockerfile `ENV` lines, CI workflow variable sections, deployment manifests
- Grep for the consumption site (`process.env.`, `os.environ`, `os.Getenv`, `ENV[`) before adding a new read — match the existing access pattern and any validation layer (zod schemas, pydantic settings, dotenv-safe)
- When adding a new variable, register it everywhere the project tracks them: `.env.example`, the validation schema, the docs — not just the code that reads it
- When telling a user to set a variable, quote the name verbatim from the project's files, and never state the *value* of a secret or claim to know what's currently set in their environment
- Don't assume the convention of one ecosystem in another: `NODE_ENV`, `RAILS_ENV`, `APP_ENV`, and `ENVIRONMENT` are four different worlds

**Red flags that you're about to violate this:**
- "The database URL will be in DATABASE_URL..."
- "Just set API_KEY in your .env..."
- "Every Node app keys off NODE_ENV..."
- "I'll add a sensible env var name for this..." — without checking the existing naming scheme
- "The variable is probably already defined somewhere..."
- Writing an env var name that appears in none of the project files you've read this session

---

## Why It Works

1. **It demotes conventions to suggestions.** The AI experiences `DATABASE_URL` as a fact about the universe; stating that env naming is genuinely unstandardized reframes every name as a lookup, not a recall.

2. **It centers the silent-fallback failure.** Crashes get fixed; empty-string keys and localhost fallbacks ship. Naming the no-error path explains why this needs verification *before* running, not debugging after.

3. **It treats declaration sites as the index.** `.env.example`, config modules, and compose files form a complete, greppable registry — pointing at them turns "verify the name" into a concrete fifteen-second search.

4. **It closes the registration gap.** New variables that exist only in code are landmines for the next developer; requiring updates to example files and schemas makes the AI leave the registry as consistent as it found it.

## Origin

An AI wired a new payment webhook to read `STRIPE_SECRET` — a perfectly conventional name. The project's config schema validated `PAYMENTS_API_SECRET` and ignored unknown variables, while the webhook code's `?? ""` fallback meant signature verification ran against an empty secret and rejected everything. Five days of "intermittent webhook failures" later, someone noticed the failures weren't intermittent at all — retries from the payment provider had been creating the illusion of partial success while exactly zero webhooks verified.
