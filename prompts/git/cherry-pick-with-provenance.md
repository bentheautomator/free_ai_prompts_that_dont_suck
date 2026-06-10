---
title: Cherry-Pick With Provenance
slug: cherry-pick-with-provenance
category: git
tags: [universal, git, history]
works_with: all
severity: medium
one_liner: "Stops untraceable cherry-picks and accidental duplicate commits"
---

# Cherry-Pick With Provenance

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from scattering unmarked copies of commits across branches, creating duplicates that conflict at merge time and history nobody can trace.

**[Copy-paste ready version](../../install/cherry-pick-with-provenance.md)** — just the instruction block, no explanation.

## The Problem

Cherry-picking copies a commit; it doesn't move it. AI assistants blur this constantly: asked to "move that fix to the release branch" or "get this commit onto main," they cherry-pick and consider the job done. Now the same change exists as two unrelated commits with different hashes. When the branches eventually merge, the duplicates meet — sometimes merging silently, sometimes conflicting in ways that make no sense to whoever has to resolve them, because the history shows no relationship between the twins.

Two omissions make it worse. Skipping `-x` means the copy carries no pointer back to its origin, so six months later nobody can tell whether the release branch has the *current* version of the fix or a stale snapshot of it. And picking a range with the wrong syntax — `git cherry-pick A..B` excludes A, a detail assistants get backwards routinely — silently drops the first commit of the intended set, which is the kind of bug that's invisible until the missing change matters.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Cherry-Pick With Provenance

When cherry-picking, always preserve traceability and remember you are copying, not moving.

- Use `-x` on every cherry-pick of a commit that exists on a public branch: `git cherry-pick -x <sha>`. The appended "(cherry picked from commit ...)" line is the only durable link between the copy and the original.
- A cherry-pick does not remove the original. If the source branch will later merge into the destination, the duplicate pair can produce confusing conflicts; say so when proposing the pick, and prefer merging the source branch (or waiting for it) when the whole branch is destined for the target anyway.
- "Move this commit to branch X" means cherry-pick onto X *and then* deal with the original: remove it from the source branch if the source is private to you, or tell the user it still exists there if not.
- Range syntax drops commits silently: `git cherry-pick A..B` excludes A itself; use `A^..B` to include it. Verify what you picked afterward: `git log --oneline -<n>`.
- If a cherry-pick conflicts, resolve it like any merge conflict or run `git cherry-pick --abort`; never commit half-applied picks, and never resolve by discarding one side wholesale.
- Cherry-pick from a known sha, not from memory of "the fix commit." Confirm with `git show --stat <sha>` that the commit is the one you mean before copying it anywhere.

**Red flags that you're about to violate this:**

- "Cherry-picking it over effectively moves it."
- "-x just adds noise to the message."
- "A..B obviously includes both endpoints."
- "The branches will never meet, so duplicates don't matter."
- "I remember which commit the fix was; no need to inspect it."

---

## Why It Works

1. **It corrects the copy/move category error at the vocabulary level.** Once "move" is defined as pick-plus-handle-the-original, the assistant's most common incomplete action becomes visibly half-done.
2. **Mandatory `-x` externalizes provenance into the history itself**, so the question "is this fix current over there?" has an answer that survives the session, the assistant, and the team's memory.
3. **Naming the `A..B` off-by-one is a targeted inoculation** — it's a specific, repeatable mistake, and a rule that names it precisely gets checked precisely.

## Origin

A hotfix was cherry-picked (no `-x`) from a feature branch to a release branch by an assistant, and the feature branch merged a month later. The merge conflicted on the twin commits; the engineer resolving it, seeing no relationship between them, kept what looked newer — the feature-branch version, which predated a follow-up correction made directly on release. The corrected behavior regressed, and the investigation took a day because the history claimed the two changes were strangers.
