---
title: Never Move Published Tags
slug: never-move-published-tags
category: git
tags: [universal, git, history]
works_with: all
severity: high
one_liner: "Stops retagging pushed releases to point at different commits"
---

# Never Move Published Tags

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from force-moving or deleting a pushed tag, so that the same version name means different code on different machines.

**[Copy-paste ready version](../../install/never-move-published-tags.md)** — just the instruction block, no explanation.

## The Problem

A release tag exists to be immutable: `v2.1.0` must mean the same commit on every machine, forever, or it means nothing. When a release goes out flawed, AI assistants reach for the obvious-looking fix — `git tag -f v2.1.0 <new-sha> && git push -f origin v2.1.0` — and quietly redefine the version. The trap is that tags don't propagate like branches: clones that already fetched `v2.1.0` keep the old one silently, because `git fetch` does not update changed tags by default. Now CI builds, deploy scripts, and developer machines disagree about what `v2.1.0` is, and nothing reports the disagreement.

Build systems, package managers, and security tooling all assume tag immutability; a moved tag can mean two different artifacts shipped under one version label, which is somewhere between a debugging nightmare and a supply-chain incident. Assistants do it because the syntax is right there and the operation "succeeds." The correct fix for a bad release has always been boring: cut a new version.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Move Published Tags

NEVER move, force-update, or delete a tag that has been pushed. A published tag is a permanent name for one commit; once others may have fetched it, changing it makes the same version mean different code on different machines, silently — `git fetch` does not update moved tags by default.

- Bad release? Tag a new version (`v2.1.1`) on the fixed commit. The flawed tag stays as a historical fact. This is the entire playbook.
- Banned on any pushed tag: `git tag -f <name>`, `git push -f origin <tag>`, `git push origin :refs/tags/<name>` (deletion), and delete-then-recreate sequences, which are a move with extra steps.
- Local-only tags (never pushed; verify with `git ls-remote --tags origin <name>` returning nothing) may be freely fixed before publishing.
- Creating tags: use annotated tags for releases (`git tag -a v2.1.1 -m "release v2.1.1"`), confirm the tagged commit is the one intended (`git show v2.1.1 --stat`), and push by name (`git push origin v2.1.1`), never `git push --tags`.
- If the user explicitly insists on moving a published tag, state the consequence first — existing clones keep the old tag silently; anything that cached the version may pin stale code — and require their confirmation.

**Red flags that you're about to violate this:**

- "The release was broken, so I'll just point v2.1.0 at the fixed commit."
- "Deleting and recreating the tag is cleaner than a new version number."
- "Tags are just refs; updating one is like updating a branch."
- "Everyone will get the corrected tag next time they fetch."
- "A patch release for a one-commit fix feels like bureaucracy."

---

## Why It Works

1. **It corrects the "tags are like branches" model with the one fact that matters:** fetch doesn't update moved tags. Branches converge after a force-push; tags silently fork across machines. That asymmetry is the whole argument, and most AIs have never been told it.
2. **It supplies the boring correct move (new version) at the moment of temptation**, so the rule competes with the bad fix rather than leaving a vacuum.
3. **The delete-then-recreate clause closes the obvious loophole** an AI would otherwise use to comply with the letter of "don't force-move."

## Origin

After a flawed release, an assistant retagged `v3.4.0` onto the fixed commit and force-pushed the tag. The deploy pipeline, which had already fetched, kept building the old commit; developer machines split between the two depending on when they'd last cloned. The team spent two days debugging "irreproducible" behavior differences between environments running what every log line swore was the same version.
