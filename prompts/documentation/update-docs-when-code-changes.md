---
title: Update Docs When Code Changes
slug: update-docs-when-code-changes
category: documentation
tags: [universal, docs]
works_with: all
severity: high
one_liner: "AI changing code while leaving the docs describing the old behavior"
---

# Update Docs When Code Changes

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from shipping a code change while the documentation still describes the behavior it just removed.

**[Copy-paste ready version](../../install/update-docs-when-code-changes.md)** — just the instruction block, no explanation.

## The Problem

The AI renames `maxRetries` to `retryLimit`, updates every call site, runs the tests, and declares victory. Meanwhile `docs/configuration.md` still says `maxRetries: number of retry attempts (default 3)`, and the next person who reads it configures a key that no longer exists and gets the silent default. The code change was complete by every measure the AI checks — compiles, tests pass — because no measure the AI checks includes prose.

AI assistants do this because docs are invisible to their feedback loop. A stale doc produces no compiler error, no red test, no lint warning. The model's definition of "done" is built entirely from signals the doc can't emit. So unless the docs happen to be in the same file it's editing, they don't exist.

The damage is worse than missing docs. A missing doc sends the reader to the source. A wrong doc sends the reader confidently in the wrong direction, and they only discover the lie after the debugging session it caused.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Update Docs When Code Changes

ALWAYS treat documentation that describes the code you're changing as part of the change. A code edit that invalidates a doc is not complete until the doc is updated in the same change.

The core problem: stale docs fail silently. Wrong documentation is worse than none, because readers trust it and act on it.

Rules:
- Before finishing any change to behavior, configuration, defaults, CLI flags, environment variables, or public APIs, search the repo's docs (README, docs/, wiki files, inline guides) for mentions of what you changed
- Search by the old names: the old function name, the old flag, the old default value. Those strings are exactly what's now wrong
- Update every hit, or list the ones you deliberately left and why
- If you can't find docs but the change alters user-visible behavior, say so explicitly: "No docs mention this flag; nothing to update" is a verifiable claim, silence is not
- Renames and removals are the highest-risk cases. A doc describing a removed option misleads more aggressively than a doc missing a new one
- Never describe the change as complete while a known-stale doc remains. "Code done, docs pending" is an unfinished task, not a finished one with a footnote

**Red flags that you're about to violate this:**
- "The docs are a separate concern from this change..."
- "Tests pass, so the task is complete..."
- "Someone closer to the docs should update them..."
- "It's just a rename, the docs are probably generic enough..."
- "I'll mention the doc update as a follow-up suggestion..."
- "The user only asked me to change the code..."

---

## Why It Works

1. **It redefines "done."** The AI's completion signal is compiles-plus-green-tests. Explicitly adding "docs that describe this code" to the definition of complete closes the gap that prose can't signal through.

2. **It gives a mechanical search step.** "Update the docs" is vague; "grep the docs for the old name" is executable. The old identifier is a precise fingerprint of every place that's now lying.

3. **It blocks the deferral reframe.** "Docs as follow-up" feels responsible but means never. Declaring a known-stale doc as task-incomplete removes the polite exit.

4. **It states the asymmetry.** Models treat docs as nice-to-have because missing docs seem harmless. Naming that wrong docs actively misdirect readers flips the cost calculation.

## Origin

An assistant changed a job queue's default visibility timeout from 30 seconds to 5 minutes to fix duplicate processing. The ops runbook still said 30 seconds, so during the next incident the on-call engineer computed redelivery timing from the documented value, concluded the queue was wedged, and force-restarted workers mid-batch. Ninety minutes of incident time traced back to one undocumented default change that had been "complete" for six weeks.
