---
title: Put Cross-Cutting Concerns at Seams
slug: put-cross-cutting-concerns-at-seams
category: architecture
tags: [universal, architecture, layering]
works_with: all
severity: medium
one_liner: "Auth checks, logging, and retries copy-pasted inline into every function"
---

# Put Cross-Cutting Concerns at Seams

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from hand-rolling logging, auth checks, retries, and timing inline in each function instead of installing them once at a middleware, decorator, or interceptor seam.

**[Copy-paste ready version](../../install/put-cross-cutting-concerns-at-seams.md)** — just the instruction block, no explanation.

## The Problem

Asked to "add logging to the new endpoints," the AI opens each handler and adds `logger.info(...)` at the top and bottom — slightly different wording per handler, request ID included in some, duration measured in two of five. Asked to make an API call resilient, it writes a bespoke retry loop around that one call. Asked to protect a route, it pastes the permission check from a neighboring route, including the neighboring route's stale comment.

Inline cross-cutting code has a property that makes it uniquely treacherous: it's *almost* uniform. Forty-seven of fifty handlers check auth; finding the three that don't requires reading all fifty. The log format drifts per copy, so the "search all requests by trace ID" query silently misses the handlers written in March. Policy changes — log redaction, retry budgets, a new permission model — become fifty-file diffs where forty-nine get updated.

AI assistants default to inline because the task arrives scoped to one function, and the seam (middleware stack, decorator, interceptor, base handler) is global machinery the prompt never mentioned. Inline is also self-evidently correct in the diff: the check is *right there*. Whether it's the forty-eighth copy of the check is not visible in the diff.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Put Cross-Cutting Concerns at Seams

NEVER implement a cross-cutting concern — logging, auth checks, retries, timing, rate limiting, tracing, input sanitization, transaction wrapping — inline in individual functions. These belong at the codebase's seams: middleware, decorators, interceptors, base classes, or wrapper utilities that apply uniformly.

Inline copies are almost-uniform by construction: the gaps and drift between copies are exactly where the security holes and unsearchable logs live.

- First, find the seam the codebase already has: a middleware stack, a `@requires_auth`-style decorator, an interceptor chain, a `with_retries()` helper. Use it. Most codebases have one; the failure is not looking
- If the seam exists but lacks your case (a new permission level, a new retry policy), extend the seam — one change, every route — instead of going inline in your handler
- If no seam exists and you need the concern in 3+ places, build the smallest one (a decorator or wrapper function is enough) and apply it; don't lay copy number one of a future fifty
- Never hand-roll an inline retry loop, manual timing pair, or ad-hoc permission check next to an established mechanism that does the same thing
- Concern logic that genuinely varies per function (a domain-specific audit message) can be inline — but the transport of it (how it's logged, where it goes) still flows through the seam

**Red flags that you're about to violate this:**
- "I'll just add the check at the top of this one function..."
- "Touching the middleware affects every route, that feels too risky..."
- "The other handlers all have this block inline, so I'll match them..."
- "A retry loop is six lines, a shared helper is overkill..."
- "This endpoint is special, it can do its own logging..."

---

## Why It Works

1. **It makes "find the seam" the first move.** The inline default comes from not knowing the seam exists; mandating the search converts a knowledge gap into a one-grep step.

2. **It targets the almost-uniform failure mode.** The danger of inline concerns isn't repetition, it's *variation* — naming gaps and drift as the actual cost defuses "but the copies all work."

3. **It inverts the risk framing.** "Changing middleware is scary" is backwards: one reviewed change at a seam is strictly safer than fifty unreviewed inline variants; stating that flips the AI's caution toward the right target.

4. **It separates the variable part from the plumbing.** Letting per-function content stay local while routing transport through the seam removes the only legitimate argument for going inline.

## Origin

A security review found that 4 of 61 admin endpoints lacked the inline permission check — three written by an assistant matching a handler that happened to be public, one where the check was present but compared against the wrong role string, a drifted copy of a copy. Every endpoint had been reviewed at the time it was written; no diff had ever looked wrong, because no diff showed the other sixty. The remediation moved auth to route middleware, after which "which endpoints are protected" became a one-file question for the first time in the project's life.
