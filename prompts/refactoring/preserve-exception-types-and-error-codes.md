---
title: Preserve Exception Types and Error Codes
slug: preserve-exception-types-and-error-codes
category: refactoring
tags: [universal, refactoring, api]
works_with: all
severity: high
one_liner: "Stops refactors from changing thrown error types, codes, and statuses"
---

# Preserve Exception Types and Error Codes

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from changing the exceptions, error codes, and failure responses a function produces while cleaning up its internals.

**[Copy-paste ready version](../../install/preserve-exception-types-and-error-codes.md)** — just the instruction block, no explanation.

## The Problem

What a function throws is as much its interface as what it returns, and it's the half that refactors trample. An assistant tidying up validation replaces a raised `ValueError` with a custom `ValidationError` "for consistency," and the caller's `except ValueError` upstream stops catching anything. A cleanup converts a thrown exception into a returned `None`, or an error result object, or vice versa, and every caller built for the old failure style now mishandles failure. An HTTP handler refactor turns a 422 into a 400, or a domain-specific error code `INSUFFICIENT_FUNDS` into a generic `PAYMENT_FAILED`, and client retry logic keyed on the old value goes blind.

The model does this because error signaling is where codebases are least consistent, so "make it consistent" feels like the obvious cleanup, and because it sees the throw site but not the catch sites. The catcher might be three frames up, in another module, in a global error handler mapping exception types to HTTP responses, or in a client SDK shipped to customers. Changing what's thrown is changing all of them, blind.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Preserve Exception Types and Error Codes

When refactoring, a function's failure interface is frozen: the same conditions must produce the same exception types, error codes, status codes, and failure styles as before. NEVER change what code throws or returns on failure while changing its shape.

Every throw has catchers you can't see: upstream handlers, global error mappers, client retry logic, monitoring matchers.

- Keep exception types exact. Don't replace `ValueError` with a custom exception, a subclass, or a wrapper; don't consolidate distinct exception types into one "cleaner" hierarchy mid-refactor. `except` clauses upstream match on these names.
- Keep failure style: a function that throws keeps throwing; one that returns `None`/error tuples/Result objects keeps doing that. Converting between styles changes every caller's correctness silently.
- Keep error codes, enum values, and HTTP statuses byte-identical: `INSUFFICIENT_FUNDS` stays `INSUFFICIENT_FUNDS`; the 422 stays 422. Clients branch on these.
- Preserve which condition maps to which error. If empty input raised `ValidationError` and malformed input raised `ParseError`, don't merge them; callers may handle them differently.
- When wrapping or re-raising, preserve the original chaining behavior (`raise ... from e`, `cause`); error-reporting tools and debugging depend on it.
- Exception message text is lower-stakes but not free: anything matching on messages (tests, log alerts, client code that shouldn't but does) breaks. Don't reword messages without a reason, and mention it when you do.
- If the error design is genuinely bad, propose a redesigned failure interface as separate work with a deprecation story; never install it during cleanup.

**Red flags that you're about to violate this:**

- "I'll introduce a proper exception hierarchy while I'm in here."
- "Returning None is cleaner than throwing for a missing record."
- "These three error types are redundant; one will do."
- "400 is the more appropriate status for this case."
- "I'm just making the error handling consistent with the rest of the module."

---

## Why It Works

1. **It declares the failure interface to be interface.** Models guard return types but treat throws as internals; stating that catchers, mappers, and clients bind to error identities puts throws inside the behavior-preservation contract.
2. **"Every throw has catchers you can't see" counters the local view.** The model evaluates a throw site in isolation; naming the invisible consumers (global handlers, SDKs, alerting) explains why local consistency edits have non-local victims.
3. **Style conversion is named as its own hazard.** Throw-to-return conversions don't look like error changes to the model, they look like simplification; calling the style itself contractual closes the largest loophole.

## Origin

A refactor of a payments module replaced three ad-hoc exceptions with a unified `PaymentError`, updating all in-module handling. The API gateway's global error mapper, in a different repo, translated the old `CardDeclinedException` into a 402 that mobile clients used to prompt for a new card. Unified errors mapped to a generic 500, so declined cards started rendering as "something went wrong, try again later." Checkout conversion dipped for a week before anyone connected it to a cleanup that "didn't change behavior."
