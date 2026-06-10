---
title: Don't Commit Accidental Submodule Bumps
slug: dont-commit-accidental-submodule-bumps
category: git
tags: [universal, git]
works_with: all
severity: high
one_liner: "Stops submodule pointer changes from sneaking into unrelated commits"
---

# Don't Commit Accidental Submodule Bumps

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from sweeping a changed submodule pointer into an unrelated commit, silently pinning the project to a different version of a dependency.

**[Copy-paste ready version](../../install/dont-commit-accidental-submodule-bumps.md)** — just the instruction block, no explanation.

## The Problem

In a repo with submodules, `git status` often shows a line like `modified: vendor/lib (new commits)`. That isn't a file change — it's the submodule pointer differing from what the superproject recorded, usually because someone ran a build script that updated the submodule, or fetched inside it, or the checkout is simply stale. An AI assistant doing unrelated work sees the line, stages it along with everything else, and commits. The project is now pinned to a different version of a dependency, inside a commit titled "fix typo in README."

These stowaway bumps are uniquely nasty because they're invisible at review (the diff is one inscrutable hash-to-hash line), they change dependency behavior with no corresponding code change, and reverting the README typo fix later also un-bumps the dependency. The reverse failure exists too: an AI that *should* update a submodule edits files inside it, commits in the superproject only, and ships a pointer to commits that exist nowhere but the local machine — broken for everyone who clones.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Commit Accidental Submodule Bumps

NEVER stage or commit a submodule pointer change (`modified: <path> (new commits)` in `git status`) unless updating that submodule is the deliberate point of the commit.

A staged submodule line pins the whole project to a different version of a dependency. Swept into an unrelated commit, it changes behavior invisibly and gets reverted accidentally later.

- When `git status` shows a modified submodule you didn't intentionally update, leave it unstaged. If it's noise from a stale checkout, restore the recorded version: `git submodule update --init <path>`.
- When you DO intend a bump, make it its own commit, stating the version movement: `chore: bump vendor/lib to <sha> (pulls in upstream fix for X)`. Never mix a submodule bump with code changes.
- Before committing a bump, verify the target commit is pushed in the submodule's remote: `cd <submodule> && git branch -r --contains HEAD`. A superproject pointing at unpushed submodule commits is broken for every other clone.
- If you changed files *inside* a submodule, that is a commit-and-push in the submodule's own repo first; only then update the pointer in the superproject.
- Never run `git submodule update --remote` or sync commands as incidental "freshening"; they move pointers, which is a dependency change requiring intent.
- Wildcard staging (`git add -A`) in superprojects is how stowaway bumps happen; stage by path.

**Red flags that you're about to violate this:**

- "git status shows the submodule modified, so it's part of my changes."
- "Staging everything is fine; that submodule line is probably nothing."
- "I'll update the submodule to latest while I'm here."
- "I committed my submodule edits in the superproject, so they're saved."
- "The pointer diff is just two hashes; it can't matter much."

---

## Why It Works

1. **It decodes the status line.** `modified: <path> (new commits)` doesn't parse as "dependency version change" to an AI; once translated, treating it like a modified text file stops making sense.
2. **The own-commit rule makes bumps reviewable and revertable in isolation** — the two properties stowaway bumps destroy — so the discipline directly removes the documented harms.
3. **The pushed-commit check before bumping kills the "works on my machine" pointer**, the reverse failure that no amount of superproject testing can catch locally because locally it always works.

## Origin

A one-line documentation commit in a superproject quietly carried a submodule bump — the assistant had staged with `-A` after a build script fetched the submodule forward. The bumped dependency included an upstream behavior change that broke payment reconciliation in a subtle way. Three weeks later, bisect pointed at "docs: clarify setup steps," which the team initially refused to believe until someone read the second line of the diff.
