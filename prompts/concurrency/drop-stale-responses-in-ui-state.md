---
title: Drop Stale Responses in UI State
slug: drop-stale-responses-in-ui-state
category: concurrency
tags: [universal, concurrency, frontend]
works_with: all
severity: high
one_liner: "Stops slow stale responses from overwriting fresh data in the UI"
---

# Drop Stale Responses in UI State

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from writing UI fetch logic where whichever response arrives last wins, so a slow stale request overwrites the fresh data the user actually asked for.

**[Copy-paste ready version](../../install/drop-stale-responses-in-ui-state.md)** — just the instruction block, no explanation.

## The Problem

A user types "ja" in a search box, then "java." Two requests go out; the "ja" query hits a cold cache and takes 900ms, the "java" query returns in 200ms. The UI shows java results for 700ms, then the "ja" response lands and replaces them. The user is now looking at results for a query they're no longer making, with no error and no way to tell. The same race hits tab switches (open Profile, click Settings, Profile's slow response paints over Settings), filter changes, pagination, and any `useEffect`-fetches-on-prop-change component.

AI assistants write `const data = await fetch(query); setResults(data);` because it is the canonical data-fetching snippet, and in a world where responses arrive in request order it's correct. Nothing in the code says "responses may interleave"; the bug is the *absence* of a guard, which no amount of reading the happy path reveals. Local dev makes it worse: against localhost, responses essentially always arrive in order, so the developer (and the AI's mental simulation, and the e2e suite) never sees the inversion that's routine on real networks.

Every response handler that writes shared UI state needs to answer one question first: "am I still the request this view is waiting for?"

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Drop Stale Responses in UI State

ALWAYS guard response handlers that write UI state: before applying a response, verify it belongs to the *latest* request for that piece of state. Responses arrive in any order; last-write-wins means slowest-write-wins.

- Abort the previous request when issuing a new one for the same state: keep an `AbortController` per fetch target, `abort()` it on re-fetch, and ignore `AbortError`. Cancellation beats checking, because it also stops wasted work.
- Where you can't abort, version-check: capture a request ID or the query value when the request starts; in the handler, `if (requestId !== latestRequestId) return;` before any `setState`.
- In effect-based frameworks, use the cleanup function: set a `cancelled` flag in React's `useEffect` cleanup and check it before applying the response. A fetch in an effect without a cleanup guard is a race by default.
- The guard must cover *all* the state the handler writes — results, loading flags, and error banners. A stale request's error overwriting a fresh success is the same bug in a trench coat.
- Don't debounce as a substitute. Debouncing reduces how often the race runs; it doesn't make any ordering guarantee. You can have both; you can't have only debounce.
- Prefer a data-fetching layer that handles this (query libraries with key-based caching and cancellation) over hand-rolling the guard in every component.

**Red flags that you're about to violate this:**
- "Responses will come back in the order I sent them."
- "The debounce means there's only ever one request in flight."
- "This effect refetches on every keystroke; the latest render wins anyway."
- "It works perfectly in dev." (Localhost never reorders.)
- "Adding request tracking to this little component is overkill."

---

## Why It Works

1. **It converts an invisible omission into a required line:** "every response handler answers 'am I still current?'" is a presence check a reviewer or AI can verify, unlike "watch out for races."
2. **Abort-first ordering matters:** cancellation removes the stale writer entirely instead of racing it to the guard, and frees the connection besides.
3. **It extends the guard to loading and error state,** where most hand-rolled fixes quietly leave the race alive.
4. **It severs the false comfort of in-order localhost behavior** by naming response reordering as the normal case on real networks, not an edge case.

## Origin

An order-management dashboard let agents switch between customer accounts. The account view fetched on selection with no guard; under afternoon load, a slow response for the previous customer routinely landed after the fast one for the current customer. An agent issued a refund while looking at customer A's screen that was actually showing customer B's orders. The refund went to the wrong account, the bug was unreproducible on the office network, and the eventual fix was four lines of AbortController that should have shipped with the first version.
