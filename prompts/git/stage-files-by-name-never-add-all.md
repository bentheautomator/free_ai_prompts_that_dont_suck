---
title: Stage Files by Name, Never git add -A
slug: stage-files-by-name-never-add-all
category: git
tags: [universal, git]
works_with: all
severity: critical
one_liner: "Stops git add -A from sweeping secrets and junk into commits"
---

# Stage Files by Name, Never git add -A

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from staging everything in the working tree and committing your `.env`, debug scripts, and half-finished work along with the actual change.

**[Copy-paste ready version](../../install/stage-files-by-name-never-add-all.md)** — just the instruction block, no explanation.

## The Problem

Ask an AI assistant to commit its work and the first command out of it is `git add -A` or `git add .`. It edited three files, but your working tree also contains a `.env` with live credentials, a `node_modules` folder that escaped the gitignore, a `scratch.py` you were noodling on, and a 200MB database dump. All of it gets staged. All of it gets committed. If the AI also pushes, your API keys are now in a remote's history, which is a rotation incident, not an undo.

AI assistants do this because `git add -A` always succeeds and never requires knowing which files matter. Listing files by name requires actually tracking what was changed, and the lazy path is one flag. The assistant treats "commit my work" as "commit everything that exists," which is a completely different operation.

The damage is asymmetric: staging files by name costs five extra seconds; un-leaking a credential from pushed history costs an afternoon and a key rotation.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Stage Files by Name, Never git add -A

NEVER stage with `git add -A`, `git add .`, `git add --all`, or `git commit -a`. ALWAYS stage by explicit path: `git add src/auth.py tests/test_auth.py`.

Blanket staging commits everything in the working tree, including files you did not touch and files that must never enter history: credentials, local config, scratch files, build output.

- Before staging, run `git status` and read the output. Every file you stage must be one you deliberately changed for this task.
- Stage only the files you edited, by full path. If you edited many files, list them all; length is not an excuse for `-A`.
- If `git status` shows untracked files you did not create, leave them alone and mention them to the user.
- If `git status` shows files that look like secrets or local config (`.env`, `*.pem`, `credentials*`, `*.key`, `settings.local.*`), never stage them, even if asked vaguely to "commit everything." Name them and ask.
- After staging, run `git diff --cached --stat` and confirm the file list matches what you intended before committing.

**Red flags that you're about to violate this:**

- "There are a lot of changed files, `git add -A` is simpler."
- "The user said commit everything, so everything means everything."
- "These untracked files are probably fine to include."
- "I'll just stage it all and the gitignore will filter out the bad stuff."
- "I don't have time to figure out which files I actually changed."

---

## Why It Works

1. **It removes the loophole in "commit my work."** The AI reads that phrase as "commit the working tree." The rule redefines the unit of staging as *files you deliberately changed*, which makes blanket flags definitionally wrong rather than merely risky.
2. **The `git diff --cached --stat` checkpoint forces verification at the last safe moment.** Once the file list is printed, an unexpected `.env` in it is impossible to not notice; before that, it's invisible inside a single flag.
3. **Naming the rationalizations ("there are a lot of files") defuses the exact thought** that precedes the flag. The AI recognizes its own reasoning and stops.

## Origin

A developer asked their assistant to "commit and push the login fix." The fix touched two files; the working tree also held a `.env` with production Stripe keys, freshly untracked because a teammate had reorganized the gitignore that morning. The assistant ran `git add -A`, committed, and pushed. The keys were rotated within the hour, but the cleanup, including a forced history rewrite on a shared branch, ate the rest of the day.
