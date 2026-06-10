---
title: Keep the PR Description Synced With Revisions
slug: keep-pr-descriptions-synced-with-revisions
category: code-review
tags: [universal, review, documentation]
works_with: all
severity: medium
one_liner: "Stops PR descriptions from describing code the PR no longer contains"
---

# Keep the PR Description Synced With Revisions

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the PR description from drifting out of sync with the code as review rounds reshape what the PR actually does.

**[Copy-paste ready version](../../install/keep-pr-descriptions-synced-with-revisions.md)** — just the instruction block, no explanation.

## The Problem

The description says "Adds caching to the profile endpoint with a 5-minute TTL." Then review happened: the TTL became configurable, the cache moved from in-process to Redis at a reviewer's insistence, and the profile endpoint change got split out, leaving only the search endpoint. The description still says what it said on day one. The assistant updated the code five times and the description zero times.

This happens because assistants treat the description as a creation-time artifact — write it once when opening the PR, then operate exclusively in code and comment threads. There's no step in "address review feedback" that touches the description, so it fossilizes while the diff evolves underneath it.

The damage lands on three audiences. The late-arriving reviewer reads the description, builds the wrong mental model, and reviews the diff against it. The merge produces a squash commit whose message — pulled from the description — is now false history. And six months later, someone running `git blame` to understand the Redis dependency finds an explanation describing an in-process cache that never shipped. A stale description isn't missing documentation; it's confidently wrong documentation at the exact spot people look first.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep the PR Description Synced With Revisions

ALWAYS re-read the PR description after making review-driven changes, and update it whenever the diff no longer matches it. The description must describe the PR as it is now, not as it was when opened.

A stale description is worse than none: reviewers and future archaeologists trust it precisely because it looks authoritative.

- After each push that changes behavior, approach, or scope, diff your description against reality: does the stated approach match the code? Are listed changes still in the PR? Did anything get added that the description doesn't mention?
- Things that always require an edit: a changed technical approach (in-process → Redis), changes split out to another PR, changes pulled in, a changed default or config surface, abandoned parts of the original plan.
- Don't delete the history — supersede it. A short "Revised during review: cache is now Redis-backed (was in-process), per discussion below" keeps the thread legible without preserving false claims as current ones.
- Check the title too. Titles become squash-commit subjects; "Add profile caching" on a PR that now caches search is a lie headed straight for `git log`.
- Pure mechanical pushes (typo fixes, lint appeasement) don't require a description pass. Behavior or scope changes always do.

**Red flags that you're about to violate this:**

- "Everyone following the thread knows what changed..."
- "The description was accurate when I wrote it..."
- "The commit messages tell the real story..."
- "I'll fix the description right before merge..."
- "It's mostly still right, just the caching section is outdated..."

---

## Why It Works

1. **It attaches the update to an existing trigger.** "After each behavior-changing push" piggybacks on an action the model already performs, instead of relying on a free-floating "keep docs fresh" intention that never fires.
2. **The always-edit list removes judgment calls.** Approach changed, scope split, default changed — concrete events, each mapping to "edit the description," so drift can't hide behind "it's mostly still right."
3. **It names the downstream artifact.** Descriptions become squash-commit messages and blame-trail answers. The model stops treating the edit as thread hygiene and starts treating it as writing permanent history.
4. **Supersede-don't-delete preserves thread coherence,** which removes the legitimate objection ("editing will orphan the discussion") that otherwise justifies leaving it stale.

## Origin

A PR opened as "add soft-delete to attachments" was reshaped during review into a hard-delete with a 30-day async purge job, after the reviewer pointed out the storage cost. The description never changed. A second reviewer, joining late, reviewed the purge job against the soft-delete description, concluded the deletion path was "an extra safeguard," and approved. The squashed commit said "add soft-delete." During an incident a year later, an on-call engineer read that commit message, assured a customer their data was recoverable, and then had to call back.
