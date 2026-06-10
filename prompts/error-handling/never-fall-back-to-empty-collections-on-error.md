---
title: Never Fall Back to Empty Collections on Error
slug: never-fall-back-to-empty-collections-on-error
category: error-handling
tags: [universal, errors, fallbacks]
works_with: all
severity: critical
one_liner: "AI returning an empty list on failure so downstream code runs on nothing"
---

# Never Fall Back to Empty Collections on Error

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents a failed fetch from being disguised as a successful fetch that found zero results.

**[Copy-paste ready version](../../install/never-fall-back-to-empty-collections-on-error.md)** — just the instruction block, no explanation.

## The Problem

A function that fetches users from an API throws on a network error, and the AI's fix is `catch (e) { return []; }`. Now every consumer of that function — the sync job, the report generator, the cleanup task — receives a perfectly valid empty array and proceeds with confidence. The sync job syncs nothing. The report says zero users. The cleanup task, told that zero users should exist, starts deleting.

This pattern is seductive because it makes the type signature happy. The function promises a `List[User]`, an empty list *is* a `List[User]`, and the calling code runs without modification. No crash, no red text, demo works. The AI has converted "the operation failed" into "the operation succeeded and the answer is nothing" — two statements with wildly different downstream consequences that are now indistinguishable to every caller.

Empty collections are the worst possible fallback because emptiness is *meaningful* in most domains. "No orders today" triggers different business logic than "couldn't reach the orders service." Code that can't tell those apart will eventually act on the wrong one.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Fall Back to Empty Collections on Error

NEVER catch an error and return an empty list, dict, set, or array in its place. An empty collection is a successful result that claims "zero items exist" — it is not an error representation.

The moment a failure becomes `[]`, every downstream consumer treats it as truth: reports show zero, syncs propagate zero, deletes reconcile against zero.

- If a fetch, query, or parse fails, propagate the error: re-raise it, or return an explicit failure value (`Result`/`Either`, or raise a domain exception) — never `return []` or `return {}`
- Do not write `data = fetch() or []`, `items = response.get('items', [])` on a failed response, or `catch { return [] }`
- An empty collection is only a valid return when the operation genuinely succeeded and genuinely found nothing — those are the only conditions under which you may return one
- If a caller truly wants degrade-to-empty behavior (e.g. optional decorative data), that decision belongs at the call site, written explicitly by the caller — not buried inside the fetching function as a default for everyone
- When you see existing code consuming a possibly-failed fetch, do not "fix" a crash by defaulting the input to empty; fix the error path instead

**Red flags that you're about to violate this:**
- "Returning an empty list keeps the return type consistent..."
- "Downstream code handles empty lists fine, so this is safe..."
- "If the API is down we can just show nothing..."
- "I'll default to [] so the loop doesn't blow up..."
- "Empty is a reasonable neutral value here..."

---

## Why It Works

1. **It names the semantic collision.** The model sees `[]` as a safe neutral value. Spelling out that empty means "zero items exist, confirmed" — a claim with business consequences — breaks the illusion of neutrality.

2. **It relocates the degrade decision to the caller.** Sometimes empty-on-failure is genuinely right (a widget, a suggestion strip). The rule doesn't ban that; it bans deciding it *inside* the producer where every caller inherits it invisibly.

3. **It blocks the type-checker rationalization.** "It satisfies the signature" is the strongest pull toward this pattern; explicitly stating that type-consistency is not success-consistency removes that cover.

4. **It covers the idiom variants.** `or []`, `.get(..., [])`, and `catch { return [] }` are the actual keystrokes; listing them catches the pattern at the syntax level, not just the concept level.

## Origin

An assistant was asked to make a nightly inventory sync "more resilient" after a few crashes. It wrapped the warehouse API call so failures returned an empty product list. The next time the API had an outage, the sync ran "successfully," concluded the warehouse stocked nothing, and zeroed out availability for every SKU on the storefront. Sales flatlined for six hours before anyone realized the resilient sync had been faithfully propagating a network error as inventory truth.
