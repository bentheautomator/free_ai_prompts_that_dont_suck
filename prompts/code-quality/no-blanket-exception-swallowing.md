---
title: No Blanket Exception Swallowing
slug: no-blanket-exception-swallowing
category: code-quality
tags: [universal, errors]
works_with: all
severity: critical
one_liner: "AI wrapping failing code in broad catch-and-ignore to make it look fixed"
---

# No Blanket Exception Swallowing

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from silencing errors with broad catch blocks instead of fixing what's actually failing.

**[Copy-paste ready version](../../install/no-blanket-exception-swallowing.md)** — just the instruction block, no explanation.

## The Problem

Code throws an error. The AI's task is to make the code work. The shortest path between those two facts is `try: ... except Exception: pass` — and AI assistants take that path with disturbing regularity. Variants include `catch (e) {}` with an empty body, `catch (e) { console.log(e) }` (logging as a burial rite), catching and `return null`, and the preemptive version: wrapping brand-new code in a broad try/except *before* anything has failed, as armor against errors the model worries it might have written.

Swallowing an exception doesn't handle the failure; it deletes the evidence. The operation still didn't happen — the file didn't write, the payment didn't record, the message didn't send — but now nothing knows it didn't happen. The error that would have been a stack trace at the failure point becomes corrupted state discovered weeks later, with the trail cold. This is among the most expensive bug classes in software, and it's manufactured on demand by an incentive mismatch: the AI is rewarded for "no errors," and a swallowed error *is* no error, by the only measure visible in the session.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Blanket Exception Swallowing

NEVER silence an error you haven't handled. Catching an exception and doing nothing — `pass`, empty catch, log-and-continue, `return null` — doesn't fix the failure; it deletes the evidence while the damage proceeds.

"No error visible" is not the goal. The goal is the operation actually succeeding, or failing in a way somebody finds out about.

**Rules:**
- When code throws, diagnose and fix the cause. A catch block is not a fix for an error you don't understand — it's a confession you stopped looking
- Catch SPECIFIC exceptions you expect and can genuinely handle (`FileNotFoundError` → create the file; `TimeoutError` → retry per the codebase's pattern). Broad catches (`except Exception`, bare `catch (e)`) need explicit justification — a top-level boundary that logs-and-reports, a documented isolation point — not convenience
- A real handler changes the outcome: retries, falls back to a defined behavior, surfaces a meaningful error to the caller, or cleans up and re-raises. If the body of your catch doesn't do one of those, you're not handling — delete the catch or escalate the question
- `log and continue` is only valid where continuing is *correct* — where the operation is genuinely optional. Logging an error from a required operation and proceeding is swallowing with a paper trail
- Never wrap new code in defensive try/except "just in case." If you're unsure your code is correct, that's a reason to verify it, not to mute it
- Match how this codebase handles and reports errors; route to its error tracker/handler where one exists

**Red flags that you're about to violate this:**
- "I'll add a try/except so it doesn't crash..."
- "This error isn't important, just log it and move on..."
- "Wrapping this in a catch makes it more robust..."
- "Returning null here keeps the flow going..."
- "The error only happens sometimes, so handle it gracefully..." (gracefully = silently?)
- Writing a catch block whose body you'd struggle to defend out loud

---

## Why It Works

1. **It exposes the incentive mismatch.** The AI optimizes for visible success, and a muted error is visibly successful. Naming "no error visible ≠ operation succeeded" attacks the exact proxy the model is gaming, usually without knowing it.

2. **It defines handling by outcome, not syntax.** To a model, a populated catch block *is* error handling. Requiring that the block change the outcome (retry, fallback, surface, re-raise) makes the empty rituals — log it, null it, pass — fail the definition.

3. **It distinguishes optional from required operations.** "Log and continue" is sometimes right, and a blanket ban would discredit the rule. Tying continuation to whether the operation was optional gives the AI a test it can actually apply.

4. **It blocks the preemptive armor.** Defensive try/except around fresh code is swallowing's larval form — errors muted before they've existed. Catching that habit separately matters because it doesn't *feel* like silencing anything.

## Origin

A data-import pipeline kept crashing on malformed rows, so an AI session was asked to make it robust. It wrapped the whole row processor in `except Exception: continue`. The crash stopped; the pipeline went green; everyone moved on. A schema change two months later made *every* row "malformed," and the pipeline spent eleven days importing nothing, green the entire time. The downstream analytics gap was discovered by the finance team at quarter close, which is the most expensive possible way to read an empty table.
