---
title: Don't Branch Defaults on Environment
slug: dont-branch-defaults-on-environment
category: configuration
tags: [universal, config, defaults]
works_with: all
severity: medium
one_liner: "Stops code that computes different default values depending on the environment"
---

# Don't Branch Defaults on Environment

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from writing defaults that compute differently per environment in code, so the same unset key silently means different things in dev and prod.

**[Copy-paste ready version](../../install/dont-branch-defaults-on-environment.md)** — just the instruction block, no explanation.

## The Problem

The AI wants caching on in production but off in development, so it writes the default as logic: `cache_enabled = env.CACHE_ENABLED ?? (APP_ENV === "production")`. Now the *absence* of a value means opposite things in different environments. The dev who tests with the key unset experiences one system; production, with the key equally unset, runs another. Nothing in any config file records either behavior — the effective value exists only as an expression in code, evaluated differently everywhere, visible nowhere.

This pattern is the AI's favorite compromise when dev convenience and prod correctness pull in different directions: rather than pick one default and override it somewhere visible, it encodes the disagreement into the fallback itself. It feels thoughtful. It's actually the worst of both worlds — the dev/prod difference exists (so environments diverge) *and* it's undocumented (so nobody can see the divergence by reading config). Debugging "works in dev, broken in prod" now requires noticing that an unset key defaults differently, which is about the last hypothesis anyone forms.

The honest version is boring: one static default, the same everywhere, and any environment that wants something else sets the key explicitly in its own config — where the difference is written down, diffable, and reviewable.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Branch Defaults on Environment

A default is ONE static value, identical in every environment. NEVER compute a default from the environment name, another config value, or runtime conditions — `default = (env == "production") ? X : Y` makes the unset key mean different things in different places, recorded nowhere.

If environments need different values, they set the key explicitly in their own config. The difference belongs in config files (visible, diffable), not in fallback logic (invisible, evaluated).

- Pick the default for safety, not convenience: the value you'd want a brand-new, unconfigured environment to get. Each environment that wants otherwise overrides it in writing.
- `?? (APP_ENV === "production" ? a : b)`, defaults derived from `NODE_ENV`, "smart" defaults that sniff other settings (`debug ? verbose : quiet`), and defaults that differ between the config class and a per-env subclass are all the same pattern. Replace each with one static default plus explicit per-environment entries.
- The static default should appear in the example/template file, so unset-key behavior is documented behavior.
- If you can't choose a single safe default because environments genuinely disagree and no value is safe everywhere, that's not a default — make the key required and let every environment state its value.
- Framework dual-personality defaults you can't remove (dev servers that auto-enable debug): pin the value explicitly in config anyway, so your environments don't depend on the framework's mood.

**Red flags that you're about to violate this:**
- "Defaulting based on the environment gives everyone the right behavior automatically."
- "Devs shouldn't have to set this key just to get sensible local behavior."
- "The conditional default means less per-environment config to maintain."
- "It's documented — the ternary is right there in the code."
- "Production will override it anyway, the smart default is just a safety net."

---

## Why It Works

1. **It moves the dev/prod difference from an evaluated expression to written data.** A line in `production.yml` can be read, diffed, and questioned in review; a ternary inside a fallback is invisible until someone reads the loader's source mid-incident.
2. **One static default makes unset-key behavior a fact instead of a function,** which is what allows the example file, the docs, and the operator's mental model to all be simultaneously correct.
3. **The required-key escape hatch resolves the genuine conflicts honestly:** when no single value is safe everywhere, forcing each environment to declare beats encoding the disagreement where nobody can see it.

## Origin

A job scheduler defaulted its concurrency: 1 outside production, CPU-count inside, via a conditional fallback added "so local runs don't melt laptops." A new performance-testing environment was stood up to certify a release; its env name wasn't "production," so the unset key quietly meant 1, and the certification run validated single-threaded behavior of a system that ships parallel. The release passed every test and immediately exhibited a concurrency bug in production — one the perf environment was built specifically to catch, and would have, if "unset" had meant the same thing twice.
