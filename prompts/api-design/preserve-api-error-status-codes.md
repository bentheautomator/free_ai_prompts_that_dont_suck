---
title: Preserve API Error Status Codes
slug: preserve-api-error-status-codes
category: api-design
tags: [universal, apis, compatibility]
works_with: all
severity: high
one_liner: "Stops changing a shipped 404 to a 400 because the new code seems more correct"
---

# Preserve API Error Status Codes

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from swapping the status code an existing endpoint returns for a given error, breaking every client that branches on it.

**[Copy-paste ready version](../../install/preserve-api-error-status-codes.md)** — just the instruction block, no explanation.

## The Problem

An endpoint returns 404 when a record doesn't exist. The AI, mid-refactor, decides 404 is wrong — the *route* exists, only the resource is missing, so surely 400 or 410 is "more semantically correct." Or it upgrades a 500 to a 422 because the failure is really a validation problem. Each change is defensible in an HTTP trivia contest and catastrophic in production, because clients don't read RFC debates — they read status codes with `if` statements.

A retry library that retries 500s but not 422s stops retrying. A client that treats 404 as "record deleted, remove from local cache" now sees 400 and surfaces an error dialog instead. A monitoring rule alerting on 5xx goes quiet while the failure keeps happening. The HTTP semantics got marginally purer and three downstream behaviors silently changed.

The AI does this because it evaluates status codes against the spec, not against the installed base. It can see that 404 is arguably imprecise; it cannot see the eleven consumers whose error handling was written against the imprecise code and works fine.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Preserve API Error Status Codes

NEVER change the status code an existing endpoint returns for an existing error condition, even if a different code is more semantically correct. Clients branch on exact status codes: retry logic, cache invalidation, and error display are all keyed to the codes this endpoint already returns.

- Do not "fix" a 404 to a 400, a 500 to a 422, a 403 to a 404, or any other swap on a shipped error path. Correctness per the HTTP spec does not outweigh the behavior of deployed clients.
- A status code may look wrong and still be load-bearing: clients retry on 5xx but not 4xx, evict caches on 404, and refresh tokens on 401. Changing the code changes all of that behavior at once.
- New error conditions you are adding may use whatever code is most appropriate — the freeze applies only to conditions that already exist.
- If a code is genuinely harmful (e.g., a 200 that hides failures), flag it to the user as a breaking change and propose rolling it out behind an API version or an opt-in header, not as a silent edit.
- When refactoring a handler, list every (condition → status) pair the old code produced and verify the new code produces the identical mapping before finishing.

**Red flags that you're about to violate this:**
- "404 is technically wrong here; the resource path is valid, so 400 fits better."
- "The new framework's default error handler returns 422, which is more standard anyway."
- "Clients should be checking the error body, not the status code."
- "I'm normalizing all the not-found cases to one consistent code."
- "It's an error path — nobody depends on the exact failure code."

---

## Why It Works

1. **It reframes status codes as client behavior, not spec compliance.** The AI's default scoring function is "which code does the RFC prefer." Listing retry, cache, and auth behaviors keyed to codes moves the decision into compatibility territory where swaps are breakage.
2. **It closes the "error paths don't matter" loophole.** Error handling is exactly where clients branch hardest, and saying so removes the assumption that only happy paths are contracts.
3. **It forces a condition-to-status diff**, converting "the new handler looks right" into a mechanical comparison against the old mapping.
4. **It permits correct codes on new conditions**, so the rule reads as a freeze on shipped behavior rather than a ban on knowing HTTP.

## Origin

A team asked their assistant to migrate an endpoint to a new web framework. The framework's validation layer returned 422 where the old hand-rolled checks had returned 400, and the assistant kept the "more correct" defaults. A partner's client library treated 4xx codes it didn't recognize as fatal and stopped its sync loop entirely instead of surfacing field errors to users. The partner spent two days debugging their own code before anyone thought to diff the status codes.
