---
title: Force-Push With Lease, Never Bare --force
slug: force-push-with-lease-only
category: git
tags: [universal, git]
works_with: all
severity: critical
one_liner: "Stops bare force-pushes from erasing teammates' commits on the remote"
---

# Force-Push With Lease, Never Bare --force

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from overwriting commits on the remote that it has never seen, by requiring `--force-with-lease` and explicit user approval for any forced push.

**[Copy-paste ready version](../../install/force-push-with-lease-only.md)** — just the instruction block, no explanation.

## The Problem

When a push gets rejected, AI assistants reach for `git push --force` because it makes the error go away. What it actually does is replace the remote branch with the local one unconditionally. If a teammate pushed commits in the meantime, those commits are gone from the branch tip with no warning, no conflict, no prompt. The teammate finds out when their work vanishes from the PR.

`--force-with-lease` exists precisely for this: it refuses the push if the remote has moved since you last fetched, meaning you can only overwrite what you've actually seen. It is strictly safer and costs nothing to type. Assistants skip it because `--force` is the famous flag, error messages and old tutorials suggest it, and the assistant's goal is "make the push succeed," not "make the push safe." A bare force-push that destroys a colleague's afternoon looks identical to a successful one in the terminal output.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Force-Push With Lease, Never Bare --force

NEVER run `git push --force`. If a forced push is genuinely required and the user has approved it, use `git push --force-with-lease` and nothing else.

A bare `--force` replaces the remote branch unconditionally, deleting any commits teammates pushed since your last fetch. `--force-with-lease` refuses to overwrite history you have not seen, which is the entire safety difference.

- A rejected push is information, not an obstacle. Diagnose why the remote is ahead (`git fetch` then `git log HEAD..@{upstream}`) before considering any forced push.
- Never force-push to a default branch (`main`, `master`, `develop`, release branches) under any circumstances.
- Force-pushing is acceptable only on a branch the user owns, after history was deliberately rewritten, with the user's explicit approval for that specific push.
- Run `git fetch` immediately before `git push --force-with-lease` so the lease reflects current remote state; a stale lease is barely better than no lease.
- If `--force-with-lease` is rejected, the remote has new commits. Stop and show them to the user; do not retry with `--force`.

**Red flags that you're about to violate this:**

- "The push was rejected, so I need --force."
- "It's probably just my own rewritten commits up there."
- "--force-with-lease failed, so I'll use the stronger flag."
- "This is a feature branch, force-pushing is fine without checking."
- "The user wants this pushed; whatever is on the remote is outdated."

---

## Why It Works

1. **It converts a judgment call into a vocabulary substitution.** The AI doesn't have to reason about safety in the moment; `--force` is simply not in its toolkit, and the safe flag is a drop-in replacement.
2. **"If the lease fails, stop" closes the escalation path.** The most dangerous moment is when `--force-with-lease` is rejected and `--force` would "work"; the rule names that exact moment as a hard stop instead of a hint.
3. **Requiring a fresh fetch before the lease removes the stale-lease loophole**, which is the one known way `--force-with-lease` silently degrades to `--force`.

## Origin

Two people were on the same feature branch. One asked their assistant to rebase and push; the push was rejected because the other had pushed three commits of test fixes minutes earlier. The assistant ran `git push --force`, and the three commits disappeared from the branch. They were recovered from the teammate's local clone, but only because that laptop hadn't pulled yet; with a `--force-with-lease`, the push would simply have been refused.
