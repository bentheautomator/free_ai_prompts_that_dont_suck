---
title: Untrack With git rm --cached, Not git rm
slug: untrack-with-rm-cached-not-rm
category: git
tags: [universal, git]
works_with: all
severity: critical
one_liner: "Stops git rm from deleting files the user only wanted untracked"
---

# Untrack With git rm --cached, Not git rm

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from deleting a file from disk when the request was only to remove it from version control.

**[Copy-paste ready version](../../install/untrack-with-rm-cached-not-rm.md)** — just the instruction block, no explanation.

## The Problem

"Remove the .env file from git" has two readings, and they differ by one flag and one catastrophe. `git rm --cached .env` removes the file from the index — it stays on disk, working, holding the user's credentials. `git rm .env` deletes it from the index *and from disk*. AI assistants pick the second one alarmingly often, because it's the shorter command and "remove from git" pattern-matches to `git rm`.

The files involved make it worse: untracking requests are almost always about local-only files — env files, credentials, machine-specific config — which by nature exist nowhere else. No remote copy, no teammate's clone, often no backup. After the deletion is committed, the file's contents may survive in earlier history (its own problem), but the *current* version with this week's keys is just gone. There's also a quieter second trap: even `--cached` removal means the file disappears from everyone else's working tree on their next pull, which users rarely expect and assistants never mention.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Untrack With git rm --cached, Not git rm

When asked to remove a file from git, from tracking, or from the repo, ALWAYS use `git rm --cached <path>` — which keeps the file on disk — unless the user has explicitly said they want the file deleted from the filesystem too.

`git rm` without `--cached` deletes the file from disk as well as the index. Untracking requests usually target local-only files (`.env`, keys, machine config) that exist nowhere else; deleting them is unrecoverable by git.

- Default reading of "remove X from git": untrack it. Use `git rm --cached X` (add `-r` for directories), then add an ignore entry so it doesn't get re-added by the next broad stage.
- Immediately after, verify the file still exists on disk: `ls -la <path>`.
- Warn the user of the propagation effect: once the untracking commit is pulled, the file disappears from teammates' working trees, because for them it goes from tracked to deleted. If others need it, they must copy it aside first.
- If the file holds secrets and was ever committed, untracking does not remove it from history; say so explicitly rather than implying the secret is now gone.
- Only run bare `git rm <path>` when the user has clearly asked for the file to be deleted, and restate that consequence in your reply ("this deletes the file from disk as well").

**Red flags that you're about to violate this:**

- "Remove from git means git rm, simple."
- "The file shouldn't exist anyway if it's not supposed to be tracked."
- "--cached is an extra flag; the basic command is probably what they meant."
- "It's just a config file; it can be regenerated."
- "I'll untrack it and the history question can wait."

---

## Why It Works

1. **It pins the default interpretation of an ambiguous phrase.** "Remove from git" is genuinely ambiguous; the rule resolves it to the non-destructive reading, which means a wrong guess now costs an extra command instead of a file.
2. **The post-command `ls` makes the failure detectable in seconds** — if the file is gone, the AI finds out while `git checkout HEAD~ -- <path>` style recovery (or simply not committing) is still possible.
3. **Spelling out the pull-propagation and history caveats covers the two adjacent surprises** users hit even when the flag is right, turning a technically-correct command into a correctly-communicated change.

## Origin

A developer asked an assistant to "get config/secrets.yml out of the repo." The assistant ran `git rm config/secrets.yml`, committed, and reported success. The file — containing staging and production credentials maintained by hand over months, never stored anywhere else — was deleted from disk in the same motion. An old copy was eventually dug out of git history, which meant the secrets were both lost *and* still leaked: the full bingo card.
