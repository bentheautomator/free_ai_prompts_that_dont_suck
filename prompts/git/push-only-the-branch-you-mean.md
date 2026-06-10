---
title: Push Only the Branch You Mean
slug: push-only-the-branch-you-mean
category: git
tags: [universal, git, branches]
works_with: all
severity: medium
one_liner: "Stops push --all and vague refspecs from publishing the wrong branches"
---

# Push Only the Branch You Mean

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from publishing every local branch, pushing to the wrong remote, or pushing a branch other than the one it just worked on.

**[Copy-paste ready version](../../install/push-only-the-branch-you-mean.md)** — just the instruction block, no explanation.

## The Problem

When a push is part of the task, AI assistants get sloppy about *what* gets pushed. `git push --all` publishes every local branch — including the user's `wip-do-not-push` experiments, abandoned spikes, and a branch with an embarrassing name from 2023. `git push origin main` from muscle memory pushes a branch the assistant never touched. A bare `git push` with `push.default` set to `matching` (old configs still have it) pushes multiple branches at once. And in multi-remote repos, pushing to `origin` when the user works against `upstream` or a fork creates phantom branches on the wrong server.

These mistakes are quieter than force-push disasters but they pollute shared remotes, trigger CI runs on garbage branches, and occasionally publish work the user deliberately kept local. The fix is pure explicitness: one push, one named remote, one named branch, verified to be the branch the work is on.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Push Only the Branch You Mean

Push with a fully explicit refspec: `git push origin <branch-name>`, where `<branch-name>` is the branch you verified you're on. NEVER use `git push --all`, `git push --mirror`, or `git push --tags` as part of routine work.

Vague pushes publish things you didn't intend: the user's local experiments, stale branches, or commits on a branch you never worked on.

- Immediately before pushing, confirm the branch: `git branch --show-current`. The name in your push command must be that output, not an assumption.
- Check what you're about to publish: `git log --oneline @{upstream}..HEAD` (or `origin/<branch>..HEAD` for a first push). If commits appear that you didn't create this session, stop and ask.
- In repos with multiple remotes (`git remote -v`), confirm which remote is the intended target before pushing; forks and upstreams are routinely confused.
- First push of a new branch: `git push -u origin <branch-name>` to set the upstream once, explicitly.
- Other branches the user has locally are never yours to publish, no matter how "ready" they look.
- Tags are pushed only by name and only on request: `git push origin v1.2.3`, never `--tags`, which publishes every local tag including experiments.

**Red flags that you're about to violate this:**

- "push --all makes sure nothing is left behind."
- "I'll push main too while I'm at it; it looks ahead."
- "origin is always the right remote."
- "A bare git push will do whatever's configured, which is probably fine."
- "I'll push the tags along with the branch to be thorough."

---

## Why It Works

1. **It converts pushing from a state-dependent action to a parameter-checked one.** Bare `git push` outcomes depend on `push.default`, upstream config, and remote layout the AI hasn't inspected; a full refspec makes the outcome a function of what's typed.
2. **The pre-push log check surfaces stowaway commits** at the only moment they're cheap to catch — unexpected commits in `@{upstream}..HEAD` mean the AI is about to publish someone else's work.
3. **"Thoroughness" is named as the driving rationalization**, because `--all` and `--tags` feel diligent to an AI; reframing them as over-publication flips the valence of the flag.

## Origin

An assistant finishing a feature decided to be thorough and ran `git push --all`. Among the eleven branches it published was the user's local scratch branch containing a hardcoded customer dataset used for debugging — kept deliberately unpushed for exactly that reason. The remote was an org-visible repo. The branch was deleted within the hour, but org-side clones and CI logs meant the cleanup conversation involved the security team.
