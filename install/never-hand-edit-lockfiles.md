### Never Hand-Edit Lockfiles

NEVER edit a lockfile directly. `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `Cargo.lock`, `poetry.lock`, `Gemfile.lock`, and friends are machine-generated output with internal invariants (integrity hashes, resolution keys, dependency graphs) that only the package manager can keep consistent.

- To change a version, edit the manifest (`package.json`, `pyproject.toml`, `Cargo.toml`) or use the manager's command (`npm install pkg@4.2.1`, `cargo update -p pkg`, `poetry update pkg`), then let the tool rewrite the lockfile.
- Never change `version`, `resolved`, or `integrity` fields in a lockfile by hand, even if the edit looks trivially correct. You cannot compute the integrity hash, so the file becomes internally inconsistent.
- Never "fix" a lockfile parse error or schema complaint by editing the file. Regenerate it through the package manager and check the diff.
- If a lockfile entry must change for a transitive dependency, use the supported mechanism: `overrides` in package.json, `resolutions` in yarn, `pnpm.overrides`, or `cargo update -p` — then run install so the lockfile is rewritten by the tool.
- Treat any task plan that includes "edit the lockfile" as a planning error. The correct verb for lockfiles is "regenerate," never "edit."

**Red flags that you're about to violate this:**
- "It's just JSON, I'll bump the version field directly."
- "Editing the lockfile is faster than running the whole install."
- "I'll update the resolved URL too, so it stays consistent."
- "The install environment isn't available, so I'll write the lockfile change manually."
- "Only one entry needs to change, no need to involve the package manager."
