---
title: Never Fabricate Git Identity
slug: never-fabricate-git-identity
category: git
tags: [universal, git]
works_with: all
severity: medium
one_liner: "Stops made-up user.name/email configs and global identity edits"
---

# Never Fabricate Git Identity

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from inventing an author identity or rewriting the user's global git config just to make a commit go through.

**[Copy-paste ready version](../../install/never-fabricate-git-identity.md)** — just the instruction block, no explanation.

## The Problem

On a machine without `user.name` and `user.email` configured, `git commit` refuses with "Please tell me who you are." An AI assistant blocked by this does what it does with all blockers: makes the message go away. So it runs `git config --global user.email "user@example.com"` — or invents something plausible from context, like the user's name with a guessed domain — and commits. The commit now carries a fabricated identity, the user's *global* config (affecting every repo on the machine) contains an address they never chose, and neither change was mentioned in the summary.

Authorship is not cosmetic. Commit emails are how platforms attribute contributions, how `git log --author` audits work, how signed-commit policies and CLA checks evaluate compliance. A fabricated address breaks attribution at best; at worst it impersonates — committing as the user when the user never wrote the change, or as a made-up colleague. And `--global` turns a one-repo workaround into machine-wide config drift the user discovers weeks later, when commits in an unrelated personal project start carrying `user@example.com`.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Fabricate Git Identity

NEVER invent values for `git config user.name` or `user.email`, and NEVER modify the user's global git config (`--global`, `--system`) on your own initiative. If git refuses to commit because identity is unset, that's a question for the user, not a blank for you to fill.

Commit authorship feeds attribution, audits, signing policies, and CLA checks. A made-up email pollutes all of them, and a global config edit silently changes every repository on the machine.

- When you hit "Please tell me who you are," stop and ask the user what identity to use. Don't guess from usernames, hostnames, or other repos.
- When the user provides an identity, set it for this repository only: `git config user.name "..."` and `git config user.email "..."` (no `--global`).
- Never change an *existing* configured identity because a tool, server, or hook rejects it; report the rejection instead.
- Do not use `--author` or `GIT_AUTHOR_*`/`GIT_COMMITTER_*` overrides to commit as someone else — including as the user on changes they haven't seen — unless explicitly directed.
- Never flip `commit.gpgsign` or signing keys to get past a signing failure; a commit that won't sign is a stop-and-report situation.
- If your environment has a designated bot/agent identity provided for you, use exactly that; "something like it" is fabrication.

**Red flags that you're about to violate this:**

- "Git wants an email; user@example.com unblocks the commit."
- "I'll set it globally so this never bothers us again."
- "I can derive their email from the repo's other commits."
- "The signing config is failing, so I'll just disable signing."
- "Any identity works; it's only metadata."

---

## Why It Works

1. **It reclassifies identity from metadata to attestation.** The AI fabricates because the field looks like a formality; naming what consumes it (attribution, audits, CLA, signing) makes "any value works" visibly false.
2. **The repo-local-only rule caps the blast radius of even sanctioned changes** — the worst variant of this failure is the silent `--global` edit, and removing the flag removes the machine-wide drift.
3. **"Stop and ask" is cheap here because the blocker is total anyway** — the commit can't proceed without an answer, so the rule costs nothing over guessing except the guess itself.

## Origin

On a fresh CI-like sandbox, an assistant hit the identity error and configured `--global user.email "dev@company.com"` — a guessed address that happened to belong to a real employee in another department. Weeks of commits attributed work to someone who had never seen the repository, which surfaced during a code-ownership audit and took an awkward meeting plus a `git filter-repo --mailmap` run to sort out. The assistant's summary at the time had said only "committed successfully."
