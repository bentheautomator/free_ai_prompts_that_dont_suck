---
title: Keep API Empty Result Contract
slug: keep-api-empty-result-contract
category: api-design
tags: [universal, apis, compatibility]
works_with: all
severity: high
one_liner: "Stops swapping empty array, null, and 404 as how an endpoint says nothing found"
---

# Keep API Empty Result Contract

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from changing how an endpoint represents "no results" — empty array vs. null vs. 404 vs. empty object — on consumers tuned to the current answer.

**[Copy-paste ready version](../../install/keep-api-empty-result-contract.md)** — just the instruction block, no explanation.

## The Problem

"Nothing found" has at least four spellings — `200` with `[]`, `200` with `null`, `200` with `{}`, and `404` — and APIs in the wild use all of them. AI assistants hold opinions here: a list with no matches should *obviously* be `200 []`, a missing singular resource should *obviously* be `404`. So when one touches an endpoint that returns `404` for an empty search, or `200 null` for an absent profile, it standardizes to the correct answer. And the correct answer breaks consumers calibrated to the incorrect one.

The breakage runs in both directions. A client that treated `404` as the normal "no results" signal now receives `200 []` — its error-path-based handling never fires, or it tries to iterate something it never null-checks. A client that expected `200 null` and used the status code to distinguish "absent" from "error" now gets `404` — which its HTTP library throws on, converting a routine empty state into an exception, a retry storm, or a circuit-breaker trip. Either way, the empty case is usually the *least tested* path on the consumer side, so the failure surfaces late and weird.

The AI changes this because empty-case handling looks like an implementation afterthought — one `if not results:` branch — rather than what it is: the half of the contract that only shows up in production data.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep API Empty Result Contract

NEVER change how an existing endpoint represents "no results" or "not found": the status code (200 vs. 404) and the body shape (`[]` vs. `null` vs. `{}` vs. error body) are both frozen, even when the current choice contradicts REST convention. Consumers are calibrated to the exact current signal, and their empty-case handling is the least-tested code they have.

- If a search endpoint returns 404 when nothing matches, it keeps returning 404 — even though `200 []` is the better design. If a lookup returns `200` with `null`, that stays too. Correctness of convention does not outrank deployed calibration.
- Both halves matter: changing `404` → `200 []` silently disables consumers' error-path-based empty handling; changing `200 null` → `404` makes their HTTP clients throw on a routine state. Neither direction is the safe one.
- Watch for indirect flips: ORM changes (`.get()` raising vs. returning None), framework error handlers, and "fix inconsistent not-found behavior" cleanups all change the empty contract without the word "empty" appearing in the task.
- Distinguish the cases when *building new* endpoints — empty collection (`200 []`), missing singular resource (`404`), and existent-but-empty resource (`200` with empty value) — and pick deliberately, because whatever ships becomes permanent.
- If the user asks to standardize empty behavior across existing endpoints, enumerate which endpoints change which signal, and recommend doing it only behind a new API version.

**Red flags that you're about to violate this:**
- "Returning 404 for an empty search result is just wrong; empty list is the standard."
- "I'll make all the not-found cases consistent across the API."
- "null is a poor representation of absence — an empty object is cleaner."
- "Clients should be handling both 200-empty and 404 anyway."
- "This is a one-branch change in the handler; it barely touches anything."

---

## Why It Works

1. **It removes the "correct answer" override.** The AI genuinely knows the conventional best practice, which is exactly why it changes shipped behavior; ranking calibration above convention removes the justification at its root.
2. **It states that both directions break**, preventing the half-reasoned move where the AI assumes one of the two signals must be the safe harbor.
3. **It names the indirect vectors** (ORM raise-vs-None semantics, global error handlers), where the empty contract changes as a side effect of code that never mentions emptiness.
4. **It points out the empty path is consumers' least-tested code**, explaining why this break surfaces as production weirdness rather than caught-in-staging errors — raising its perceived severity to match reality.

## Origin

A cleanup standardized a vehicle-lookup endpoint from `404` to `200` with an empty object when a plate had no record — more RESTful, the reasoning went, since the *query* succeeded. The consuming kiosk system used the 404 as its "no record, proceed with registration flow" signal and treated any 200 as "record exists." Every new registration began routing into the update-existing flow, failing on a missing internal ID. Registrations were down for an afternoon over a change whose commit message said "normalize not-found responses."
