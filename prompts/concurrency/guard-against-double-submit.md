---
title: Guard Against Double Submit
slug: guard-against-double-submit
category: concurrency
tags: [universal, concurrency, idempotency]
works_with: all
severity: critical
one_liner: "Stops double-clicks and retries from creating duplicate orders and charges"
---

# Guard Against Double Submit

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from shipping submit flows where a double-click, an impatient retry, or a flaky network creates two orders, two charges, or two of anything that should be one.

**[Copy-paste ready version](../../install/guard-against-double-submit.md)** — just the instruction block, no explanation.

## The Problem

Users double-click. Not sometimes — reliably, the moment a button doesn't respond within their patience budget, which on a slow checkout is about 800ms. Each click is an independent POST; the server, asked twice to create an order, politely creates two. The same duplication arrives via network retries (the request succeeded but the response was lost, so the client resends), browser refresh on a POST result, and mobile apps retrying on timeout. The AI ships `onSubmit → POST /orders → create row` because that's the tutorial shape, and the tutorial user clicks exactly once with a perfect network.

The deeper miss is architectural: assistants treat double-submit as a frontend etiquette problem ("disable the button") when it's a server correctness problem. Button-disabling reduces the easy duplicates but does nothing about retries, refreshes, or a second tab — the server is the only party that can actually enforce "this operation happens once." Two concurrent identical requests will both pass any check-the-database-first logic, because both check before either has written.

Tests pass because tests click once. Real money gets moved twice.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Guard Against Double Submit

Every state-creating submit MUST be idempotent at the server, enforced by something atomic. Client-side button disabling is a courtesy, not a defense; retries, refreshes, and second tabs go around it.

Two identical requests will arrive concurrently. The server must turn them into one effect.

- Generate an idempotency key client-side when the *form is shown* (not when clicked — both clicks must share the key), send it with the request, and enforce it server-side with a unique constraint or atomic insert. Second arrival gets the first result back, not an error and not a second effect.
- The enforcement must be atomic: a unique index on the key, `INSERT ... ON CONFLICT`, or an atomic set-if-absent. "Check if a request with this key exists, then insert" is itself a race and will pass both concurrent duplicates.
- Pass idempotency keys through to payment and third-party APIs that support them; otherwise your one order can still become their two charges.
- Client side, still do the courtesy: disable on submit, show progress, re-enable on failure. It prevents most duplicates from existing; the server prevents the rest from mattering.
- Retries must reuse the original key. A retry with a fresh key is just a duplicate with paperwork.
- Make the duplicate path return success with the original result. Surfacing "duplicate request" as an error teaches clients to retry harder.

**Red flags that you're about to violate this:**
- "The submit button is disabled while pending, so duplicates can't happen."
- "I check whether the order already exists before inserting." (Both requests check first.)
- "Our users wouldn't double-click a payment button." (They will. Especially that one.)
- "The network layer handles retries transparently." (That's the threat, not the defense.)
- "I'll dedupe by user + timestamp." (Two clicks in the same second share both.)

---

## Why It Works

1. **It relocates the defense to the only layer that sees every duplicate** — the server — instead of the layer (the button) that sees only one browser tab on one click path.
2. **Key-at-form-render is the detail that makes the key work:** generated on click, each click gets its own key and the mechanism dedupes nothing.
3. **It demands atomic enforcement explicitly,** because the natural implementation of "check for the key first" reintroduces the exact race it was meant to kill.
4. **Returning the original result on duplicates breaks the retry spiral:** clients that get success stop retrying; clients that get errors retry with enthusiasm.

## Origin

A ticketing checkout took three seconds under launch-day load. Users double- and triple-clicked Buy; each click created an order and charged the card. Support refunded duplicates by hand for two days, and the "fix" that shipped first — disabling the button — didn't touch the duplicates coming from the mobile app's automatic timeout retry. The durable fix was an idempotency key minted at checkout-page render and a unique index that turned every duplicate into a replay of the first success.
