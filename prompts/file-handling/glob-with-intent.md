---
title: Glob with Intent
slug: glob-with-intent
category: file-handling
tags: [universal, files, shell]
works_with: all
severity: medium
one_liner: "Stops globs that silently skip dotfiles or sweep in vendored junk"
---

# Glob with Intent

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents glob patterns that quietly miss dotfiles or match far more than intended, so bulk operations hit exactly the set of files you meant.

**[Copy-paste ready version](../../install/glob-with-intent.md)** — just the instruction block, no explanation.

## The Problem

A glob is a query whose result set nobody inspects. `*` famously excludes dotfiles, so `cp src/* dest/` silently drops `.env.example`, `.eslintrc`, and `.github/` — a "complete" copy missing the configuration that made it work, discovered only when the copy misbehaves somewhere downstream. The other direction is overmatch: `**/*.js` cheerfully includes `node_modules/` (forty thousand files), `dist/`, and `coverage/`, so the "format all our JS" command rewrites vendored code, the lint run takes twenty minutes, or the search-and-replace edits a dependency's internals — changes that get blown away on the next `npm install` or, worse, committed.

Recursive-flag mismatches compound it: `grep -r pattern *` skips dotfiles at the top level, `mv * ../` leaves hidden files behind in a "moved" directory. Glob behavior also differs by shell and library (bash needs `dotglob`; some libraries' `**` doesn't recurse without a flag), so a pattern correct in one context lies in another. Assistants write globs from intent, never look at the file list the glob actually produced, and feed that unexamined list to a bulk operation.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Glob with Intent

ALWAYS know what a glob excludes and includes before acting on its matches. `*` skips dotfiles; `**` includes `node_modules`. Both defaults are wrong for half the things people use them for.

A glob feeding a bulk operation is a query you never reviewed; preview the result set before mutating it.

- Moving or copying "everything"? `*` misses dotfiles. Use the directory itself as the unit (`cp -a src/. dest/`, `mv src dest`, `rsync -a src/ dest/`), or enable `shopt -s dotglob` deliberately.
- Recursing over a repo? Exclude the standing junk: `node_modules`, `.git`, `dist`, `build`, `vendor`, `coverage`, `__pycache__`, `.venv`. Prefer tools that respect `.gitignore` by default (`rg`, `fd`, `git ls-files`) over raw `find`/`grep -r`.
- Before a destructive or bulk-mutating command, preview the match list: `echo <glob>`, `ls -d <glob>`, or run the `find` without `-exec` first. Count it; if "all our source files" comes back as 48,000, your glob found the dependency tree.
- A glob with zero matches passes itself through literally in some shells (a file named `*.bak` is not what you want to operate on). Use `nullglob` in scripts, or check the match count.
- Character ranges and brace expansions deserve a test: `[A-z]` matches punctuation; `{a,b}` is brace expansion, not a glob, and behaves differently in `find -name`.
- In code, know your library's flags: Python `glob` needs `recursive=True` for `**`; many JS globbers need `dot: true` for dotfiles.

**Red flags that you're about to violate this:**

- "Star means everything." (It means everything visible.)
- "I'll run the replace across **/*.ts — that's our source." (And your node_modules.)
- "No need to preview; the pattern is obviously right."
- "The copy succeeded, so everything came across."
- "grep -r * covers the whole tree." (Minus every dotfile and dot-directory at the top.)

---

## Why It Works

1. **It names the two specific lies globs tell** — `*` under-matches dotfiles, `**` over-matches vendored trees — so the assistant checks for the failure it's actually about to have rather than vaguely "being careful."
2. **Previewing converts the glob from write-only to reviewable:** an `echo` costs nothing, and a match count is an instant sanity oracle (8 files vs 48,000).
3. **Directory-as-unit operations sidestep the dotfile problem entirely** — `cp -a src/. dest/` has no expansion step to get wrong, which beats remembering `dotglob` every time.

## Origin

A migration script "moved" a service's config directory with `mv old/* new/` and reported success. The hidden `.credentials/` subdirectory stayed behind and was destroyed two weeks later with the old tree's cleanup. The outage that followed traced back through three layers of "but the move succeeded" before someone listed the deleted directory from backup and noticed every missing path started with a dot.
