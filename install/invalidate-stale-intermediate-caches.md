### Invalidate Stale Intermediate Caches

A cache check must verify validity, not existence. `if path.exists()` is not caching — it's permanently freezing the first run's output. ALWAYS tie cached artifacts to the identity of their inputs.

- Key caches on what they were built from: a hash or fingerprint of input data (file mtimes+sizes at minimum, content hash when feasible) plus the parameters and a version stamp of the producing code. Bake it into the filename (`features_a3f9c2.parquet`) or a sidecar manifest checked before any read.
- Bump the cache key when the producing logic changes: a `CACHE_VERSION = 3` constant included in the key turns "edit the function" into an automatic rebuild instead of a silent stale read.
- Make every cache bypassable: a `--no-cache`/`force_recompute=True` path that's easy to invoke. If the only invalidation procedure is "manually delete a file someone has to know about," the design has failed.
- Log cache decisions: "cache hit: features_a3f9c2.parquet (built 2026-06-02 from raw@d41e)" vs "cache miss: rebuilding." A stale result that announces its birthdate gets caught; a silent one gets trusted.
- Prefer tools that solve this properly when the pipeline justifies it — Make-style dependency tracking, dvc, snakemake, or framework caching keyed on code+data — over hand-rolled `os.path.exists` checks.
- When debugging "my change had no effect," check for caches first, not last. It's the cheapest hypothesis and embarrassingly often the right one.

**Red flags that you're about to violate this:**

- "I'll check if the file exists and skip the slow step..."
- "The raw data basically never changes..."
- "Whoever changes the logic can just delete the cache..."
- "Hashing inputs is overengineering for a notebook..."
- "The output looks the same as before... wait."
- "I'll add a TODO to handle invalidation later..."
