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
