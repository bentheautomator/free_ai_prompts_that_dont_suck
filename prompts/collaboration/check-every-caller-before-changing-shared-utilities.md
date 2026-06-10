---
title: Check Every Caller Before Changing Shared Utilities
slug: check-every-caller-before-changing-shared-utilities
category: collaboration
tags: [universal, teamwork, shared-code]
works_with: all
severity: high
one_liner: "Stops bending a shared utility to fit one caller and breaking the other six"
---

# Check Every Caller Before Changing Shared Utilities

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from changing a shared function's behavior to suit the one caller it's working on, silently breaking every other caller.

**[Copy-paste ready version](../../install/check-every-caller-before-changing-shared-utilities.md)** — just the instruction block, no explanation.

## The Problem

The AI is fixing a feature, traces the bug into `formatDate()` in `utils/`, and discovers the function doesn't quite do what its caller needs. So it changes the function: a different default timezone, trimmed whitespace, a thrown error instead of a returned null. The feature works. The other six callers of `formatDate()` — written by four different people across three modules — now get behavior nobody asked for. Two of them break in production; the rest break subtly, which is worse.

This happens because the AI sees the shared utility through the keyhole of the current task. From where it's standing, the function has exactly one caller — the one in its context window — and "fix the function" looks identical to "fix the bug." It has no instinct for the fact that a function in `utils/`, `lib/`, `common/`, or `shared/` is a treaty between everyone who calls it.

The fix shipped in one file and the breakage surfaced in six others, often days later, in code the author of the change never looked at. That's the signature of this failure: the diff looks tiny and the blast radius isn't in the diff.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Check Every Caller Before Changing Shared Utilities

NEVER change the observable behavior of a shared function, class, or module until you have found and read every call site. A shared utility's behavior is a contract with all of its callers, not just the one in front of you.

- Before editing anything in `utils/`, `lib/`, `common/`, `shared/`, `helpers/`, or any file imported from more than one place, search the whole repo for its usages and list them.
- If every caller is fine with the change, proceed and say which call sites you checked.
- If even one caller depends on the current behavior — return value shape, null vs. throw, defaults, side effects, ordering — do not change it. Instead: add a parameter with a backward-compatible default, or write a new function next to the old one and use it from your caller.
- "Fixing" a shared function so it does what your caller expects is the most common form of this break. If your caller is the odd one out, adapt the caller, not the utility.
- Behavior includes the unglamorous parts: error types, log output, mutation of arguments, treatment of empty input. Callers depend on all of it, deliberately or not.
- If the change is genuinely right for everyone, update every caller in the same change and say so explicitly.

**Red flags that you're about to violate this:**
- "This shared helper almost does what I need, I'll just change it."
- "The function's current behavior is clearly a bug anyway."
- "It's a one-line change to the utility versus ten lines in my caller."
- "Nobody could be relying on it returning null here."
- "I'll fix the utility now and check the other callers later."

---

## Why It Works

1. **It forces the who-else-uses-this question before the edit**, converting an invisible constraint (other callers exist) into a mandatory, mechanical step (search and list them).
2. **It reframes shared code as an interface with people**, not just a module — the AI stops reasoning about one function and starts reasoning about a contract with N callers it can't see.
3. **It provides a cheaper legal move** (new parameter, sibling function, adapt the caller), so the AI isn't choosing between "break others" and "fail the task."
4. **It defines behavior broadly** — errors, defaults, side effects — closing the loophole where the signature survives but the semantics change underneath it.

## Origin

An assistant fixing a report page changed a shared `parseAmount()` helper to treat empty strings as zero instead of throwing, because the report had blank cells. The billing pipeline used the same helper precisely because it threw on blanks — that throw was the input validation. For four days, malformed invoice imports were silently recorded as $0.00 instead of being rejected, and the team spent a week reconciling accounts. The diff that caused it was two lines long.
