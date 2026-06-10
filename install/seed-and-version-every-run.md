### Seed and Version Every Run

Every experiment must be re-runnable to the same result. ALWAYS pin the three things that vary: randomness, data, and configuration — before trusting or reporting any number.

- Set seeds explicitly everywhere randomness enters: `random_state=SEED` in every `train_test_split`, model constructor, and CV splitter; `np.random.seed(SEED)`; framework seeds (`torch.manual_seed`, `tf.random.set_seed`) where applicable. Define `SEED` once at the top, not scattered literals.
- Seeds are for reproducibility, not performance. Never tune the seed; if results swing meaningfully across seeds, that variance is a finding to report (see multi-run averaging), not a dial to turn.
- Pin the data identity, not just the filename. Record a content hash, snapshot path, or data-version tag (DVC, lakeFS, a dated immutable copy) alongside results. `data.csv` is a name, not a version.
- Record the run's configuration with its result: hyperparameters, code commit, data hash, seed — as a logged dict, a JSON sidecar next to the metrics, or an experiment tracker entry. A metric without its config is unfalsifiable.
- Outputs should never silently overwrite previous outputs: write models and metrics to run-specific paths (`runs/2026-06-10_a1b2c3/`) so history survives.
- Note known nondeterminism you can't remove (GPU atomics, multithreaded data loading) so a small wobble on rerun isn't misread as a code change.

**Red flags that you're about to violate this:**

- "It's a quick experiment, seeding is ceremony..."
- "The split is random but it'll be roughly the same every time..."
- "I'll remember which CSV this was..."
- "I'll add tracking once the model actually works..."
- "The number moved on rerun, but it's probably fine..."
- "Let me try a different seed, that one was unlucky..."
