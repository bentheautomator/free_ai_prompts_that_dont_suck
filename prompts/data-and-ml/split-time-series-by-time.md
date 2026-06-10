---
title: Split Time Series by Time
slug: split-time-series-by-time
category: data-and-ml
tags: [universal, ml, evaluation]
works_with: all
severity: critical
one_liner: "Random splits on temporal data train the model on its own test future"
---

# Split Time Series by Time

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents random train/test splits on temporal data, where shuffling hands the model training rows from after its test rows.

**[Copy-paste ready version](../../install/split-time-series-by-time.md)** — just the instruction block, no explanation.

## The Problem

`train_test_split(X, y, test_size=0.2)` is the assistant's universal reflex, and on temporal data it's a rigged exam. Shuffling interleaves past and future: the model trains on Thursday and is tested on Wednesday, learns December's level and is quizzed on November. For autocorrelated series — prices, demand, sensor readings, user activity, which is to say nearly everything with a timestamp — neighboring rows are near-copies, so a shuffled test set is substantially the training set wearing different row numbers. K-fold cross-validation repeats the trick five times and averages the flattery.

The production task is always "predict forward from now," and the shuffled eval answers a different question: "interpolate between points you've already seen." The offline number can be spectacular while the deployed model, facing an actual future for the first time, falls back to roughly persistence. The gap doesn't show up until real time has passed, which makes it among the most expensive eval bugs to discover.

Assistants do it because `train_test_split` is the canonical pattern in every tutorial, the timestamp column doesn't announce that order is meaning, and the resulting metrics — being inflated — look like evidence the approach worked.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Split Time Series by Time

If rows have a meaningful time dimension, NEVER split them randomly. Train on the past, evaluate on the future, always — a shuffled split lets the model see ahead of its test set and reports interpolation skill as forecasting skill.

- Wrong: `train_test_split(X, y, test_size=0.2)` on timestamped data. Right: pick a cutoff and split by it — `train = df[df.ts < cutoff]; test = df[df.ts >= cutoff]` — with the test window entirely after the train window.
- For cross-validation, use forward-chaining (`sklearn.model_selection.TimeSeriesSplit` or equivalent expanding/rolling windows), never `KFold`/`cross_val_score` defaults, which shuffle or interleave folds across time.
- Mind the boundary: if labels or features are windowed (e.g., target is "next 7 days"), leave a gap of at least the window length between train end and test start, or boundary rows leak across.
- Before deciding the split, ask whether time matters even if the task isn't "forecasting": user behavior, transactions, logs, and text scraped over time all drift, and a random split overstates performance on all of them. Default to temporal splits whenever a timestamp exists; justify random splits, not the reverse.
- Hyperparameter tuning obeys the same arrow: the validation window must follow the training window, and the final test window must follow both.
- Evaluate against a persistence baseline (predict last known value / same period last cycle). On a shuffled split persistence looks beatable; on an honest split it tells you whether the model does anything at all.

**Red flags that you're about to violate this:**

- "train_test_split with a fixed seed is the standard approach..."
- "It's not really forecasting, so random splitting is fine..."
- "K-fold gives more reliable estimates than a single time split..."
- "Stratifying by month handles the time structure..."
- "The model scores 0.95 — the random split clearly didn't hurt..."

---

## Why It Works

1. **It matches the eval to the deployment question.** Production only ever asks "given the past, what's next?"; a forward split is the only design whose score estimates the answer, so the offline number regains predictive meaning.

2. **It targets autocorrelation, the actual leak mechanism.** Shuffled splits fail because adjacent rows are near-duplicates spanning the train/test line; splitting by time puts the redundancy entirely on one side.

3. **Defaulting to temporal-unless-justified flips the burden of proof.** Assistants reliably misjudge whether time matters; making the safe split the default means the misjudgment costs nothing.

4. **The persistence baseline is a leak alarm.** When "repeat yesterday" scores nearly as well as the model on a random split, the eval is exposed as interpolation — a one-line check that has invalidated whole projects before they shipped.

## Origin

An energy-demand model cross-validated at 0.96 R² using standard five-fold CV on three years of hourly data. Deployed, it tracked reality for a few hours after each retrain and degraded into an expensive moving average. Hourly demand is so autocorrelated that random folds had surrounded every test hour with its neighbors; re-evaluated with forward-chaining splits, the model beat persistence by almost nothing — a fact available before any of the deployment infrastructure was built.
