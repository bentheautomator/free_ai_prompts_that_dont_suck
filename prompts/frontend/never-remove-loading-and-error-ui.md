---
title: Never Remove Loading and Error UI
slug: never-remove-loading-and-error-ui
category: frontend
tags: [universal, frontend]
works_with: all
severity: high
one_liner: "Stops deletion of loading and error states during refactors and redesigns"
---

# Never Remove Loading and Error UI

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from dropping spinners, skeletons, empty states, and error messages while restyling or refactoring a component, leaving blank screens when anything is slow or fails.

**[Copy-paste ready version](../../install/never-remove-loading-and-error-ui.md)** — just the instruction block, no explanation.

## The Problem

A component handles four states: loading, error, empty, and data. Ask an AI to "redesign this list" or "simplify this component," and the rewrite handles one: data. The `if (isLoading) return <Skeleton/>` branch vanishes because the redesign mock only showed the happy state. The `error &&` block disappears because the refactor "cleaned up" conditional rendering. New components get built with no non-happy states at all, because the AI's mental test run has instant, successful data.

The consequence surfaces only on slow networks and failed requests — exactly the conditions absent from the AI's evaluation and most local dev. Users on a flaky connection now stare at a blank white region with no indication anything is happening. When the API errors, the component renders nothing, or worse, crashes on `data.items` of undefined, and the user's takeaway is "the page is broken" with zero recovery path. Removed empty states are subtler: a new user with no data yet sees a void instead of "Create your first project."

This is regression by omission. The diff shows beautiful new markup; what it doesn't show is the three branches that used to exist. Reviewers approve what's there, not what's missing.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Remove Loading and Error UI

NEVER ship or rewrite a data-driven component without explicit loading, error, and empty states. When refactoring, every state branch that existed before must exist after — restyled is fine, removed is a regression.

The happy path is one of four states. Code that only renders data works only on fast networks where nothing fails, which is no one's production.

- Before rewriting a component, inventory its current branches: loading, error, empty, partial, stale. Carry every one into the new version. If the redesign mock doesn't show them, that's a gap in the mock, not permission to delete.
- New data-driven components start from the four states, not from the data render: loading (skeleton or spinner), error (human-readable message plus a retry action where retrying makes sense), empty ("no results" with a next step), data.
- Error states must not just say something failed — render the message where the user is looking, and never let a failed fetch render the component as if there's simply no data. "Empty" and "errored" are different facts; collapsing them tells users their data is gone.
- Never let `data.something` execute before data exists; the loading branch is also your null guard.
- Async mutations (save, delete, submit) count too: a button that fires a request needs pending feedback (disabled + indicator) and a visible failure path, not fire-and-forget.
- If you genuinely intend to remove a state branch, say so explicitly in your summary so a human can veto it. Silent removal is never acceptable.

**Red flags that you're about to violate this:**

- "The design mock doesn't include a loading state, so the component doesn't need one."
- "I'll simplify by removing these conditionals — they clutter the render."
- "The API is fast, a spinner would just flash."
- "I'll handle errors in a follow-up; the happy path is the deliverable."
- "If the fetch fails, the list will just be empty, which is fine."
- "console.error in the catch block covers the error case."

---

## Why It Works

1. **It makes the inventory step explicit.** Refactor regressions happen because the AI rewrites from the mock instead of from the existing branches; requiring a before/after branch census catches the deletion at the only moment it's visible.
2. **It distinguishes empty from errored.** Collapsing fetch failure into "no data" is the most insidious variant — it looks handled — and only a rule that names the distinction prevents it.
3. **It extends the definition to mutations.** "Loading state" pattern-matches to fetches; save/submit buttons fail the same way and get skipped unless included explicitly.
4. **It converts silent removal into a flagged decision.** The AI sometimes has a defensible reason to drop a branch; routing that through an explicit statement preserves the legitimate case while killing the accidental one.

## Origin

During a visual refresh, an assistant rebuilt an orders table from the new design mock — which, like all mocks, showed a full table of tidy data. The loading skeleton, the error banner, and the "no orders yet" state all silently vanished. The week of a backend incident, every customer opening the page saw a pristine, completely empty table and concluded their order history had been deleted. Support escalations outnumbered the actual incident's impact, and the postmortem's root cause read: "the UI reported a failure as an empty success."
