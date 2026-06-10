---
title: Avoid Pandas Chained Assignment
slug: avoid-pandas-chained-assignment
category: data-and-ml
tags: [universal, data, pandas]
works_with: all
severity: high
one_liner: "Chained indexing writes to a maybe-copy, and your edit silently goes nowhere"
---

# Avoid Pandas Chained Assignment

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents writes through chained indexing that land on a temporary copy instead of the DataFrame you meant to change.

**[Copy-paste ready version](../../install/avoid-pandas-chained-assignment.md)** — just the instruction block, no explanation.

## The Problem

`df[df.score < 0]['score'] = 0` reads like a perfectly sensible sentence: take the negative scores, set them to zero. What pandas actually does is evaluate `df[df.score < 0]` into a new object — which may be a copy — and then assign into that object, which is immediately garbage collected. The original `df` is untouched. Whether you get the intended edit or a no-op depends on internal block layout, which is why this bug famously works in one notebook and fails in the next. The same trap hides in two-step form: `sub = df[mask]` ... fifty lines later ... `sub['col'] = x`, which either fails to propagate or stomps shared memory, depending on the version.

The consequence is data that you believe you cleaned but didn't. The capping never happened, the imputation never happened, the label fix never happened — and every model and report downstream consumed the dirty values. `SettingWithCopyWarning` was the one chance to notice, and the standard reflex is to suppress it.

AI assistants generate chained assignment constantly because it mirrors how humans describe the operation, the code raises no error, and in many environments it even works — until pandas copy-on-write semantics (default in 3.x) guarantee that it never does.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Avoid Pandas Chained Assignment

NEVER assign through chained indexing in pandas. `df[mask]['col'] = value` writes into a temporary object and may silently change nothing; under copy-on-write (pandas 3.x default) it is guaranteed to change nothing.

- Wrong: `df[df.a > 0]['b'] = 1`. Right: `df.loc[df.a > 0, 'b'] = 1` — one `.loc` with both row and column selection in a single indexing operation.
- Wrong: `sub = df[mask]` then later `sub['col'] = x` while intending to modify `df`. If you need a working subset, take an explicit copy (`sub = df[mask].copy()`) and decide deliberately whether results get merged back; if you mean to edit `df`, use `df.loc[mask, 'col'] = x` directly.
- Never silence `SettingWithCopyWarning` with `pd.set_option('mode.chained_assignment', None)` or warning filters. The warning marks code whose behavior is version- and layout-dependent; fix the indexing instead.
- The same applies through method chains: `df.query('a > 0')['b'] = 1` and `df.dropna()['b'] = 1` assign into temporaries.
- For conditional column updates prefer explicit whole-column constructions: `df['b'] = df['b'].mask(df.a > 0, 1)` or `np.where(...)` — these produce a new column and cannot half-apply.
- After any in-place cleaning step, verify it took: a quick `assert (df.loc[mask, 'col'] == expected).all()` catches a write that landed on a copy.

**Red flags that you're about to violate this:**

- "df[mask]['col'] = value reads cleanly, pandas will figure it out..."
- "It's just a warning, not an error — I'll suppress it..."
- "This exact pattern worked in the last cell..."
- "I'll filter into a variable first, it's the same DataFrame anyway..."
- "No time to restructure the indexing, the assignment probably propagates..."

---

## Why It Works

1. **It replaces a maybe with a certainty.** Chained assignment's behavior depends on pandas internals; the single-`.loc` form has exactly one defined meaning, so correctness stops depending on which version runs the notebook.

2. **It treats the warning as a defect report, not noise.** `SettingWithCopyWarning` fires precisely on ambiguous writes; banning suppression keeps the only built-in detector switched on.

3. **It forces the copy-or-view decision into the code.** Writing `.copy()` explicitly makes "is this a new table or a window onto the old one?" a reviewed line instead of an accident of memory layout.

4. **The post-write assert converts a silent no-op into a loud failure**, which is the difference between fixing the bug now and shipping unclipped data for a quarter.

## Origin

A risk team capped outlier transaction amounts with `df[df.amt > cap]['amt'] = cap` in a preprocessing script that had run "successfully" for months. The write went to a temporary; the model trained on uncapped values, and a handful of extreme transactions dominated the loss enough to distort scores for an entire merchant segment. The line had been emitting `SettingWithCopyWarning` the whole time — into a log nobody read, below a filter someone had added to "clean up the output."
