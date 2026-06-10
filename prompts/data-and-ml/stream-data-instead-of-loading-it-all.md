---
title: Stream Data Instead of Loading It All
slug: stream-data-instead-of-loading-it-all
category: data-and-ml
tags: [universal, data, performance]
works_with: all
severity: high
one_liner: "Loading the full dataset into RAM or VRAM works in the demo and dies at scale"
---

# Stream Data Instead of Loading It All

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents pipelines that materialize entire datasets in memory or GPU and then OOM the first time they meet production-sized data.

**[Copy-paste ready version](../../install/stream-data-instead-of-loading-it-all.md)** — just the instruction block, no explanation.

## The Problem

`df = pd.read_csv("events.csv")` then operate on the whole thing; `dataset = torch.tensor(X).cuda()` to move everything to the GPU at once; `pd.concat(all_dfs)` building a list of every partition before combining. Assistants write whole-dataset code because it's the shortest path and it works flawlessly on the sample they're developing against. The code's memory footprint is a hidden linear function of input size, and nothing in the code states or checks the assumption "this fits."

Then the data grows, or the pipeline meets the real table instead of the dev extract, and the process is OOM-killed at 3 a.m. — often with no Python traceback at all, just a dead worker and a SIGKILL in dmesg. The sneakier variant doesn't crash: the box swaps, the job that took minutes takes twelve hours, and intermediate copies (`df.merge(...)` doubling peak usage, a string column stored as Python objects at 10x the file size) push a "20GB dataset on a 64GB machine" comfortably over the cliff. CSV bytes on disk are not DataFrame bytes in RAM; the multiplier is routinely 3-8x.

It's the default because memory is invisible at authoring time: the sample loads instantly, the operations are textbook pandas, and no metric punishes the approach until the input does.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It surfaces the hidden assumption as an explicit number.** "Does it fit?" becomes a measured size against a known limit instead of an unexamined default, so the failure is predicted at authoring time rather than discovered by the OOM killer.

2. **Chunked aggregation makes memory flat in input size.** Footprint becomes O(chunk) instead of O(dataset); the pipeline that worked on 1GB works identically on 100GB, which is the property "it ran on my sample" merely impersonates.

3. **Accounting for peak (copies, merges, optimizer state) prevents the near-miss OOMs** — the jobs that fit at rest but die mid-merge, which size-at-rest reasoning systematically clears as safe.

4. **Dtype and column pruning attack the multiplier itself**, frequently making the honest answer "it fits now" — but as a verified conclusion with stated headroom, not a guess.

## Origin

A feature-engineering job developed against a 200MB extract shipped to production, where the source table was 40GB. The pandas merge at its center needed roughly triple that at peak; the nightly run was OOM-killed with no traceback, restarted by the scheduler, and killed again — a loop that burned a weekend of compute and an on-call rotation's patience before anyone read dmesg. Rewritten around chunked aggregation, the job finished in 6GB of RAM, and the only real change was admitting the data had a size.
