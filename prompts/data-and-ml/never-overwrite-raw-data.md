---
title: Never Overwrite Raw Data
slug: never-overwrite-raw-data
category: data-and-ml
tags: [universal, data]
works_with: all
severity: critical
one_liner: "Writing processed output over your source data destroys the only ground truth"
---

# Never Overwrite Raw Data

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents pipelines from saving cleaned or transformed output back over the raw input files they read from.

**[Copy-paste ready version](../../install/never-overwrite-raw-data.md)** — just the instruction block, no explanation.

## The Problem

The symmetric beauty of `df = pd.read_csv("data/users.csv")` ... clean, filter, transform ... `df.to_csv("data/users.csv")` is exactly what makes it lethal. The assistant reads a file, improves it, and writes it back to the same name because that's the tidy thing to do — one file, always current. The first run replaces the raw data with a lossy derivative: rows dropped, columns coerced, strings normalized, free text mangled by an encoding round-trip. There is no undo. The original bytes are gone.

The damage is usually discovered on the second run, or the second question. The dedup logic had a bug? You'd fix it and rerun — except the input is now the deduplicated output, and the "duplicates" (some of which were legitimate repeat events) no longer exist anywhere. A stakeholder asks for a cut that needs a column the cleaning step dropped? That column is gone from the only copy. Worse, in-place pipelines aren't idempotent: each rerun re-applies transformations to already-transformed data, compounding the corruption quietly.

Assistants do this because overwriting reads as housekeeping, the run succeeds, and the cost is invisible until someone needs the original — which is always later.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Overwrite Raw Data

NEVER write processed output to the path you read input from. Raw data is the only ground truth; every transformation must produce a new artifact, leaving the source byte-for-byte intact.

- Wrong: `df = pd.read_csv(p); ...; df.to_csv(p)`. Right: read from `data/raw/`, write to `data/processed/` (or a versioned/staged equivalent). Input and output paths must differ, structurally, in every pipeline step.
- Treat `data/raw/` as immutable. Nothing in the codebase writes there except the original ingestion. Enforce it where you can: filesystem permissions (`chmod -R a-w data/raw/`), object-store write protection, or an assert in shared save helpers that refuses paths under the raw root.
- Pipelines must be re-runnable from raw: raw in, derived out, every time. If a step can only run once because it consumes its own input, it's destructive by design — restructure it.
- The same rule applies in memory and in databases: don't mutate the one loaded copy of the source and then persist it; don't `UPDATE`/`DELETE` the ingestion table in place — write cleaned data to a new table or layer.
- If disk space genuinely forbids keeping both, that's a decision for the user, made explicitly with a stated retention plan — never a default you choose silently.
- Filename versioning (`users_v2.csv`) beats overwriting, but directory-stage separation (`raw/` → `interim/` → `processed/`) beats both.

**Red flags that you're about to violate this:**

- "I'll save it back to the same file so there's one source of truth..."
- "Keeping both copies wastes disk..."
- "The cleaning is correct, we won't need the original..."
- "It's simpler if the path doesn't change..."
- "I'll overwrite just this once and re-download if anything goes wrong..."

---

## Why It Works

1. **It preserves the ability to fix bugs retroactively.** Every cleaning step eventually turns out to be wrong somewhere; raw-in/derived-out means a bug fix is a rerun, while in-place overwrite makes the bug permanent.

2. **It makes pipelines idempotent.** When input and output are distinct, running twice gives the same result as running once; in-place pipelines re-transform their own output and corrupt compoundingly.

3. **Immutability enforced by the filesystem outlasts discipline.** A write-protected raw directory stops the 2 a.m. shortcut that a convention merely discourages.

4. **It keeps every past and future question answerable.** Derived data encodes today's assumptions about what's worth keeping; the raw copy is the only artifact that can answer questions nobody has asked yet.

## Origin

A churn analysis pipeline wrote its deduplicated, outlier-trimmed DataFrame back over the raw export it had loaded. Months later the team discovered the "outliers" it trimmed were the enterprise accounts — the most valuable customers, removed as statistical noise — but those rows existed nowhere anymore, and the upstream system retained only ninety days. The fix wasn't a code change; it was an apology and a permanent asterisk on a year of churn numbers.
