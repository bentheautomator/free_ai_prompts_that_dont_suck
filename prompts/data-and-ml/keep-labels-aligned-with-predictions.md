---
title: Keep Labels Aligned With Predictions
slug: keep-labels-aligned-with-predictions
category: data-and-ml
tags: [universal, ml, pandas]
works_with: all
severity: critical
one_liner: "Sorting or filtering X without y scores predictions against the wrong rows"
---

# Keep Labels Aligned With Predictions

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents features, labels, and predictions from drifting out of row alignment after sorts, filters, resets, and round-trips through files.

**[Copy-paste ready version](../../install/keep-labels-aligned-with-predictions.md)** — just the instruction block, no explanation.

## The Problem

Somewhere between loading and scoring, the rows moved. `X = X.sort_values('date')` but `y` kept its old order. `X = X.dropna()` shed twelve rows, then `accuracy_score(y, model.predict(X))` was called with the original `y` — or worse, lengths still matched because `y` was filtered by a slightly different condition. Predictions were written to CSV without an ID column and merged back positionally onto a table that had since been re-sorted. In every variant, row i of the predictions is being graded against row j of the truth, and the metric that comes out is a measurement of nothing.

The cruel part is the failure direction: misalignment usually makes metrics worse, occasionally makes them better, and never raises an exception as long as lengths agree. A team can burn weeks "improving" a model whose true performance is fine, because the eval is shuffled — or ship a model whose eval was accidentally flattering. NumPy arrays make it worse by having no index at all, so the moment `y.values` enters the picture, alignment is pure faith.

Assistants cause this because they manipulate `X` and `y` as independent variables, and each individual operation — a sort here, a dropna there, a `reset_index` to silence a warning — is locally reasonable. Alignment is a property of the pair, and nothing in the code represents the pair.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep Labels Aligned With Predictions

NEVER apply a sort, filter, or reorder to features without applying the identical operation, atomically, to labels and any other row-aligned arrays. Alignment is invisible and length checks don't prove it; equal-length misaligned arrays produce confident garbage metrics.

- Keep `X` and `y` in one DataFrame until the last possible moment: sort/filter/dedupe the combined frame, then split with `y = df.pop('target')`. Two variables transformed separately will eventually diverge.
- If they must be separate, derive every subset from one mask: `mask = X.notna().all(axis=1); X, y = X[mask], y[mask]` — never two independently-written conditions that "should" select the same rows.
- Carry a stable row ID through the entire pipeline, and attach it to predictions at scoring time: `preds = pd.DataFrame({'id': ids, 'pred': model.predict(X)})`. Join predictions to labels on ID, never by position, especially across any file write/read boundary.
- `reset_index(drop=True)` discards the only built-in alignment record pandas has. Don't use it to silence alignment warnings; the warning was the diagnosis.
- Beware silent positional alignment: `np.asarray(y)`, `.values`, and most sklearn calls strip the index. Do all row manipulation before converting, and convert `X` and `y` in the same statement or function.
- Before computing any metric, spot-check alignment with a known relationship: join a few predictions back to source rows by ID and confirm the features match what the model saw. One assert on a sentinel row catches a shuffled eval instantly.

**Red flags that you're about to violate this:**

- "I'll sort X by date for the plot, y can stay as is..."
- "Lengths match, so they're aligned..."
- "reset_index(drop=True) will fix this indexing error..."
- "I'll save predictions to CSV and line them up later..."
- "The dropna conditions are basically the same on both..."
- "Positional order survived the merge, surely..."

---

## Why It Works

1. **One-frame-until-split makes misalignment unrepresentable.** While `X` and `y` are columns of the same DataFrame, no operation can move one without the other; the rule shrinks the window where the bug can exist to a few final lines.

2. **ID-joined predictions survive every boundary that kills positional order** — file round-trips, database writes, re-sorts, distributed scoring — because the alignment is carried in the data instead of assumed from memory layout.

3. **It reframes equal lengths as non-evidence.** The dangerous mental shortcut is "shapes match, we're fine"; explicitly invalidating it forces an actual alignment check where intuition would have stopped.

4. **The sentinel spot-check is cheap and decisive.** A shuffled eval looks like a mediocre model from the metric alone; one row traced by ID distinguishes "model is weak" from "grading the wrong answers" in seconds.

## Origin

A model retrain came back two points worse than the incumbent and a team spent three weeks on architecture changes to win them back. The regression was eventually traced to an eval script that sorted the feature frame by timestamp for a drift plot — after `y` had been extracted. Every metric since that commit had been computed against labels in the original order: the model was scored on a quietly shuffled answer key, and the "two points" the team fought to recover had never been lost.
