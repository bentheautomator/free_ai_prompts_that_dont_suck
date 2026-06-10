---
title: Reject Unknown Config Keys
slug: reject-unknown-config-keys
category: configuration
tags: [universal, config, validation]
works_with: all
severity: high
one_liner: "Stops typo'd config keys from being silently ignored while defaults run"
---

# Reject Unknown Config Keys

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents config systems that silently ignore unrecognized keys, so a typo'd `max_conections: 100` does nothing while the default quietly runs.

**[Copy-paste ready version](../../install/reject-unknown-config-keys.md)** — just the instruction block, no explanation.

## The Problem

An operator sets `max_conections: 100` — one letter off. The config loader, built on `dict.get` with defaults, looks up `max_connections`, finds nothing, uses the default of 10, and says nothing about the orphaned key sitting right there in the file. The operator believes the system is configured for 100 connections. The system runs at 10. Both are certain, neither is checking, and the file *says* 100 — it's just a 100 that nothing reads. Misnested YAML produces the identical failure: the key is spelled perfectly, one indentation level too deep, and equally invisible.

This failure mode exists because lenient lookup is the default in every language: `get(key, default)` answers "what if my key is missing?" and nobody writes the converse check, "what if their key is unconsumed?" AI assistants compound it — they generate the lenient pattern reflexively, and when *writing* config they sometimes introduce the typo'd or misnested key themselves, with no loader pushback to catch either side.

A config system that ignores unknown keys also can't tell you a key was removed: set a key the app deprecated two versions ago and you get the same silence as a typo. Every misspelling, misnesting, and stale key produces identical symptoms — the value you set has no effect — and that symptom has no error message, no log line, and no stack trace. Just behavior that doesn't match the file.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Reject Unknown Config Keys

Config loading must reject or loudly warn on keys it doesn't recognize. NEVER build or extend config handling that silently ignores unknown keys — a typo'd key that does nothing while the default runs is the most expensive kind of nothing.

`get(key, default)` handles the missing key. Nothing handles the unconsumed key unless you build it.

- Use strict parsing where the stack offers it: pydantic with `extra="forbid"`, serde's `deny_unknown_fields`, JSON Schema with `additionalProperties: false`, yaml/struct decoders in strict mode. If the project's config library has a strict switch, turn it on for config (APIs are a different question; config files have exactly one writer-audience and deserve strictness).
- If strictness isn't available, add the converse check: after loading, diff the file's keys against the known-key set and fail or warn-with-key-name on leftovers. One function, reusable, worth writing.
- Apply the same rigor to env vars where feasible: a documented prefix (`APP_*`) makes "set but unrecognized" detectable; warn on `APP_*` vars nothing consumed.
- Unknown-key errors should name the key and suggest the nearest valid one ("unknown key `max_conections`; did you mean `max_connections`?"). The error exists for a human mid-typo; serve them.
- When you remove or rename a key (with its alias window), keep the old name in the known-set as an explicit "deprecated, use X" rejection rather than letting it age into anonymous silence.
- When you *write* config, the same discipline inverted: copy key names from the schema or existing usage, never retype them.

**Red flags that you're about to violate this:**
- "Extra keys are harmless, the loader just skips them."
- "Strict mode might break someone's existing config file." (That file has a key doing nothing — that's the breakage, already shipped.)
- "Typos are rare and code review will catch them."
- "I'll just use .get() with a default like the rest of the file does."
- "Warning on unknown keys is too noisy."

---

## Why It Works

1. **It gives a silent failure an error message.** Typo'd config has no symptom except absence-of-effect; strict loading converts it into a named, located, suggestible startup error — moving the cost from a production investigation to a ten-second fix.
2. **It catches whole classes beyond typos with one mechanism:** misnested YAML, keys removed in upgrades, and copy-paste from other services' configs all surface as unknown keys.
3. **The did-you-mean suggestion exploits the structure of the failure** — typos are near-misses by definition, so nearest-key matching almost always names the fix in the error itself.
4. **It addresses both directions:** strict loaders catch operator typos at runtime; copy-don't-retype prevents the AI from authoring the mismatch in the first place.

## Origin

A queue consumer was falling behind, so an SRE raised `prefetch_count` in its config from 50 to 500 — under the `consumer:` block, where it looked at home but where the loader expected it one level up. The loader ignored the misplaced key without comment and ran the default of 50. Over two on-call rotations, three more values were tuned in the same wrong block, each producing no effect, each deepening the team's conviction that the queue library itself was broken. The eventual fix enabled strict parsing; the very first boot listed all four orphaned keys, with line numbers, in one error message that would have saved roughly a month.
