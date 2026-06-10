---
title: Assert Loop Bodies Actually Ran
slug: assert-loop-bodies-actually-ran
category: testing
tags: [universal, testing, assertions]
works_with: all
severity: high
one_liner: "Assertions inside loops that pass vacuously when the loop runs zero times"
---

# Assert Loop Bodies Actually Ran

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents loop-based assertions that all silently vanish when the collection comes back empty.

**[Copy-paste ready version](../../install/assert-loop-bodies-actually-ran.md)** — just the instruction block, no explanation.

## The Problem

A classic vacuous pass, beloved of generated tests everywhere:

```python
def test_all_orders_have_valid_totals():
    orders = fetch_orders(customer_id)
    for order in orders:
        assert order.total > 0
        assert order.currency in SUPPORTED_CURRENCIES
```

If `fetch_orders` regresses to returning an empty list — wrong query, broken join, bad customer ID in the fixture — the loop executes zero times, zero assertions run, and the test passes. Mathematically it's even *true*: all zero orders do have valid totals. The test's name promises verification of orders; an empty result delivers verification of nothing, scored identically.

AI assistants produce this shape whenever asked to verify a property "for all items": iterate and assert is the direct translation. What's missing is the existential half — asserting that there were items at all — which doesn't appear in the prompt's phrasing and so doesn't appear in the code. The same hole hides in filtered iterations (`for o in orders if o.status == 'failed'` — what if the filter matches nothing?), in callback-style assertions that may never be invoked, and in `forEach` over a parsed structure that parsing silently emptied.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Assert Loop Bodies Actually Ran

ALWAYS pair per-item assertions in a loop with an assertion that the loop had items. A for-loop over an empty collection runs zero assertions and passes, which means "verify every order" silently degrades to "verify nothing" the moment the collection is empty.

The core problem: universally-quantified assertions are vacuously true over empty sets. The most likely failure of the code under test — returning nothing — is exactly the case the test waves through.

Rules:
- Before (or after) the loop, assert the expected count: `assert len(orders) == 3` when the fixture determines it, or at minimum `assert len(orders) > 0` when it doesn't
- Prefer exact counts from fixtures over `> 0`. You created the test data; you know how many should come back
- The same applies to filtered iteration: if you assert only over `[o for o in orders if o.failed]`, also assert how many matched the filter
- The same applies to assertions inside callbacks, event handlers, and mock side-effect functions: assert the callback was actually invoked (`assert mock.call_count == 2`, `expect(handler).toHaveBeenCalled()`), or the assertions inside it are decorative
- Framework helpers that fail on empty input (e.g., asserting collection equality against a full expected list) are better than hand-rolled loops; prefer them where available
- Quick audit: for each loop containing an assert, ask what happens if the iterable is empty. If the answer is "passes," the test is incomplete

**Red flags that you're about to violate this:**
- "The fixture always returns data, no need to check it's non-empty..."
- "Iterating and asserting each item covers everything..."
- "If the list were empty, other tests would catch it..."
- "The assertion inside the callback verifies the behavior..."
- "Checking the length feels redundant with the per-item checks..."

---

## Why It Works

1. **It names the vacuous-truth trap.** The AI doesn't model that `for...assert` over an empty set is a pass; the construct *feels* like coverage. Stating the quantifier logic plainly — universal claims are free over empty sets — gives the AI a reason, not just a rule.

2. **It targets the likeliest regression.** Functions fail toward empty: bad queries, failed parses, broken filters all return `[]` rather than wrong items. Pointing out that emptiness is the dominant failure mode shows why the missing assertion is the load-bearing one.

3. **It extends the pattern to invisible loops.** Callbacks and mock side-effects are loops the AI doesn't recognize as loops. Enumerating them closes the variants that the literal "for-loop" rule would miss.

## Origin

A data-export feature was covered by a test iterating exported rows and asserting each row's schema. A query refactor introduced a join that matched nothing in the test database, the export began producing empty files, and the test kept passing — zero rows, zero assertions, zero complaints. Customers reported empty exports before any test did; the eventual fix added one line, `assert len(rows) == 14`, which would have failed on day one.
