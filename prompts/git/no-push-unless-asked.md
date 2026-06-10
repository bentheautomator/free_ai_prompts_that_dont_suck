---
title: No Push Unless Asked
slug: no-push-unless-asked
category: git
tags: [universal, git]
works_with: all
severity: high
one_liner: "Stops unrequested pushes from publishing work before it's reviewed"
---

# No Push Unless Asked

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from pushing to the remote on its own initiative, turning local, reversible work into published, shared state.

**[Copy-paste ready version](../../install/no-push-unless-asked.md)** — just the instruction block, no explanation.

## The Problem

There's a bright line in git between local and pushed. Local commits can be amended, reordered, squashed, or deleted with zero coordination; pushed commits are visible to teammates, may trigger CI and deploy pipelines, and can only be unwound with reverts or history rewrites that affect other people. AI assistants cross this line casually — asked to "commit the fix," they commit *and push*, because push is the next verb in every tutorial and "done" feels like it lives on the server.

An unrequested push forecloses options the user was counting on. They wanted to review the commit, rewrite the message, squash it into yesterday's work — all trivial pre-push, all disruptive post-push. Worse, in repos with push-triggered automation, the assistant's helpful push *is* a deployment. The asymmetry is total: not pushing costs one later command; pushing too early can cost a coordinated cleanup or an unplanned release.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Push Unless Asked

NEVER run `git push` unless the user explicitly requested a push in this conversation. Committing and pushing are separate authorizations: "commit this" does not include pushing.

Pushing converts reversible local work into published state. Before push, anything can be cleaned up freely; after push, mistakes require reverts or coordinated history rewrites, and push-triggered CI/CD may act on the commits immediately.

- Words that authorize a push: "push," "push it up," "publish the branch," "open a PR" (pushing the branch is a prerequisite, say you're doing it). Words that do not: "commit," "save the work," "finish up," "we're done here."
- When your work is committed and unpushed, end your summary with the state: "Committed locally on <branch>; not pushed."
- If a push seems clearly useful (e.g. the user wants CI feedback), suggest it and wait: "Want me to push so CI runs?"
- A standing instruction in project config ("always push after committing") counts as explicit authorization; an inference from past sessions does not.
- If you discover the repo has push-triggered deploys, treat pushing with extra gravity and say what the push will trigger when you ask.

**Red flags that you're about to violate this:**

- "Commit and push go together; the task isn't done until it's on the remote."
- "Pushing now saves the user a step later."
- "They said 'wrap it up,' which surely includes pushing."
- "The branch is ahead of origin; syncing it is just hygiene."
- "Last session they always wanted pushes, so this session does too."

---

## Why It Works

1. **It names the local/published boundary as the thing being crossed.** The AI models push as "save to cloud"; reframing it as "publish irreversibly, possibly deploy" makes the unrequested push feel like the overreach it is.
2. **The authorization vocabulary kills inference.** "Wrap it up" and "finish" are exactly the phrases assistants stretch into push permission; listing them as non-authorizing removes the stretch.
3. **The mandatory "not pushed" status line keeps the user informed without action** — the AI's urge to close the loop is satisfied by reporting state instead of changing it.

## Origin

A user asked their assistant to "commit the migration changes so I don't lose them" at the end of a late session, intending to review everything in the morning. The assistant committed and pushed. The repo deployed staging from that branch on every push, the half-reviewed migration ran against the staging database overnight, and the morning began with restoring staging from a snapshot instead of a code review.
