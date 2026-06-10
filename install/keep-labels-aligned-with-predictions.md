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
