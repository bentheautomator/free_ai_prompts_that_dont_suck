---
title: Decide What Empty Env Vars Mean
slug: decide-what-empty-env-vars-mean
category: configuration
tags: [universal, config, env-vars]
works_with: all
severity: medium
one_liner: "Stops FOO= (set but empty) from slipping past is-it-set checks as a real value"
---

# Decide What Empty Env Vars Mean

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents config code that conflates "set to empty string" with "set to a value" — or handles unset and empty inconsistently across keys.

**[Copy-paste ready version](../../install/decide-what-empty-env-vars-mean.md)** — just the instruction block, no explanation.

## The Problem

Env vars have three states, not two: unset, empty, and set-to-a-value. Tooling manufactures the middle state constantly — a compose file with `PROXY_URL:` and no value, a CI secret that doesn't exist interpolating to `""`, a Helm template whose missing value renders as an empty string, a `.env` line someone blanked instead of deleting. The variable is *set*, and its value is nothing.

Code rarely agrees with itself about that state. `if "PROXY_URL" in os.environ:` says configured, then passes `""` to the HTTP client. JavaScript's `process.env.PROXY_URL || defaultUrl` treats empty as unset; `process.env.PROXY_URL ?? defaultUrl` treats it as a real value — and AI assistants pick between `||` and `??` by stylistic habit, not by deciding what empty should mean for that key. The result is a system where `FOO=` falls back to the default for one key, crashes a URL parser for the second, and silently disables a feature for the third.

These bugs are bewildering in direct proportion to how innocent the trigger looks: a YAML line with nothing after the colon. The variable shows up in `env | grep`, every "is it set" check passes, and the value doing the damage is invisible by definition.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Decide What Empty Env Vars Mean

Every env var read must deliberately handle three states — unset, empty, set — and the project must handle them ONE way. NEVER let the choice between `||` and `??`, or between `in os.environ` and `os.environ.get(...)`, silently make that decision per call site.

`FOO=` is set and empty. Compose files, CI interpolation, and templating produce that state routinely; code that only imagines two states hands `""` to something that needed a URL.

- Default policy, unless a key documents otherwise: empty means unset. Strip whitespace; if nothing remains, behave exactly as if the variable were absent (apply the default, or fail if required). This matches how empties are produced — by accident.
- Required-var validation must reject empty, not just absent. `if not os.environ.get("DATABASE_URL"):` is correct; `if "DATABASE_URL" not in os.environ:` waves `DATABASE_URL=` straight through to the connection code.
- If a key gives empty a real meaning ("empty CORS_ORIGINS = allow none"), that's an exception: document it at the key's declaration, and prefer an explicit sentinel (`CORS_ORIGINS=none`) over load-bearing emptiness.
- Implement the policy once, in the config layer's read helper — not re-decided by each call site's choice of `||` vs `??`. In JS specifically, treat a bare `??` on `process.env` as a flag: it asserts that empty string is a meaningful value. Is it?
- Extend the same three-state thinking to file-based config: a key present with `null`/`""` versus a key absent. Loaders that collapse those differently than your env handling create the same bug one format over.

**Red flags that you're about to violate this:**
- "I checked that the variable is set, so it has a value."
- "Nobody sets a variable to empty on purpose." (Correct — that's why it happens by accident.)
- "`??` and `||` do basically the same thing here."
- "The empty string will just fail validation downstream anyway."
- "Compose always passes our variables through, the value will be there."

---

## Why It Works

1. **It adds the missing third state to the AI's model.** The bugs come from two-state reasoning (set/unset) applied to a three-state reality; once empty-but-set is named, `in os.environ` checks become visibly insufficient.
2. **"Empty means unset" matches the production process of empties** — interpolation of missing values, blanked lines, valueless YAML keys are all accidents, so treating their output as absence repairs the accident instead of propagating it.
3. **Centralizing the policy disarms the `||`/`??` lottery:** one helper encodes the decision once, instead of each call site's operator choice silently voting differently.
4. **Requiring sentinels for meaningful emptiness keeps the rare legitimate case** out of the accident-shaped channel, so the default policy can stay strict.

## Origin

A worker's compose file listed `SENTRY_DSN:` with no value — pass-through syntax for a host variable that didn't exist on the new machines. The SDK's init saw a non-null DSN, accepted the empty string, and disabled itself with a debug-level note nobody read. Error reporting was silently off for that fleet for a month, discovered only when a user-reported crash had no corresponding event and an engineer went looking. The variable was set the entire time; every checklist that asked "is SENTRY_DSN configured?" got a technically-true yes.
