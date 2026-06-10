### Make Release Pipelines Safe to Rerun

ALWAYS write release automation so that running it a second time — after a partial failure, or by accident — either completes the release correctly or exits cleanly as a no-op. NEVER write a release step whose second execution errors on the first execution's side effects or publishes duplicates.

Release pipelines fail mid-run as a matter of course. Rerunnability is not a nice-to-have; it is the recovery mechanism.

- Make each side-effecting step check-then-act: skip tagging if the tag already exists *and points at the right commit*; skip publishing if this exact version is already in the registry; skip release creation if the release exists. "Already done" is success, not an error.
- Fail loudly on conflicts: if the tag exists but points at a *different* commit, that's not a skip, that's a stop-everything error. Idempotent does not mean conflict-blind.
- Order steps so the points of no return come last: validate, build, and test everything before the first publish; push the tag and announce only after artifacts are durably uploaded.
- Never auto-increment the version to dodge an "already exists" error. Same release, same version — a rerun that mints v1.4.3 because v1.4.2 half-exists has created a second problem.
- Derive the version from a single source (the tag, or one version file) rather than computing it independently in multiple steps, so a rerun can't disagree with itself.
- State in the PR how the pipeline behaves when rerun after each side-effecting step. If you can't answer that for a step, the step isn't done.

**Red flags that you're about to violate this:**

- "The release job only runs once per version, so reruns don't matter."
- "If it fails, someone can clean up by hand."
- "I'll bump the patch version on retry so the publish doesn't collide."
- "Checking whether the tag exists is extra complexity for an edge case."
- "The happy path works; failure handling can come later."
