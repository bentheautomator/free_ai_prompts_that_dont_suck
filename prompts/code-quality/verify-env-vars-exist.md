---
title: Verify Env Vars Exist
slug: verify-env-vars-exist
category: code-quality
tags: [universal, config]
works_with: all
severity: high
one_liner: "AI reading environment variables that nothing anywhere actually sets"
---

# Verify Env Vars Exist

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from writing code that depends on environment variables no environment actually defines.

**[Copy-paste ready version](../../install/verify-env-vars-exist.md)** — just the instruction block, no explanation.

## The Problem

`os.environ["API_TIMEOUT_SECONDS"]`. `process.env.ENABLE_CACHE`. The AI needs a knob, so it reads one from the environment — a variable with a perfectly sensible name that is set in exactly zero places: not in `.env`, not in `.env.example`, not in the compose file, the Helm values, the CI config, or the deployment platform. The model invented it the way it invents method names, except environment variables get no compiler, no import resolution, and no spell check. Nothing in any toolchain will ever flag a read of an unset variable as suspicious.

How this lands depends on the access pattern. The strict read (`environ["X"]`) crashes at startup in every environment — loud, at least, though now deploys are broken until someone hunts down where config gets set in this stack. The default read (`environ.get("X", "false")`, `process.env.X ?? 30`) is the quiet disaster: the code runs everywhere, the default silently wins everywhere, and the feature everyone believes is configurable is actually hardcoded with extra steps. The team flips the flag in their deployment config — spelled the way *they* think it's spelled — and nothing changes, because the code reads `ENABLE_CACHE` and they set `CACHE_ENABLED`. Both names are sensible. That's the problem.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Verify Env Vars Exist

NEVER read an environment variable you invented. Env var names are project facts, not vocabulary — before your code reads one, confirm the exact name is defined somewhere real or explicitly establish it as new.

No tool will ever catch a misspelled or imagined env var. A strict read crashes deploys; a defaulted read silently pins the default forever while everyone believes the knob works.

**Before reading any environment variable:**
- Search for the exact name in the places environments are actually defined: `.env*` files, `docker-compose.yml`, Dockerfiles, Helm charts/`values.yaml`, Kubernetes manifests, CI workflow files, Terraform, platform config (Procfile, app.yaml), and the project's settings/config module
- Prefer the project's config layer over raw env reads: if the codebase funnels environment access through a settings module (`config.py`, `settings.ts`, pydantic Settings, `convict`), add your value there, following its naming and validation patterns — don't scatter fresh `os.environ` calls
- Match the project's naming convention for any genuinely new variable (`SERVICE_` prefixes, casing, separators), and register it everywhere the project registers vars: `.env.example` at minimum, plus deployment configs as applicable
- A new variable is a deployment requirement, not a code detail — name it explicitly in your summary so the humans who own the environments know it exists
- Treat defaults honestly: a default that makes the feature silently off (`.get("ENABLE_X", "false")`) means the feature doesn't exist until someone sets the var — say so

**Red flags that you're about to violate this:**
- "This would typically be configured via an env var called..."
- "I'll read it from the environment with a sensible default..."
- "They probably have DATABASE_TIMEOUT set..."
- "The deployment surely defines this..."
- "I'll name it what it's usually named..."
- Typing `process.env.` or `os.environ` followed by a name you've never seen in this repo

---

## Why It Works

1. **It reclassifies env names from vocabulary to facts.** The model generates variable names from plausibility, the same engine that hallucinates methods. Stating that no tool will ever validate the name justifies manual verification in the one namespace with zero safety nets.

2. **It exposes the defaulted-read trap.** `.get()` with a default feels defensive and correct to the AI. Naming the consequence — a knob that silently never works — converts the "safe" pattern into the recognized-dangerous one.

3. **It routes through the config layer.** Centralized settings modules exist to make env access visible, validated, and typo-resistant. Directing new values there makes the codebase's own machinery enforce what the instruction asks.

4. **It promotes new vars to deployment events.** A var mentioned only in code is invisible to the people who own environments. Requiring registration plus a summary callout puts the new requirement in front of whoever must actually set it.

## Origin

A caching layer was added behind `os.environ.get("REDIS_CACHE_ENABLED", "false")` — a flag name the AI composed on the spot. The platform team's config, written months earlier, set `CACHE_ENABLED`. Both names sat in the repo looking official. The cache ran disabled in production for two months while dashboards tracked "cache-enabled" performance work, and the discrepancy was caught only when someone investigating costs noticed the Redis instance had served roughly zero traffic since launch.
