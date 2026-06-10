---
title: Parse Boolean Env Vars One Way
slug: parse-boolean-env-vars-one-way
category: configuration
tags: [universal, config, env-vars]
works_with: all
severity: high
one_liner: "Stops five competing definitions of true scattered across one codebase"
---

# Parse Boolean Env Vars One Way

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from adding yet another ad-hoc boolean parser, so that `FLAG=1` means true in one module and false in the next.

**[Copy-paste ready version](../../install/parse-boolean-env-vars-one-way.md)** — just the instruction block, no explanation.

## The Problem

Module A checks `env.FEATURE === "true"`. Module B checks `["1", "true", "yes"].includes(env.FEATURE)`. Module C checks `env.FEATURE !== "false"`. Module D, written last Tuesday by an AI assistant, checks `Boolean(env.FEATURE)`. Set `FEATURE=1` and it's false in A, true in B, true in C, true in D. Set `FEATURE=True` — Python's own repr of a boolean, which ends up in env vars constantly — and you get a different split. One variable, one value, four behaviors.

Each parser was locally reasonable. That's the trap: boolean parsing is so trivial that nobody checks how the codebase already does it. AI assistants, generating one call site at a time, write whichever idiom is most common in their training data for that language, which guarantees inconsistency across a project written over months.

The resulting bugs are gaslighting-grade. An operator flips a flag and half the system responds. The config is right, the code is right *line by line*, and the bug lives in the disagreement between lines — the place no one reads.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Parse Boolean Env Vars One Way

ALWAYS parse boolean config through the project's single shared helper. NEVER inline a fresh `=== "true"`, `!== "false"`, `in ("1", "yes")`, or truthiness check at a call site.

Multiple parsers means one env value can be true and false in the same process. That bug is invisible in any single file because every file is individually correct.

- Before parsing a boolean env var, find how the project already does it. If a helper exists (`parseBool`, `env_flag`, `strtobool` wrapper, the settings library's bool field), use it — even if you'd have written it differently.
- If no helper exists, create one and route the new code through it. One function, one definition of true: accept a small documented set case-insensitively (`true/false`, `1/0`), reject everything else loudly. `FLAG=ture` is an error, not a false.
- `!== "false"` deserves special hostility: it makes the *unset* variable true, so the flag defaults on and can never be safely introduced. Default values belong in the config layer, not encoded in comparison direction.
- When your change touches a file containing a divergent inline parser, flag it; migrate it if it's in scope.
- The helper, not each caller, decides the unset behavior: unset means "use the declared default," never "whatever this comparison happens to yield."

**Red flags that you're about to violate this:**
- "It's a one-line check, importing a helper is overkill."
- "This is how the file I'm editing already does it." (Is it how the *project* does it?)
- "Everyone sets booleans as 'true' or 'false', edge cases won't happen."
- "I'll use `!== 'false'` so it defaults to enabled."
- "Python's `bool()` on the string is close enough."

---

## Why It Works

1. **It converts a convention problem into a code-reuse problem.** AI assistants are bad at maintaining unwritten conventions across sessions but reliable at calling an existing function once told to look for it.
2. **A single parser makes flag behavior a property of the value, not the call site.** `FEATURE=1` means one thing everywhere, so operators can predict the system from the config alone.
3. **Strict rejection surfaces the inputs that lenient parsers silently misread** — `True`, `TRUE`, `yes`, trailing whitespace — at startup, with the key name attached, instead of as behavioral drift.
4. **Naming `!== "false"` specifically defuses the most damaging idiom,** the one that quietly couples a flag's default to its parsing.

## Origin

A rollout was halted by setting `ENABLE_NEW_PIPELINE=0` across the fleet. The ingestion service parsed booleans with an allowlist and read `0` as false; the downstream enrichment service used JavaScript truthiness on the raw string and read `"0"` as true. For nine hours the pipeline ran half-disabled — old ingestion feeding new enrichment — producing records in a hybrid format that took two weeks of backfills to repair. Both services' parsing code had been reviewed and approved. Separately.
