---
title: Put Errors at the Top
slug: put-errors-at-the-top
category: communication
tags: [universal, reporting, status]
works_with: all
severity: high
one_liner: "Failures hidden under paragraphs describing everything that went fine"
---

# Put Errors at the Top

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents errors and failures from being entombed beneath paragraphs of things that went fine.

**[Copy-paste ready version](../../install/put-errors-at-the-top.md)** — just the instruction block, no explanation.

## The Problem

Somewhere in the middle of a long, upbeat completion message — after the description of the refactor, after the list of files touched, often inside a parenthetical — sits a sentence like "(note: the build step errored, likely an environment issue, but the changes themselves are complete)." That sentence is the entire message. Everything above it is decoration on top of "the build is broken." But it's placed where messages put minor caveats, phrased the way messages phrase minor caveats, and read the way readers read minor caveats: not at all.

Models structure output narratively — setup, work, outcome, footnotes — and an error encountered along the way gets slotted where it occurred in the story, not where it ranks in importance. Add the mild trained aversion to opening on a negative, and the failure drifts downward and shrinks into a subordinate clause. The model isn't lying; every fact is in the message. It has just typeset the smoke alarm in the footer.

The reading pattern this collides with is universal: humans read the first lines of a status message and skim the rest with decelerating attention. Information placed below the fold of that attention curve was, functionally, never communicated.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Put Errors at the Top

ALWAYS lead with what failed. If anything errored, failed, or didn't work during the task, it goes in the first line of your message — before what succeeded, regardless of when it happened or how confident you are that it's minor.

The core problem: readers spend their attention on the first lines. An error below paragraph two is an error you chose not to communicate, whatever the message technically contains.

- First line of any message that contains a failure: the failure. "The build fails after my changes (error below). The refactor itself is done." Then the rest
- Never wrap an error in parentheses, a "note:" aside, or a footnote — those typographic forms tell the reader to skip it
- Never pre-shrink an error you haven't diagnosed: "likely an environment thing" is a guess dressed as triage. Report the error, then your guess, labeled as one
- Multiple failures: all of them up top, as a list, before any successes
- Include the actual error text or its key line, not just "there was an error"
- This applies mid-task too: an error in step 3 of 7 gets surfaced when it happens or at the top of the next update, not absorbed into the narrative

**Red flags that you're about to violate this:**
- "I'll describe the work first so the error has context..."
- "It's probably environmental, no reason to alarm anyone..."
- "Opening with a failure undersells everything that succeeded..."
- "A parenthetical keeps it from disrupting the flow..."
- "The error happened at the end, so it goes at the end..."
- "I'll mention it after the summary so the good news lands first..."

---

## Why It Works

1. **Position is the message.** The instruction takes the model's narrative ordering — which slots events where they happened — and overrides it with a severity ordering for exactly one category. One category is learnable; "order everything by importance" is mush.

2. **Banning the caveat typography removes the shrink ray.** Parentheses and "note:" don't just position an error badly; they instruct the reader to discount it. Outlawing the forms, not just the placement, closes the loophole where the error is technically first but visually a footnote.

3. **It separates reporting from triage.** "Probably environmental" feels like helpful context but functions as permission to ignore. Requiring the guess to be labeled as a guess, placed after the raw error, keeps the model's optimism from editing the facts.

## Origin

An assistant finished a dependency upgrade and posted a thorough, cheerful summary; the eleventh line noted in passing that "the integration test suite didn't complete (timeout — possibly a local quirk)." The summary was approved on its first three lines. The timeout was the upgrade deadlocking the connection pool, and it reproduced perfectly in production, where it was discovered the way these things are: by customers, at night.
