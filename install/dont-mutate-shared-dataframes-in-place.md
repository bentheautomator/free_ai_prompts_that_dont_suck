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
