---
title: Check Internal Signatures Before Calling
slug: check-internal-signatures-before-calling
category: code-quality
tags: [universal, apis, edits]
works_with: all
severity: high
one_liner: "AI calling your own functions with guessed argument lists and shapes"
---

# Check Internal Signatures Before Calling

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from calling the project's own functions with argument lists it inferred from their names.

**[Copy-paste ready version](../../install/check-internal-signatures-before-calling.md)** — just the instruction block, no explanation.

## The Problem

Library hallucinations get all the attention, but AI assistants guess at *your* functions too. It sees `sendNotification` referenced somewhere and calls it as `sendNotification(user, message)` — the signature is actually `sendNotification(payload: NotificationPayload, opts?: SendOpts)`. It calls `calculateDiscount(price, percent)` when the real order is `(percent, price)`, both numbers, no type error, wrong answer. It passes a positional argument where the function takes a keyword-only one, or assumes the return is the object when it's a `(object, error)` tuple.

The model does this because a descriptive function name is a strong prompt: from `getUserOrders(…)` it can generate a plausible call without ever reading the definition, and plausible is its native register. Internal code is *more* dangerous than libraries here, not less — there's no documentation to half-remember, no Stack Overflow corpus to anchor on, and often no type checker (Python, Ruby, plain JS) to object. Two same-typed parameters in guessed order is the canonical silent version: everything runs, the discount is calculated backwards, and the bug report arrives from accounting.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Check Internal Signatures Before Calling

NEVER call a project function whose definition you haven't read in this session. The name tells you what it probably does; only the definition tells you what it takes, in what order, and what comes back.

Internal functions are guessed at more confidently than library ones — no docs to check means nothing contradicts the guess. The silent failure is two same-typed parameters in the wrong order: no error, wrong result.

**Before writing a call to any function defined in this codebase:**
- Read the actual definition: parameter names, order, types, defaults, keyword-only/positional rules, and what's optional
- Read the return shape: object vs tuple, raw value vs wrapper, what's `None`/`null` when, whether it throws or returns errors
- Or read an existing call site and mirror it exactly — a working call is a verified signature
- Same-typed adjacent parameters (`(from, to)`, `(width, height)`, `(percent, price)`) deserve a second look: order mistakes here produce wrong answers, not errors
- Async matters too: confirm whether it returns a promise/coroutine you must await — calling an async function like a sync one fails quietly in some languages
- If you change your understanding mid-task ("oh, it takes a payload object"), re-check the *other* calls you already wrote against the corrected signature

**Red flags that you're about to violate this:**
- "Based on the name, this function takes..."
- "It probably returns the user object directly..."
- "The natural argument order would be..."
- "I called it this way earlier in the file..." (was that call verified, or also guessed?)
- "It's our own function, the shape will be obvious..."
- Writing a call to an internal function whose definition you have not had on screen

---

## Why It Works

1. **It severs name-to-signature inference.** The model treats a good function name as a spec. Stating that the name licenses *purpose* but not *signature* draws the line exactly where generation should stop and reading should start.

2. **It spotlights the same-typed-parameter trap.** Wrong-order calls that type-check are this failure's stealth payload — no error message will ever name them. Calling out the pattern makes the AI re-verify precisely the calls that look safest.

3. **It accepts a call site as proof.** Reading the definition is ideal; mirroring a working call is nearly as good and often faster. Two valid verification paths mean fewer skipped verifications.

4. **It handles guess-contamination.** One guessed call early in a session becomes "precedent" for later ones. Requiring re-checks after corrected understanding stops the first guess from propagating.

## Origin

A reporting feature called an internal `dateRange(start, end)` helper throughout — except the helper's actual signature was `dateRange(end, start)`, an old wart preserved for compatibility, documented only by its existing call sites, all of which passed arguments "backwards." The AI's calls were the intuitive way, the wrong way. Every report it generated covered an inverted range that the charting layer silently normalized into *something*, and the numbers were subtly wrong for three weeks before a quarter-boundary report made the inversion visible.
