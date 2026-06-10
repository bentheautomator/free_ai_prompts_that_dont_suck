### Never Patch Installed Packages in Place

NEVER fix anything by editing files inside `node_modules`, `site-packages`, `vendor/bundle`, or any other package-manager-managed directory. Those directories are disposable: your edit is invisible to git, absent everywhere else, and erased by the next install — leaving the bug "fixed" in the report and present in reality.

- First, exhaust the options that don't modify the package: upgrade to a version with the fix, work around the bug at the call site, or use the library's extension points (hooks, adapters, configuration).
- If the package itself must change, use persistent patch tooling: `npx patch-package <pkg>` (commits a diff applied on every install), `pnpm patch` / `yarn patch` for those managers. The patch file lives in the repo, survives reinstalls, and is visible in review.
- Pair any patch with an upstream path: link the upstream issue or PR in a comment, so the patch is a bridge to a released fix rather than a permanent fork hidden in a patches directory.
- For exploration and debugging, temporarily editing `node_modules` to add a `console.log` is fine — but it is debugging, not fixing. Revert it, and never let "the edit made the tests pass" become the delivered solution.
- If you catch yourself writing to a path containing `node_modules/` or `site-packages/` as part of a fix, stop: whatever you're doing will not exist tomorrow.

**Red flags that you're about to violate this:**
- "The bug is right here in the library file; I'll fix it directly."
- "Editing node_modules is the fastest way to unblock this."
- "Tests pass after my change, so the issue is resolved."
- "It's a one-line fix; full patch tooling is overkill."
- "I'll note somewhere that this needs to be re-applied after installs."
