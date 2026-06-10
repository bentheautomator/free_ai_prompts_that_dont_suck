---
title: No Shared Mutable Config Objects
slug: no-shared-mutable-config-objects
category: architecture
tags: [universal, architecture, state]
works_with: all
severity: high
one_liner: "One config dict passed everywhere and mutated as a side-channel"
---

# No Shared Mutable Config Objects

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from passing one mutable config/context object through the whole system and letting components communicate by writing keys into it.

**[Copy-paste ready version](../../install/no-shared-mutable-config-objects.md)** — just the instruction block, no explanation.

## The Problem

There's a `config` dict (or `Settings` object, or `ctx`) that gets passed to everything. The AI needs to get a value from step 2 to step 5 of a pipeline, and the config object travels through all five steps already. So step 2 does `config["resolved_region"] = region`, step 5 reads it back, and no signature changed. The diff is two lines. What actually happened: the config object stopped being configuration and became a shared mutable blackboard, and the system grew an invisible data channel with no schema, no types, and an ordering dependency nothing documents.

These objects rot in a characteristic way. Keys appear at runtime that exist in no class definition, so the type checker is blind, autocomplete lies, and reading the config class tells you a fraction of what's actually in the object in production. Components become order-sensitive — step 5 works only if step 2 ran — but the signature `run(config)` looks identical for every step, so nothing warns you when reordering breaks it. And because the same object instance is shared, a temporary tweak in one corner (`config["timeout"] = 1` in a retry path) leaks to every other holder of the reference, including concurrent requests in threaded servers.

AI assistants love this move because the channel is already plumbed everywhere. The honest alternative — changing a return type or adding a parameter — touches signatures; mutating the bag touches nothing visible.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Shared Mutable Config Objects

NEVER mutate a shared config, settings, or context object after startup, and NEVER use one as a channel to pass data between components. Configuration is read-only after load; data flows through parameters and return values.

A mutable config bag is an untyped global with delivery service: every write creates an invisible dependency between the writer and whoever reads the key, sequenced only by luck.

- Treat config as frozen at startup: load it, validate it, then make it immutable (frozen dataclass, `Object.freeze`, read-only properties). All keys exist in the schema/class definition — no runtime key invention
- If step 2 computes something step 5 needs, return it from step 2 and pass it to step 5 — yes, that changes signatures; the signature change IS the documentation of the data flow
- If a component needs a variant of the config (shorter timeout, different endpoint), derive a new immutable copy for that scope; never edit the shared instance in place
- Don't widen a god-context as the workaround: adding `ctx.results`, `ctx.scratch`, or a `extras` dict to the config type is the same bag with a type annotation
- Per-request or per-job state lives in a per-request object created and discarded with the request — never in anything shared across requests

**Red flags that you're about to violate this:**
- "The config already flows through every step, it's the easiest channel..."
- "I'll stash the intermediate result on the context and read it later..."
- "Changing the return types of three functions is too invasive..."
- "I'll set the flag temporarily and put it back after the call..."
- "It's config-adjacent, so the config object is the natural home..."
- "Everything else already reads and writes this object..."

---

## Why It Works

1. **It restores the type system's jurisdiction.** Frozen config with a fixed schema means the class definition and the runtime object agree again — every invented key was a lie the type checker couldn't catch.

2. **It makes data flow legible at the signature.** `step5(region)` declares its dependency on step 2's output; `step5(config)` hides it. The rule trades two minutes of plumbing for permanent reorderability.

3. **It eliminates spooky action at a distance.** Derived copies for scoped variants mean a timeout tweak in one path physically cannot affect another holder of the config — the concurrency bug class disappears structurally.

4. **It blocks the typed-bag regression.** The natural "fix" is giving the bag a class with an `extras` dict; naming it keeps the rule from being satisfied cosmetically.

## Origin

A data pipeline's stages communicated through keys written into the shared settings object — twenty-one runtime keys, zero in the schema. A routine reordering of two stages, reviewed and approved because both signatures were just `run(settings)`, shipped a pipeline where stage 6 read a key that no longer existed yet and fell back to a default region. Eleven days of records landed in the wrong region's storage before an auditor noticed. The postmortem's diagram of "actual data flow vs. apparent data flow" had to be drawn by grepping for bracket-assignments on the settings object.
