---
title: Scrub PII Before It Reaches Error Trackers and Analytics
slug: no-pii-in-error-trackers
category: security
tags: [universal, security, logging]
works_with: all
severity: high
one_liner: "AI attaching emails, names, and addresses to third-party telemetry"
---

# Scrub PII Before It Reaches Error Trackers and Analytics

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from shipping personal data to error trackers, analytics, and observability vendors as debug context.

**[Copy-paste ready version](../../install/no-pii-in-error-trackers.md)** — just the instruction block, no explanation.

## The Problem

"Add error tracking" is a task AI assistants complete enthusiastically: initialize the SDK, then enrich every event with context — `setUser({ email, name, phone })`, breadcrumbs containing form contents, the full Redux state attached to crash reports, request bodies in the extras. Each enrichment makes errors easier to debug and quietly turns the error tracker into a shadow database of personal information, hosted by a third party, retained on their schedule, accessible to everyone on the team with a login, and absent from the data inventory your privacy policy describes. The same applies to product analytics ("track signup with all form fields"), session replay tools (recording keystrokes into SSN fields), and verbose spans in tracing systems.

The AI does this because context is genuinely what makes telemetry useful, the SDKs offer `setUser` and `extra` parameters as first-class features, and nothing in the type system distinguishes `userId` (fine) from `email` (regulated). Unlike a secrets leak, nothing ever breaks: the data flows out for years until a privacy review, a deletion request that can't be honored ("it's in the replay vendor's archive"), or a vendor breach makes it everyone's problem. Regulated identifiers — health data, government IDs, payment details — turn "embarrassing" into "reportable."

The discipline is simple: identify users to telemetry by opaque ID, allowlist what gets attached, and use the scrubbing hooks every major SDK provides.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Scrub PII Before It Reaches Error Trackers and Analytics

NEVER send personal data to third-party telemetry (error trackers, analytics, session replay, tracing) as debugging or tracking context. Identify users by opaque internal ID; allowlist every attached field.

Telemetry vendors are an unaudited copy of whatever you send them, with their own retention, access, and breach surface. Context that includes PII is a privacy incident on a delay.

- Identify users as `setUser({ id: internalId })`. Do not attach email, name, phone, addresses, or usernames to events; if support needs to find a user's errors, the internal ID is searchable on both sides.
- Never attach whole objects as context: request bodies, form state, Redux/app state, user records, or `extra: req.body`. Attach named, individually chosen fields.
- Configure the SDK's scrubbing: `beforeSend` hooks to delete known-sensitive keys, server-side data scrubbers, and denylists for field names (`password`, `email`, `ssn`, `token`, `card`). Turn ON the SDK's default PII filters and leave `sendDefaultPii`-style options OFF.
- Session replay and heatmap tools: mask all inputs by default (`maskAllInputs: true` or equivalent), and explicitly block replay on pages handling payments, health data, or identity documents.
- Analytics events carry the same rule: `signup_completed` with a plan name is fine; with the user's email and company as event properties, it's PII replication. Marketing can join on the internal ID server-side.
- URLs leak too: if routes embed emails or names (`/users/jane@example.com`), telemetry inherits them; route by ID and the problem disappears upstream.
- Regulated categories (health, payment card data, government IDs) must never reach general-purpose telemetry, full stop; that's a compliance boundary, not a scrubbing preference.

**Red flags that you're about to violate this:**
- "Attaching the user object makes every error instantly debuggable..."
- "The error tracker is a trusted vendor, it's not like posting publicly..."
- "Support wants to search errors by email, so email has to be on the event..."
- "Session replay needs real inputs to be useful for UX research..."
- "It's just the email address, hardly sensitive data..."
- "We can add scrubbing once the privacy team asks for it..."

---

## Why It Works

1. **It swaps the identifier, preserving the workflow.** The legitimate need is correlating a user to their errors; the opaque-ID pattern satisfies it completely, which is why the rule gets followed instead of bypassed.

2. **It bans the whole-object attach, which is how PII actually travels.** Nobody writes `extra: {ssn}`; they write `extra: req.body` and the SSN rides along — the same container-dump mechanism as log leaks, named at the SDK call site.

3. **It points at the scrubbing features by name.** `beforeSend`, mask-all-inputs, and default-PII toggles exist in every major SDK and go unused because nobody puts them in the setup snippet; in context, they make compliance one parameter.

4. **It reframes the vendor as a copy, not a tool.** "Trusted third party" is the rationalization; "unaudited copy with its own breach surface and retention" is the model correction that survives contact with a deletion request.

## Origin

An assistant wired up crash reporting for a telehealth app and, following the SDK's own examples, attached user context: name, email, and the current page's form state, which on the symptom-checker page included free-text health descriptions. Eighteen months of crashes later, a privacy audit found medical information in a general-purpose error tracker with 90-day-default retention, team-wide access, and no processing agreement covering health data. The disclosure obligations cost more than the app's entire observability budget; the fix was one `beforeSend` and an ID.
