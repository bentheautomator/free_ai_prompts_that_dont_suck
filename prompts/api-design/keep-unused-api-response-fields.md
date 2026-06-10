---
title: Keep Unused API Response Fields
slug: keep-unused-api-response-fields
category: api-design
tags: [universal, apis, compatibility]
works_with: all
severity: critical
one_liner: "Stops deletion of response fields that grep says are unused but consumers read"
---

# Keep Unused API Response Fields

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from deleting response fields because nothing in the repo reads them — when the real readers are outside the repo.

**[Copy-paste ready version](../../install/keep-unused-api-response-fields.md)** — just the instruction block, no explanation.

## The Problem

"Remove unused code" is one of the most common cleanup requests, and AI assistants execute it with grep. A field like `legacy_discount_code` appears in the response serializer, grep finds zero reads anywhere in the repository, and the assistant concludes it's dead weight. It deletes the field, the serializer test, and sometimes the underlying query column for good measure. The diff is satisfyingly red.

But "unused" measured by grep means "unused by this repository." A response field's consumers are HTTP clients: other services, spreadsh eet importers, a partner's nightly sync job. None of them show up in a code search. The field that looked dead was load-bearing for someone who will discover its absence when their integration starts writing nulls into their database.

This failure is structural. The AI's evidence-gathering tools all point inward, so an outward-facing dependency is literally invisible to it. Worse, the field genuinely *looks* vestigial — old name, no internal reads, maybe a stale comment — which makes deletion feel like diligence rather than risk.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep Unused API Response Fields

NEVER remove a field from an API response because it appears unused. A code search proves nothing: response fields are consumed by HTTP clients outside this repository, and grep cannot see them.

- "No references in the codebase" is not evidence a response field is dead. It is the expected state for a field whose only consumers are external — which is most of them.
- Do not delete fields during refactors, serializer rewrites, DTO consolidation, or "remove dead code" tasks. Carry every existing field through, even ones that look vestigial, misnamed, or always-null.
- If a field is expensive to compute or genuinely believed dead, the safe sequence is: log or instrument its access where possible, mark it deprecated in docs/OpenAPI, announce a sunset date, then remove it in a deliberate, human-approved change. Not as a side effect of cleanup.
- When rewriting a handler or serializer, diff the old response shape against the new one field-by-field before finishing. Any missing key is a breaking change unless the user explicitly asked for its removal.
- If the user explicitly asks to drop a field, comply, but say clearly that any external consumer reading that key will break, and offer the deprecation path.

**Red flags that you're about to violate this:**
- "Grep shows nothing reads this field, so it's safe to remove."
- "This field is always null anyway; no one could be using it."
- "The new serializer is cleaner without these legacy fields."
- "I'm consolidating two DTOs and only keeping the fields that overlap."
- "The frontend in this repo doesn't use it, and that's the only client."

---

## Why It Works

1. **It invalidates the AI's measuring instrument.** The failure starts with grep being treated as proof. Stating that zero references is the *expected* state for an externally consumed field removes the false evidence the deletion was built on.
2. **It names the high-risk task contexts** (refactors, DTO merges, dead-code sweeps) where deletions happen as side effects rather than decisions.
3. **It mandates a field-by-field diff of response shapes**, turning "the new code looks complete" into a checkable comparison against the old contract.
4. **It supplies a legitimate removal path**, so the rule reads as "removal is a process" rather than "removal is forbidden," which keeps the AI from arguing with it.

## Origin

During a "delete dead code" pass, an assistant removed six response fields from a customer endpoint after verifying none were referenced anywhere in the monorepo. One of them, `external_ref`, was the join key a billing partner used to reconcile invoices. The partner's nightly sync silently matched zero records for four days. Reconciling the missed invoices by hand cost the finance team most of a sprint, for a field that cost nothing to keep.
