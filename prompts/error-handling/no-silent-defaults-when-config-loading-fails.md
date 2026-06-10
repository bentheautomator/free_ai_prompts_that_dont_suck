---
title: No Silent Defaults When Config Loading Fails
slug: no-silent-defaults-when-config-loading-fails
category: error-handling
tags: [universal, errors, fallbacks]
works_with: all
severity: critical
one_liner: "AI quietly substituting hardcoded defaults when config or env loading fails"
---

# No Silent Defaults When Config Loading Fails

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents an app from booting on hardcoded fallback config when the real config failed to load.

**[Copy-paste ready version](../../install/no-silent-defaults-when-config-loading-fails.md)** — just the instruction block, no explanation.

## The Problem

The config file is missing, the env var is unset, or the YAML has a typo — and instead of refusing to start, the app shrugs and runs on whatever the AI hardcoded as a fallback: `os.getenv("DB_HOST", "localhost")`, `config.get("timeout", 30)`, `catch { config = DEFAULT_CONFIG; }`. The process starts, health checks pass, and the service is now connected to localhost in production, or running with a feature flag set to whatever the assistant guessed was sensible.

Assistants produce this constantly because defaulted config *looks* like mature engineering — every getenv-with-fallback in their training data reinforces it. And in a dev sandbox it genuinely is convenient. The trap is that the same line ships to production, where "the config didn't load" is not an inconvenience to paper over but a deployment failure that must stop the rollout. A crash at boot gets caught by the deploy pipeline in thirty seconds. A silent default gets caught by a customer.

The worst variants are security-relevant: `SECRET_KEY = os.getenv("SECRET_KEY", "dev-secret")`, `verify_ssl = config.get("verify_ssl", False)`. Those aren't bugs waiting to happen; they're incidents pre-installed.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Silent Defaults When Config Loading Fails

NEVER substitute a hardcoded default when required configuration is missing or fails to parse. If config can't be loaded, the program must refuse to start and say exactly what's missing.

A silent default means the app runs with settings nobody chose, in an environment where nobody knows the real config was ignored.

- Required settings (database URLs, API keys, secrets, service endpoints, security flags) must hard-fail when absent: raise at startup with the setting name, e.g. `raise RuntimeError("DB_HOST is not set")` — never `os.getenv("DB_HOST", "localhost")`
- If a config file fails to parse, propagate the parse error; do not fall back to a `DEFAULT_CONFIG` object
- Never default a secret, credential, or security toggle, in any environment, ever — no `"dev-secret"`, no `verify=False` fallback
- Defaults are legitimate only for genuinely optional tuning values (page size, log format), and each one must be a documented decision: define it once in a central config schema with a comment, not inline at the call site
- Distinguish "missing" from "invalid": an unset optional value may take its documented default; a *malformed* value must error, because someone tried to set it and failed
- When asked to "make startup more robust," robustness means clearer failure messages, not fewer failures

**Red flags that you're about to violate this:**
- "I'll default to localhost so it works out of the box..."
- "If the config is missing we can fall back to sensible values..."
- "This keeps the app running even when the env isn't set up..."
- "A default secret is fine for development..."
- "getenv with a fallback is the standard pattern..."

---

## Why It Works

1. **It separates the two populations of settings.** The model treats all config uniformly, and defaults are fine for *some* of it. Forcing the required/optional split makes "should this default?" an explicit question instead of a reflex.

2. **It reframes the boot crash as the success case.** A startup failure caught by the deploy pipeline is the cheapest possible place to catch a config error; the instruction states that trade directly, countering the model's "crashing is bad" prior.

3. **It makes the missing/invalid distinction load-bearing.** "Someone set this and it didn't parse" is never a situation where a default is correct — naming it removes the largest gray area.

4. **It pre-empts the "out of the box" rationalization.** Developer convenience is the stated motive in nearly every instance of this pattern; calling it out by name makes the model recognize the moment.

## Origin

A team asked an assistant to clean up their service's startup code. It helpfully added fallbacks to every `os.environ[...]` access so the service "wouldn't crash on missing config" — including `REDIS_URL` defaulting to a localhost address. Weeks later, a Kubernetes secret was misnamed during a migration; every pod booted green and quietly pointed its rate-limiter state at a Redis that didn't exist, failing open. The rate limits were off for nine days, discovered only when an abuse spike got through unthrottled.
