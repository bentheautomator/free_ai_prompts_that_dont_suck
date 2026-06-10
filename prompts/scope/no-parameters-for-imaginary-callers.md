---
title: No Parameters for Imaginary Callers
slug: no-parameters-for-imaginary-callers
category: scope
tags: [universal, scope, over-engineering]
works_with: all
severity: medium
one_liner: "AI adding parameters and options for callers that don't exist"
---

# No Parameters for Imaginary Callers

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from widening function signatures with optional parameters that no actual caller needs.

**[Copy-paste ready version](../../install/no-parameters-for-imaginary-callers.md)** — just the instruction block, no explanation.

## The Problem

The request: a function that sends a Slack message to a channel. The delivery: `send_message(channel, text, thread_ts=None, retry=True, formatter=None, on_failure=None, dry_run=False, client=None)`. One caller exists. It passes two arguments. The other six parameters serve callers that live only in the AI's imagination.

Signature padding happens because every parameter looks like generosity — surely someone, someday, will want to inject their own formatter. But a signature is a contract, and every optional parameter is a clause that must be honored forever. The untested combinations pile up (does `dry_run=True` with `on_failure` set call the handler?), the docstring grows a table, call sites become keyword soup, and when the function needs real changes, every vestigial parameter is a constraint the refactorer must preserve or audit. Six defaults that nobody overrides are not flexibility; they're a fence of frozen guesses around the function's future.

The function with two parameters can grow a third the day a real caller needs it, with that caller's actual requirements in hand. The function born with eight can never lose one without a breaking change.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Parameters for Imaginary Callers

Design function signatures for the callers that exist. NEVER add parameters, defaults, or injection points for callers you are imagining.

The core problem: every parameter is a permanent contract clause, and ones added speculatively freeze your guesses into the signature while their combinations ship untested.

- Write the signature the actual call sites in this change require, and nothing wider
- No optional parameters whose only justification is "someone might want to customize this"
- No dependency-injection parameters (`client=None`, `logger=None`, `clock=None`) added by reflex; inject only what the current task or the project's established testing pattern actually requires
- No flag parameters (`dry_run`, `verbose`, `strict`) without a caller in this change that passes a non-default value
- A parameter whose value is identical at every call site is configuration nobody asked for; hardcode it
- Adding a parameter later, when a real caller arrives, is a small and well-understood change; say so in one sentence if you think that day is coming, and leave the signature narrow

**Red flags that you're about to violate this:**
- "I'll make this injectable in case someone wants a custom one..."
- "An optional flag covers the other use case for free..."
- "Callers might want to override the default behavior..."
- "More parameters with sensible defaults can't hurt the existing caller..."
- "I'll accept a callback so this stays extensible..."
- "Better to design the full signature now than break it later..."

---

## Why It Works

1. **It grounds design in observable callers.** "Callers that exist" is checkable in the diff; "callers that might want" is unbounded, and the AI fills unbounded spaces with parameters.

2. **It prices the default as a contract, not a freebie.** The AI models `=None` defaults as costless because existing calls keep working; naming the permanent support and combination-testing burden corrects the accounting.

3. **It defuses break-it-later fear.** The "design the full signature now" rationalization assumes later changes are expensive; stating that adding a parameter is a small, well-understood change removes the motive for speculation.

4. **It gives a mechanical test.** "Identical value at every call site means hardcode it" lets the AI audit its own signature without judgment calls.

## Origin

A utility for generating signed URLs was requested with one expiry policy. It shipped with seven parameters, including a pluggable hash algorithm "for future flexibility." A later security audit had to verify every parameter combination, and found that one non-default path, never used by any caller, signed with a deprecated algorithm. The team paid an audit finding, remediation work, and a release note for a code path that existed only because the signature was designed for imaginary callers.
