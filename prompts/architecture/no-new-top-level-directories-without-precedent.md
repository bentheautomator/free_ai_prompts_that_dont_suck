---
title: No New Top-Level Directories Without Precedent
slug: no-new-top-level-directories-without-precedent
category: architecture
tags: [universal, architecture, structure]
works_with: all
severity: medium
one_liner: "A new root folder bolted on without learning the existing structure"
---

# No New Top-Level Directories Without Precedent

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from minting a new top-level directory or module when the existing structure already has a place — and a logic — for the code being added.

**[Copy-paste ready version](../../install/no-new-top-level-directories-without-precedent.md)** — just the instruction block, no explanation.

## The Problem

The AI is asked to add webhook handling. The repo has `src/api/` for inbound HTTP, but the AI doesn't study the tree — it creates `src/webhooks/` at the root, sibling to everything. Next month, another session adds `src/integrations/`, which also contains webhook code. Then `src/external/`. None of these directories is wrong in isolation. Together they mean the repo's top level no longer encodes any decision — it's a sediment record of which sessions read the map and which didn't.

A codebase's top level is its table of contents. When it's coherent, a newcomer (or the next AI session, which is a perpetual newcomer) can predict where anything lives from the directory names alone. Every unprincipled root addition degrades that predictive power, and root directories are the worst place to lose it: they're the first thing everyone reads, they're expensive to rename (imports, CI globs, deploy scripts, docs all reference them), and they multiply — a new root dir is high-visibility precedent that the structure is open for unilateral amendment.

AI assistants mint root directories because creating a folder is the lowest-friction way to make code "organized," and because nothing in the immediate task punishes it. The structure's logic — what the existing top level is *organized by* — takes a minute of study the AI doesn't spend unless told to.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No New Top-Level Directories Without Precedent

NEVER create a new top-level directory, package, or module without first mapping the existing structure and confirming the new code has no home in it. The default is always: new code goes inside the structure that exists.

The top level of a repo is its table of contents; every unprincipled addition makes the whole codebase less predictable, and root directories are nearly permanent once CI, deploys, and imports reference them.

- Before creating any directory at or near the root, list what's there and state (to yourself, concretely) what the level is organized by — features? layers? deployables? If your code fits one of the existing entries, it goes there
- "Doesn't fit perfectly" usually means "fits imperfectly in an existing place," which beats a new root entry: webhook handlers fit an existing `api/`; a new vendor client fits an existing `integrations/` or the module that uses it
- Check for near-misses before minting: a `webhooks/` next to an existing `api/inbound/`, a `helpers/` next to an existing `lib/`, a `scripts/` next to an existing `tools/` — synonym directories are the most common form of this failure
- If the code genuinely has no home — a truly new kind of thing for this repo — propose the new directory in your summary with its organizing rationale, rather than silently creating it; root-level structure is a team decision, not a diff detail
- Apply the same discipline one level down in large repos: a new top-level package inside `src/` or a new app in a monorepo carries the same costs

**Red flags that you're about to violate this:**
- "This is a new kind of thing, it deserves its own top-level folder..."
- "I'll make a new directory so my changes don't disturb existing code..."
- "The existing folder names don't quite match what I'm adding..."
- "A fresh module keeps my work self-contained..."
- "It's just a folder, we can always move it later..."

---

## Why It Works

1. **It forces the organizing principle to be named.** Most violations happen because the AI never articulated what the top level is sorted by; once stated, "where does this go" usually answers itself.

2. **It targets synonym directories specifically.** `helpers/` next to `lib/`, `webhooks/` next to `api/` — the near-miss is the dominant real-world case, and a check for it catches what a general principle misses.

3. **It reprices "we can move it later."** Root paths get baked into imports, CI configs, and deploy scripts within days; naming that lock-in corrects the AI's instinct that directories are cheap to relocate.

4. **It routes genuine novelty to humans.** Sometimes a new root entry is right — but as a proposed, reasoned decision. Moving it from silent diff to stated proposal costs one paragraph and preserves the table of contents as something somebody actually maintains.

## Origin

A platform repo accumulated, over a year of heavy AI assistance, root directories named `services/`, `svc/`, `apps/`, and `applications/` — four generations of the same idea, each created by a session that didn't find (or didn't look for) the previous one. CI configuration had grown path filters for all four. The unification renamed two directories and took twenty minutes of `git mv`; updating the forty-one files that referenced the old paths across CI, Dockerfiles, and developer docs took two weeks of follow-up breakage, which was the lesson.
