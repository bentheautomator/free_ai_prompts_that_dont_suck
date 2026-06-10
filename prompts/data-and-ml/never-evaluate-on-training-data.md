---
title: Never Evaluate on Training Data
slug: never-evaluate-on-training-data
category: data-and-ml
tags: [universal, ml, evaluation]
works_with: all
severity: critical
one_liner: "Scoring a model on the rows it trained on reports memory, not skill"
---

# Never Evaluate on Training Data

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents reporting a model's score on the same rows it was trained on and calling that performance.

**[Copy-paste ready version](../../install/never-evaluate-on-training-data.md)** — just the instruction block, no explanation.

## The Problem

`model.fit(X, y)` followed by `model.score(X, y)` is the shortest possible path from "train a model" to "print a number," and AI assistants take it constantly — especially in quick demos, debugging sessions, and notebooks where the split feels like ceremony. The number that comes out is not an estimate of anything. A random forest will happily score 0.99 on its own training rows because trees memorize; that 0.99 says nothing about the next row the model sees.

The failure compounds when the demo code gets promoted. The "let's just see if it learns" cell becomes the evaluation cell, the 0.99 lands in a status update, and someone allocates a quarter based on it. By the time a real holdout score arrives — often 20+ points lower — the project has momentum built on a number that measured memorization.

Assistants do this because it runs, it's short, and a high accuracy reads as success. There is no error, no warning, and the output looks exactly like a legitimate evaluation. The only defense is a rule that scoring training rows is never evaluation, ever, including "just for a sanity check."

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Evaluate on Training Data

NEVER report a metric computed on rows the model was trained on as the model's performance. Training-set scores measure memorization capacity, not generalization, and for high-capacity models they are near-perfect regardless of whether the model learned anything.

- Wrong: `model.fit(X, y); print(model.score(X, y))`. Right: split first, fit on `X_train`, report `model.score(X_test, y_test)` and label it as held-out.
- Every printed or logged metric must say which split it came from: `train_acc=...`, `test_acc=...`. An unlabeled metric is assumed to be contaminated.
- Training-set metrics are allowed for exactly one purpose: diagnosing under/overfitting by comparing train vs. held-out side by side. Never alone, never as the headline number.
- In notebooks and quick experiments, do the split anyway. "It's just a demo" scores get copy-pasted into real claims.
- If the dataset is too small to hold out a test set, use cross-validation and report the out-of-fold scores — do not fall back to scoring the training rows.
- When summarizing results in comments, docstrings, or commit messages, never carry forward a number without verifying it came from held-out data.

**Red flags that you're about to violate this:**

- "I'll just score it on X and y since they're already in scope..."
- "This is only a sanity check, the real eval comes later..."
- "99% accuracy — the model works, moving on..."
- "Splitting feels like overkill for this small example..."
- "The user just wants to see that training succeeds..."

---

## Why It Works

1. **It defines what the number means.** "Training scores measure memorization capacity" replaces the assistant's implicit belief that any accuracy number is evidence of model quality — once the metric is reframed as meaningless, printing it stops feeling like progress.

2. **It forces labeled provenance.** Requiring `train_acc=` / `test_acc=` labels makes contamination visible at the print statement, so a bad number can't quietly travel into a summary.

3. **It closes the demo loophole.** "Just a sanity check" is the exact rationalization that produces this bug; naming it as a red flag means the assistant recognizes the thought as it forms.

4. **It pre-routes the small-data excuse.** Cross-validation is given as the sanctioned fallback, so "not enough data to split" can't justify scoring training rows.

## Origin

A fraud-detection prototype was greenlit on a reported 0.98 accuracy. The evaluation cell scored the model on the full training frame; the holdout split existed in the notebook but was never passed to `.score()`. On its first week of live traffic the model flagged at chance level. The postmortem found the 0.98 had been screenshot into three decks before anyone asked which rows it was computed on.
