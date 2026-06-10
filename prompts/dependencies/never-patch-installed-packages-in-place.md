---
title: Never Patch Installed Packages in Place
slug: never-patch-installed-packages-in-place
category: dependencies
tags: [universal, dependencies]
works_with: all
severity: high
one_liner: "Stops editing files inside node_modules, where fixes vanish on the next install"
---

# Never Patch Installed Packages in Place

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from fixing bugs by editing installed package files that the next install silently reverts.

**[Copy-paste ready version](../../install/never-patch-installed-packages-in-place.md)** — just the instruction block, no explanation.

## The Problem

A bug traces into a dependency, and the AI assistant does what it does with any bug it can see: it edits the file. The file happens to live in `node_modules/some-lib/dist/index.js`, or `site-packages/somelib/core.py`, but it's text and the assistant can write to it, so the fix goes in, the tests pass, and the task is reported complete. Truthfully, even — the bug is fixed, on this machine, until the next `npm install`.

Installed package directories are disposable by design. They're gitignored, rebuilt from the lockfile on every fresh clone and CI run, and wiped by routine cache and dependency operations. An edit there is invisible to version control, absent from every other environment, and silently destroyed by the next install — at which point the bug returns, except now there's a passing test run and a "fixed" report in the history saying it can't be there. Debugging a bug that was fixed is significantly worse than debugging a bug, because the first hypothesis everyone rules out is the true one.

Assistants make this mistake because nothing distinguishes the editable surface from the ephemeral one — `node_modules` files open like any others. The legitimate tooling for this exact need (patch-package, pnpm patch, yarn patch) exists precisely because editing in place is so tempting and so useless.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It marks the territory as ephemeral.** The AI's file-editing instinct doesn't distinguish durable files from regenerated ones; declaring package directories disposable creates the missing boundary.
2. **It names the specific delayed harm** — a bug that returns *after* being reported fixed — which is worse than no fix and explains why "tests pass now" is insufficient.
3. **It channels the impulse into tooling built for it.** patch-package and `pnpm patch` give the AI a way to do the exact thing it wanted, persistently and reviewably, so the rule redirects rather than blocks.
4. **It carves out debugging edits explicitly**, preventing the overcorrection where the AI refuses to even instrument a library while investigating — while making clear the instrumentation is never the deliverable.

## Origin

An assistant fixed a timezone bug by editing two lines inside `node_modules` in a date library's compiled output, ran the suite, and closed the task as fixed. It was — for nine days, until a teammate's routine dependency install rebuilt `node_modules` and the bug returned. Because the fix was on record, the regression was investigated as a new bug with a different cause, burning two days before someone diffed the library file against the registry tarball and found the missing edit. The patch-package version of the same fix took ten minutes and survived every install since.
