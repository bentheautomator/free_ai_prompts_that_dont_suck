---
title: Rebuild Before Claiming the Build Is Fixed
slug: rebuild-before-claiming-the-build-is-fixed
category: verification
tags: [universal, verification, builds]
works_with: all
severity: critical
one_liner: "Declaring a broken build fixed without running the build again"
---

# Rebuild Before Claiming the Build Is Fixed

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the assistant from declaring a build error resolved without rerunning the build that produced the error.

**[Copy-paste ready version](../../install/rebuild-before-claiming-the-build-is-fixed.md)** — just the instruction block, no explanation.

## The Problem

The build fails. The assistant reads the error, edits the offending line, and announces "Fixed the build error." What it did not do is run the build. The fix addressed the first error the compiler reported — and build failures arrive in queues, not units. Error two was hiding behind error one the whole time, and sometimes the "fix" itself introduced error three.

Assistants do this because the error message makes the failure feel fully understood: here's the line, here's the problem, here's the edit, done. Rerunning a build costs thirty seconds to several minutes, while writing "the build should succeed now" costs nothing and reads identically to the user. The asymmetry only becomes visible when someone else runs the build.

That someone is usually the user, at the worst time — right after being told it was fixed. A "fixed" build that still fails costs a round trip per hidden error, and each round trip starts with the user doing the verification the assistant skipped.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Rebuild Before Claiming the Build Is Fixed

NEVER declare a build fixed, compiling, or passing until you have rerun the exact build command that failed and watched it exit successfully.

The core problem: fixing the error you can see says nothing about the errors queued behind it. Compilers and bundlers report failures incrementally; only a full clean run proves the queue is empty.

- After editing in response to a build error, rerun the same build command before saying anything about the build's state. The edit is a hypothesis; the rerun is the test.
- "Fixed the type error" is a fine claim after an edit. "The build is fixed" is only a fine claim after a successful build.
- Expect cascades. If a rerun surfaces a new error, fix it and rerun again. Repeat until the build exits zero. Report how many iterations it took rather than narrating each one as a fresh success.
- Confirm the success signal explicitly: exit code zero and the expected artifact or "build succeeded" line in output. Some build wrappers print errors and exit zero anyway.
- If the build takes too long to run or you lack the environment, say "I made the fix but could not rebuild; run <command> to confirm" — and do not use the word "fixed" without that qualifier.

**Red flags that you're about to violate this:**
- "That was the only error, so the build is good now..."
- "The fix directly addresses the compiler message, no need to rebuild..."
- "Rebuilding takes three minutes; I'll skip it this once..."
- "I fixed the same kind of error earlier, this one will behave the same..."
- "The error was trivial — missing import, it's definitely fine..."

---

## Why It Works

1. **It names the queue.** Assistants genuinely model a failed build as "one error to fix." Stating that errors arrive incrementally replaces that model with one where a rerun is obviously necessary, not optional diligence.

2. **It splits the edit from the outcome.** Distinguishing "I fixed the type error" from "the build is fixed" gives the model an honest thing to say at the point it most wants to claim success, removing the pressure to overclaim.

3. **It pre-authorizes iteration.** Cascading errors feel like mounting failure, which tempts the model to stop rerunning and start asserting. Framing the loop as expected makes the third rerun routine instead of embarrassing.

4. **It closes the exit-code loophole.** Requiring the explicit success signal blocks the case where a wrapper script swallows the failure and the model claims victory off a misleading zero.

## Origin

An assistant was asked to fix a failing release build. It corrected the reported import error and posted "Build fixed, ready to release." The release engineer kicked off the pipeline, which failed eleven minutes in — on the next compile error in the queue, then again on the one after that. Three pipeline runs and forty minutes later, someone ran the build locally and cleared the remaining errors in one sitting. The original session contained exactly zero build invocations after the edit.
