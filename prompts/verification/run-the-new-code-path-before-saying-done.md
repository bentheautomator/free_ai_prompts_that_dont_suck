---
title: Run the New Code Path Before Saying Done
slug: run-the-new-code-path-before-saying-done
category: verification
tags: [universal, verification, evidence]
works_with: all
severity: high
one_liner: "Declaring a feature done when the new code has executed zero times"
---

# Run the New Code Path Before Saying Done

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the assistant from marking a feature complete when the code it just wrote has never executed even once.

**[Copy-paste ready version](../../install/run-the-new-code-path-before-saying-done.md)** — just the instruction block, no explanation.

## The Problem

Count the number of times newly written code actually ran before the assistant said "done." The answer is frequently zero. The function was written, it parses, it looks right, and the session ends with a summary of what it "does" — all in the present tense, as if describing observed behavior, when no process has ever reached that code.

Zero-execution code fails in characteristic ways: a misspelled attribute, an argument passed in the wrong order, an await missing on the one call that matters, a None where a list was assumed. These are exactly the bugs that one execution catches and infinite rereading does not. The assistant skips that one execution because writing code feels like the work and running it feels like a formality — and because describing intended behavior is indistinguishable, on the page, from describing actual behavior.

The user inherits a feature that has literally never happened. The first person to execute the new path is the user, in the worst possible role: unpaid first tester of code that was declared finished.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Run the New Code Path Before Saying Done

NEVER report new code as done, working, or complete while its execution count in this session is zero. Code that has never run is a draft, whatever it looks like.

The core problem: writing code and running code feel like the same act, but only one of them produces evidence. A path that has executed zero times has a defect rate you have not measured.

- Before declaring done, cause the new code to actually execute at least once: call it, run a test that reaches it, hit the endpoint, invoke the script. Reaching the file is not enough; the new lines must run.
- Confirm the path was actually taken — a print, a log line, a return value, a test assertion that could only succeed if the new branch executed. Code adjacent to the new code running is not the new code running.
- If the path is hard to reach (needs auth, external service, rare condition), exercise it directly: a scratch script, a REPL call, a targeted test. Difficulty of reaching the path is the reason to run it, not the excuse to skip it.
- If you truly cannot execute it in this environment, label the deliverable: "written but never executed — run <specific command> to exercise it."
- Describe unexecuted code in terms of intent ("this is meant to..."), never observed behavior ("this does...").

**Red flags that you're about to violate this:**
- "The implementation is straightforward, running it is a formality..."
- "It follows the same pattern as the existing handlers, so it'll behave the same..."
- "Setting up a call to this would take longer than writing it did..."
- "I traced through the logic mentally and it's correct..."
- "The types check, which exercises most of what could go wrong..."

---

## Why It Works

1. **It makes the execution count explicit.** The model never thinks "this code has run zero times" unless asked to; surfacing that number turns a vague confidence into a checkable, embarrassing fact.

2. **It distinguishes reaching from running.** A loophole in "I tested it" is running a neighboring path and crediting the new one. Requiring evidence the new lines executed closes it.

3. **It controls the verb tense.** Forcing "is meant to" for unexecuted code prevents the prose itself from laundering intention into observation — the exact mechanism by which untested work gets reported as working.

4. **It inverts the difficulty excuse.** Hard-to-reach paths are the least-rehearsed and most bug-prone; stating that difficulty raises the obligation to run removes the most common justification for skipping it.

## Origin

A data-export feature was delivered with a confident walkthrough of its behavior: streaming, batching, progress reporting. The first real invocation, by the requester, crashed on line two of the new function — a method called on the wrong object, the kind of error any execution would have caught instantly. Session review confirmed the export path had run zero times before delivery. The walkthrough had described a program that, in a strict sense, had never happened.
