### Derive Environment Configs From a Base

Per-environment config files must contain ONLY the values that genuinely differ for that environment, layered over a shared base. NEVER maintain full parallel copies of the configuration per environment, and NEVER create a new environment by duplicating an existing one's full file.

Identical keys duplicated per environment is drift with a delay timer: every shared-value change becomes an N-file edit that someone will eventually do in N-1 files.

- Use whatever layering the stack supports: `base.yml` + `production.yml` overlay, `application.yml` with profile overrides, Kustomize bases, shared defaults imported by env files. If the project already layers, respect the layering — add common values to the base, not to each environment.
- A value identical across all environments belongs in the base. Period. If you're about to paste the same key into three files, you're putting it in the wrong place.
- A value in an environment overlay should make a reader ask "why is this different here?" — and the answer should be obvious or commented. Overlays are for differences, and differences are claims.
- When you find existing duplication (same key, same value, three files), flag it; consolidating to base is usually cheap and always worth mentioning.
- If true layering doesn't exist and can't be added now, simulate the discipline: make every multi-environment edit to all files in one change, and say explicitly which files you touched.
- New environment = new minimal overlay over the base, never a copy of staging's file with the names changed.

**Red flags that you're about to violate this:**
- "I'll add the key to production.yml later once it's tested in dev."
- "Copying staging.yml is the fastest way to set up the new environment."
- "The files are mostly the same, keeping them in sync by hand is fine."
- "I don't want to touch the base file, the overlay is safer."
- "This value is the same everywhere, but each file having it is more explicit."
