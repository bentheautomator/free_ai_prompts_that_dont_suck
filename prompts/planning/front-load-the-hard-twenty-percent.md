---
title: Front-Load the Hard Twenty Percent
slug: front-load-the-hard-twenty-percent
category: planning
tags: [universal, planning]
works_with: all
severity: high
one_liner: "The easy 80% built first, invalidated by the hard 20% built last"
---

# Front-Load the Hard Twenty Percent

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents doing the comfortable majority of a task first, only to find the difficult remainder invalidates it.

**[Copy-paste ready version](../../install/front-load-the-hard-twenty-percent.md)** — just the instruction block, no explanation.

## The Problem

Every task has a gradient: scaffolding, types, CRUD handlers, and happy paths on one end; the gnarly bit — the concurrency edge, the third-party API quirk, the algorithm that actually has to be correct — on the other. Assistants reliably start at the easy end. The first hour produces a satisfying stack of files, the progress narration sounds great, and the hard part sits untouched at the bottom of the list.

Then the hard part arrives and turns out to have opinions. The rate-limited API can't be called per-item the way all the scaffolding assumes. The diffing algorithm needs state the data structures don't carry. Now the choice is rewriting the easy 80% or contorting the hard 20% to fit it — and assistants, anchored by their own sunk work, usually pick the contortion.

The easy work wasn't wasted because it was wrong in itself. It was wasted because it encoded guesses about the hard part, and the hard part is precisely the place guesses fail.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Front-Load the Hard Twenty Percent

ALWAYS identify the hardest part of the task and build it first — or at minimum prove it out first. NEVER spend the first hour on scaffolding, types, and happy paths while the difficult core sits unexamined.

The core problem: easy work generates visible progress, so the hard part drifts to the end — exactly where its discoveries are most expensive, because everything built before it encoded assumptions about it.

- Before starting, answer: "Which single piece of this is most likely to not work the way I currently imagine?" That piece goes first.
- Build the hard core in rough form before polishing anything around it. An ugly working version of the hard part is worth more than a beautiful frame around an empty middle.
- Let the hard part dictate the interfaces. Scaffolding adapts to the core cheaply; the core adapts to scaffolding painfully.
- If the hard part is hard because it's unknown, spend the first effort making it known: read the API docs, trace the existing code, run a small experiment.
- When you notice yourself deferring a step repeatedly, that step is probably the real task. Stop and do it.

**Red flags that you're about to violate this:**
- "Let me get the easy parts out of the way first..."
- "I'll set up all the boilerplate, then tackle the tricky bit..."
- "The hard part will make more sense once everything around it exists..."
- "I'm making great progress" (on the parts that were never in doubt)
- "I'll just assume the API supports batch mode and check later..."

---

## Why It Works

1. **It moves discovery to where it's cheap.** The hard part's surprises are fixed in quantity; the only variable is how much built work they invalidate. First means they invalidate nothing.

2. **It inverts the interface flow.** When the core exists first, surrounding code conforms to reality. When scaffolding exists first, the core gets bent to fit guesses — and bent cores are where bugs live.

3. **It neutralizes sunk-cost anchoring.** With 80% built, the pressure to contort the hard part rather than rework is enormous. With 0% built, there's nothing to protect.

4. **It makes progress reports honest.** "Five files done" means nothing if the open question is still open. Front-loading makes early progress measure actual risk retired.

## Origin

A bulk-import feature: the assistant spent its first session on upload UI, file parsing, validation messages, and progress bars — then reached the actual import and learned the ORM had no efficient bulk-upsert, requiring a raw-SQL staging-table approach that returned different error semantics. The validation messages, progress reporting, and parser output format were all built around per-row errors that no longer existed. The staging-table constraint, checked first, would have shaped everything correctly from the start.
