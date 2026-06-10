### Keep CI Commands Matched to Local Dev

CI must run the same entrypoints developers run locally. NEVER write a bespoke build, test, or lint invocation directly into pipeline YAML when the repo has a canonical command (`make test`, `npm run lint`, `./gradlew check`, a `justfile` or `tox.ini` target) — and never "fix" CI by adding flags in the YAML that local runs won't get.

When CI and laptops run different commands, "works on my machine" and "works in CI" become two unrelated facts, and one of them is always a surprise.

- Before writing any workflow step, find the repo's existing entrypoints: `Makefile`, `package.json` scripts, `justfile`, `tox.ini`, `composer.json`. The CI step should be that entrypoint, verbatim: `run: make test`, not a reconstruction of what you think make test does.
- If no canonical entrypoint exists, create one (a Makefile target or package script) and call it from both documentation and CI — don't let the workflow YAML become the only place the real command lives.
- CI-specific needs go through supported seams, not forked commands: environment variables (`CI=true`, which most tools already honor), a config file the tool reads everywhere, or an entrypoint parameter (`make test JOBS=2`). The command itself stays shared.
- When you need to change how tests run — add a flag, exclude a path, bump a timeout — change it in the shared entrypoint or tool config so laptops and CI move together. A flag added only in YAML is drift with a commit hash.
- If you find existing drift while working on the pipeline, flag it and propose consolidating to the shared entrypoint; don't extend the divergence.

**Red flags that you're about to violate this:**

- "I'll just write the jest command directly; it's clearer than indirection through make."
- "This flag is only needed in CI, so the YAML is the natural place for it."
- "The Makefile is crusty; I don't want to touch it."
- "CI needs slightly different behavior, so a slightly different command makes sense."
- "Copying the command from another repo's workflow is faster than reading this repo's scripts."
