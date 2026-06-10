### Audit NaNs Before Aggregating

ALWAYS measure missingness before computing aggregates, and report it next to the result. Pandas skips NaNs silently, so every mean, sum, and count is implicitly conditioned on "rows where this happened to be present."

- Before aggregating a column, check the null fraction: `df['revenue'].isna().mean()`. If it's material (pick a threshold; >1-5% usually is), the aggregate must carry it: report `mean` alongside `n` and `pct_missing`, e.g. via `.agg(['mean', 'count', lambda s: s.isna().mean()])`.
- Check whether missingness is concentrated: `df.groupby('region')['revenue'].apply(lambda s: s.isna().mean())`. Uniform missingness widens uncertainty; clustered missingness biases the answer.
- Know the dangerous identities: `sum()` of all-NaN is `0.0` (use `min_count=1` to get NaN instead); `count()` is non-null count, not row count (`size()` is rows); `groupby` drops NaN keys unless `dropna=False`; comparisons like `x > 0.5` are False for NaN, so filters silently shed missing rows.
- Never `fillna(0)` (or any constant) just to make aggregation "work." Zero is a value with meaning; imputation is a modeling decision made explicitly, with the method and the affected fraction stated.
- When filtering on a column with NaNs, decide their fate explicitly: `df[df.score.gt(0.5)]` vs `df[df.score.gt(0.5) | df.score.isna()]` are different populations — say which you mean.
- In reports and notebooks, a number derived from a column with material missingness gets a caveat in the same cell, not in a separate data-quality section nobody reads.

**Red flags that you're about to violate this:**

- "mean() handles NaNs automatically, so this is fine..."
- "I'll fillna(0) so the groupby works..."
- "Missing values are probably rare in this column..."
- "The two filtered halves should cover everything..."
- "The aggregate looks reasonable, the data must be complete..."
