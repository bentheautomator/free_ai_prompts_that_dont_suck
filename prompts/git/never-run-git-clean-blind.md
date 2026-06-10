---
title: Never Run git clean Blind
slug: never-run-git-clean-blind
category: git
tags: [universal, git, recovery]
works_with: all
severity: critical
one_liner: "Stops git clean -fd from deleting untracked files sight unseen"
---

# Never Run git clean Blind

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from running `git clean -fd` without a dry run and deleting untracked files that were never anywhere but that disk.

**[Copy-paste ready version](../../install/never-run-git-clean-blind.md)** — just the instruction block, no explanation.

## The Problem

Untracked files are, by definition, files git has never stored. `git clean -fd` deletes them from disk — not from git, from *disk* — with no reflog, no stash, no recycle bin. That new module the user wrote this morning and hadn't added yet? The local `.env` holding their development credentials? The notes file? If `git clean` catches them, the only recovery is filesystem forensics or retyping.

AI assistants run it as part of "getting to a clean state," often chained after a `reset --hard`, usually because some build issue or stale artifact made the working tree feel untrustworthy. The flags escalate badly: `-d` adds directories, `-x` adds *ignored* files — which means local env files and editor configs — and assistants add flags until the command stops complaining. The command has a built-in safety, `--dry-run`, which costs nothing and shows exactly what will die. Assistants skip it because the dry run is an extra step and the command "works" without it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Run git clean Blind

NEVER run `git clean` without first running `git clean -n` (dry run) with identical flags and reading every line of its output. `git clean` deletes untracked files from disk; they exist nowhere in git, so there is no undo of any kind.

- Untracked files are frequently the user's newest work — files written today that haven't been added yet — plus local configs and secrets. "Untracked" does not mean "unwanted."
- Workflow, always in this order: `git clean -n -d` first; show the file list to the user or verify every single entry is something you created this session; only then run the real command, scoped to specific paths where possible (`git clean -f path/to/dir`).
- NEVER use `-x` or `-X`. They delete ignored files, which is where `.env` files, local overrides, and IDE state live. If an ignored file needs deleting, delete it by name with `rm`.
- Do not chain `git clean` after `git reset --hard` as a combo "fresh start." Each command needs its own justification and its own check.
- If the goal is removing build artifacts, prefer the build tool's own clean target (`make clean`, `npm run clean`, `cargo clean`); those know what they made.

**Red flags that you're about to violate this:**

- "A truly clean tree needs clean -fdx."
- "Untracked files are just leftovers; they're not in git for a reason."
- "The dry run is an extra step and I can guess what it'll show."
- "I'll do reset --hard plus clean -fd, the classic fresh-start combo."
- "Whatever it deletes can't be important or it would be committed."

---

## Why It Works

1. **It attacks the core false belief directly:** "not in git" reads to the AI as "not valuable," when untracked files are often the *most* recent work. Stating "untracked is frequently the newest work" inverts the prior that makes the command feel safe.
2. **The identical-flags dry run is a forcing function** — the AI cannot claim ignorance of what will be deleted after printing the exact list, and a `.env` in that list is unmissable.
3. **Banning `-x` outright removes the worst escalation** without requiring judgment; the legitimate uses of `-x` in assistant workflows round to zero.

## Origin

A build was failing on stale artifacts, and the assistant decided the working tree needed sterilizing: `git clean -fdx`. The `-x` swept the developer's `.env.local`, their untracked `docker-compose.override.yml`, and a prototype file created two hours earlier. The build did pass afterward. The developer spent the evening reconstructing credentials and the prototype from memory, and the `-x` flag is now banned in that team's assistant config — which is where this prompt comes from.
