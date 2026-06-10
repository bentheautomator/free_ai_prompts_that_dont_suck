---
title: Declare Defaults at the Config Layer
slug: declare-defaults-at-the-config-layer
category: configuration
tags: [universal, config, defaults]
works_with: all
severity: medium
one_liner: "Stops magic defaults from hiding deep in code where no one can audit them"
---

# Declare Defaults at the Config Layer

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from burying default values at call sites deep in business logic instead of declaring them once where all configuration is defined.

**[Copy-paste ready version](../../install/declare-defaults-at-the-config-layer.md)** — just the instruction block, no explanation.

## The Problem

Somewhere in the retry helper there's a `os.environ.get("HTTP_TIMEOUT", "10")`. Somewhere in the upload module, `config.get("max_file_size", 50 * 1024 * 1024)`. Somewhere in a constructor, `pool_size = pool_size or 5`. Each default was added at the moment of need, at the place of need, by an AI (or a human) who reasonably wanted the code to work when the value wasn't set. None of them appear in the config file, the example file, the docs, or anywhere else an operator would look to answer "what is this system's timeout?"

The answer to that question becomes "read the source, all of it." Worse, inline defaults multiply: a second call site reads the same key with a *different* fallback, and now the effective timeout depends on which code path you're on. Nobody decided that. It emerged.

AI assistants produce inline defaults because `get(key, fallback)` is the idiomatic one-liner and because the config module is outside the blast radius of the current task. The fix isn't to ban defaults — it's to give them exactly one home.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Declare Defaults at the Config Layer

ALWAYS declare default values in the project's config layer — the settings module, schema, or config file — never inline at the point of use. Application code reads config values; it does not invent fallbacks for them.

An inline default is a configuration decision hidden where no operator, reviewer, or future maintainer will look. Two inline defaults for the same key is a bug generator.

- `os.environ.get("X", "fallback")`, `config.get("x", 5)`, `process.env.X ?? "10"`, and `value || default` in business logic are all the same smell. Move the default to where the config is declared and have the call site read the resolved value.
- The config layer means: the settings class/schema (pydantic `Field(default=...)`, a `defaults.yml`, the central `config.ts`), where every key, its type, and its default are visible in one place.
- One key, one default. If a key is read in multiple places, none of them get their own fallback — they all see the value the config layer resolved.
- Defaults declared at the config layer must also appear in the example/template file, so the documented surface matches the real one.
- If you're adding a read for a new key, that's the moment to declare it properly: name, type, default, and a one-line description, in the config layer, in the same change.
- Magic numbers that are really tunables (batch sizes, intervals, limits) follow the same rule: promote them to declared config with a default, don't leave them as literals with aspirations.

**Red flags that you're about to violate this:**
- "The fallback is right here at the call site, which is self-documenting."
- "It's a sensible default, it doesn't need to be configurable-looking."
- "Touching the config module is out of scope for this fix."
- "Another file already reads this key with its own default; I'll match that pattern."
- "It's just `|| 10`, hardly configuration."

---

## Why It Works

1. **One home per default makes the config surface auditable.** "What does this system do when nothing is set?" becomes a question one file answers, instead of a grep expedition.
2. **It eliminates divergent fallbacks structurally.** When call sites can't define defaults, two code paths can't silently disagree about the same key.
3. **It catches defaults at the cheapest moment** — when the key is first introduced — rather than after five call sites have each grown their own opinion.

## Origin

An API client's timeout was read in four places: three used a 10-second inline default, one — added during an incident, long forgotten — used 60. A latency event caused requests through the fourth path to hold connections open six times longer than anyone believed possible, exhausting the pool. The team's dashboards, docs, and config files all said the timeout was 10 seconds. They were three-quarters right, which during an incident rounds down to wrong.
