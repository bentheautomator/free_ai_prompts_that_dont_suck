---
title: No Nested Git Repos
slug: no-nested-git-repos
category: git
tags: [universal, git]
works_with: all
severity: medium
one_liner: "Stops stray git init and clones from creating broken repos-in-repos"
---

# No Nested Git Repos

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from running `git init` or `git clone` inside an existing repository and creating accidental nested repos that commit as empty, broken gitlinks.

**[Copy-paste ready version](../../install/no-nested-git-repos.md)** — just the instruction block, no explanation.

## The Problem

An AI assistant scaffolds a new service inside a monorepo, and the scaffolding tool (or the assistant itself, "to be safe") runs `git init` in the subdirectory. Or it clones a reference project into the workspace to read its code. Either way, there's now a repository inside a repository, and git's behavior around that is a trap: the outer repo won't track the inner one's files at all. `git add` on the directory stages a single *gitlink* entry — a bare commit pointer, the mechanism submodules use, minus all the submodule configuration that makes it work. The commit succeeds, the push succeeds, and everyone who clones gets an empty directory where the new service should be.

The failure is silent at every step, which is why it ships. `git status` shows the directory as one untracked entry rather than hundreds of files — a tell, but only if something prompts the assistant to find one entry for a whole directory suspicious. Cleanup is also misunderstood in both directions: fixing it requires removing the inner `.git` directory (or the staged gitlink with `git rm --cached`), and assistants either don't, or "fix" the wrong layer by deleting actual code.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Nested Git Repos

NEVER run `git init` or `git clone` inside an existing repository's working tree without the user explicitly asking for a nested repo or submodule. A repo inside a repo doesn't get tracked; it gets committed as an empty pointer (a gitlink), and clones receive an empty directory.

- Before any `git init`, check where you are: `git rev-parse --show-toplevel`. If it prints a path, you are already inside a repository; initializing here creates a nested one.
- Scaffolding tools (project generators, `create-*` CLIs) often run `git init` themselves. After scaffolding inside an existing repo, check for and remove the stray inner repo: `find <new-dir> -maxdepth 2 -name .git`, then delete that `.git` directory (the code is untouched; only the inner repo metadata goes).
- Need to read another project's code? Clone it OUTSIDE the working tree (`/tmp` or a sibling directory), never into the repo.
- The status tell: a whole directory appearing as a single untracked entry, or staging it producing one `new file (mode 160000)` line instead of many files, means there's an inner `.git`. Stop and remove it before committing.
- If a gitlink already got committed, fix it explicitly: `git rm --cached <dir>` (one level, no `-r` needed for a gitlink), remove the inner `.git`, then `git add <dir>` to track the actual files.
- If the user genuinely wants an embedded repository, that's a submodule conversation (`git submodule add <url> <path>`), not a bare nested clone.

**Red flags that you're about to violate this:**

- "I'll git init the new package directory so it has version control."
- "Cloning the example repo into the project keeps everything together."
- "The generator ran git init, but that's probably harmless."
- "git status shows the directory, so its contents are being tracked."
- "Mode 160000 is just some permission thing."

---

## Why It Works

1. **The pre-init location check makes the invisible boundary visible.** Nested repos happen because nothing about `git init` reveals you're already inside one; `git rev-parse --show-toplevel` is the one-command boundary detector.
2. **Teaching the two tells (single entry for a directory, mode 160000) converts a silent failure into a detectable one** at staging time, the last cheap moment to fix it.
3. **It names scaffolding tools as the usual culprit**, which matters because the AI often didn't run `git init` itself and so won't suspect a nested repo exists unless told these tools create them.

## Origin

An assistant scaffolded a new microservice inside a monorepo using a generator that helpfully ran `git init`. The service directory was committed — as a gitlink — and pushed. CI cloned an empty directory and failed with a missing-module error that mentioned nothing about git. Two engineers debugged the build for an afternoon before one of them noticed the directory's diff was a single line: a mode 160000 pointer to a commit that existed only on the assistant's machine.
