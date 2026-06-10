---
title: Back Up Before Bulk History Rewrites
slug: back-up-before-bulk-history-rewrites
category: git
tags: [universal, git, history]
works_with: all
severity: critical
one_liner: "Stops filter-repo style rewrites run without backup or coordination"
---

# Back Up Before Bulk History Rewrites

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from running repository-wide history rewrites as casually as any other command, without a backup, a plan, or anyone's agreement.

**[Copy-paste ready version](../../install/back-up-before-bulk-history-rewrites.md)** — just the instruction block, no explanation.

## The Problem

Some tasks legitimately call for rewriting all of history: purging a large file from every commit, scrubbing a path, fixing author info across years. The tools — `git filter-repo`, the deprecated `git filter-branch`, BFG-style cleaners — rewrite every commit hash in the repository. An AI assistant treats these like any other CLI invocation: find the right flags, run it, report success. But a bulk rewrite is closer to a database migration than a command. Run with slightly wrong flags, it silently drops content you meant to keep; run on the only copy of the repo, there's no way back (filter-repo deliberately strips the old refs); run without team coordination, it invalidates every clone, branch, and open PR in existence simultaneously.

Assistants skip the surrounding discipline because nothing in the tool demands it — `filter-repo` runs just as happily without a backup as with one. The discipline is the product: fresh backup clone, dry run, verification of what changed, and an explicit go-ahead from the humans whose history this is.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Back Up Before Bulk History Rewrites

NEVER run a repository-wide history rewrite (`git filter-repo`, `git filter-branch`, BFG-style tools, `git rebase --root`) without, in this order: a full backup, the user's explicit informed approval, and a dry run.

A bulk rewrite changes every commit hash in the repository. Done wrong, it silently destroys content; done right, it still invalidates every existing clone, branch, and open PR.

- Backup first, no exceptions: `git clone --mirror . ../repo-backup.git` (a mirror clone preserves all refs). Confirm it exists before touching the original.
- State the consequences to the user in plain terms before proceeding: all commit hashes change; every collaborator must re-clone or hard-reset; open PRs will need rebasing; tags and release references break unless handled.
- Dry run and verify before the real thing: filter-repo's `--dry-run`/analysis output, then after the rewrite compare expectations — does the purged file still appear in `git log --all -- <path>`? Is content you meant to keep intact? Is repo size what you predicted (`git count-objects -vH`)?
- Never run a bulk rewrite to fix something smaller. Wrong author on one unpushed commit is an amend; a secret at HEAD is targeted handling. Reach for whole-history tools only when the problem is genuinely whole-history.
- Pushing the rewritten history is a separate, explicitly approved step — it is where the blast radius goes from local to everyone.

**Red flags that you're about to violate this:**

- "filter-repo is the documented tool for this, so I'll just run it."
- "The operation is well-understood; a backup would be redundant."
- "I'll rewrite first and explain the hash changes afterward."
- "The dry run output is long; the real run will reveal any problems."
- "While I'm rewriting history anyway, I'll clean up a few other things."

---

## Why It Works

1. **It reclassifies the operation.** "Migration, not command" is the load-bearing reframe: commands get run, migrations get backups, dry runs, and sign-off, and the AI already knows the migration playbook.
2. **The ordered checklist front-loads the irreversible-proofing.** Backup before approval before dry run before execution means the cheapest safeguard exists before any step that could need it.
3. **The "never to fix something smaller" clause blocks scope inflation** — assistants reach for whole-history tools to solve single-commit problems because the tool name matches the keyword, and the rule cuts that mapping.

## Origin

Asked to purge an accidentally committed media directory, an assistant ran a history filter on the team's main repository with a path pattern one character too broad — it also matched a source directory with a similar prefix. No backup had been taken; the tool had stripped original refs as designed. The source directory's history was reassembled over two days from developers' local clones, which existed only because the rewrite hadn't been pushed everywhere yet. The pattern error would have been obvious in a dry run.
