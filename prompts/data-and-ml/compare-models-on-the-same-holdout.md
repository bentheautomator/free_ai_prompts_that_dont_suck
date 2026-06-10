---
title: Compare Models on the Same Holdout
slug: compare-models-on-the-same-holdout
category: data-and-ml
tags: [universal, ml, evaluation]
works_with: all
severity: high
one_liner: "An improvement claim needs both models scored on one identical held-out set"
---

# Compare Models on the Same Holdout

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents "the new model is better" claims built on scores from different splits, different data, or no held-out comparison at all.

**[Copy-paste ready version](../../install/compare-models-on-the-same-holdout.md)** — just the instruction block, no explanation.

## The Problem

Asked to improve a model, an assistant will make a change, run the new training script, get 0.83, recall that the old model "was around 0.81," and declare victory. Look closer and the two numbers were never comparable: the old score came from a different random split, or from a notebook run in March on March's data, or from cross-validation while the new one used a single holdout, or — the classic — the new model was scored on its own validation set, the one used to tune it. Sometimes there's no old number at all, and "better" is an inference from the loss curve looking smoother.

A difference between two numbers only measures the model change if everything else was held fixed. Different eval rows, different time windows, different preprocessing on the eval side, different metric implementations — each one can move a score by more than a real improvement is worth. The claim "B beats A" silently becomes "B-on-Tuesday's-split beats A-on-March's-split," which is a claim about nothing.

Assistants do this because the rigorous comparison requires re-running the old model, and the old model is annoying to resurrect. Quoting a remembered or logged number is frictionless, and the resulting sentence — "improved from 0.81 to 0.83" — looks exactly like science.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Compare Models on the Same Holdout

NEVER claim model B improves on model A unless both were evaluated on the same frozen held-out set, with the same metric implementation, in the same run or from artifacts you can verify match. A comparison across different eval data measures the data difference, not the model difference.

- Freeze a holdout once (fixed rows, saved to disk or pinned by seed and data version) and score every candidate on it. Tuning happens on a separate validation set; the holdout is touched only for final comparisons.
- If the old model's score came from a different split, a different date, or a different notebook, it is not a baseline. Re-score the old model on the current holdout — actually run it — before claiming a delta.
- Same metric, same code path: both models' predictions go through one evaluation function. Two implementations of "F1" (different averaging, different thresholds) can differ by more than your improvement.
- Eval rows must get identical treatment on both sides except the model: same preprocessing version, same filtering. If the new pipeline also changed cleaning, you're comparing pipelines, not models — say so, or isolate the change.
- Report the paired result: both scores, the delta, n, and ideally per-segment or per-fold deltas. A delta smaller than run-to-run seed variance (measure it) is "no detectable difference," not a win.
- No held-out comparison available? Then the honest claim is "not yet compared" — never infer improvement from training loss, vibes, or sample outputs.

**Red flags that you're about to violate this:**

- "The old model got about 0.81 last quarter, and we're at 0.83 now..."
- "Re-running the baseline is a hassle; the logged number is fine..."
- "It's the same dataset, just a fresh random split..."
- "Training loss is lower, so the model is better..."
- "I tuned on this set, but it's still held-out-ish..."
- "The 0.4-point gain is small but it's progress..."

---

## Why It Works

1. **It isolates the variable.** Fixing rows, metric, and preprocessing means the only difference between the two scores is the model — the precondition for the word "improvement" meaning anything.

2. **Forcing the baseline re-run kills the stale-number comparison**, which is the most common counterfeit: two scores separated by months of data drift, presented as a controlled experiment.

3. **Calibrating against seed variance gives "better" a noise floor.** A delta has to clear the measured run-to-run wobble to count, which stops noise-sized gains from accumulating into a fictional trend across many "improvements."

4. **One evaluation function eliminates metric-implementation drift** — the silent killer where sklearn's default average and a hand-rolled F1 disagree by two points and nobody thinks to check.

## Origin

A team "improved" a lead-scoring model four times in a year, each time quoting the previous model's score from the doc of the prior project. When an audit finally scored all five model versions on one frozen holdout, the newest model was two points worse than the original: each comparison had ridden a fresh random split and a slightly different eval query, and the accumulated deltas were noise plus drift. Five training efforts, net negative, every step individually "an improvement."
