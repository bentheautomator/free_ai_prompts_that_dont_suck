---
title: Fit Preprocessing on Train Data Only
slug: fit-preprocessing-on-train-only
category: data-and-ml
tags: [universal, ml, evaluation]
works_with: all
severity: high
one_liner: "Fitting scalers and encoders on the full dataset leaks test data into training"
---

# Fit Preprocessing on Train Data Only

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents normalization, imputation, and encoding statistics computed on the full dataset from leaking test-set information into the model.

**[Copy-paste ready version](../../install/fit-preprocessing-on-train-only.md)** — just the instruction block, no explanation.

## The Problem

`scaler.fit_transform(X)` followed three lines later by `train_test_split` is one of the most common shapes of ML code an AI assistant will write, because it reads naturally: clean the data, then split it. But the scaler just memorized the mean and standard deviation of rows that are supposed to be the future. Every "unseen" test row was already consulted when the preprocessing was fit. The same bug wears other costumes: imputing missing values with the full-dataset median, fitting a `LabelEncoder` or TF-IDF vocabulary on everything, selecting features by correlation with the target across all rows.

The consequence is an evaluation score that is quietly optimistic. Not absurdly — often just a point or two — which is exactly what makes it dangerous. The inflated number survives review because it looks plausible, gets reported as the model's performance, and the gap only appears in production where the real future hasn't been folded into anyone's `.fit()`.

AI assistants default to this because the leaky version is shorter, the tidy version requires threading a fitted transformer through two code paths, and nothing fails. The pipeline runs, the metrics print, and a number that prints looks like a number that's correct.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Fit Preprocessing on Train Data Only

NEVER fit any preprocessing step on data that includes the test or validation set. Split first; fit on train; transform everything else with the already-fitted object. Statistics computed on the full dataset (means, medians, vocabularies, category mappings, feature selections) leak test-set information into training and inflate every metric you report afterward.

- Wrong: `X = scaler.fit_transform(X)` then `train_test_split(X, y)`. Right: split first, then `scaler.fit_transform(X_train)` and `scaler.transform(X_test)`.
- This applies to every fitted step, not just scalers: imputers (`SimpleImputer`), encoders (`OneHotEncoder`, `LabelEncoder`, target encoders), text vectorizers (vocabulary and IDF weights), PCA, feature selection by correlation or importance, outlier-clipping thresholds.
- Prefer an `sklearn.Pipeline` (or equivalent) containing all preprocessing, fit inside `cross_val_score`/`GridSearchCV`, so each CV fold refits preprocessing on its own training portion. Preprocessing done before cross-validation leaks into every fold.
- Target encoding and any feature that aggregates the label are the highest-risk versions; compute them per-fold or with out-of-fold estimates, never globally.
- If preprocessing genuinely needs only constants (e.g., a fixed unit conversion, a hand-specified category list), say so explicitly in a comment; otherwise assume it is fitted and belongs after the split.
- When reviewing existing code, trace every `.fit` and `.fit_transform` call and confirm its input excludes test rows before trusting any reported metric.

**Red flags that you're about to violate this:**

- "I'll normalize the whole dataset first so train and test are on the same scale..."
- "It's just a scaler, the mean barely changes with or without the test rows..."
- "Fitting twice is redundant, fit_transform on everything is cleaner..."
- "I'll do feature selection up front, then split..."
- "Cross-validation will catch any leakage anyway..."

---

## Why It Works

1. **It reframes "same scale for train and test" as the trap, not the goal.** The AI's instinct that consistent preprocessing means fitting once on everything is exactly backwards; the rule replaces it with fit-once-on-train, transform-everywhere.

2. **It enumerates the costumes.** Assistants that know about scaler leakage still leak through imputers, vocabularies, and feature selection; listing the fitted-step categories closes the "it's not a scaler so it doesn't count" loophole.

3. **It moves preprocessing inside cross-validation explicitly.** The most common partial fix (split correctly, but preprocess before CV) is named as still-broken, which blocks the "CV will catch it" rationalization.

4. **It makes the audit mechanical.** "Trace every `.fit` call and check its input" is a concrete review action, not a vibe, so leakage gets caught at write time instead of in production.

## Origin

A churn model reported 0.84 AUC in offline evaluation and decayed to roughly random within weeks of deployment. The notebook had fit a target encoder for a high-cardinality account-type column on the full dataset before splitting, so every test row's encoding already contained its own label's contribution. The model had learned to read the encoder, not the customers, and the team spent a quarter retraining on "more data" before anyone traced the `.fit_transform` line.
