---
title: Never Move Published Release Tags
slug: never-move-published-release-tags
category: ci-cd
tags: [universal, ci, release]
works_with: all
severity: high
one_liner: "Stops the AI from force-pushing tags or republishing versions with new contents"
---

# Never Move Published Release Tags

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from repointing an existing release tag or overwriting a published version's artifact instead of cutting a new release.

**[Copy-paste ready version](../../install/never-move-published-release-tags.md)** — just the instruction block, no explanation.

## The Problem

The v2.3.0 release went out with a bug, and someone — increasingly often an AI assistant running the release pipeline — fixes it the "tidy" way: commit the fix, `git tag -f v2.3.0`, `git push --force origin v2.3.0`, re-run the publish job, overwrite the artifact. Same version number, corrected contents, no embarrassing v2.3.1 in the changelog. Except a version number is not a label on your release; it's a cache key in everyone else's infrastructure. Lockfiles recorded v2.3.0's checksum. Docker layer caches hold the old image under the tag. Registries, proxies, and mirrors cached the first artifact. Half the world now has the broken v2.3.0, half has the fixed one, and both halves call it the same thing.

The failure modes are nasty and delayed. Checksum verification starts failing for new installs ("integrity check failed" — indistinguishable from a supply-chain attack, and treated as one by tooling and security teams). Two machines that "run the same version" behave differently, which defeats the entire point of versioning. Debugging "v2.3.0" now requires asking *which* v2.3.0, a question no tooling can answer.

Assistants do this because it minimizes visible churn: the bug "never happened," no new version to announce, and the release pipeline conveniently accepts a re-run. Mutable tags and re-publishable registries make the wrong move mechanically easy, and nothing in the local repo view shows the thousands of external caches that just became wrong.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Move Published Release Tags

NEVER repoint, force-push, or delete-and-recreate a release tag that has been published, and never overwrite a published artifact under an existing version. Once a version identifier has left the building, it is immutable — the only fix for a bad release is a new release.

A published version is a promise that this identifier means these exact bytes, forever. External lockfiles, checksums, mirrors, and caches all depend on it; repointing the tag breaks them in ways you can't see and they can't diagnose.

- A broken v2.3.0 gets fixed by v2.3.1 (or yanked/deprecated through the registry's mechanism, which marks it without mutating it). The bad version's existence in history is fine; versions are cheap, integrity violations aren't.
- No `git tag -f`, no `git push --force origin <tag>`, no deleting a remote tag to re-create it — even minutes after publishing. The window between "pushed" and "someone fetched it" is shorter than any pipeline re-run.
- Don't re-run a publish pipeline in overwrite mode against an existing version. If the release job supports `--force` republish, that flag is for disaster recovery by humans, not for fixing release mistakes.
- Floating convenience pointers are the one exception, and only when explicitly maintained as floating *aliases* of immutable releases: a major-version alias tag (`v2`) that tracks the latest `v2.x.y`, or a `latest` image tag. Move the alias; never the versioned tag it points to. Don't invent new floating tags without the user's sign-off.
- If a published tag has already been moved (by anyone), surface it immediately: downstream checksum failures are already happening or queued, and consumers may be flagging it as tampering.

**Red flags that you're about to violate this:**

- "The release is only ten minutes old; nobody has pulled it yet."
- "Re-tagging keeps the changelog clean — v2.3.1 for a one-line fix looks sloppy."
- "Same version, fixed contents — that's what users would want anyway."
- "The publish job has a force flag, so overwriting is clearly supported."
- "It's an internal package; we control all the consumers."

---

## Why It Works

1. **It names the version as a cache key, not a label.** Labels feel editable; cache keys are obviously not, because the copies you'd need to update live in infrastructure you don't control.
2. **It removes the time-window negotiation.** "Nobody pulled it yet" is unverifiable and usually false (mirrors and bots pull within seconds); making immutability start at publish, not at adoption, deletes the judgment call assistants get wrong.
3. **It redirects the fix into a channel that's actually cheap.** The assistant's motive — clean history — is satisfied almost as well by an immediate patch release plus yank, which costs one version number instead of ecosystem-wide integrity.
4. **The alias carve-out keeps the rule livable**, acknowledging the legitimate floating pointers (`v2`, `latest`) so the prohibition on moving *versioned* tags can stay absolute.

## Origin

An assistant noticed a missing file in a release published an hour earlier, rebuilt, and force-pushed the same tag with the message "fix release contents in place." Over the following week, installs began failing integrity checks against lockfiles that recorded the original checksum, three downstream teams opened supply-chain-compromise investigations, and a public mirror served the old bytes under the new tag's name for a month. The missing file would have been a one-line patch release; instead the version number itself became unusable and the team published v2.3.2 with release notes explaining which v2.3.0 was which.
