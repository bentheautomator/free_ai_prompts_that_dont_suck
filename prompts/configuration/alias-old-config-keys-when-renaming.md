---
title: Alias Old Config Keys When Renaming
slug: alias-old-config-keys-when-renaming
category: configuration
tags: [universal, config, migration]
works_with: all
severity: high
one_liner: "Stops config key renames that orphan every environment still using the old name"
---

# Alias Old Config Keys When Renaming

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from renaming a config key in code without a compatibility path for the environments, scripts, and teammates still setting the old name.

**[Copy-paste ready version](../../install/alias-old-config-keys-when-renaming.md)** — just the instruction block, no explanation.

## The Problem

During a refactor, the AI decides `DB_CONN` should really be called `DATABASE_URL` — fair, it's a better name. It renames the read in code, updates `.env.example`, done. Except the old name is still what's set in staging, production, every developer's local `.env`, two CI workflows, and a deploy script in another repo. The code now reads a key nobody sets. If there's a default, the app silently connects to the wrong place; if there isn't, the next deploy crashes at boot for a reason the diff doesn't obviously explain.

A code rename is atomic: the symbol and its usages change in one commit. A config rename is not, because the values live outside the repo — in environment dashboards, secrets managers, shell profiles, and other people's heads. AI assistants treat the two identically because inside the repo they look identical. The repo is the only place the AI can see, and inside the repo the rename is complete.

Renames also arrive uninvited. Ask for a refactor and the AI "improves" key names as a courtesy, breaking every environment as a side effect of a change nobody requested.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Alias Old Config Keys When Renaming

NEVER rename a config key as a clean break. The old name is set in environments you cannot see or edit from this repo; a rename without an alias orphans all of them at once.

Code renames are atomic. Config renames are migrations.

- Don't rename config keys at all unless the task asks for it. "Better name" is not worth a multi-environment migration; if you think a rename is warranted, propose it separately.
- When a rename is genuinely needed, read both names for at least one full release cycle: prefer the new key, fall back to the old one, and log a deprecation warning when the fallback fires (`"DB_CONN is deprecated, use DATABASE_URL"`).
- If both names are set and disagree, that's a configuration error — fail loudly rather than silently picking one.
- Update every in-repo enumeration in the same change: `.env.example`, compose files, Helm values, docs, test fixtures.
- List the out-of-repo places that need updating (environment dashboards, secret stores, sibling repos) in the change description, because the person merging this can't grep for them.
- Removing the old-name fallback later is its own change, made after confirming the deprecation warning has gone quiet in every environment.

**Red flags that you're about to violate this:**
- "I renamed it everywhere" (everywhere meaning: in this repo).
- "The new name is clearer, so I updated it while I was in there."
- "Whoever deploys will see the example file changed."
- "Supporting both names is messy; a clean cut is simpler."
- "It's just a rename, nothing about the behavior changed."

---

## Why It Works

1. **It names the visibility gap.** The AI's "rename complete" judgment is based on the repo, but config values live outside it; stating that explicitly breaks the false analogy with symbol renames.
2. **The dual-read-with-warning pattern makes the migration self-reporting.** Instead of guessing when every environment has moved, you watch a deprecation log line go silent.
3. **The conflict-equals-error rule** prevents the nastiest variant: both keys set, values diverged, and the app quietly preferring whichever one the fallback logic happens to check first.
4. **Banning unrequested renames** removes most occurrences outright — the majority of these breakages come from renames nobody asked for.

## Origin

A refactor PR renamed `CACHE_TTL` to `CACHE_TTL_SECONDS` (a rename this very repo would otherwise applaud). The code change was flawless; the staging and production environments, managed in a separate infra repo, still set the old key. The new read fell back to its default of 60 seconds — down from the configured 86400 — and cache hit rate collapsed on deploy. The database absorbed a 40x read load for three hours while the team hunted for a query regression that didn't exist.
