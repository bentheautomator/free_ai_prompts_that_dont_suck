---
title: Look Before You Overwrite
slug: look-before-you-overwrite
category: file-handling
tags: [universal, files, data]
works_with: all
severity: medium
one_liner: "Stops creating a new file from blindly replacing one that already exists"
---

# Look Before You Overwrite

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents "create a file" operations from silently replacing an existing file that happens to live at the same path.

**[Copy-paste ready version](../../install/look-before-you-overwrite.md)** — just the instruction block, no explanation.

## The Problem

Asked to "create a helper for date formatting," the assistant writes `src/utils/dates.ts` — straight over the `dates.ts` that already existed, with its twelve exported functions and four years of history. Write APIs don't distinguish create from replace: `open(path, "w")`, `fs.writeFileSync`, and most assistant write tools will happily install fresh content on top of anything. The assistant never *decided* to destroy the old file; it decided to create a new one, and the collision did the destroying. If the file was committed, recovery is a checkout. If it was uncommitted work — a config someone was iterating on, generated output not yet saved elsewhere — it's just gone.

Name collisions are likelier than they feel. Sensible names converge: every project wants a `utils`, a `config`, a `helpers`, a `constants`, an `index`. An assistant that doesn't check the target path is betting the file's existence on the originality of a name chosen precisely because it's conventional. The failure also compounds with stale context: the assistant checked the directory twenty minutes ago, remembers no `dates.ts`, and trusts a memory that predates its own earlier work.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Look Before You Overwrite

NEVER write "new" content to a path you haven't confirmed is vacant. Creating a file and replacing a file are the same syscall; only checking first makes them different intents.

- Before creating any file, check the target: `ls` the directory or test the exact path. Do this at creation time, not from memory of a listing taken earlier in the session — directories change, including by your own hand.
- If the path is occupied, stop and choose deliberately: the task may actually be "extend the existing file" (most common — add your function to the existing `utils.ts`), or the new content belongs under a different name, or replacement is truly intended and you can say so before doing it.
- Conventional names are collision magnets: `utils`, `helpers`, `config`, `constants`, `types`, `index`, `setup`, `main`. Assume these exist until proven otherwise.
- The same rule covers copies and moves: `cp` and `mv` overwrite existing destinations without a murmur. Use `mv -n`/`cp -n` (no-clobber) or check the destination when the target directory isn't fully known to you.
- Watch for near-collisions too: creating `DateUtils.ts` beside an existing `dateUtils.ts` doesn't overwrite anything on your filesystem but will on a case-insensitive checkout (see the case-sensitivity rule) — and it's a fork either way.
- An overwrite of uncommitted content is the unrecoverable case. Treat any dirty working tree as a minefield for blind writes.

**Red flags that you're about to violate this:**

- "It's a new file, so there's nothing to check."
- "I listed that directory earlier; there was no dates.ts." (Earlier isn't now.)
- "utils.ts is such a generic name, I'll just create it."
- "If something was there, the write tool would have warned me." (It didn't, and it won't.)
- "Worst case, git has it." (Uncommitted changes say otherwise.)

---

## Why It Works

1. **It names the API reality that intent doesn't survive:** create and replace are one operation at the filesystem level, so the distinction the assistant means must be enforced by a check the assistant makes.
2. **The "extend, rename, or replace deliberately" fork turns a destructive default into a decision point** — and the most common right answer (add to the existing file) is also the one blind creation makes impossible.
3. **The stale-memory clause matters because sessions are long:** most blind overwrites aren't ignorance of the directory, they're confidence in an old observation of it.

## Origin

An assistant asked to scaffold a `config.py` for a new feature wrote it over the existing `config.py` — eighty lines of carefully tuned settings, half of them uncommitted because the developer was mid-experiment. The scaffold was perfect; the experiment was unrecoverable. The developer's incident note ended with the policy their team adopted verbatim: "creation is overwriting until you've looked."
