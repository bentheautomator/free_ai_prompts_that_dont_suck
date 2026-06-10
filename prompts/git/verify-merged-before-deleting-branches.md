---
title: Verify Merged Before Deleting Branches
slug: verify-merged-before-deleting-branches
category: git
tags: [universal, git, branches]
works_with: all
severity: high
one_liner: "Stops branch -D from deleting branches with unmerged commits"
---

# Verify Merged Before Deleting Branches

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from deleting branches it merely assumes are merged, especially by escalating from `-d` to `-D` when git refuses.

**[Copy-paste ready version](../../install/verify-merged-before-deleting-branches.md)** — just the instruction block, no explanation.

## The Problem

Asked to "clean up old branches," an AI assistant runs `git branch -d old-feature`, git refuses with "not fully merged," and the assistant immediately retries with `-D`. That refusal was git's entire safety mechanism doing its job — the branch contains commits that exist nowhere else — and the assistant treated it as a permissions problem to route around. The capital flag wins, the branch is gone, and the unmerged commits are findable only through the reflog for a limited time, by someone who knows to look.

The deeper error is the assumption itself. Branch names lie: `old-feature` might hold last week's unfinished work, and squash-merged branches show as "not fully merged" even when their *content* landed — which trains assistants that the warning is noise. It isn't noise. It's the only thing standing between "delete a label" and "delete commits." Distinguishing the two cases takes one log command, which is exactly the step that gets skipped.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Verify Merged Before Deleting Branches

NEVER delete a branch with `git branch -D` as a retry after `git branch -d` is refused. The refusal means the branch holds commits that exist nowhere else; deleting it discards them.

- Before deleting any branch, check what would be lost: `git log --oneline main..<branch>`. Empty output means safe to delete with `-d`; any output means those commits exist only there.
- If the branch was squash-merged, `-d` refuses even though the content landed. Verify before believing this: confirm the squash commit exists on the target (`git log --oneline main | head`, compare against the branch's changes with `git diff main...<branch>` — an empty diff means the content is merged).
- Use `-D` only after you have verified the content is preserved elsewhere or the user has explicitly confirmed the unmerged commits are disposable, with the commit list in front of them.
- The same rule covers remote deletion: before `git push origin --delete <branch>`, run the same unmerged-commit check against the remote ref.
- When asked to "clean up branches," produce the list of candidates with their unmerged-commit counts and let the user approve the deletions; do not bulk-delete on your own judgment.

**Red flags that you're about to violate this:**

- "-d failed, so the command I actually need is -D."
- "The branch is six months old; nobody wants it."
- "It says not fully merged, but that's probably just the squash-merge thing."
- "The user said clean up, and a clean repo has fewer branches."
- "I can always get it back from the reflog if I'm wrong."

---

## Why It Works

1. **It rebrands the `-d` refusal as a verdict, not an obstacle.** The escalate-to-`-D` reflex exists because the AI parses the error as "insufficient force"; the rule parses it correctly as "data present," which makes escalation obviously wrong.
2. **The squash-merge clause removes the AI's best excuse.** Because the warning genuinely false-positives on squashed branches, assistants learn to ignore it; giving them the `git diff main...` test lets them confirm the false positive instead of assuming it.
3. **Requiring the unmerged-commit list before approval forces consequences into view** — "delete old-feature" and "delete these 9 commits including 'WIP payment retry logic'" get very different answers from users.

## Origin

During a "delete stale branches" cleanup, an assistant hit the not-fully-merged refusal on four branches and used `-D` on all of them. Three were squash-merged and genuinely safe. The fourth held two weeks of un-merged spike work on a migration. It was recovered from the reflog — barely — because the developer happened to check that same afternoon, before any gc ran.
