---
title: Regenerate Lockfiles to Resolve Merge Conflicts
slug: regenerate-lockfiles-to-resolve-merge-conflicts
category: dependencies
tags: [universal, dependencies, lockfiles]
works_with: all
severity: high
one_liner: "Stops resolving lockfile merge conflicts by hand-picking hunks like source code"
---

# Regenerate Lockfiles to Resolve Merge Conflicts

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from resolving lockfile merge conflicts line-by-line instead of regenerating through the package manager.

**[Copy-paste ready version](../../install/regenerate-lockfiles-to-resolve-merge-conflicts.md)** — just the instruction block, no explanation.

## The Problem

A rebase hits conflict markers in `package-lock.json`, and the AI assistant resolves them the way it resolves every merge conflict: read both sides, pick the right hunks, delete the markers. For source code, that's the job. For a lockfile, it's assembling a Frankenstein document — the dependency graph, resolution entries, and integrity hashes from two different resolutions stitched together by something choosing "ours" or "theirs" hunk by hunk, with no resolver ever validating that the combination is internally consistent.

A hand-merged lockfile can claim versions that satisfy neither branch's manifest, reference packages whose entries were half-kept, or pair versions with the other version's integrity hash. Sometimes `npm ci` rejects it loudly; sometimes the file is plausible enough to install — just not the tree either branch tested. The correct procedure has never been hunk-picking: take the manifest merge as the source of truth, then let the package manager rebuild the lockfile from it. npm even auto-resolves lockfile conflicts itself when you run `npm install` on a conflicted file; yarn and pnpm have their own supported paths.

Assistants fall into this because conflict markers all look the same, and resolving them is a task the assistant is confident at. The category error — this file is resolver output, not authored content — is invisible at the level of conflict hunks.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Regenerate Lockfiles to Resolve Merge Conflicts

NEVER resolve a lockfile merge conflict by choosing hunks like source code. A lockfile is resolver output: the only valid post-merge lockfile is one the package manager generated from the merged manifest, not one assembled from pieces of two different resolutions.

- Resolve the manifest first. `package.json` (or `pyproject.toml`, `Cargo.toml`) conflicts are real merge decisions — combine both branches' dependency changes there, by hand, correctly.
- Then regenerate, don't merge, the lockfile. npm: run `npm install` with the conflicted lockfile present — npm detects the markers and rebuilds correctly from the merged package.json. Equivalent flow for pnpm/yarn. Cargo/poetry: checkout one side's lockfile (or delete it as the documented conflict procedure for that tool prescribes) and re-run the lock step so the tool rewrites it from the merged manifest.
- Never delete conflict markers from a lockfile manually and commit what remains — even if the result parses, no resolver has verified it.
- Validate before committing: a clean `npm ci` / `pnpm install --frozen-lockfile` run proves manifest and regenerated lockfile agree. If it fails, the manifest merge is wrong — fix that, regenerate again.
- Check the regenerated lockfile's diff covers both branches' intents: the package your branch added and the ones the other branch changed should all be present. A regeneration that silently dropped one side means the manifest merge dropped it first.

**Red flags that you're about to violate this:**
- "Conflict markers — I'll take ours for these hunks and theirs for those."
- "Both sides just added different packages, so I'll keep both blocks."
- "The merged file is valid JSON, so the conflict is resolved."
- "Hand-merging is faster than re-running the whole install."
- "Lockfile conflicts are mechanical; no need to involve the package manager."

---

## Why It Works

1. **It splits the merge into the part that is human work (the manifest) and the part that is machine work (the lockfile)** — the AI's error is applying source-code merge skills uniformly to both.
2. **It surfaces the built-in path**: npm's conflict auto-resolution on `npm install` means the correct move is less work than hunk-picking, removing the efficiency rationalization entirely.
3. **It installs a pass/fail validator** — a frozen-lockfile install — so a bad merge is caught at the desk instead of in CI or, worse, accepted silently.
4. **It adds the both-intents check**, covering the subtle failure where regeneration succeeds but the manifest merge quietly lost one branch's dependency change.

## Origin

Rebasing a feature branch, an assistant hand-resolved roughly thirty conflict hunks in a yarn lockfile, alternating sides based on which looked newer. The result parsed, installed, and carried an ORM version from one branch with the dependency subtree the other branch's version needed — a combination neither branch had ever run. It worked in dev, then deadlocked under production load due to a connection-pool behavior that existed only in that chimera of versions. The fix, once found, was rerunning the merge the supported way: five minutes, one regenerated lockfile.
