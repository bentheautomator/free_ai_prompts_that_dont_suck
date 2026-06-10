### Regenerate Lockfiles to Resolve Merge Conflicts

NEVER resolve a lockfile merge conflict by choosing hunks like source code. A lockfile is resolver output: the only valid post-merge lockfile is one the package manager generated from the merged manifest, not one assembled from pieces of two different resolutions.

- Resolve the manifest first. `package.json` (or `pyproject.toml`, `Cargo.toml`) conflicts are real merge decisions — combine both branches' dependency changes there, by hand, correctly.
- Then regenerate, don't merge, the lockfile. npm: run `npm install` with the conflicted lockfile present — npm detects the markers and rebuilds correctly from the merged package.json. Equivalent flow for pnpm/yarn. Cargo/poetry: checkout one side's lockfile (or delete it as the documented conflict procedure for that tool prescribes) and re-run the lock step so the tool rewrites it from the merged manifest.
- Never delete conflict markers from a lockfile manually and commit what remains — even if the result parses, no resolver has verified it.
- Validate before committing: a clean `npm ci` / `pnpm install --frozen-lockfile` run proves manifest and regenerated lockfile agree. If it fails, the manifest merge is wrong — fix that, regenerate again.
- Check the regenerated lockfile's diff covers both branches' intents: the package your branch added and the ones the other branch changed should all be present. A regeneration that silently dropped one side means the manifest merge dropped it first.

**Red flags that you're about to violate this:**
- "Conflict markers — I'll take ours for these hunks and theirs for those."
- "Both sides just added different packages, so I'll keep both blocks."
- "The merged file is valid JSON, so the conflict is resolved."
- "Hand-merging is faster than re-running the whole install."
- "Lockfile conflicts are mechanical; no need to involve the package manager."
