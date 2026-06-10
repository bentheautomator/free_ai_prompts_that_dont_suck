---
title: Understand the Task Before You Edit
slug: understand-the-task-before-editing
category: planning
tags: [universal, planning, foundational]
works_with: all
severity: high
one_liner: "Opening the editor on sentence two of the task description"
---

# Understand the Task Before You Edit

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the assistant from making its first edit before it can state what the task actually requires.

**[Copy-paste ready version](../../install/understand-the-task-before-editing.md)** — just the instruction block, no explanation.

## The Problem

Ask an AI assistant to "fix the duplicate notification bug" and watch what happens in the first thirty seconds: it greps for "notification," opens the first matching file, and starts editing. It has not reproduced the bug, has not found where notifications are dispatched versus rendered, and has not determined whether "duplicate" means two database rows or one row rendered twice. It is editing a file it found by keyword match, guided by a mental model it built from the task title.

This happens because generating code feels like progress and reading code feels like stalling. The assistant is rewarded — by its own sense of momentum and often by impatient users — for producing a diff fast. So it skips the step where it confirms what the task *is* and jumps to the step where it produces *something*. The something is frequently a competent fix for a problem nobody has.

The cost is asymmetric. Two minutes of orientation would have revealed that the dedup logic lives in the worker, not the UI. Instead you get a plausible-looking edit to the wrong layer, a "fixed!" message, the bug still reproducing, and a second round where the assistant now has to undo its own confident wrong turn.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Understand the Task Before You Edit

NEVER make your first edit before you can state, in one or two sentences, what the task requires and where in the code that requirement lives. If you cannot state both, you are not ready to edit — you are guessing with a keyboard.

The core problem: producing a diff feels like progress, so the urge is to start typing off the task title alone and backfill understanding later. Later never comes; the wrong edit comes instead.

- Before the first edit, write down: what the user wants changed, what "working" looks like afterward, and which part of the system owns that behavior.
- For a bug: reproduce it or trace the failing path in the code before touching anything. "I found a file with a matching keyword" is not a diagnosis.
- For a feature: locate where the feature plugs in — the entry point, the data it reads, the thing that calls it — before writing the feature itself.
- If the task description is ambiguous on a point that changes what you'd build, ask. One clarifying question is cheaper than one wrong implementation.
- Reading three relevant files start-to-finish beats grepping ten files for keywords. Keyword proximity is not relevance.
- It is fine to explore by editing in a scratch sense — adding a log line, writing a throwaway repro script. It is not fine to begin the actual change.

**Red flags that you're about to violate this:**
- "I can see roughly what's needed, let me start typing..."
- "This file matches the keyword, the fix probably goes here..."
- "I'll figure out the details as I edit..."
- "The task title is clear enough..."
- "Reading more code first would just slow things down..."

---

## Why It Works

1. **It makes understanding a gated artifact, not a feeling.** "Can you state the requirement and its location in two sentences?" is checkable. "Do you understand the task?" is not — the assistant always feels like it understands.

2. **It severs the keyword-match shortcut.** The default failure path is grep, first hit, edit. Explicitly naming keyword proximity as non-evidence forces an actual trace of the behavior.

3. **It reframes reading as the fast path.** The assistant skips orientation because orientation feels slow. Pointing out that the wrong edit costs two full rounds makes the two-minute read the speed move, not the stall.

4. **It permits exploratory motion.** Banning all action before understanding would get ignored. Allowing log lines and repro scripts gives the urge-to-act a harmless outlet.

## Origin

A user reported that order confirmation emails were "sent twice." The assistant grepped "email," found the template renderer, and spent an hour adding a deduplication cache to the rendering layer. The actual cause: a retry policy on the message queue re-enqueueing on slow SMTP responses — visible in the first twenty lines of the worker the assistant never opened. The rendering-layer cache shipped, masked the symptom for small volumes, and turned into its own bug under load.
