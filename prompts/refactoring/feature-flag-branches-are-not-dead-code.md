---
title: Feature-Flag Branches Are Not Dead Code
slug: feature-flag-branches-are-not-dead-code
category: refactoring
tags: [universal, refactoring]
works_with: all
severity: critical
one_liner: "Stops removal of flag-gated branches and kill switches as unreachable code"
---

# Feature-Flag Branches Are Not Dead Code

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from deleting feature-flag branches, kill switches, and config-gated paths because static reading makes them look unreachable.

**[Copy-paste ready version](../../install/feature-flag-branches-are-not-dead-code.md)** — just the instruction block, no explanation.

## The Problem

To a static reader, a feature-flag branch looks like the easiest cleanup in the world. `if flags.use_new_matcher:` where the flag defaults to false, an `else` branch nobody seems to hit, a `LEGACY_MODE` environment check that's never set in any file the model can see: all of it pattern-matches to dead code, and dead code is what refactors exist to remove. So the assistant removes it, the diff gets a satisfying red tint, and the system loses something that wasn't dead at all, merely *sleeping*: the kill switch for the next incident, the branch that's enabled for 5% of traffic via a remote config service, the legacy path that one enterprise customer's contract keeps alive.

The model can't see runtime. Flag values live in databases, remote config services, environment-specific deploy files, and ops runbooks, none of which are in context. "This branch is unreachable" is a claim about production state being made by something that has never seen production state. The especially nasty variant is the kill switch: a branch whose entire purpose is to be unused until the day it saves you, which means usage data will *always* say it's dead.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Feature-Flag Branches Are Not Dead Code

NEVER remove a branch gated by a feature flag, environment variable, config value, or runtime setting on the grounds that it appears unused or the gate appears permanently set. Static reading cannot determine runtime reachability; flag values live in systems outside the repo.

- Treat every gate as live: feature-flag checks, `os.environ` reads, config lookups, license/plan tier checks, per-tenant toggles, A/B test branches, and anything named like a kill switch, fallback, or legacy mode.
- "The flag defaults to false" proves nothing; defaults are what remote config and per-environment overrides exist to override. "No code sets this variable" proves nothing; deploy tooling, dashboards, and runbooks set it from outside the repo.
- Kill switches and emergency fallbacks are *designed* to look dead. Their unuse is their readiness. They are the last code in the file you should touch.
- When refactoring code containing flag branches, preserve both sides of every gate through the restructure: same condition, both behaviors intact. Restructure around the flag, not through it.
- Removing a flag and its losing branch (flag retirement) is legitimate, deliberate work, but it is its own task: it requires confirming the flag's state in every environment and with its owner. If you believe a flag is retirable, say so and ask; never retire it as a side effect of cleanup.
- The same applies to the *winning* branch's hardcoding: collapsing `if flag: A else: B` into just `A` is flag retirement too, even though it deletes the "dead" side.

**Red flags that you're about to violate this:**

- "This flag is false everywhere I can see, so the branch is dead."
- "This legacy path can't still be in use."
- "Nothing in the codebase ever enables this, so it's safe to remove."
- "Removing this old A/B branch simplifies the function a lot."
- "The else branch is clearly the abandoned experiment."

---

## Why It Works

1. **It corrects the evidence model.** The assistant's deadness proofs ("defaults to false," "nothing sets it") are genuinely the best evidence available in-repo, and genuinely worthless; explaining *why* they're worthless (values live outside the repo) defeats them better than prohibition alone.
2. **It reframes unuse as readiness for kill switches.** The model's strongest deletion signal, "never executed," is inverted for exactly this class of code; naming the inversion protects the branches whose whole job is to look dead.
3. **It closes both deletion directions.** Models also "simplify" by hardcoding the currently-winning branch, which feels like keeping the live code; defining that as flag retirement too prevents the loophole.
4. **The retirement path keeps cleanup legitimate.** Stale flags are real debt; routing their removal through ownership confirmation converts a silent risk into ordinary, schedulable work.

## Origin

A simplification pass removed an `if config.use_fallback_provider:` branch from a payment-routing module; the flag was false in every config file in the repo, and the branch hadn't run in months. It was the failover path for the primary payment provider, flipped via remote config during provider outages. The next outage arrived on a Friday evening, ops flipped the flag, and nothing happened, because the code the flag controlled no longer existed. Payments were down for the duration of an emergency revert and deploy.
