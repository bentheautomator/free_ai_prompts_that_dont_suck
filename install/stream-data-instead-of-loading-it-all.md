### Stream Data Instead of Loading It All

NEVER assume the dataset fits in memory. Before writing whole-dataset code, establish the real data size and the available RAM/VRAM; when full-size data is or will be larger than a comfortable fraction of memory, process it incrementally by design.

- Check size first: file bytes times a 3-8x in-memory multiplier for CSV→DataFrame, `df.memory_usage(deep=True).sum()` on a sample, extrapolated. Code that works only on the dev sample's scale should say so out loud.
- Read incrementally: `pd.read_csv(..., chunksize=100_000)` with per-chunk aggregation, `pyarrow.parquet` with column and row-group selection, or push the heavy lifting to engines built for out-of-core work (Polars lazy/streaming, DuckDB querying files directly, Dask/Spark at cluster scale).
- Load only what you use: `usecols=`/column projection, predicate pushdown via Parquet filters, and proper dtypes (`category` for low-cardinality strings, downcast floats/ints) — often a 5-10x footprint cut before any streaming is needed.
- On GPU, batch by construction: `DataLoader` with a tuned `batch_size`, never `torch.tensor(full_dataset).cuda()`. VRAM holds model + batch + gradients + optimizer state, not the corpus.
- Watch peak memory, not resting memory: merges, `concat`, sorts, and `astype` create temporary copies that can double usage. Aggregate-as-you-go beats build-then-reduce (`pd.concat(list_of_everything)`).
- If you choose full in-memory because the data verifiably fits with headroom, state the size, the limit, and what happens when the data grows — that's a decision; silence is just hope.

**Red flags that you're about to violate this:**

- "read_csv the whole thing, it's simpler..."
- "It loads fine on my sample..."
- "I'll move the entire tensor to GPU so it's fast..."
- "The file is only 15GB and the box has 64..."
- "concat everything first, then aggregate..."
- "We can deal with memory when it becomes a problem..."
