---
title: Never Silently Drop Unparseable Rows
slug: never-silently-drop-unparseable-rows
category: data-and-ml
tags: [universal, data]
works_with: all
severity: high
one_liner: "Rows that fail to parse must be counted and reported, not vanished"
---

# Never Silently Drop Unparseable Rows

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents parse failures from being swallowed by `errors='coerce'`, bare `except: continue`, and `dropna()` so that bad rows disappear without a trace.

**[Copy-paste ready version](../../install/never-silently-drop-unparseable-rows.md)** — just the instruction block, no explanation.

## The Problem

When a loader hits rows it can't parse, an AI assistant's first instinct is to make the error go away: `pd.to_datetime(df['ts'], errors='coerce')` followed by `dropna()`, a `try/except: continue` inside the row loop, or `pd.read_csv(..., on_bad_lines='skip')`. The code now runs end to end, which is the assistant's definition of fixed. What actually happened is that some unknown fraction of the dataset was deleted by a side effect, with no count, no log line, and no record of which rows or why.

The deleted rows are almost never a random sample. Timestamps fail to parse because one upstream system uses a different format — so you just dropped one entire data source. Numbers fail because one region uses comma decimals — so you dropped a country. Every downstream statistic is now computed on a biased subset, and it still sums, averages, and plots beautifully.

This pattern survives because the failure is invisible at every layer: the pipeline exits zero, the DataFrame has plenty of rows, the metrics are plausible. Nobody compares row counts before and after, because nothing suggested rows were lost.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Silently Drop Unparseable Rows

NEVER let parsing failures remove rows without counting and reporting them. A row that fails to parse is information about your data; making it vanish converts a visible bug into an invisible bias.

- After any coercion step (`errors='coerce'`, `on_bad_lines='skip'`, `try/except` in a row loop), count what was lost and surface it: `n_bad = df['ts'].isna().sum() - n_na_before; log.warning(f"dropped {n_bad}/{len(df)} rows: unparseable ts")`.
- Never write `except Exception: continue` around row parsing. Catch the specific error, increment a counter, and keep a sample of failing rows (e.g., the first 10) for inspection.
- Set a tolerance and enforce it: `assert n_bad / len(df) < 0.01, f"{n_bad} unparseable rows"` — pick the threshold deliberately, don't default to "any amount is fine."
- Check whether failures are concentrated before dropping: group the failing rows by source, date, or region. Parse failures cluster; a cluster means you're about to delete a whole segment, not noise.
- Quarantine, don't delete: write rejected rows to a sidecar file or DataFrame (`rejects.parquet`) so they can be inspected and re-ingested after the parser is fixed.
- `dropna()` with no subset and no comment is a red flag in any loader. Specify columns, state why, and log the row delta.

**Red flags that you're about to violate this:**

- "errors='coerce' and dropna will clean this right up..."
- "It's probably just a few malformed rows, not worth logging..."
- "A bare except keeps the loop simple..."
- "The pipeline needs to not crash, I'll skip bad lines..."
- "Row counts look roughly right, close enough..."
- "We can always reparse later if something seems off..."

---

## Why It Works

1. **It converts a silent subtraction into a visible number.** Once "dropped 38,412/2,100,000 rows" appears in the log, a human decides whether that's acceptable — the decision stops being made implicitly by an exception handler.

2. **It exploits the clustering property of parse failures.** Bad rows share a cause, so the grouped-failure check catches "you just deleted Belgium" before the deletion, which random spot checks never would.

3. **It separates crash-avoidance from data loss.** The assistant's legitimate goal (pipeline shouldn't die on one bad row) is satisfied by quarantine-and-count, removing the excuse for delete-and-forget.

4. **A tolerance assert makes drift fail loudly.** When the upstream format changes and 40% of rows stop parsing, the pipeline halts instead of publishing statistics on the surviving 60%.

## Origin

A demand-forecasting pipeline ran clean for five months while `errors='coerce'` quietly nulled every timestamp from one acquiring company's point-of-sale system, whose dates were day-first. The subsequent `dropna()` removed that entire business unit from the training data, and forecasts for it were silently extrapolated from everyone else's. The bug surfaced only when a finance analyst noticed the unit's "actuals vs forecast" gap was the largest in company history.
