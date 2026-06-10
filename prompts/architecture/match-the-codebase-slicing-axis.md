---
title: Match the Codebase Slicing Axis
slug: match-the-codebase-slicing-axis
category: architecture
tags: [universal, architecture, structure]
works_with: all
severity: medium
one_liner: "A new controllers/ folder dropped into a codebase that slices by feature"
---

# Match the Codebase Slicing Axis

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from organizing new code by technical type in a feature-sliced codebase, or by feature in a layer-sliced one.

**[Copy-paste ready version](../../install/match-the-codebase-slicing-axis.md)** — just the instruction block, no explanation.

## The Problem

Every codebase slices along one axis. Some group by technical type — `models/`, `services/`, `controllers/`, a feature smeared across all three. Some group by feature — `checkout/`, `inventory/`, each folder containing its own models, services, and routes. Neither is wrong. What's wrong is the AI adding a feature to a feature-sliced codebase by creating `services/invoice_service.py` and `models/invoice.py`, because layer-slicing is what its training data looks like. Or the reverse: dropping a self-contained `reporting/` folder into a strict Rails-style layout where everything else lives in `app/models` and `app/controllers`.

One off-axis addition breaks the codebase's lookup function. Before: "everything about checkout is in `checkout/`." After: "everything about checkout is in `checkout/`, except invoices, which are in `services/` and `models/`, for historical reasons." Every search now has two phases. And misplaced code is a precedent magnet — the next contributor sees both axes in use and flips a coin, which is how codebases end up organized by archaeology.

The AI gets this wrong because folder structure is the one thing it tends not to study before writing. It sees the file it's editing, not the tree, and its prior for "where code goes" comes from a million tutorials, most of which slice by layer.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Match the Codebase Slicing Axis

ALWAYS determine how the codebase is sliced — by feature (`checkout/`, `billing/`, each self-contained) or by technical layer (`models/`, `services/`, `controllers/`) — before creating any file, and place new code on the same axis. NEVER introduce the other axis.

A codebase's structure is a lookup function; one off-axis addition breaks it for every future search and licenses the next contributor to break it further.

- Before creating a file, list the top one or two directory levels and identify the axis. Then ask: where does the most recently added comparable feature live? Put yours in the same kind of place
- Feature-sliced codebase: a new feature gets a new feature folder with its own models/services/routes inside, mirroring an existing folder's internal layout. Do not create or grow top-level `services/` or `models/` directories
- Layer-sliced codebase: the feature's parts go into the existing layer directories, named consistently with their siblings. Do not create a self-contained feature folder on the side, however much tidier it feels
- Mirror the internal conventions too: if every feature folder has `routes.py`, `service.py`, `models.py`, yours has those names, not `api.py`, `logic.py`, `entities.py`
- If the codebase is mid-migration (both axes present), match the newer pattern — usually findable from recent commits — and say which one you matched

**Red flags that you're about to violate this:**
- "Standard practice is a services layer, so I'll add a services folder..."
- "This feature is cleaner as its own self-contained module..."
- "The tutorial structure for this framework puts models in models/..."
- "I'll organize my new code properly even if the rest isn't..."
- "It's just one file in a new folder, the structure can absorb it..."

---

## Why It Works

1. **It makes structure an input instead of an output.** Listing the tree before writing forces the axis to be observed; the default failure is generating structure from training priors without ever looking.

2. **It uses the newest comparable feature as ground truth.** Codebases drift; the most recent feature encodes the team's current intent better than the oldest folder or any README.

3. **It protects the lookup function by name.** "Where is everything about X" having one answer is the concrete value of consistent slicing — stated as a mechanism, it outweighs "but my way is the best practice."

4. **It handles the migration case.** Half-migrated codebases are where AIs do the most damage; "match the newer pattern and say so" turns an ambiguous situation into a visible, reviewable choice.

## Origin

A feature-sliced app gained a `services/` directory from one AI-written feature, structured the way the framework's documentation suggested. Within four months it held parts of five features, because each subsequent contributor saw it and assumed it was the team's new direction. The team eventually held a meeting to decide whether to migrate to the structure none of them had chosen, or migrate back — and discovered nobody could say with confidence where two of the five features' business logic actually lived. They voted to migrate back, then spent a sprint doing it.
