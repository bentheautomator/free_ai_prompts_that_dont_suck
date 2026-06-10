---
title: Update All Callers on Signature Change
slug: update-all-callers-on-signature-change
category: code-quality
tags: [universal, edits, apis]
works_with: all
severity: high
one_liner: "AI changing a function signature without fixing every call site"
---

# Update All Callers on Signature Change

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from changing a function's signature and leaving some or all of its call sites broken.

**[Copy-paste ready version](../../install/update-all-callers-on-signature-change.md)** — just the instruction block, no explanation.

## The Problem

Adding a required parameter to a function is a thirty-second edit. Finding the eleven places that call it is the actual job, and it's the part AI assistants routinely skip. The model edits the definition, updates the one call site it happens to have in context, and presents the change as complete — leaving ten callers passing the old argument list.

In compiled or type-checked languages, this is an annoying wall of build errors the user has to mop up. In Python, Ruby, or untyped JavaScript, it's far worse: the broken callers don't announce themselves. They fail at runtime, only when executed, and only on the code paths that reach them. A signature change in a logging helper can lurk in an exception handler for weeks until the first real error finally triggers a `TypeError: log_event() missing 1 required positional argument` — at the precise moment you needed logging to work.

The model behaves this way because its attention is anchored on the file in front of it. Call sites in other files aren't in the context window, and out of context means out of existence unless something forces the search.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Update All Callers on Signature Change

NEVER change a function's signature — parameters added, removed, reordered, renamed, return shape changed — without finding and updating every call site in the same change. The definition edit is the easy 10%; the callers are the job.

Call sites you haven't seen don't stop existing. In dynamic languages they break silently and detonate at runtime, often inside the error-handling paths that run least.

**When changing any signature:**
- Search the entire codebase for the function name before editing — including dynamic references: decorators, callbacks, event handler registrations, strings used for dispatch, and re-exports
- Update every caller in the same edit session, not "in a follow-up"
- Changed the return type or shape? Then every *consumer* of the return value is a call site too — check destructuring, `.property` access, and truthiness checks on the result
- In dynamically typed code, be extra exhaustive: nothing will catch what you miss
- If there are too many callers to update safely, say so and propose adding a parameter with a default instead — a deliberate compatible change beats an accidental breaking one
- After editing, re-run the search and confirm every remaining reference matches the new signature

**Red flags that you're about to violate this:**
- "I've updated the function and its usage..." (singular)
- "The compiler will catch any call sites I missed..."
- "This function is probably only called from here..."
- "I'll update the other callers if anything breaks..."
- "The new parameter is optional-ish, most callers won't care..."
- Editing a definition without having run a project-wide search for its name first

---

## Why It Works

1. **It re-proportions the task.** The AI experiences the definition edit as the work and callers as cleanup. Stating that callers *are* the job (90% of it) realigns effort with where the breakage actually lives.

2. **It expands "call site" beyond the obvious.** Decorated functions, event registrations, and return-value consumers are the references the AI never counts. Enumerating them converts unknown unknowns into a checklist.

3. **It removes the type-checker crutch.** "The compiler will catch it" is both a real rationalization and false in dynamic languages. Naming it neutralizes it where it's most dangerous.

4. **It offers a legitimate alternative.** Defaulted parameters give the AI a sanctioned path when full migration is too large, so it doesn't pick the unsanctioned one silently.

## Origin

An assistant was asked to make a notification helper accept a priority level. It added the required argument, fixed the two callers in the file it had open, and reported success. Five other services in the monorepo called that helper. Four broke loudly in CI; the fifth — a cron job with no tests — broke quietly and stopped sending payment-failure alerts for nine days. The missed alerts cost more than every hour the AI had ever saved.
