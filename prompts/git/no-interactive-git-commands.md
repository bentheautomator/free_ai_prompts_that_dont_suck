---
title: No Interactive Git Commands
slug: no-interactive-git-commands
category: git
tags: [universal, git]
works_with: all
severity: high
one_liner: "Stops rebase -i and add -p from hanging or half-executing in agents"
---

# No Interactive Git Commands

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from launching editor-driven git commands it cannot drive, leaving the repo hung mid-operation or mangled by an improvised workaround.

**[Copy-paste ready version](../../install/no-interactive-git-commands.md)** — just the instruction block, no explanation.

## The Problem

`git rebase -i` opens an editor and waits for a human. An AI assistant running in a non-interactive shell has no human and usually no editor — so the command hangs until a timeout, exits via whatever `$EDITOR` resolves to, or "succeeds" with an untouched todo list, silently doing nothing the AI thinks it did. The same goes for `git add -i`, `git add -p` without scripted input, and any commit or merge that pops an editor for a message. The AI then misreads the wreckage: it may believe the rebase happened, or find the repo stuck mid-rebase and start "fixing" with resets.

The workarounds assistants improvise are worse than the hang — piping `yes` into prompts, setting `EDITOR=true` so the editor "succeeds" instantly (accepting whatever default content was there), or killing the process and leaving `.git/rebase-merge` behind. Every interactive git operation has a scriptable equivalent; the failure is reaching for the keyboard-driven one in an environment with no keyboard.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Interactive Git Commands

NEVER run git commands that open an editor or expect interactive keyboard input. In a non-interactive environment they hang, no-op silently, or leave the repo stuck mid-operation. Use the scriptable equivalent.

- Banned: `git rebase -i`, `git add -i`, `git add -p` (without programmatic input), `git commit` with no `-m`, `git merge` without `-m` when it would prompt, `git commit --amend` without `--no-edit` or `-m`.
- Substitutes:
  - Commit message: `git commit -m "subject" -m "body"`.
  - Amend keeping the message: `git commit --amend --no-edit`.
  - Squash the last N local commits: `git reset --soft HEAD~N && git commit -m "..."`.
  - Autosquash without an editor: `git commit --fixup <sha>`, then `GIT_SEQUENCE_EDITOR=true git rebase --autosquash <base>` (the `true` editor accepts the generated todo unchanged; use it only for autosquash, where the default todo is the intent).
  - Partial staging: stage by file, or split the work at the edit level instead of the hunk level.
- If you find a repo stuck mid-operation (a `.git/rebase-merge` or `.git/MERGE_HEAD` exists), do not improvise: `git rebase --abort` / `git merge --abort` returns to the pre-operation state.
- Never set `EDITOR` or `GIT_EDITOR` to a no-op as a general technique for surviving prompts you didn't anticipate.

**Red flags that you're about to violate this:**

- "rebase -i is the standard way to squash; it'll probably work here."
- "I'll set EDITOR=true so git stops asking questions."
- "The command returned, so the rebase must have happened."
- "I can pipe input into the editor prompt somehow."
- "The interactive flow is cleaner; the environment will cope."

---

## Why It Works

1. **It maps each interactive habit to a drop-in replacement.** The AI reaches for `rebase -i` because it's the canonical answer; giving the `reset --soft` and `--fixup` equivalents means the canonical answer is no longer the only retrieved one.
2. **"The command returned, so it worked" is named as the trap** — the silent no-op (editor exits 0, todo unread) is this failure's worst variant precisely because nothing looks wrong, and the rule pre-loads suspicion of it.
3. **The stuck-state protocol (`--abort`, not improvisation) caps the blast radius** of any interactive command that slips through, converting a compounding failure into a clean rollback.

## Origin

Asked to squash five commits before review, an assistant ran `git rebase -i HEAD~5` in a headless shell. The configured editor exited immediately with the todo unmodified, the rebase "completed" having changed nothing, and the assistant — trusting the exit code — reported the squash done. The unsquashed branch was merged as-is, and the discrepancy surfaced a week later when someone tried to revert "the commit" and found five.
