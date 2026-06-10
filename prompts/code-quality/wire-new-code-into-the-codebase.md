---
title: Wire New Code Into the Codebase
slug: wire-new-code-into-the-codebase
category: code-quality
tags: [universal, completeness]
works_with: all
severity: high
one_liner: "AI writing new code that nothing actually calls, mounts, or registers"
---

# Wire New Code Into the Codebase

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from delivering functions, routes, and components that exist but are never connected to anything.

**[Copy-paste ready version](../../install/wire-new-code-into-the-codebase.md)** — just the instruction block, no explanation.

## The Problem

The AI writes a beautiful route handler — validation, error cases, the works — and never adds it to the router. A middleware function, never inserted into the chain. A migration file, never registered in the sequence. A React component, exported and imported by nothing. A cron job class with no schedule entry. The code is genuinely good; it's also genuinely unreachable, which makes it dead on arrival.

This happens because the model's unit of "task" is the artifact, not the integration. "Write an endpoint for password reset" parses as *write the handler* — and the registration line in `routes.py`, the entry in `urls.ts`, the export from the barrel file, the schedule in the cron config are all in *other files* the model never opened. The dangerous part is how complete it looks: the diff is substantial, the code reviews well, the summary says "endpoint added." Whether anyone notices before a user hits a 404 depends entirely on whether someone manually exercised the feature — and "the AI said it's done" is precisely the situation where nobody does.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Wire New Code Into the Codebase

New code isn't done when it's written — it's done when something reaches it. ALWAYS complete the wiring: the registration, mounting, export, scheduling, or call that makes your new code part of the running system.

A handler the router doesn't know about is a 404 with excellent internals. The artifact is half the task; the connection is the other half, and it usually lives in a file you haven't opened yet.

**For every new piece of code, identify and complete its connection point:**
- Route handlers → registered in the router/URL config
- Middleware → inserted into the middleware chain, in the right position
- Components → imported and rendered by an actual parent (and exported from the barrel file if the project uses them)
- Event handlers/listeners → subscribed to the emitter, queue, or signal
- Migrations → named/numbered so the migration runner picks them up
- Scheduled jobs → an actual schedule entry in the cron/scheduler config
- CLI commands → registered with the command group/parser
- DI services → bound in the container/module providers
- Find the connection convention by looking at how an *existing* sibling is wired, and wire yours the same way
- After wiring, trace the path once: from entry point (URL, event, schedule, import chain) to your code, confirming each hop exists. If you cannot complete the wiring (e.g., the parent component is ambiguous), say so explicitly — never present unwired code as a finished feature

**Red flags that you're about to violate this:**
- "The handler is implemented — the feature is complete..."
- "They'll hook it up wherever it fits best..."
- "The registration is trivial, I'll focus on the logic..."
- "I've created the component; integration is a separate concern..."
- "The framework probably auto-discovers this..." (verified, or assumed?)
- Finishing a feature without having edited any file that *references* your new code

---

## Why It Works

1. **It moves the definition of done from artifact to reachability.** The model optimizes for the deliverable it can see. "Something must reach it" makes the invisible registration file part of the success condition.

2. **The checklist names the second file.** Each wiring point (router, chain, schedule, container) is a concrete file the AI now knows to open — converting "integration" from an abstraction into a short list of edits.

3. **The trace is a cheap end-to-end proof.** Walking entry point → code, hop by hop, catches both missing wiring and wrong wiring (middleware in the wrong order, route shadowed by another) in one pass.

4. **It punctures auto-discovery optimism.** "The framework probably picks this up" is the rationalization that lets the AI skip the check exactly when conventions (file naming, decorators, directory placement) silently disqualify the new file.

## Origin

A team requested a scheduled cleanup job for expired upload tokens. The AI delivered a well-tested job class with batching and dry-run support — and no entry in the scheduler config. The summary read "cleanup job implemented and tested," which was technically true. Four months later, the uploads table had grown enough to degrade query performance across the product, and the investigating engineer found the cleanup job sitting in the repo: complete, correct, and never once executed.
