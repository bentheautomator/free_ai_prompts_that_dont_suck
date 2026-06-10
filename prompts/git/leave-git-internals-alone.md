---
title: Leave .git Internals Alone
slug: leave-git-internals-alone
category: git
tags: [universal, git, recovery]
works_with: all
severity: critical
one_liner: "Stops hand-edits and deletions inside the .git directory"
---

# Leave .git Internals Alone

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from "repairing" a repository by directly editing or deleting files inside `.git`, turning a recoverable hiccup into actual corruption.

**[Copy-paste ready version](../../install/leave-git-internals-alone.md)** — just the instruction block, no explanation.

## The Problem

When git misbehaves, some AI assistants go under the hood: deleting `.git/index` because the staging area "seems corrupt," hand-editing `.git/config` or `packed-refs`, removing files from `.git/refs/`, or — the genuinely catastrophic one — deleting `.git` entirely to "reset git while keeping the files." The `.git` directory is a database with internal consistency requirements (the index, refs, packed-refs, and object store reference each other), and surgical edits by something that doesn't hold the full model tend to convert a confused-but-healthy repo into a genuinely damaged one. Deleting `.git` outright destroys every commit, branch, stash, and piece of history that wasn't pushed — permanently, with no reflog, because the reflog was inside it.

The pull toward internals comes from a generic debugging instinct — when the tool misbehaves, inspect its state files — applied to a tool whose state files have a porcelain layer specifically so nobody has to touch them. Nearly every legitimate "internals" fix has a porcelain command: stale lock removal aside, there is essentially no repo problem whose best fix starts with editing a file under `.git` by hand.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Leave .git Internals Alone

NEVER manually edit, delete, or create files inside the `.git` directory. It is a database with internal consistency rules; hand modifications corrupt it. Above all, NEVER delete the `.git` directory itself — that permanently destroys all history, branches, stashes, and the reflog for anything unpushed.

Use porcelain commands for everything:

- Config changes: `git config <key> <value>`, never editing `.git/config` directly.
- Refs and branches: `git branch`, `git update-ref`, `git symbolic-ref` — never touching `.git/refs/` or `packed-refs` by hand.
- A "corrupt" index: `git read-tree HEAD` or at most removing `.git/index` is folk wisdom; before anything like it, try `git status` in a fresh shell, then report. Do not delete index, HEAD, or any state file as a debugging move.
- The one narrow exception: a stale `.git/index.lock` may be removed, but only after verifying no git process is running (`ps aux | grep git`) and saying you're doing it. Nothing else in `.git` qualifies for this treatment.
- In-progress operation state (`MERGE_HEAD`, `rebase-merge/`, `CHERRY_PICK_HEAD`) is cleared with the operation's `--abort`/`--continue`, never by deleting the files.
- If you suspect real corruption (`git fsck` errors, "bad object" messages), stop, run `git fsck` for the report, and bring the output to the user. Repository surgery is a human decision made with backups, not an autonomous fix.

**Red flags that you're about to violate this:**

- "The index seems corrupted; deleting .git/index should rebuild it."
- "I'll just edit .git/config directly; it's a plain text file."
- "Removing this ref file is faster than figuring out the command."
- "Deleting .git resets the repo but keeps all the code."
- "I saw this fix on a forum: rm a couple of files under .git."

---

## Why It Works

1. **The database framing replaces the text-files framing.** `.git` contents look like editable config and state, which invites hand-fixes; "interlinked database" correctly predicts that partial edits corrupt, and makes the porcelain layer feel mandatory rather than ceremonial.
2. **It singles out the catastrophic move by name.** "Delete .git but keep the files" sounds *conservative* to an AI — the code survives! — so the rule explicitly prices it: all history, all branches, all stashes, the reflog itself.
3. **Granting the one legitimate exception (stale index.lock) with conditions** keeps the rule credible; absolute rules with a known-good counterexample get dismissed wholesale, while a rule that names its exception holds everywhere else.

## Origin

A repo threw a "bad object" error after a crashed process. The assistant diagnosed "git database corruption" and treated it by deleting `.git` so the project could "start fresh with clean version control" — on a machine holding two unpushed branches and a month of reflog. The original error had been a truncated pack file that `git fsck` plus refetching from the remote would have repaired in minutes. Instead, the remote's three-week-old state became the only history that existed anywhere.
