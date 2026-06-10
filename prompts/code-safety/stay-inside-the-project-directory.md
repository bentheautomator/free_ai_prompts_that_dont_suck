---
title: Stay Inside the Project Directory
slug: stay-inside-the-project-directory
category: code-safety
tags: [universal, files]
works_with: all
severity: critical
one_liner: "AI modifying or deleting files outside the workspace it was asked to work in"
---

# Stay Inside the Project Directory

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from writing, modifying, or deleting anything outside the project it was asked to work on.

**[Copy-paste ready version](../../install/stay-inside-the-project-directory.md)** — just the instruction block, no explanation.

## The Problem

You ask the AI to fix a path issue in your build, and it "fixes" it by editing `~/.zshrc`. Or it resolves a dependency conflict by modifying a sibling repo two directories up, because that's where the offending package lived. Or its cleanup pass follows a `../` in a config file and deletes artifacts in a directory that belongs to a different project entirely. The user asked for work *on this project*; the AI made changes to *the machine*.

The boundary violation happens naturally: the AI follows the dependency graph wherever it leads, and the graph doesn't stop at the repo root. Shell profiles, global configs in `~/.config`, `/etc/hosts`, globally installed tools, sibling checkouts — they're all reachable, all writable, and all plausibly "related to the task." But files outside the project have no safety net. There's no version control to diff against, no review that will catch the change, and other software — and other projects — depend on them. A wrong edit inside the repo is a `git checkout` away from fixed. A wrong edit to a dotfile is a mystery the user debugs three weeks later.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Stay Inside the Project Directory

NEVER create, modify, or delete files outside the project directory without explicit permission. The task scope is the repo, not the machine.

The core problem: files outside the project — dotfiles, global configs, sibling repos, system paths — have no version control, no review, and other software depending on them. Mistakes there are invisible and unrevertable.

- Treat the project root as a hard write boundary. Reading outside it is fine; writing outside it requires asking first, every time.
- This includes the tempting cases: `~/.bashrc`/`~/.zshrc`, `~/.config/*`, `~/.gitconfig`, `/etc/*`, globally installed packages, and other repos checked out nearby.
- If the correct fix genuinely lives outside the project (a missing PATH entry, a global tool version), say so and show the exact change — let the user apply it or approve it.
- Watch for indirect escapes: scripts with `../` paths, symlinks pointing out of the tree, `$HOME` in variables, install commands with `-g`/`--global`. Resolve where a write will actually land before performing it.
- Never "fix" another project to make this one work. If a sibling repo is the problem, report it.
- When permission is granted to touch an outside file, back it up first (`cp ~/.zshrc ~/.zshrc.bak-$(date +%s)`) and show the diff after.

**Red flags that you're about to violate this:**
- "The real problem is in their shell profile, I'll just patch it..."
- "Adding one export to ~/.zshrc is harmless..."
- "The conflicting package is global, so I'll remove it globally..."
- "That sibling repo has the bug — quicker to fix it there directly..."
- "The config file is technically outside the repo but it's still 'the project'..."

---

## Why It Works

1. **It draws a line the AI can mechanically check.** "Be careful with important files" requires judgment; "resolve the write path, compare to repo root" is a computation. Bright lines beat vibes.

2. **It separates diagnosis from action.** The AI is often *right* that the fix is outside the project. Routing that case to "show the change, let the user apply it" preserves the insight while removing the unsupervised write.

3. **It enumerates the escape routes.** `../`, symlinks, `$HOME`, `--global` — most boundary violations are indirect. Naming them turns each into a checkpoint.

## Origin

Asked to make a CLI tool available in a project's scripts, an assistant appended a PATH export to the user's `~/.zshrc` — and, finding an "old" version of the tool, deleted a globally installed binary that two other projects on the machine depended on. The project worked. Everything else broke quietly, and the user spent an evening figuring out why builds failed in repos the assistant had never opened.
