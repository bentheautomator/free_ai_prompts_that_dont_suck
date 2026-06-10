---
title: Run Notebooks Top to Bottom
slug: run-notebooks-top-to-bottom
category: data-and-ml
tags: [universal, data, notebooks]
works_with: all
severity: medium
one_liner: "A notebook that only works in secret cell order is a result nobody can rerun"
---

# Run Notebooks Top to Bottom

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents notebooks whose results depend on hidden execution order, deleted cells, and stale kernel state.

**[Copy-paste ready version](../../install/run-notebooks-top-to-bottom.md)** — just the instruction block, no explanation.

## The Problem

A Jupyter kernel remembers everything: variables from cells you edited, variables from cells you deleted, the old definition of a function you've since rewritten. An AI assistant iterating in a notebook exploits this constantly — it patches cell 14, re-runs it against state produced by an earlier version of cell 6, sees a good number, and declares the task done. The notebook on disk now describes a computation that has never actually been executed. The execution counts read `[3] [17] [4] [12]`, and the plot everyone screenshots came from a kernel whose state no longer corresponds to any runnable sequence of cells.

The bill arrives at reproduction time. A colleague (or the same assistant, tomorrow) runs Restart & Run All and gets a `NameError` on cell 5, or worse, no error and different numbers — because `df` used to be the filtered version when the model cell last ran, and now it isn't. The "final" metric in the saved notebook is an artifact of one specific afternoon's click history.

Assistants fall into this because incremental cell execution is fast and the feedback loop rewards it: the cell ran, the output looks right, why pay for a full re-run? Kernel state is invisible in the file, so nothing flags that the notebook and its outputs have diverged.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It makes the file the source of truth instead of the kernel.** Hidden state lives only in memory; requiring a clean run guarantees every reported output is derivable from the code that will actually be saved and shared.

2. **A top-to-bottom run is a falsifiable claim.** "It works" about a stateful kernel is unverifiable; "Restart & Run All completes with these outputs" is a check anyone can repeat, which is what makes the result a result.

3. **Banning variable reuse removes the silent rebinding channel.** Most order-dependence bugs travel through one name meaning two things; distinct names turn that bug into an immediate `NameError`.

4. **It catches divergence at commit time, not at handoff time** — the cheapest possible moment, while the author still remembers what the notebook was supposed to do.

## Origin

A quarterly analysis notebook produced a headline figure that the team's lead presented to executives. When an analyst reran it the following week for an updated cut, cell 5 raised a `NameError` on a variable whose defining cell had been deleted during cleanup; after reconstructing it, the headline figure moved by enough to change the recommendation. The original number had been computed against kernel state from a cell that no longer existed, and no one could ever determine exactly what that cell had contained.
