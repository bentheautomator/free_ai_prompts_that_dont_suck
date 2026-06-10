---
title: Invalidate Stale Intermediate Caches
slug: invalidate-stale-intermediate-caches
category: data-and-ml
tags: [universal, data]
works_with: all
severity: medium
one_liner: "A cache that ignores upstream changes serves yesterday's data forever"
---

# Invalidate Stale Intermediate Caches

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents cached intermediate datasets from silently outliving the code and inputs that produced them.

**[Copy-paste ready version](../../install/invalidate-stale-intermediate-caches.md)** — just the instruction block, no explanation.

## The Problem

Somewhere in the pipeline there's a slow step, so the assistant adds the obvious optimization: `if os.path.exists("features.parquet"): df = pd.read_parquet("features.parquet") else: <expensive computation>`. It's a genuine speedup and everyone is briefly happy. The check is existence, not validity — so when the raw data refreshes, the cleaning logic gets fixed, or the feature definition changes, the cache keeps answering with the artifact built before any of that happened. The pipeline runs fast and lies.

Stale caches generate a uniquely maddening class of bug: you fix the code, rerun, and the output doesn't change. You add the new column upstream and it never arrives downstream. Two teammates get different "current" results because their caches were built on different days. Eventually someone discovers that deleting a file fixes everything, which becomes tribal knowledge ("rm the parquet first") instead of a fixed pipeline. The cost isn't just wrong results — it's every debugging hour spent doubting correct code while a file from last month supplies the actual answer.

Assistants write existence-checked caches because the happy path is all they see: cache miss, compute, hit, fast. Staleness requires the world to change after the conversation ends, which is exactly the part they never observe.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Invalidate Stale Intermediate Caches

A cache check must verify validity, not existence. `if path.exists()` is not caching — it's permanently freezing the first run's output. ALWAYS tie cached artifacts to the identity of their inputs.

- Key caches on what they were built from: a hash or fingerprint of input data (file mtimes+sizes at minimum, content hash when feasible) plus the parameters and a version stamp of the producing code. Bake it into the filename (`features_a3f9c2.parquet`) or a sidecar manifest checked before any read.
- Bump the cache key when the producing logic changes: a `CACHE_VERSION = 3` constant included in the key turns "edit the function" into an automatic rebuild instead of a silent stale read.
- Make every cache bypassable: a `--no-cache`/`force_recompute=True` path that's easy to invoke. If the only invalidation procedure is "manually delete a file someone has to know about," the design has failed.
- Log cache decisions: "cache hit: features_a3f9c2.parquet (built 2026-06-02 from raw@d41e)" vs "cache miss: rebuilding." A stale result that announces its birthdate gets caught; a silent one gets trusted.
- Prefer tools that solve this properly when the pipeline justifies it — Make-style dependency tracking, dvc, snakemake, or framework caching keyed on code+data — over hand-rolled `os.path.exists` checks.
- When debugging "my change had no effect," check for caches first, not last. It's the cheapest hypothesis and embarrassingly often the right one.

**Red flags that you're about to violate this:**

- "I'll check if the file exists and skip the slow step..."
- "The raw data basically never changes..."
- "Whoever changes the logic can just delete the cache..."
- "Hashing inputs is overengineering for a notebook..."
- "The output looks the same as before... wait."
- "I'll add a TODO to handle invalidation later..."

---

## Why It Works

1. **Input-keyed caches make staleness structurally impossible.** When the key is derived from data + params + code version, any change produces a different key and therefore a miss; correctness no longer depends on a human remembering to delete anything.

2. **A code-version constant in the key captures the change hashes can't see.** Data fingerprints miss "we fixed the dedup bug"; bumping `CACHE_VERSION` in the same commit as the logic ties cache life to code life.

3. **Logged hits with build provenance convert invisible staleness into a readable symptom.** "Built 2026-06-02" in today's log is a red flag a human can actually notice, unlike a byte-identical silent read.

4. **The check-caches-first debugging rule attacks the real cost center** — not the wrong numbers, but the hours spent disbelieving correct code while a file answers from the past.

## Origin

A team shipped a fix for a deduplication bug in their feature builder and spent two days confused about why the downstream model's training data still contained duplicates. The feature step was fronted by an `os.path.exists` cache; every "verification rerun" read the same pre-fix parquet at full speed. The fix had been correct since the first hour. The postmortem's only action item was a cache key, and the file's hash has been in the run logs ever since.
