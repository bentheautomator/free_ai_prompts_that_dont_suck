---
title: Single-Source Every Config Value
slug: single-source-every-config-value
category: configuration
tags: [universal, config, drift]
works_with: all
severity: high
one_liner: "Stops the same config value living in five files and drifting in four"
---

# Single-Source Every Config Value

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from copying a config value into yet another file instead of referencing the one place it's already defined.

**[Copy-paste ready version](../../install/single-source-every-config-value.md)** — just the instruction block, no explanation.

## The Problem

You ask the AI to wire up a new service, and it needs the API base URL. The URL already lives in `config/app.yml`. It also lives in `docker-compose.yml`, `jest.setup.js`, and a constant in `src/constants.ts`, because three previous changes each found it convenient to paste the string where it was needed. The AI, seeing this precedent, pastes it a fifth time. Now changing the URL means finding five files, and someone will find four.

AI assistants do this because pasting a literal is the lowest-friction way to make the immediate task compile. The duplication is invisible in the diff — a reviewer sees one plausible URL in one new file, not the four existing copies it just diverged from. Nothing fails until the day the value changes and one copy doesn't.

The bug that results is the worst kind: partial. Most of the system uses the new value, one code path uses the stale one, and the symptom shows up far from the config — a webhook that posts to a decommissioned host, a test suite that passes against the wrong environment, a retry that hammers an endpoint that moved.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Single-Source Every Config Value

NEVER introduce a second definition of a config value that already exists somewhere in the project. Every value gets exactly one authoritative definition; everything else references it.

Duplicated config doesn't fail when you write it — it fails months later when someone updates one copy and the others silently keep the old value.

- Before hardcoding any URL, port, timeout, bucket name, or identifier, search the repo for it. If it exists in a config file, env template, or constants module, reference that definition instead of pasting the literal.
- If a value must appear in multiple artifacts that can't share code (e.g., app config and `docker-compose.yml`), make one the source of truth, derive or inject the others (env interpolation, build-time templating), and if true derivation is impossible, add a comment at every copy pointing to the authoritative one.
- When you find existing duplication while working, don't add to it. Flag it, and consolidate if it's in scope.
- New constants belong in the project's existing config layer, not in a fresh `constants.ts` next to the code that wants them.
- "Same value, different name" counts: `API_URL`, `BASE_API_ENDPOINT`, and `serviceUrl` holding identical strings are duplication wearing disguises.

**Red flags that you're about to violate this:**
- "It's just one string, defining it here is simpler than importing config."
- "The other copies are in different formats, so sharing isn't practical."
- "This value never changes anyway."
- "The test file needs its own copy so tests stay self-contained."
- "I'll paste it now and consolidate in a follow-up."

---

## Why It Works

1. **It mandates a search before a paste.** The duplication happens because the AI doesn't know the value already exists; forcing a repo search converts unknown duplication into a visible decision.
2. **It handles the legitimate multi-file case** (compose files, CI matrices) with a derivation-or-annotation rule, so the AI can't use "these files can't import each other" as a blanket excuse.
3. **It names the aliasing trick.** Without the "same value, different name" clause, the AI satisfies the letter of the rule by inventing a new constant name for the same string.

## Origin

A payment provider's API hostname was defined in application config, a worker's config, and an inline string inside a webhook signature check. A migration to the provider's new domain updated the first two. Signature verification kept using the old hostname for header construction and began rejecting every webhook — quietly, with retries masking the failure for two days. The fix was a one-line change; finding it took a weekend, because everyone who grepped the main config saw the migration was "done."
