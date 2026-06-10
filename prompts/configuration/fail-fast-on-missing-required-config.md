---
title: Fail Fast on Missing Required Config
slug: fail-fast-on-missing-required-config
category: configuration
tags: [universal, config, env-vars]
works_with: all
severity: critical
one_liner: "Stops silent fallback defaults from hiding missing required config until prod"
---

# Fail Fast on Missing Required Config

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from papering over a missing required config value with a quiet fallback default instead of crashing loudly at startup.

**[Copy-paste ready version](../../install/fail-fast-on-missing-required-config.md)** — just the instruction block, no explanation.

## The Problem

The AI needs `PAYMENT_API_URL` and writes `os.environ.get("PAYMENT_API_URL", "http://localhost:8080")`. On its machine, the fallback works — there's a mock running on 8080. The code passes review because a one-line `.get()` with a default looks defensive, even responsible. Then the deploy hits an environment where the var was never set, and instead of crashing, the service cheerfully sends payment requests to localhost. Nothing errors. The requests just vanish.

AI assistants do this constantly because the fallback makes the immediate task succeed: the code runs without anyone having to set anything. A `KeyError` at startup feels like a bug; a default feels like robustness. It's exactly backwards. A crash at boot is caught by the deploy pipeline in thirty seconds. A wrong default is caught by a customer in three weeks.

The worst variants are the plausible-looking defaults: a real-ish URL, an empty string that disables auth, a `region` that happens to be valid but wrong. Those don't even smell like placeholders when someone finally reads the code.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Fail Fast on Missing Required Config

NEVER give a required config value a fallback default. If the application cannot function correctly without a value, its absence must crash the process at startup with a message naming the missing key. A silent fallback converts a loud deploy failure into a quiet production bug.

- Required values — connection strings, API endpoints, credentials references, bucket names, anything pointing at an external system — get read with no default: `os.environ["PAYMENT_API_URL"]`, `mustGetenv("PAYMENT_API_URL")`, or an explicit check that raises with the key name in the error.
- Optional values may have defaults, but only values where the default is correct in *every* environment (e.g., `LOG_FORMAT=json`). "Correct on my machine" does not qualify.
- NEVER default a required value to localhost, `127.0.0.1`, an empty string, a test endpoint, or a sandbox URL. Those are the defaults that silently route production traffic to the wrong place.
- If you genuinely need a dev convenience, put it in `.env.example` or a dev compose file — in the environment, not in the code path every environment shares.
- When you find existing code defaulting a required value, flag it rather than imitating the pattern.
- Error messages must name the key: `Missing required config: PAYMENT_API_URL`. "Configuration error" sends on-call spelunking.

**Red flags that you're about to violate this:**
- "I'll add a default so it works out of the box."
- "Defaulting to localhost is fine, that's just for dev."
- "An empty string is a safe fallback here."
- "Crashing on a missing var feels fragile; better to degrade gracefully."
- "Everyone will obviously set this in production."
- "The other config reads in this file use `.get()` with defaults, so I'll match."

---

## Why It Works

1. **It inverts the AI's definition of "robust."** The instruction explicitly names the trade: a startup crash is visible in the deploy pipeline within seconds; a fallback default fails at the first real request, possibly weeks later, with no error pointing at config.
2. **It kills the localhost default specifically.** That's the single most common shape of this bug — and naming it as forbidden removes the AI's go-to move for "make it run anywhere."
3. **It gives the AI a legitimate outlet for dev convenience** (`.env.example`, compose files), so it doesn't have to choose between "annoying to run locally" and "dangerous in prod."
4. **Requiring the key name in the error message** turns the failure into a thirty-second fix instead of a debugging session.

## Origin

A reporting service read its database host with a fallback of `localhost`. The staging environment defined the var; a newly provisioned production region didn't. The service booted clean, connected to a stray local Postgres that an old sidecar container happened to expose, and wrote three days of customer report data into a database nobody knew existed. The data was recovered; the engineer's faith in `.get(key, default)` was not.
