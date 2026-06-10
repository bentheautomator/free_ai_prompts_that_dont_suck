---
title: Resume, Don't Restart, After Mid-Task Failures
slug: resume-dont-restart-after-failures
category: agents-and-automation
tags: [universal, agents]
works_with: all
severity: high
one_liner: "Scrapping work that was ninety percent done to start over from scratch"
---

# Resume, Don't Restart, After Mid-Task Failures

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the agent from responding to a late-stage failure by throwing away everything and rebuilding from zero.

**[Copy-paste ready version](../../install/resume-dont-restart-after-failures.md)** — just the instruction block, no explanation.

## The Problem

Step nine of ten fails, and the agent announces: "Let me take a different approach" — then deletes the feature directory and starts re-scaffolding from scratch. Eight completed, working steps go into the bin because the ninth one didn't compile. Sessions exhibiting this pattern can restart the same task three or four times, each rebuild reaching roughly the same point, hitting roughly the same snag, and triggering roughly the same demolition. The session's net output trends toward zero while its token spend trends toward the ceiling.

The restart reflex comes from how clean a fresh start feels compared to debugging. A blank file has no confusing error in it. Rebuilding is also work the agent knows how to do — it just did it — while diagnosing the snag at step nine is uncertain. So "different approach" becomes a euphemism for "same approach, again, from zero," driven by the hope that the problem won't reoccur rather than an understanding of why it occurred. It usually reoccurs.

There's a legitimate version of starting over: the approach itself is genuinely wrong, and continuing would compound the error. But that's a diagnosis, made by understanding the failure — not an escape hatch from having to understand it. The difference is whether the agent can say what was wrong with the old work, specifically, before deleting it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Resume, Don't Restart, After Mid-Task Failures

NEVER throw away completed work because a later step failed. A failure at step nine is a problem with step nine — the default response is to fix step nine, keeping steps one through eight.

The core problem: a fresh start feels cleaner than debugging, so "let me take a different approach" becomes a euphemism for rebuilding the same thing from zero and hoping the snag doesn't reoccur. It reoccurs.

- When a step fails, your first moves are diagnostic and local: what exactly failed, in which step's output, and what's the smallest change that fixes it? Demolition is not a diagnostic.
- Before deleting or rewriting ANY completed work, you must state specifically what is wrong with that work. "It's gotten messy" and "a clean start would be simpler" do not qualify. "Step three's data model can't represent what step nine needs, because X" qualifies.
- When a restart genuinely is justified, scope it: restart from the latest still-valid point, not from zero. If steps one through six remain sound, the restart begins at seven.
- Salvage by default. Even when an approach changes, completed work usually contains parts that carry over — tests, types, helper functions, hard-won config. Harvest before you bulldoze.
- Count your restarts. The second time you begin the same task from scratch in one session is a hard stop: you are in a rebuild loop. Report what keeps failing instead of building the same road to the same cliff a third time.
- If you've lost track of the state badly enough that restarting feels easier than understanding, that's a context problem — re-read your notes and the actual files, then decide.

**Red flags that you're about to violate this:**
- "Let me take a completely different approach..." (followed by the same approach)
- "It'll be faster to redo this cleanly than to debug it..."
- "The code has gotten too tangled, starting fresh..."
- "I'll just delete this directory and re-scaffold..."
- "This time it should work..."

---

## Why It Works

1. **It localizes the failure by default.** The restart reflex treats one failed step as evidence against all ten. Defaulting attribution to "the step that failed" keeps eight steps of value out of the blast radius unless evidence specifically implicates them.

2. **It charges admission for demolition.** Requiring a specific, stated defect in the work being discarded converts "fresh start feels better" into a claim that vague restlessness can't pay. The legitimate restart — a real diagnosed flaw — passes easily.

3. **It scopes even justified restarts.** "Restart from the latest valid point" splits the false binary between pushing forward and rebuilding from zero, which is where most of the salvageable value lives.

4. **It caps the rebuild loop at two.** The third from-scratch attempt is where token spend goes catastrophic; an explicit counter and hard stop converts the loop into a report while there's budget left.

## Origin

An agent building an importer hit a parsing error at the final validation step and declared a fresh approach. It deleted four hours of working code — fetcher, transformer, dedupe logic, tests — and rebuilt, arriving at the same validation step and the same error, which was a malformed sample file, not the code. It rebuilt twice more before the budget ran out. Every version of the importer it deleted had been correct.
