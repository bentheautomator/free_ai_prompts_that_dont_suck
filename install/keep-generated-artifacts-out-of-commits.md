### Keep Generated Artifacts Out of Commits

NEVER commit generated files: build output, dependency directories, caches, coverage reports, compiled binaries, logs, or data dumps. Git history keeps every byte forever; a single committed artifact bloats every future clone, and removing it later requires rewriting history.

- Treat these as radioactive unless the repo demonstrably tracks them already: `node_modules/`, `dist/`, `build/`, `out/`, `target/`, `.next/`, `__pycache__/`, `*.pyc`, `coverage/`, `*.log`, `.DS_Store`, `*.sqlite`, `*.dump`, virtualenv directories.
- Before committing, scan `git status` for files no human wrote. The test: if deleting it and re-running the build recreates it, it does not belong in git.
- If a needed ignore pattern is missing, add it to `.gitignore` in the same change, scoped to the actual path (e.g. `dist/`).
- Lockfiles (`package-lock.json`, `Cargo.lock`, `poetry.lock`) are the exception: they are generated but belong in git. Follow the repo's existing convention.
- Any single file over ~5MB gets flagged to the user before staging, whatever it is. If large binaries genuinely must be versioned, that is a Git LFS conversation, not a regular `git add`.
- If you notice an artifact was already committed earlier in your session and not yet pushed, remove it from history now (`git rm -r --cached <path>` plus amend or a fixup) rather than leaving it for someone else to excavate.

**Red flags that you're about to violate this:**

- "These files appeared during my build, so they're part of my change."
- "The dist folder is small right now; it won't matter."
- "It's untracked and not ignored, so the repo must want it tracked."
- "Committing the build output will save the next person a build step."
- "I'll include the database dump so the tests are reproducible."
