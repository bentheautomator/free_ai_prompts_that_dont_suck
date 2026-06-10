---
title: A Committed Secret Is a Leaked Secret
slug: committed-secrets-are-leaked-secrets
category: git
tags: [universal, git, history]
works_with: all
severity: critical
one_liner: "Stops 'deleted in a new commit' from passing as secret cleanup"
---

# A Committed Secret Is a Leaked Secret

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from treating a follow-up commit that deletes a credential as having removed it, when the secret remains in history and must be rotated.

**[Copy-paste ready version](../../install/committed-secrets-are-leaked-secrets.md)** — just the instruction block, no explanation.

## The Problem

A key gets committed — by the AI, by the user, doesn't matter. The AI is asked to fix it, so it deletes the key from the file, commits "remove exposed API key," and reports the problem solved. It is not solved. The key sits in the previous commit, retrievable by anyone with `git log -p`, forever. If the commit was pushed, the audience includes every clone, every fork, every CI cache, and — on public repos — the scanners that watch push streams and try leaked keys within minutes, faster than any human response.

The deletion-commit theater happens because the AI applies file-thinking to a history-storage system: in a filesystem, deleting removes the data; in git, deleting *adds a commit on top of* the data. The real remediation has two parts the AI skips: rotate the credential (because exposure must be assumed the moment it left the machine) and, separately, decide whether to rewrite history (worthwhile for unpushed commits, largely symbolic after a public push). An AI that says "removed the key, all set" has converted an incident into a dormant incident.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### A Committed Secret Is a Leaked Secret

When a secret has been committed, deleting it in a new commit does NOT remove it; it remains readable in history (`git log -p`). Never report a secret as removed when it is merely deleted at HEAD.

Treat any pushed secret as compromised the moment it left the machine. On public repos, automated scanners harvest credentials from pushes within minutes.

- First question, always: was the commit pushed? `git branch -r --contains <sha>`.
- Not pushed: remove it from history for real. If it's in the latest commit, `git commit --amend` after fixing the file. If deeper, rebase the local commits to drop or edit the offending one. Verify afterward: `git log -p -S '<secret fragment>' --all` returns nothing.
- Pushed: tell the user immediately that rotation is the primary fix, before any git surgery. The credential must be revoked and reissued; history rewriting on a shared remote is secondary cleanup that does not un-leak anything (forks, clones, and caches persist) and needs team coordination.
- Never present "I removed the key in a new commit" as remediation. State plainly: the key is still in history, and here is what that means.
- Prevent the sequel: add the secret's file pattern to `.gitignore` and recommend the user check for the same value in other commits or repos.

**Red flags that you're about to violate this:**

- "I deleted the key from the file and committed; problem solved."
- "It was only pushed a few minutes ago; probably nobody saw it."
- "It's a private repo, so the leak doesn't really count."
- "Rotating the key is the user's department; my part is the git fix."
- "A history rewrite would be disruptive; the deletion commit is good enough."

---

## Why It Works

1. **It replaces filesystem intuition with history semantics.** "Deleting adds a commit on top of the data" is the one-sentence model correction from which the rest follows; without it, the deletion commit genuinely looks like a fix.
2. **The pushed/unpushed fork makes the response proportional** — full local rewrite where it's cheap and effective, rotation-first where rewriting is theater — so the AI can't apply the easy branch to the dangerous case.
3. **The verification grep (`git log -S --all`) defines "removed" operationally.** The claim "the secret is gone" must be backed by a command that returns nothing, which prevents the premature all-clear.

## Origin

A live payment-provider key was committed to a public repo. The assistant, asked to handle it, deleted the key from the config, committed "remove sensitive data," and replied that the repository was now secure. The key had been scraped before the cleanup commit even landed; the first fraudulent API calls appeared the same evening. Rotation — the thing that actually mattered — happened a day late because the all-clear sounded confident.
