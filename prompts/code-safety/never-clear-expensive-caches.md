---
title: Never Clear Expensive Caches to Fix Cheap Problems
slug: never-clear-expensive-caches
category: code-safety
tags: [universal, files, build]
works_with: all
severity: high
one_liner: "AI nuking caches that take hours to rebuild as a first debugging move"
---

# Never Clear Expensive Caches to Fix Cheap Problems

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from deleting hours of accumulated cache to fix a problem that wasn't cache-related.

**[Copy-paste ready version](../../install/never-clear-expensive-caches.md)** — just the instruction block, no explanation.

## The Problem

Something fails to build, and the AI's reflex is hygiene: clear the cache, reinstall, rebuild. Sometimes that's `rm -rf node_modules` (twenty minutes), sometimes it's the Bazel or Gradle cache (an hour of recompilation), sometimes it's a downloaded-models directory (forty gigabytes over hotel wifi), sometimes it's a compiler cache that took the whole team's CI a week to warm. The AI pays none of these costs. You pay all of them — and in most cases the cache wasn't the problem, so after the rebuild the original error is still there, now with an hour of overhead added to every iteration.

"Clear the cache" survives as advice because it occasionally works and never *looks* destructive — it's all regenerable, technically. But regenerable-at-what-cost is the actual question, and the AI never asks it. A cache is stored time. Deleting one is spending that time, and spending it on a hunch.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Clear Expensive Caches to Fix Cheap Problems

NEVER clear a cache as a debugging reflex. A cache is stored time — hours of compilation, gigabytes of downloads, a week of CI warming — and deleting it spends that time on a guess.

The core problem: "clear the cache and rebuild" feels safe because everything is technically regenerable. The regeneration cost is real, it lands on the user, and most of the time the cache wasn't the cause.

- Before clearing any cache, estimate the rebuild cost out loud: time, bandwidth, compute. If you can't estimate it, that alone is a reason to ask first.
- Establish that the cache is actually implicated before touching it: does the error mention cached paths, checksums, or stale artifacts? "I'm out of other ideas" does not implicate the cache.
- Prefer the narrowest invalidation available: one package, one key, one entry — `npm cache verify` over `npm cache clean --force`, removing a single dependency over deleting `node_modules`, invalidating one Gradle module over `rm -rf ~/.gradle/caches`.
- Treat downloaded-asset caches (model weights, datasets, container layers, SDK toolchains) as near-irreplaceable during work hours: huge, slow to refetch, sometimes behind rate limits or auth that has since changed.
- Always get confirmation before clearing anything that takes more than a minute or two to rebuild, with the cost stated: "This deletes the build cache; full rebuild is roughly 45 minutes. Proceed?"

**Red flags that you're about to violate this:**
- "Let's start with a clean slate and rebuild..."
- "It's just a cache, it'll regenerate itself..."
- "Clearing everything rules out staleness..."
- "I've tried two things already, time to nuke node_modules..."
- "The cache directory is huge anyway, deleting it is practically a favor..."

---

## Why It Works

1. **It reframes caches as stored time.** The AI categorizes caches as "derived data, value zero." Pricing them in rebuild-hours makes deletion register as spending, which triggers the cost-benefit reasoning the reflex skips.

2. **It demands evidence of causation.** Requiring the error to actually implicate the cache kills "clean slate" as a move of last resort — the situation where most pointless cache-clearing happens.

3. **It builds an escalation ladder.** Narrow invalidation first, full clear last, confirmation gated on rebuild cost — the destructive option stops being the first rung.

## Origin

Debugging a flaky test, an assistant decided the environment was "possibly corrupted" and deleted the project's Bazel cache and the local container image store. The flake was a timezone assumption in the test. The fix took one line; the rebuild and re-pull took the rest of the developer's afternoon, during which the assistant suggested clearing the Gradle cache too.
