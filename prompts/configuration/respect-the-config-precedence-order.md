---
title: Respect the Config Precedence Order
slug: respect-the-config-precedence-order
category: configuration
tags: [universal, config, layering]
works_with: all
severity: high
one_liner: "Stops new config code from guessing whether env beats file beats default"
---

# Respect the Config Precedence Order

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from assuming or improvising the precedence between env vars, config files, CLI flags, and defaults instead of following the project's actual resolution order.

**[Copy-paste ready version](../../install/respect-the-config-precedence-order.md)** — just the instruction block, no explanation.

## The Problem

Layered config has a contract: somewhere, the project decided that CLI flags beat env vars beat config files beat defaults (or some other order — that's the point, it's *a* decision). Then the AI adds a new setting and writes `config.file_value || process.env.NEW_KEY || default` — file beats env, the reverse of the project's order, invented on the spot because it read naturally left to right. Now forty-nine settings resolve one way and the fiftieth resolves backwards. The operator sets the env var, exactly as they would for any other key, and nothing changes. The config file's stale value wins silently.

Precedence bugs are uniquely hostile to debugging because every layer *individually* looks right. The env var is set correctly. The file value is what it should be. The bug exists only in the resolution order, which no single file shows and which differs for exactly one key. Operators don't suspect per-key precedence variation because no sane system has it — until an AI, writing one ad-hoc resolution at a time, builds one.

The companion failure: reading raw sources directly (`os.environ` deep in business logic) and thereby bypassing the resolution machinery entirely, so overrides that work everywhere else don't apply to this one read.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Respect the Config Precedence Order

NEVER improvise the precedence between config sources. The project has (or must get) ONE resolution order — typically CLI flag > env var > config file > default — and every key resolves through it identically.

A single key with reversed precedence creates an override that silently doesn't apply. Every layer looks correct in isolation; only the order is wrong, and nothing displays the order.

- Before adding any config read, find how existing keys resolve — the settings library, the config loader, the established `flag || env || file || default` chain — and route the new key through the same machinery. Not a lookalike chain you wrote at the call site: the same machinery.
- Never read `os.environ` / `process.env` directly from business logic when a config layer exists. Direct reads bypass file values, test overrides, and the precedence order all at once.
- If the project has no defined precedence (config is read ad hoc all over), don't add to the ad hoc pile — flag it, and at minimum make your addition's order match the most common existing pattern, stating which order you matched.
- Empty-vs-unset matters in layering: decide (and match the project's convention on) whether an empty env var overrides a file value or is treated as absent. Don't let `??` vs `||` make that decision for you.
- When debugging "I changed the config and nothing happened," check resolution order before anything else — and when you fix one of these, fix the order, don't just move the value to the winning layer.

**Red flags that you're about to violate this:**
- "I'll check the env var first since that's most specific." (Is that this project's order?)
- "Reading process.env directly here is simpler than threading config through."
- "It doesn't matter which wins, both sources will have the same value."
- "I'll write the fallback chain inline, it's only three sources."
- "The override isn't working, so I'll just edit the other file too."

---

## Why It Works

1. **It routes new keys through existing machinery instead of asking the AI to replicate the order,** removing the transcription step where reversals happen. Calling the loader can't get the precedence wrong; rewriting it can.
2. **It bans the bypass as well as the reversal** — direct env reads are precedence bugs in disguise (a one-layer order applied to a multi-layer system), and they're the variant the AI produces most.
3. **The empty-vs-unset clause targets the subtle reversal:** `||` and `??` encode different layering semantics, and the AI chooses between them by habit, not by consulting the project's convention.
4. **The debugging rule prevents entrenchment.** "Edit whichever layer wins" makes the symptom vanish and the inconsistency permanent; fixing the order makes both vanish.

## Origin

A service's deploy tooling set `DATABASE_POOL_SIZE` per environment via env var, the mechanism used for every other tunable. One key — added in a different year by a different hand — resolved file-over-env, opposite to the rest of the system. During a capacity push, ops raised the env var fleet-wide and watched connection counts not move. Three engineers verified the env var was set in the running containers (it was), suspected the orchestrator, the image, and a caching bug in that order, and found the inverted two-line fallback chain only by reading the config code line by line at hour four.
