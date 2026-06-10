---
title: Read the Whole Stack Trace Before Fixing
slug: read-the-whole-stack-trace-before-fixing
category: debugging
tags: [universal, debugging, errors]
works_with: all
severity: high
one_liner: "AI reading only the top stack frame and patching the wrong layer"
---

# Read the Whole Stack Trace Before Fixing

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from reading only the top frame of a stack trace and patching whatever code happens to live there.

**[Copy-paste ready version](../../install/read-the-whole-stack-trace-before-fixing.md)** — just the instruction block, no explanation.

## The Problem

A stack trace is a complete map from "where the symptom surfaced" to "who asked for this." AI assistants routinely read the first frame, recognize a file they can edit, and start editing. `TypeError: Cannot read properties of undefined (reading 'id')` at `formatUser.js:12`? Patch `formatUser.js`. Never mind that `formatUser` has worked for two years and frame four shows a brand-new caller passing it the result of an unawaited promise.

The top frame is where the error was *detected*, which is usually several layers downstream of where it was *caused*. Patching the detection site means the bad value still flows through the system; you've just moved the crash, or worse, hidden it. The AI does this because the first frame is the first thing in its context window and editing it produces an immediately plausible diff, while walking the trace requires opening files it hasn't read yet.

The result is a fix that compiles, looks targeted, and leaves the actual bug fully intact one layer up — where it will surface again next week with a slightly different trace, and get a second wrong patch.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Read the Whole Stack Trace Before Fixing

NEVER propose a fix after reading only the top frame of a stack trace. Walk every frame from the crash site up to the application entry point before deciding which layer owns the bug.

The top frame is where the error was detected, not where it was caused. Fixing the detection site moves the symptom; fixing the causing site removes the bug.

- Read the entire trace first, including "caused by" / inner exception sections, which often contain the real story
- For each frame in your own code, ask: did this frame create the bad state, or merely receive it? Keep walking up until the answer is "created it"
- Open and read the source for at least the first frame in application code AND its caller before forming a theory
- Frames in library or framework code are almost never the bug; find the application frame that called into them with bad arguments
- If the trace is truncated ("... 23 more"), get the full version before concluding anything
- State explicitly which frame you believe owns the bug and why, before writing any fix

**Red flags that you're about to violate this:**
- "The error is on line 12 of formatUser.js, so that's where the fix goes..."
- "I can see the null access right here, I'll guard it..."
- "I don't need the rest of the trace, the message tells me enough..."
- "This frame is in code I've already read, so I'll start there..."
- "The deeper frames are just framework noise..."
- Writing an edit in the crash-site file before opening any of its callers

---

## Why It Works

1. **It separates detection from causation explicitly.** The AI's default model treats "line in the error" as "line with the bug." Naming the distinction breaks the shortcut that makes the top frame feel like the answer.

2. **It forces file reads the AI was avoiding.** The wrong-layer patch happens because the crash-site file is in context and the caller isn't. Requiring the caller to be read before theorizing removes the convenience gradient.

3. **It demands a stated ownership claim.** Having to say "frame 4 owns this because it constructs the user object" makes a top-frame guess visibly unjustified, to the AI and to the human reading along.

4. **It handles the truncation loophole.** Traces clipped by log limits are a common reason the real cause was never even visible; the instruction makes getting the full trace a precondition, not an optional nicety.

## Origin

A team asked their assistant to fix a nightly job crashing with a `KeyError` in a small dict-access helper. The AI added a `.get()` with a default to the helper — top frame, obvious patch. The job stopped crashing and started silently writing zeroes into a revenue report, because three frames up, a renamed CSV column meant the whole row mapping was wrong. Two days of reconciliation later, the actual one-line fix was in a file the AI had never opened.
