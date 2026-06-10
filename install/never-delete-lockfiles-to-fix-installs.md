### Never Delete Lockfiles to Fix Installs

NEVER delete a lockfile (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `Cargo.lock`, `poetry.lock`, `Gemfile.lock`, `composer.lock`) to make an install error go away. Deleting it re-resolves every dependency in the project to new versions, which is a silent, unreviewed mass upgrade — not a fix.

- When an install fails, read the actual error. Resolution conflicts name the packages involved; fix those specific packages, not the whole tree.
- If the lockfile is genuinely corrupted or out of sync with the manifest, regenerate it with the package manager's intended command (`npm install` against the existing lockfile, `pnpm install --fix-lockfile`) and then diff the lockfile to confirm only the expected entries changed.
- If you must regenerate from scratch as a last resort, say so explicitly, explain why, and tell the user that every dependency version may have changed and the result needs full testing before merge.
- Never combine lockfile deletion with `rm -rf node_modules` as a reflex "clean slate" ritual. Clearing `node_modules` is fine; deleting the lockfile is the part that changes what gets installed.
- A lockfile-only diff with thousands of changed lines after fixing one package is a sign you did this. Stop and investigate.

**Red flags that you're about to violate this:**
- "The classic fix for this error is deleting the lockfile and reinstalling."
- "The lockfile is probably stale, regenerating it is harmless."
- "A fresh resolution will pick compatible versions automatically."
- "Stack Overflow's top answer says to remove package-lock.json."
- "It's just a lockfile, the real versions are in package.json."
