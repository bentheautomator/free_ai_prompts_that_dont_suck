---
title: Don't Convert Exceptions to Boolean Returns
slug: dont-convert-exceptions-to-boolean-returns
category: error-handling
tags: [universal, errors, exceptions]
works_with: all
severity: high
one_liner: "AI compressing rich failures into return False, discarding every detail"
---

# Don't Convert Exceptions to Boolean Returns

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents functions that compress every possible failure into a single uninformative False.

**[Copy-paste ready version](../../install/dont-convert-exceptions-to-boolean-returns.md)** — just the instruction block, no explanation.

## The Problem

`def send_invoice(invoice) -> bool: try: ...; return True except Exception: return False`. This signature is a data destruction device. Inside the except, there was an exception object holding the failure's type, message, stack trace, and cause chain. The function compresses all of it into one bit. The caller receives `False` and can ask exactly one question — did it work? — with no way to ask the questions that matter: was the invoice malformed (don't retry), was the mail server down (retry later), was the template missing (page a developer)?

The bit then decays further. Callers write `if not send_invoice(inv): logger.error("send failed")` — an error message reconstructing less information than the exception carried for free. Or they ignore the return entirely (`send_invoice(inv)` as a statement, no check — booleans don't demand handling the way exceptions do), and now failure is fully silent. AI assistants emit this shape constantly because it reads as tidy and "doesn't throw," and a bool-returning signature looks friendly in a quick demo. It's exception swallowing wearing a return type as a disguise.

A cousin appears in older C-style habits: returning 0/-1, or `(success, value)` tuples where the error half is just `False` or `None`.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Convert Exceptions to Boolean Returns

NEVER catch an exception and return `False`/`True` as the function's whole account of what happened. One bit cannot carry the failure's type, cause, or context — and unlike an exception, it can be silently ignored.

- Default: don't catch at all. Let the operation raise; the caller gets the full exception with type and stack, and *cannot accidentally ignore it*
- If the API must not throw, return a structured result, not a bool: `Result[Receipt, SendError]`, `(ok, error)` where `error` is the exception object, or a small dataclass with `success`, `error_type`, `detail` — something the caller can branch on and log faithfully
- Never write `except Exception: return False` — the broad catch plus the bit means even bugs (AttributeError, TypeError) report as the operation politely declining
- Status-code conventions (`return -1`, `return 0` on error) carry the same flaw plus ignorability; don't introduce them into languages with exceptions
- If you find callers writing `if not f(): log("f failed")`, that's the signal the boolean is starving them — fix `f` to raise or return structured errors rather than enriching the guesswork
- Booleans are fine for actual predicates (`is_valid(x)`, `exists(key)`) where False is an *answer*; the rule is about failure reporting, where False is a *cover-up*

**Red flags that you're about to violate this:**
- "Returning a bool keeps the interface simple..."
- "The caller only needs to know if it worked..."
- "True/False is cleaner than making them handle exceptions..."
- "If it fails, they can just check the logs..."
- "I'll return False for now and we can add detail later..."

---

## Why It Works

1. **It quantifies the loss.** "One bit" versus type-message-stack-cause makes the compression visible as destruction, not simplification — the model's "simple interface" story doesn't survive the accounting.

2. **It highlights ignorability as a separate hazard.** Exceptions interrupt; booleans wait politely to be checked. Naming this difference explains why the bool version fails even when callers are diligent today — the next call site won't be.

3. **It distinguishes predicates from failure reports.** Banning all bool returns would be wrong and the model would discard the rule; the answer-vs-cover-up test keeps `is_valid()` legal while blocking `send_invoice() -> bool`.

4. **It treats caller-side log archaeology as a symptom.** `if not f(): log("failed")` is the observable downstream damage; flagging it gives the model a way to detect the antipattern in existing code, not just avoid writing it.

## Origin

A notification module written by an assistant returned `False` for every failure: bad templates, dead SMTP, malformed addresses, and one genuine TypeError introduced later — all the same bit. Callers, having nothing to log, logged "notification failed" 30,000 times over a month. When someone finally investigated, fixing the logging just to *see* the real errors took longer than fixing all four underlying problems combined, because every layer had been built around a return type with the information content of a coin flip.
