### Run Notebooks Top to Bottom

A notebook's results are only valid if produced by a clean, top-to-bottom run. ALWAYS verify with Restart & Run All (or `jupyter nbconvert --execute`, or `papermill`) before treating any notebook output as a result or committing the notebook.

- Cells must be ordered so each one depends only on cells above it. If you find yourself scrolling up to re-run an earlier cell after editing it, reorder the notebook so the dependency reads downward.
- Never depend on state from deleted or edited-away cells. After renaming a variable or function, restart the kernel; the old binding surviving in memory is how `df_clean`-vs-`df` bugs hide.
- Don't redefine the same variable to mean different things in different cells (`df` raw in cell 2, `df` filtered in cell 9). Downstream cells silently bind to whichever ran last. Use distinct names.
- Keep imports, config, and constants in the first cells, not sprinkled where they happened to be needed during exploration.
- Out-of-order execution counts (`[17]` above `[4]`) on a notebook you're about to commit or cite are a stop sign: restart and run all first.
- For anything load-bearing (pipelines, scheduled jobs, shared analyses), move logic into importable `.py` modules and keep the notebook as a thin driver; kernels forget, files don't.

**Red flags that you're about to violate this:**

- "I'll just re-run this one cell, the rest of the state is fine..."
- "Restart & Run All takes ten minutes, the outputs are already there..."
- "I deleted that cell but the variable it made is still good..."
- "df is the filtered version right now, I'll remember that..."
- "The execution counts are out of order but the numbers look right..."
