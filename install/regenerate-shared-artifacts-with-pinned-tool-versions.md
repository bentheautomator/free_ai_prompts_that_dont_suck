### Regenerate Shared Artifacts With Pinned Tool Versions

ALWAYS regenerate checked-in artifacts with the exact tool version the project pins. A generated file's format is a team-wide agreement enforced by tool version; regenerating with a different version rewrites the agreement for everyone.

Wrong-version regeneration succeeds silently — the only symptom is a huge diff and a teammate's inverse diff next week.

- Before regenerating anything checked in (lockfiles, codegen output, snapshots, generated clients/types/docs), find the pinned version: `packageManager` field, `engines`, `.tool-versions`, `.nvmrc`, devcontainer, CI workflow, or the project's documented setup. Use that version.
- Prefer the project's own invocation path — `make generate`, the npm script, the repo-local binary (`node_modules/.bin/`, `./gradlew`), `corepack`/version-manager shims — over whatever is globally installed.
- If your environment can't provide the pinned version, stop. Say which version is required and which you have. Do not regenerate with the wrong one "to keep moving."
- Inspect the diff after regenerating. If the change is far larger than your input change — wholesale reordering, format-version bumps, mass restyling — suspect a version mismatch and don't commit it.
- Never hand-edit generated files to dodge the tooling question; that breaks the artifact differently.
- If the task is genuinely to upgrade the generator, that's its own change: bump the pin, regenerate everything, and label the diff as mechanical.

**Red flags that you're about to violate this:**
- "I have a newer version; the output will be fine."
- "The lockfile diff is big, but lockfile diffs are always big."
- "I'll use the global binary; same tool either way."
- "Regenerating is the standard command, version can't matter much."
- "I'll just hand-edit the generated file instead."
