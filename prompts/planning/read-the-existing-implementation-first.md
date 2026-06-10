---
title: Read the Existing Implementation First
slug: read-the-existing-implementation-first
category: planning
tags: [universal, planning]
works_with: all
severity: high
one_liner: "Planning a rewrite of code nobody opened, then rediscovering its edge cases"
---

# Read the Existing Implementation First

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents planning a replacement for existing code without reading what the existing code actually does.

**[Copy-paste ready version](../../install/read-the-existing-implementation-first.md)** — just the instruction block, no explanation.

## The Problem

"Replace the legacy CSV importer with something cleaner" — and the assistant starts designing the clean version immediately. New module layout, modern parsing library, tidy plan. What it didn't do is open the legacy importer, because the legacy importer is assumed to be merely *bad*: a worse version of the obvious thing. So the replacement gets planned against the obvious thing.

Then the old code turns out to be 800 lines for a reason. It normalizes three encodings because customer files actually arrive in three encodings. It tolerates a duplicate-header quirk from one major client's export tool. It caps memory because someone once uploaded a 2GB file. None of this is documented anywhere except the implementation itself — old code is frequently the only complete spec of the current behavior. A replacement planned without reading it doesn't replace the system; it replaces the naive idea of the system, and the gap ships as regressions discovered one support ticket at a time.

Reading ugly old code is unpleasant, and writing new code is pleasant, so the default ordering is exactly backwards. The plan for any replacement starts with an inventory of what the incumbent actually handles.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Read the Existing Implementation First

NEVER plan a replacement, rewrite, or "cleaner version" of existing code before reading the existing code. The old implementation is usually the only complete specification of current behavior — ugliness included, especially the ugliness.

The core problem: old code gets assumed to be a worse version of the obvious design, so the replacement gets planned against the obvious design — and every non-obvious behavior the old code earned becomes a regression.

- Before planning the replacement, read the incumbent end to end. Long is information: 800 lines where you expected 200 means 600 lines of cases you haven't thought of yet.
- Inventory the behaviors, not the style. List what it handles: input variants, error paths, limits, retries, ordering guarantees, side effects. This list is the real requirements document.
- Treat each weird branch as a claim about reality ("files arrive with duplicate headers") until checked. Use git blame and linked issues to find out why it exists.
- Classify every inventoried behavior in the plan: keep, intentionally drop (say so to the user), or confirmed-dead. Unclassified behaviors default to keep.
- If reading reveals the old code is fine and merely unfashionable, say that too. Sometimes the right plan is no replacement.

**Red flags that you're about to violate this:**
- "It's legacy code, I know roughly what it does..."
- "I'll design the clean version first and check the old one for anything I missed..."
- "Most of those 800 lines are probably cruft..."
- "The new library handles all that automatically..." (all of what, specifically?)
- "Reading that mess would take longer than rewriting it..."

---

## Why It Works

1. **It locates the real spec.** For mature systems, documented requirements lag actual behavior by years; the implementation is the only artifact that never drifted. Reading it is requirements gathering, not archaeology.

2. **It reverses the burden of proof on weird code.** Default-assume-cruft deletes earned edge cases; default-assume-reason with explicit verification keeps them unless shown dead. The keep/drop/dead classification makes every omission a decision instead of an accident.

3. **It converts line count from annoyance to estimate.** The gap between expected and actual size of the old code is a direct measurement of how much the assistant doesn't know about the problem — available before a single new line is written.

## Origin

A rewrite of a "crufty" address-formatting module was planned from the function signature alone: clean templates, one format per country, 150 elegant lines replacing 900 ugly ones. Post-ship, the regressions arrived regionally — the old module's unread branches had handled Japanese address ordering, Irish postcodes being optional, and military addresses, each added after a real incident. The team re-implemented the old behaviors one bug report at a time, effectively re-deriving the 900 lines they'd had all along, now spread across a worse month.
