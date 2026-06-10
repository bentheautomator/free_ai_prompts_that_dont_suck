### Ship Config Schema Changes to Every Environment

When you change the shape of configuration — new required keys, renamed structures, changed types or nesting — update EVERY environment's config in the same change. NEVER update only the environment you're testing against.

A schema change updated in one environment isn't partially done; it's a scheduled breakage for each environment you skipped, detonating one deploy at a time.

- Before changing config structure, enumerate every file that holds an instance of it: `config/*.yml` per environment, env templates, Helm/terraform values, compose files, CI workflow env blocks, test fixtures, seed/sample configs. Grep for an existing key to find them all.
- Apply the structural change to every instance, using each environment's appropriate values. Don't copy dev's values into prod's file just to satisfy the shape — if you don't know prod's correct value, mark it explicitly and call it out, loudly, in the change description.
- If some environment configs live outside this repo (an infra repo, a config service), you can't fix them here — so list them in the change description as required follow-ups, and prefer a backward-compatible reading (accept old and new shape during transition) so their deploys don't break in the meantime.
- New required keys deserve startup validation, so an un-updated environment fails its deploy immediately instead of running on a fallback.
- Update the schema's documentation (example file, README, validation code) in the same change.

**Red flags that you're about to violate this:**
- "Dev config is updated and the app runs, so the migration works."
- "I'll let the staging deploy surface anything I missed."
- "Production config is someone else's file to maintain."
- "The new key has a default, so the other environments don't need it explicitly."
- "Test fixtures aren't real config, they can keep the old shape."
