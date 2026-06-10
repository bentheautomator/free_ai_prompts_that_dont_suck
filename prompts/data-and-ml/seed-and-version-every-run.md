---
title: Seed and Version Every Run
slug: seed-and-version-every-run
category: data-and-ml
tags: [universal, ml, reproducibility]
works_with: all
severity: high
one_liner: "An unseeded run on unversioned data is a result you can never get back"
---

# Seed and Version Every Run

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents training runs that can never be reproduced because nothing pinned the randomness, the data, or the code that produced them.

**[Copy-paste ready version](../../install/seed-and-version-every-run.md)** — just the instruction block, no explanation.

## The Problem

The default training script an assistant writes calls `train_test_split(X, y)` with no `random_state`, initializes a model with no seed, and reads `data.csv` — whichever bytes happen to live at that name today. It runs, it prints 0.87, everyone moves on. Two weeks later someone asks whether the new feature helped, reruns the script, and gets 0.84. Is that the feature? A different random split? Different model initialization? The CSV someone re-exported on Tuesday? There is no way to know, because nothing about the original run was pinned. The 0.87 is not a measurement anymore; it's a memory.

This failure compounds. Every comparison between runs is contaminated by uncontrolled variance, so real regressions hide inside noise and noise gets celebrated as improvement. Debugging becomes impossible — you cannot bisect a problem you cannot reproduce.

Assistants skip seeding and versioning because neither changes the output of the first run, and the first run is all they're judged on. The cost lands entirely on run two, which happens after the conversation has ended.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Seed and Version Every Run

Every experiment must be re-runnable to the same result. ALWAYS pin the three things that vary: randomness, data, and configuration — before trusting or reporting any number.

- Set seeds explicitly everywhere randomness enters: `random_state=SEED` in every `train_test_split`, model constructor, and CV splitter; `np.random.seed(SEED)`; framework seeds (`torch.manual_seed`, `tf.random.set_seed`) where applicable. Define `SEED` once at the top, not scattered literals.
- Seeds are for reproducibility, not performance. Never tune the seed; if results swing meaningfully across seeds, that variance is a finding to report (see multi-run averaging), not a dial to turn.
- Pin the data identity, not just the filename. Record a content hash, snapshot path, or data-version tag (DVC, lakeFS, a dated immutable copy) alongside results. `data.csv` is a name, not a version.
- Record the run's configuration with its result: hyperparameters, code commit, data hash, seed — as a logged dict, a JSON sidecar next to the metrics, or an experiment tracker entry. A metric without its config is unfalsifiable.
- Outputs should never silently overwrite previous outputs: write models and metrics to run-specific paths (`runs/2026-06-10_a1b2c3/`) so history survives.
- Note known nondeterminism you can't remove (GPU atomics, multithreaded data loading) so a small wobble on rerun isn't misread as a code change.

**Red flags that you're about to violate this:**

- "It's a quick experiment, seeding is ceremony..."
- "The split is random but it'll be roughly the same every time..."
- "I'll remember which CSV this was..."
- "I'll add tracking once the model actually works..."
- "The number moved on rerun, but it's probably fine..."
- "Let me try a different seed, that one was unlucky..."

---

## Why It Works

1. **It makes run-to-run diffs attributable.** With randomness, data, and config pinned, a changed metric has exactly one remaining cause — the change you made — which is the entire basis for concluding anything from an experiment.

2. **It converts "the data" from a name into an identity.** Hashing or versioning catches the most insidious source of drift: the file that was quietly re-exported, re-filtered, or appended-to between runs.

3. **It separates reproducibility from seed-hacking.** Explicitly forbidding seed tuning closes the loophole where the pinning mechanism becomes a new way to cherry-pick.

4. **Run-scoped output paths make history append-only**, so the question "what did we get last month?" has an answer on disk instead of in someone's recollection.

## Origin

A team spent most of a sprint hunting a "regression" after a refactor dropped their model's AUC from 0.87 to 0.84. The refactor was innocent: the original script had an unseeded split, and 0.87 was simply a lucky partition no one could ever produce again. The proof required rerunning the old commit twenty times to map the seed variance — twenty runs that would have been one `random_state=42` at authoring time.
