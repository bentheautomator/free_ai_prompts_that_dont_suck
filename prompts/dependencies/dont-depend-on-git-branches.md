---
title: Don't Depend on Git Branches
slug: dont-depend-on-git-branches
category: dependencies
tags: [universal, dependencies, supply-chain]
works_with: all
severity: high
one_liner: "Stops deps pinned to GitHub branch URLs that change or vanish without notice"
---

# Don't Depend on Git Branches

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from pointing dependencies at mutable git refs — branches, forks, and HEADs that move or disappear.

**[Copy-paste ready version](../../install/dont-depend-on-git-branches.md)** — just the instruction block, no explanation.

## The Problem

When a needed fix is merged upstream but not yet released, AI assistants discover the git-URL install: `"some-lib": "github:user/some-lib#main"`, or `pip install git+https://github.com/user/lib.git@master`. It works immediately, which is the whole appeal. What it installs, however, is "whatever that branch contains at the moment anyone happens to run install" — a dependency whose contents are decided continuously, by someone else, with no versioning, no review, and no notice.

Branch dependencies fail in every direction at once. Reproducibility: two installs a week apart get different code, and not every lockfile pins git refs to commits equally well. Availability: the branch gets deleted, the fork's owner cleans house, the repo goes private — and every build everywhere fails on a 404. Security: the dependency is now "anything the branch owner pushes, executed in your build," which for a random user's fork is an enormous grant of trust. And git installs skip registry niceties like prebuilt artifacts, so builds get slower and flakier as a bonus.

Assistants reach for branch URLs because the immediate problem ("fix isn't released") has an immediate solution shape, and the URL is right there in the GitHub PR they just read about. The two-character difference between `#main` and `#a1b2c3d` — mutable ref versus immutable commit — carries the entire risk, and nothing about the syntax announces that.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Depend on Git Branches

NEVER point a dependency at a mutable git ref — a branch name, a fork's `main`, or a bare repo URL that defaults to HEAD. A branch dependency means "whatever that branch says at install time," which is a different package every week and a build failure the day the ref disappears.

- Strongly prefer a released version from the registry. If the fix you need is merged but unreleased, first check whether a release is imminent (open issues/milestones often say) — waiting one release beats carrying a git dependency.
- If a git dependency is genuinely unavoidable, pin it to a full commit SHA, never a branch: `github:user/lib#a1b2c3d4...`, `git+https://...@<sha>`. A commit is immutable; a branch is a moving target.
- Treat fork dependencies as a loud, temporary exception: comment in the manifest why the fork is needed, link the upstream PR or issue you're waiting on, and note what removing it depends on. A fork URL without an exit plan becomes permanent.
- Never depend on a stranger's fork for convenience. Installing `random-user/lib#patched` executes whatever that account pushes, forever after. If the patch matters, fork it into an organization you control and pin the SHA there.
- When you encounter an existing branch-pinned dependency while working, flag it — it's a build outage with an unknown date attached.

**Red flags that you're about to violate this:**
- "The fix is on main; I'll install straight from the repo until it's released."
- "Pointing at the branch means we get future fixes automatically."
- "This fork has exactly the patch we need."
- "The lockfile will pin it anyway, so the branch ref is fine."
- "It's temporary — we'll switch back to the registry version soon."

---

## Why It Works

1. **It locates the entire risk in the ref's mutability**, teaching the `#main` vs `#sha` distinction explicitly — the syntax looks identical, so only a stated rule makes the difference perceptible.
2. **It defuses the urgency rationale** by inserting the is-a-release-imminent check, which resolves most "merged but unreleased" situations without any git dependency at all.
3. **It prices the trust grant of fork dependencies** — "executes whatever that account pushes" — converting a convenience into a recognizable supply-chain exposure.
4. **It demands an exit plan in the manifest**, because the durable failure mode isn't adding the git URL, it's the git URL still being there three years later.

## Origin

Needing an unreleased fix, an assistant pointed a project's ORM dependency at a contributor's fork, `#main`. The fix worked. Eight months later the contributor — long since done with the project — deleted the fork during a profile cleanup, and the company's builds failed globally within the day: CI, new developer setups, and the production image rebuild for an urgent security patch, all on the same 404. The upstream package had shipped the fix in a tagged release seven months earlier; nobody had ever switched back.
