---
title: Stop Dumping Code Into Utils
slug: stop-dumping-code-into-utils
category: architecture
tags: [universal, architecture, cohesion]
works_with: all
severity: medium
one_liner: "Every homeless function landing in utils.py until it imports the world"
---

# Stop Dumping Code Into Utils

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from filing every hard-to-place function under utils/, helpers/, or common/, where code goes to be undiscoverable.

**[Copy-paste ready version](../../install/stop-dumping-code-into-utils.md)** — just the instruction block, no explanation.

## The Problem

The AI writes a function that doesn't obviously belong to the file it's editing — a date truncator, a slug generator, a retry helper. Filing it correctly requires a decision: what is this, really, and where does that live? Filing it in `utils.py` requires no decision at all. So `utils.py` it is. Repeat per task, and utils becomes a 90-function museum of orphans: string things next to money things next to a function that calls the geocoding API and definitely isn't a utility.

The name is the rot. "Utils" describes no domain, so nothing is ever *wrong* there, so everything ends up there. Discoverability dies first — nobody finds `format_currency` in utils, so they write a second one (utils files are where duplicate helpers breed). Dependencies rot next: one function in the pile imports the ORM, and now every module that wants the innocent string helper transitively drags in the database. The pile is imported by everything and depends on everything, which makes it the hardest file in the codebase to ever split.

AI assistants are prolific utils-feeders because "where does this concept belong" is exactly the kind of judgment call they're built to shortcut, and because the existing utils file is visible precedent that this is where the codebase puts such things.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Stop Dumping Code Into Utils

NEVER add a function to a `utils`, `helpers`, `common`, `misc`, or `shared.py`-style grab-bag module, and never create a new one. Every function gets a home named after what it's about.

A module named "utils" has no admission criteria, so it accumulates everything, gets imported by everything, and becomes the file nobody can find anything in or ever safely split.

- Name the concept, then name the module after it: date math goes in `dates.py`, money formatting in `money.py`, slug logic in `slugs.py` — small, single-topic modules, even if today they hold one function
- If the helper is only used by one module, it isn't shared yet; keep it private in that module until a second caller exists
- If the function touches your domain (knows about orders, users, plans), it isn't a utility at all — it's domain logic that belongs in the module that owns that concept
- Grab-bag modules must stay dependency-clean: nothing in a leaf helper module imports the ORM, the web framework, or feature code. If your helper needs those, it has a domain and therefore a real home
- An existing fat `utils.py` is precedent for the disease, not the cure; put your function in a properly named module and leave the pile its current size

**Red flags that you're about to violate this:**
- "It doesn't fit anywhere specific, so utils is the natural place..."
- "There's already a utils.py with stuff like this in it..."
- "A whole new file for one small function seems excessive..."
- "I'll put it in helpers for now and find it a real home later..."
- "It's sort of generic if you squint..."

---

## Why It Works

1. **It forces the naming act.** "Name the concept" is the decision utils exists to avoid; making it mandatory means each function gets classified at birth, when classification costs ten seconds instead of an archaeology project.

2. **It uses single-topic modules as natural fences.** `dates.py` rejects a geocoding function on sight; `utils.py` rejects nothing — admission criteria are the entire difference.

3. **It defers sharing until proven.** Most "shared helpers" never get a second caller; keeping them private until one exists prevents the pile from forming at all.

4. **It breaks precedent-following explicitly.** The existing fat utils file is the strongest signal pulling the AI toward dumping; the rule pre-labels it as the anti-pattern so it can't serve as the example.

## Origin

A utilities module in a mid-sized service hit 2,300 lines and 96 functions, including four distinct date formatters written months apart because none of their authors found the previous ones. The breaking point was an incident: a developer imported one pure string helper into a lambda function, and deployment failed because something else in `utils.py` imported the ORM at module level, blowing the package size limit. Splitting the file took a week, almost all of it spent answering, function by function, the question that had been dodged 96 times: "what is this actually about?"
