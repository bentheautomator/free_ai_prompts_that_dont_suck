---
title: Confirm the Requirement Before Planning
slug: confirm-the-requirement-before-planning
category: planning
tags: [universal, planning, requirements]
works_with: all
severity: high
one_liner: "A flawless plan for a requirement the user never had"
---

# Confirm the Requirement Before Planning

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents planning the implementation of an interpretation instead of the requirement.

**[Copy-paste ready version](../../install/confirm-the-requirement-before-planning.md)** — just the instruction block, no explanation.

## The Problem

"Add export to the dashboard" supports at least four readings: export the visible chart as an image, export the underlying data as CSV, a scheduled email report, or an API for programmatic pulls. The assistant picks one — usually whichever it has generated most often — and immediately starts planning *that*. The plan grows steps, file lists, edge cases. It looks rigorous. All the rigor is downstream of an unexamined coin flip on what the user meant.

This is the most expensive place to be wrong, because everything after it is internally consistent. Plan review won't catch it: the plan is a good plan for the wrong thing, and a user skimming "1. Add CSV serializer..." may not register that they wanted charts as PNGs until they see the finished feature. Implementation, tests, and polish all faithfully amplify the initial misreading.

The defense costs one message. Before planning, state the requirement as you understand it — in behavior terms, not implementation terms — and flag the interpretations you discarded. Most of the time the user says "yes, that." The remaining times pay for the habit a hundredfold.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Confirm the Requirement Before Planning

NEVER plan an implementation until the requirement itself is stated and confirmed. Planning is choosing how; it presupposes the what, and the what is where ambiguous requests silently fork.

The core problem: an ambiguous request gets resolved by silent assumption, and then all subsequent rigor — plan, code, tests — faithfully amplifies the guess.

- Before planning, restate the requirement in one or two sentences of user-observable behavior: who does what, and what happens. No implementation vocabulary.
- If the request supports multiple meaningfully different readings, name them and ask which — one short message with options beats four hours on the wrong branch.
- Confirm the requirement, not the architecture. "You want users to download the table data as CSV — correct?" is the question. "I'll use a streaming serializer" is not.
- Watch for requests phrased as solutions ("add a cache here"): briefly confirm the underlying problem, since the stated solution may not solve it.
- Proceed without asking only when all readings converge on the same work, and say which reading you took anyway.

**Red flags that you're about to violate this:**
- "They probably mean the standard version of this feature..."
- "I'll plan the most common interpretation..."
- "The details will get clarified through the plan review..." (will they read it that closely?)
- "Asking feels like stalling, I should show initiative..."
- "Export obviously means CSV..."

---

## Why It Works

1. **It catches the fork at its origin.** Every later artifact — plan, diff, tests — is consistent with whichever reading was chosen, so no later checkpoint reliably exposes the misreading. Only the explicit restatement does.

2. **It uses behavior language as a misalignment detector.** Users can't always evaluate "add a serializer to the export pipeline," but they can instantly evaluate "you'll get a download button that produces a CSV." Implementation vocabulary hides disagreement; behavior vocabulary surfaces it.

3. **It prices the question correctly.** One clarifying message costs the user ten seconds; a wrong implementation costs the full round trip plus the un-building. The rule exists because the assistant's instinct prices the question as the expensive option.

## Origin

A request to "make search faster" produced a confident plan: add an index, denormalize two joins, cache hot queries. Three days of work, search latency halved. The user's actual complaint, surfaced at demo: results *appeared* slow because the UI waited for all facets before rendering anything — they'd wanted streaming results. Perceived speed, not query speed. One restatement message ("you want the query to return in under X ms — right?") would have gotten the correction immediately: "no, I want to see results while it loads."
