---
title: Preserve Executable Bits and Permissions
slug: preserve-executable-bits
category: file-handling
tags: [universal, files, unix]
works_with: all
severity: high
one_liner: "Stops rewrites from silently dropping the executable bit off scripts"
---

# Preserve Executable Bits and Permissions

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents file rewrites from stripping the executable bit or otherwise resetting permissions, breaking hooks, scripts, and deploy steps.

**[Copy-paste ready version](../../install/preserve-executable-bits.md)** — just the instruction block, no explanation.

## The Problem

An AI assistant edits `deploy.sh` by writing a fresh file: delete-and-recreate, or write-to-temp-and-copy, or any path that creates a new inode with default permissions. The content is perfect. The mode is now `644`. The next `./deploy.sh` fails with `Permission denied`, or — quieter and worse — CI invokes it via an entry that depends on the exec bit (a git hook, a `bin/` script, a Dockerfile `RUN ./script.sh`) and the pipeline fails on a machine where nobody thinks to check `ls -l`. Git tracks exactly one permission bit, the executable bit, and a mode flip from `100755` to `100644` is a real committed change that ships to everyone.

The reverse direction also bites: creating a new script and forgetting to make it executable, so the documented `./scripts/setup.sh` invocation fails for every user, forever, until someone commits the chmod. Permissions are invisible in file content, so an assistant that only verifies content will pass its own review every time.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Preserve Executable Bits and Permissions

NEVER let an edit change a file's permission bits. A rewrite of `deploy.sh` must leave it exactly as executable as it was.

Permissions are invisible in content but tracked by git and enforced by the OS: a dropped exec bit turns a working script into `Permission denied` for everyone who pulls.

- Prefer in-place edits, which preserve the inode and its mode. If you must recreate a file (temp-and-rename, delete-and-rewrite), capture the mode first (`stat -c %a`, or `ls -l`) and restore it (`chmod --reference=` or explicit `chmod 755`).
- When creating a new script that will be invoked directly — anything with a shebang, anything in `scripts/`, `bin/`, or `.git/hooks/`-adjacent directories — `chmod +x` it as part of creation, not as a follow-up you might forget.
- After editing any script, check `git diff` for a `mode change 100755 => 100644` line (or the reverse). That line is a bug unless changing the mode was the task.
- Don't compensate for a missing exec bit by changing the invocation (`bash script.sh` instead of `./script.sh`) — that masks the symptom for you while leaving it broken for documented usage, hooks, and CI.
- Special permission cases deserve special care: private keys and secrets files are often `600` on purpose; making one group-readable is a security regression, and some tools (ssh, postgres) hard-fail on loose modes.

**Red flags that you're about to violate this:**

- "I'll just recreate the file; same content, same file."
- "I'll run it with `bash` explicitly, so the exec bit doesn't matter."
- "Permissions are an environment thing, not a code thing." (Git commits the exec bit.)
- "I'll chmod it later if something complains."
- "The diff only shows my content change." (Look for the mode line.)

---

## Why It Works

1. **It makes an invisible property explicit.** Mode bits never appear in content diffs an assistant naturally reads; the rule points at the two places they do appear (`stat`, the `mode change` line in `git diff`) and makes checking them part of the edit.
2. **The `bash script.sh` anti-pattern is banned by name** because it's the rationalization that lets the bug ship: the assistant's own verification passes while every other consumer of the script stays broken.
3. **It covers both directions** — stripping exec from existing scripts and omitting it from new ones — which are the same invisible-property failure wearing different timestamps.

## Origin

An assistant refactored a release script using a write-temp-then-move approach. Content was flawless; the move created the file as `644`. The release pipeline's final step, `./release/publish.sh`, failed at 11pm on release night with `Permission denied`, and the on-call spent forty minutes auditing the script's *content* before anyone ran `ls -l` and found the one bit that had actually changed.
