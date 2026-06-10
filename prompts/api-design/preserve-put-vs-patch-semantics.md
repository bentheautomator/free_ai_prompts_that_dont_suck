---
title: Preserve PUT vs PATCH Semantics
slug: preserve-put-vs-patch-semantics
category: api-design
tags: [universal, apis, rest]
works_with: all
severity: high
one_liner: "Stops flipping replace vs merge update semantics on shipped endpoints"
---

# Preserve PUT vs PATCH Semantics

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from changing whether an update endpoint replaces the whole resource or merges partial fields — a flip that erases data or un-erases it.

**[Copy-paste ready version](../../install/preserve-put-vs-patch-semantics.md)** — just the instruction block, no explanation.

## The Problem

An update endpoint has exactly one of two personalities: *replace* (the request body is the new complete state; omitted fields are cleared) or *merge* (only sent fields change; omissions mean "leave alone"). The spec assigns replace to PUT and merge to PATCH, but shipped APIs frequently disagree with the spec — a PUT that merges, a PATCH that replaces — and their consumers are calibrated to the actual behavior, not the verb.

Enter the AI with a copy of the RFCs. It "fixes" the merging PUT to properly replace, and every client that sends partial bodies — which worked fine for years — starts silently nulling out every field it omits. Phone numbers, addresses, preferences: erased by requests that used to be safe. Or it relaxes a replacing endpoint to merge, and clients that *relied* on omission-clears-the-field (send the object without `discount` to remove the discount) now can't clear anything; stale values survive updates indefinitely. Both directions corrupt data, in opposite ways, without a single error response.

The AI flips semantics most often during handler rewrites — swapping a field-by-field copy loop for a `**body` model update, or an ORM `update()` call for a full save — where the merge/replace behavior is an emergent property of code structure nobody mentions in the diff.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Preserve PUT vs PATCH Semantics

NEVER change whether an existing update endpoint replaces the full resource or merges partial fields — regardless of which verb it uses and regardless of what the HTTP spec says that verb should do. Consumers are calibrated to observed behavior: flipping merge → replace makes their partial requests erase data; flipping replace → merge breaks their ability to clear fields by omission. Both flips corrupt data silently.

- A PUT that has always merged keeps merging. A PATCH that has always replaced keeps replacing. Spec-correcting a shipped endpoint's update semantics is a data-corruption change, not a cleanup.
- The flip usually hides in implementation rewrites: replacing per-field assignment with whole-model updates (`obj.update(**body)`, full saves, upsert calls) changes what happens to omitted fields without anyone deciding it. When rewriting an update handler, test specifically: send a partial body and verify omitted fields behave exactly as before (kept vs. cleared).
- The null-vs-omitted distinction is part of these semantics: if the endpoint treats `"field": null` (clear it) differently from field-absent (keep it), the rewrite must preserve that — many serializer defaults collapse the two.
- If correct verb semantics are wanted, add them additively: introduce a proper PATCH alongside the existing PUT (or vice versa), leaving the shipped endpoint's behavior untouched, or stage the fix in a new API version.
- If the user explicitly asks to fix the semantics in place, spell out the consequence for current callers: which of their requests will start erasing data or failing to clear it.

**Red flags that you're about to violate this:**
- "PUT is supposed to replace the resource — this endpoint implements it wrong."
- "Updating the whole model in one call is cleaner than copying fields one by one."
- "Partial updates are what PATCH is for; PUT callers should send complete objects."
- "The ORM's update method handles all of this more idiomatically."
- "No response shape changed, so this refactor is contract-neutral."

---

## Why It Works

1. **It separates verb from behavior**, the exact conflation that triggers the failure: the AI reads the verb, infers spec semantics, and "corrects" reality toward the inference. Pinning the contract to observed behavior cuts that path.
2. **It locates the flip inside implementation patterns** (whole-model updates, upserts), where merge/replace changes as a structural side effect and would never be caught by reading the diff for intent.
3. **It mandates the partial-body test**, a two-minute check that detects the flip mechanically instead of trusting the AI's self-assessment of "contract-neutral."
4. **It includes null-vs-omitted**, the sub-contract that survives even careful merge/replace thinking and breaks clients that clear fields explicitly.

## Origin

A handler rewrite replaced twelve lines of field-by-field copying with a one-line model update — and quietly turned a merging PUT into a replacing one. A partner's system updated order statuses by PUTting `{"status": "shipped"}`, as it had since integration; each such call now blanked the order's shipping address, line-item notes, and customer reference. The data loss was discovered through delivery failures, restored from a fortunate audit table, and memorialized in a test that sends a partial body and counts what survives.
