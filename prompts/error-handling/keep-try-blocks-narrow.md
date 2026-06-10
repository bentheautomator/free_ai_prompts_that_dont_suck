---
title: Keep Try Blocks Narrow
slug: keep-try-blocks-narrow
category: error-handling
tags: [universal, errors, exceptions]
works_with: all
severity: medium
one_liner: "AI wrapping fifty lines in one try so nobody can tell what actually failed"
---

# Keep Try Blocks Narrow

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents one giant try block from making five different operations' failures indistinguishable.

**[Copy-paste ready version](../../install/keep-try-blocks-narrow.md)** — just the instruction block, no explanation.

## The Problem

Asked to add error handling to a function, an AI's favorite move is to indent the entire body one level and wrap it: `try:` at the top, `except Exception as e: logger.error(f"Error in process_order: {e}")` at the bottom. Between them sit a config read, a database query, an HTTP call, some arithmetic, and a file write — five operations with five different failure meanings, all now reporting through one handler that can only say "something in these fifty lines went wrong."

The wide block does two kinds of damage. Diagnostically, the handler can't name the failed operation, so its message is generic by construction, and any recovery logic it attempts must be valid for *all fifty lines at once* — which means it can't really attempt any. Semantically, it's a catch-radius problem: the handler was written with the HTTP call in mind, but it also now catches the `KeyError` from the config dict and the `ZeroDivisionError` from the arithmetic — bugs that deserved a crash, converted into "order processing failed, will retry," and the retry then re-runs the non-idempotent parts before the bug.

The model does this because wrapping the whole body is one edit with guaranteed coverage. Wrapping per-operation requires deciding which operations can fail and what each failure means — which is the actual work of error handling, and exactly the part being skipped.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep Try Blocks Narrow

A try block should cover one operation that can fail, not a whole function. Wrap the specific call you expect to raise; leave everything else outside.

When fifty lines share one handler, the handler can't say what failed, can't recover meaningfully, and catches bugs it was never written for.

- Put the try around the single failing operation: the `requests.get`, the `json.loads`, the file open — not the function body. Lines that can't raise the expected error don't belong inside
- One try block per distinct failure meaning: if the DB query and the HTTP call fail differently and matter differently, they get separate try blocks (or separate functions), not shared residence in one
- The narrower the block, the more the handler knows: `except requests.Timeout:` around just the call can say "payment-status check timed out for order {id}" and choose the right recovery — a function-wide handler can say only "error"
- Don't indent existing code into a new giant try as a way of "adding error handling" — that's adding error hiding; identify the fallible lines and wrap those
- Pure logic between fallible operations (arithmetic, dict access, formatting) stays outside try blocks so its bugs crash loudly instead of impersonating operational failures
- If a function needs five try blocks, that's often a sign it's five functions; refactoring beats one umbrella catch

**Red flags that you're about to violate this:**
- "I'll wrap the whole function to make sure nothing escapes..."
- "One try/except at the top level keeps it readable..."
- "Everything in here is risky, so the whole thing goes in the try..."
- "Indenting the body into a try is the quickest way to add handling..."
- "The handler can figure out what failed from the message..."

---

## Why It Works

1. **It ties handler quality to block width.** "The narrower the block, the more the handler knows" gives the model a gradient to optimize, not just a rule to obey — narrowness becomes the mechanism for the specific messages and real recovery it's separately asked to produce.

2. **It names the catch-radius hazard.** The wide block's worst effect — bugs in incidental lines being absorbed by a handler written for an I/O call — is invisible at generation time; describing it makes the umbrella catch read as dangerous rather than thorough.

3. **It blocks the one-edit shortcut explicitly.** "Indent the body and wrap it" is the precise mechanical action behind this antipattern; prohibiting that move forces the per-operation analysis that is the actual task.

4. **It keeps pure logic crash-honest.** Separating fallible I/O from infallible logic preserves the stack traces for genuine bugs, which is the debuggability the wide block quietly spends.

## Origin

A fulfillment function — fifty lines, one AI-supplied try/except logging "Error processing shipment" — started logging that message a few times per hour. The team assumed carrier API flakiness (the API call was the obvious suspect in the block) and added retries. Volume grew. The real failure was a `KeyError` on a renamed field in line 9, before the API call, crashing every affected shipment and now being *retried* uselessly. Narrow try blocks would have produced `KeyError: 'warehouse_id'` on day one; the umbrella version bought three weeks of misdiagnosis.
