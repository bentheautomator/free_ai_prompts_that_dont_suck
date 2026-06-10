---
title: Pick the Dominant Style, Never a Third
slug: pick-the-dominant-style-never-a-third
category: code-quality
tags: [universal, style, patterns]
works_with: all
severity: medium
one_liner: "AI finding two competing styles in a file and introducing a third"
---

# Pick the Dominant Style, Never a Third

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from responding to an inconsistent file by adding yet another style to it.

**[Copy-paste ready version](../../install/pick-the-dominant-style-never-a-third.md)** — just the instruction block, no explanation.

## The Problem

Real files are messy. Half the functions use promises with `.then()`, the newer half use `async/await`. Some handlers are class methods, others are arrow functions assigned to consts. Faced with this, an AI assistant frequently does the one thing guaranteed to make it worse: it writes its addition in a *third* style — generator-based, or a different callback flavor, or its own training-data favorite — because the file's inconsistency released it from any obligation to match.

The reasoning failure is subtle. When a file has one style, "match the file" is unambiguous and models mostly comply. When a file has two, the matching signal turns to noise, and the model falls back on its own prior — which usually matches neither faction. Now the file has three styles, the next AI session sees even less signal, and the decay compounds. Inconsistency in a file is an absorbing state: every contributor who treats it as permission rather than a tiebreaker-needed situation deepens it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Pick the Dominant Style, Never a Third

When a file or module contains competing styles, ALWAYS write new code in one of the existing styles — never introduce a third. Inconsistency is not permission; it's a tiebreak you must resolve, in this priority order:

1. **The project's enforced style** — formatter/linter config, style guide, or a convention clearly followed by the rest of the codebase
2. **The dominant style** — the one used by more of the file, by count
3. **The newer style** — if counts are close, match the most recently added code (check which style the newest functions use); codebases migrate forward, and you shouldn't add to the legacy pile
4. **The style nearest your edit** — if all else ties, match the code your change sits inside

Adding a third style is the only unambiguously wrong move: it reduces the file's signal for every future contributor (human or AI) and accelerates the decay you're reacting to.

**Also:**
- Do not take the inconsistency as an invitation to reformat the file to your preferred style — uninvited mass restyling buries the actual change and is a different failure, not a fix
- If the inconsistency is severe enough to genuinely block clean work, say so and ask whether a cleanup is wanted as a separate change
- This applies beyond formatting: async paradigms, component patterns, state management approaches, test structure within a file

**Red flags that you're about to violate this:**
- "This file is inconsistent anyway, so I'll write it the clean way..."
- "Neither of their approaches is ideal; mine is clearer..."
- "Since there's no convention here, I'll use the modern pattern..." (there are two conventions; pick one)
- "I'll take this opportunity to standardize the file..."
- "My addition is self-contained, its style doesn't need to match..."
- Noticing two styles and feeling freed rather than obligated

---

## Why It Works

1. **It names the exact trigger.** The failure fires at the moment the AI perceives "no consistent style" and feels released. Defining that perception as a tiebreaker situation, with a deterministic procedure, replaces the freedom with an algorithm.

2. **The priority order removes all discretion.** Config beats count beats recency beats proximity — every messy file now has exactly one right answer, so the model's own prior never gets a vote.

3. **It blocks both failure modes at once.** The same trigger produces either a third style or an uninvited mass reformat, depending on the model's mood. The instruction forbids both and routes cleanup ambition to a question.

4. **The recency rule aligns the AI with the migration.** Two styles usually means a migration in progress. Matching the newer code makes the AI a participant in the cleanup instead of fresh legacy.

## Origin

A data-layer file was mid-migration from callbacks to async/await — eleven functions converted, nine to go. An AI session added two new functions using an event-emitter pattern found nowhere else in the codebase, reasoning visibly in its output that "the file mixes styles, so I used a robust approach." The migration's author now had three paradigms to reconcile, the emitter pattern leaked into a consumer before cleanup, and the half-day migration became a multi-week one.
