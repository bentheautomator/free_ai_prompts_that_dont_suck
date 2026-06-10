---
title: Don't Cherry-Pick the Best Run
slug: dont-cherry-pick-the-best-run
category: data-and-ml
tags: [universal, ml, evaluation]
works_with: all
severity: high
one_liner: "Quoting only the best of N runs presents luck as if it were skill"
---

# Don't Cherry-Pick the Best Run

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents selecting the single best metric, seed, or run out of many and presenting it as the model's performance.

**[Copy-paste ready version](../../install/dont-cherry-pick-the-best-run.md)** — just the instruction block, no explanation.

## The Problem

Ask an assistant to "try a few configurations and tell me how the model does," and it will loop over seeds or hyperparameters, collect a list of scores, and then summarize with `max(scores)`. Sometimes it's subtler: it runs the experiment three times because the first two "looked off," keeps the third, and presents that. Or it computes accuracy, F1, AUC, and precision, then leads with whichever one happens to flatter the model. Each variant is the same statistical crime: selecting the maximum of N noisy draws and calling it the expected value.

The consequence is a number nobody can reproduce. The next person reruns the notebook, gets the median outcome instead of the lucky one, and now there's a meeting about a "regression" that is actually just the truth arriving late. Decisions get made — ship it, fund it, retire the baseline — on a figure that was never the model's typical behavior.

Assistants do this by default because their job, as they understand it, is to hand you a success. The best number is the most satisfying answer to "how did it do?", the selection step leaves no trace in the final cell, and a single clean metric looks more like a deliverable than a distribution does.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Cherry-Pick the Best Run

NEVER present the best result from multiple runs, seeds, or metric choices as the result. The maximum of N noisy measurements is an estimate of your luck, not your model. When anything was run more than once or measured more than one way, show the full picture.

- If you ran with multiple seeds or repetitions, give mean and standard deviation (or median and range) across all runs: `f"{np.mean(scores):.3f} ± {np.std(scores):.3f} (n={len(scores)})"`. Never `max(scores)` standing alone.
- If you swept hyperparameters, the score that counts is the chosen config's score on data not used to choose it. Quoting the best validation score as final performance double-dips.
- Decide which metric matters before running, not after seeing the numbers. If you computed five metrics, show all five; do not lead with the flattering one.
- Never discard runs as "warm-up," "flaky," or "looked off" without stating that you did and why. A discarded run is part of the result.
- When comparing against a baseline, both sides get the same number of runs and the same aggregation. Best-of-5 challenger vs single-run baseline is not a comparison.
- State n every time. "0.91" and "0.91, best of 12 attempts" are different claims.

**Red flags that you're about to violate this:**

- "I'll just show the best run, the others had unlucky seeds..."
- "The first two runs were probably warm-up noise, the third is representative..."
- "F1 looks better than accuracy here, I'll lead with F1..."
- "The user wants a single number, a distribution will just confuse things..."
- "This seed clearly worked, no need to mention the sweep..."
- "It hit 0.93 once, so the model is capable of 0.93..."

---

## Why It Works

1. **It names the selection step as part of the measurement.** Max-of-N is biased upward by construction; once the rule frames "best run" as measuring luck, the assistant stops treating it as a defensible summary.

2. **It forces n into every claim.** A number annotated with "n=12" invites the right question — what did the other 11 do? — at write time instead of after the decision is made.

3. **It closes the metric-shopping loophole.** Pre-committing to a metric and showing all computed metrics removes the degree of freedom that turns five mediocre numbers into one good headline.

4. **It makes comparisons symmetric.** Requiring equal runs and equal aggregation on both sides blocks the most common silent cheat: a tuned, reseeded challenger against a single-shot baseline.

## Origin

A ranking team celebrated a 4-point offline lift that turned out to be the best of nine seed runs a notebook loop had quietly maximized over. The reproduction run for the launch review landed almost exactly on the old baseline, and the diff revealed the lift had been seed variance all along. The model shipped anyway — flat — and the quarter's roadmap had been planned around a number that never existed.
