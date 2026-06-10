---
title: Don't Mutate Shared DataFrames in Place
slug: dont-mutate-shared-dataframes-in-place
category: data-and-ml
tags: [universal, data, pandas]
works_with: all
severity: high
one_liner: "In-place edits to a DataFrame other code reads make results depend on call order"
---

# Don't Mutate Shared DataFrames in Place

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents functions and cells from silently editing DataFrames that other code still depends on in their original form.

**[Copy-paste ready version](../../install/dont-mutate-shared-dataframes-in-place.md)** — just the instruction block, no explanation.

## The Problem

A function signature like `def add_features(df):` looks innocent, but if the body does `df['log_amt'] = np.log(df['amt'])` or `df.dropna(inplace=True)`, the caller's DataFrame just changed. Python passes the reference; pandas mutates through it. Now `analyze_raw(df)` called after `add_features(df)` quietly operates on the feature-engineered, row-dropped version, and whether your numbers are right depends on the order two unrelated lines were called in. In notebooks the same disease spreads through cells: cell 12 mutates `df`, and every earlier cell becomes a lie if re-run.

These bugs are miserable to find because the corruption is at a distance — the symptom appears in code that did nothing wrong. The function that misbehaves isn't on the stack trace when the wrong number prints; it ran minutes ago and returned successfully. Double-applied transformations are the signature variant: run the mutation twice (easy in a notebook) and amounts get log-transformed twice, categories re-encoded over encoded values, and nothing errors.

Assistants mutate in place by default because it's fewer characters, `inplace=True` sounds like an optimization, and within the single cell they're focused on, the mutation is invisible — the cost only exists in code they're not currently looking at.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Mutate Shared DataFrames in Place

Functions that receive a DataFrame must not modify it. ALWAYS transform a copy and return it; the caller decides what to do with the result. Mutation through a shared reference makes correctness depend on call order, which is invisible in the code.

- Pattern: first line of any transforming function is `df = df.copy()`; transform; `return df`. Caller writes `df = add_features(df)`. The intent is explicit on both sides.
- Avoid `inplace=True` everywhere. It saves no meaningful memory in modern pandas, it returns None (breaking chains and enabling `df = df.dropna(inplace=True)` bugs), and it converts local code into action at a distance.
- Adding or overwriting a column on a parameter (`df['new'] = ...`) is mutation — same rule, even though no `inplace` appears.
- In notebooks, don't write cells that destructively update a shared `df` such that re-running them double-applies (`df['amt'] = np.log(df['amt'])`). Derive new names (`df_feat`) or make the cell idempotent from a stable upstream variable.
- Make transformations re-derivable: prefer one pipeline expression (`df_clean = (raw.pipe(parse).pipe(filter_valid).pipe(add_features))`) over scattered mutations, so the current state of any frame has exactly one definition.
- If you genuinely need in-place behavior for memory at scale, that's an explicit, documented decision with a comment and a name that says so (`mutate_df_inplace_`), never a silent default.

**Red flags that you're about to violate this:**

- "inplace=True is more memory-efficient..."
- ".copy() on every call is wasteful..."
- "This function is the only thing using df right now..."
- "I'll just add the column directly to the argument..."
- "Re-running the cell is fine, the transform is probably idempotent..."

---

## Why It Works

1. **It removes call-order as a correctness variable.** When no function mutates its inputs, any sequence of reads gives the same answer; the entire class of "worked until we reordered two calls" bugs becomes unrepresentable.

2. **`df = f(df)` documents dataflow at the call site.** Reassignment makes "this variable changed" visible in the caller's code, where mutation through a reference shows nothing.

3. **Copy-and-return makes notebook cells safely re-runnable**, eliminating the double-applied-transform variant — the one that corrupts data in a way that looks like a modeling problem instead of a code problem.

4. **One-expression pipelines give each frame a single definition**, so "what is df_clean right now?" is answered by reading one place rather than replaying the kernel's mutation history.

## Origin

An anomaly report and a forecasting job shared a loader that returned a cached DataFrame. The forecasting code called a helper that dropped weekends and holidays — `inplace=True`, on the cached object. Whenever forecasting ran first, the anomaly report silently analyzed a calendar with a fifth of its days missing and flagged phantom volume drops every Monday. The on-call engineer chased "weekend data loss" through the ingestion stack for days; the bug was one keyword argument in a helper neither pipeline owned.
