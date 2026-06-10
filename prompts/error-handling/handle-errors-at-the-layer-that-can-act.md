---
title: Handle Errors at the Layer That Can Act
slug: handle-errors-at-the-layer-that-can-act
category: error-handling
tags: [universal, errors, exceptions]
works_with: all
severity: high
one_liner: "AI burying error handling in low-level helpers that lack context to decide"
---

# Handle Errors at the Layer That Can Act

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents low-level utilities from making recovery decisions that only their callers have the context to make.

**[Copy-paste ready version](../../install/handle-errors-at-the-layer-that-can-act.md)** — just the instruction block, no explanation.

## The Problem

A generic `http_get()` helper catches its own timeouts, logs "request failed," and returns `None`. It has now made a policy decision — timeouts are non-fatal and worth nothing more than a log line — on behalf of every caller it will ever have. The health-check caller wanted that timeout to mean "mark the node down." The payment-status caller needed it to mean "retry, then alert." The report generator could genuinely shrug it off. One of those callers is now correct by coincidence; the helper chose for all three without knowing any of them.

When asked to add error handling, AI assistants put the try/catch where the error *occurs*, because that's the code on screen. But the layer where an error occurs is usually the layer with the least context about what it means. A `save()` method doesn't know if it's saving a draft (failure is shruggable) or a payout record (failure is a page-someone event). Handling at the bottom hardcodes one answer.

The symptom is recognizable: utility modules dense with try/catch/log/return-None, and business logic above them that never sees an exception and never gets to make a decision — it just receives mysterious Nones.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Handle Errors at the Layer That Can Act

Catch an error at the layer that has both the context to decide what it means and the power to do something about it. Low-level helpers should add context and propagate — NEVER absorb errors and return degraded values on behalf of callers they know nothing about.

- A reusable function (HTTP helper, DB accessor, file util) must not decide that its own failures are tolerable; it doesn't know whether the caller is rendering a widget or moving money
- Default behavior for low layers: let the exception propagate, optionally wrapping it with added context (`raise StorageError(f"writing {path}") from e`) — do not catch-log-return-None
- Catch at the layer where a meaningful decision exists: the request handler that can return a 503, the job runner that can reschedule, the orchestration code that knows whether this step is optional
- One error, one handling site: if the bottom layer already logged-and-absorbed, the top layer can never apply its policy; if both handle, you get duplicate handling and contradictory outcomes
- "Adding error handling" to a utility usually means *removing* the decision from it: wrap-and-rethrow with context is the utility's whole job
- If a helper must offer a lenient mode, make it explicit at the call site (`fetch(url, on_error="return_none")`) so each caller opts in knowingly rather than inheriting a hidden policy

**Red flags that you're about to violate this:**
- "I'll handle the error right where the request is made..."
- "The helper can just log it and return None..."
- "Callers shouldn't have to worry about failures..."
- "This keeps the exception from bubbling up..."
- "Every function should handle its own errors..."

---

## Why It Works

1. **It replaces "where it occurs" with "where it's decidable."** The model's default placement heuristic is proximity. Giving it a competing heuristic — context plus authority to act — redirects the catch block to the layer that can actually answer "now what?"

2. **It reframes propagation as the helper doing its job, not shirking it.** Models read an uncaught exception in a utility as incomplete work; defining wrap-with-context-and-rethrow as the utility's responsibility makes propagation feel like completion.

3. **It names the multi-caller problem.** A helper has many callers with different stakes; pointing out that absorbing errors picks one policy for all of them exposes why bottom-layer handling can't be right even when it looks tidy.

4. **The explicit-lenient-mode pattern preserves convenience honestly.** Sometimes return-None really is wanted; making it an opt-in parameter keeps that use case while killing the invisible default.

## Origin

An assistant was asked to "make the storage client more defensive." It added catch-log-return-None to every method. The notification service upstream interpreted None from `get_preferences()` as "user has no preferences" and fell back to sending everything to everyone. During a brief storage outage, the system promoted every failure to "no preferences on file" and emailed an entire user base notifications they had explicitly opted out of. The outage lasted four minutes; the unsubscribe wave and the apology email lasted considerably longer.
