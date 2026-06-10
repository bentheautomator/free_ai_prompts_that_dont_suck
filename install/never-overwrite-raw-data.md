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
