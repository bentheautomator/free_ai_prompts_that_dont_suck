---
title: Hoist Invariant Work Out of Loops
slug: hoist-invariant-work-out-of-loops
category: performance
tags: [universal, performance, loops]
works_with: all
severity: high
one_liner: "Stops recomputing the same value on every iteration of a data-sized loop"
---

# Hoist Invariant Work Out of Loops

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from putting work that produces the same result every iteration inside the loop instead of before it.

**[Copy-paste ready version](../../install/hoist-invariant-work-out-of-loops.md)** — just the instruction block, no explanation.

## The Problem

Inside a loop over 200,000 records: `re.compile(pattern)` on every iteration. `new Intl.DateTimeFormat(...)` per row. `json.loads(SCHEMA)` per item. `datetime.now()` called fresh each pass when the loop conceptually runs "at one moment." A lookup list rebuilt per iteration so the loop can do `if x in build_blocklist()`. None of these depend on the loop variable. Each produces an identical result every time. Each is paid 200,000 times for one result's worth of value.

AI assistants put invariant work inside loops because they generate code locally: when writing the loop body, the body is the context, so everything the body needs gets created right there. It's also how snippets look in documentation, where the loop runs three times and locality beats efficiency. The code is correct, the tests are green, and the cost is pure silent multiplication.

The flagship offender is the inner lookup: `for order in orders: customer = next(c for c in customers if c.id == order.customer_id)`. That's a full scan per iteration — invariant work (indexing customers by ID) left inside the loop, upgrading O(n) to O(n×m). Building the dict once before the loop is both faster and clearer, and the AI knows how; it just didn't notice the loop boundary mattered.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Hoist Invariant Work Out of Loops

NEVER leave work inside a loop body if it produces the same result on every iteration. Anything that doesn't depend on the loop variable gets computed once, before the loop. Inside a data-sized loop, every line is multiplied by the iteration count.

- Hoist construction of reusable objects: compiled regexes, date/number formatters, parsed schemas, template engines, lookup tables, sets used for `in` checks. Build before the loop, use inside it.
- The big one: replace per-iteration linear searches with a pre-built index. `for a in items: match = [b for b in others if b.key == a.key]` scans `others` once per item; build `by_key = {b.key: b for b in others}` once and do dict lookups inside. This turns O(n times m) into O(n + m).
- Hoist repeated property chains and conversions that can't change mid-loop (`config.settings.locale`, `str(today)`), and capture "now" once if the loop represents one logical moment.
- Function calls in the loop *condition* count too: `for i in range(len(expensive()))` and `while i < items.count()` may re-evaluate per pass depending on language. Bind to a local first.
- Do not hoist what actually varies or has per-iteration side effects; if you're unsure whether a call is pure, check it before moving it.
- Verify the multiplication: iteration count times per-call cost is the bill. A 2ms call in a 100k-iteration loop is 200 seconds. If the loop is hot, profile before/after to confirm the hoist mattered.

**Red flags that you're about to violate this:**
- "Declaring it inside the loop keeps related code together."
- "Compiling the regex is fast."
- "The runtime probably caches this internally."
- "A nested scan is fine, both lists are short." (today)
- "Extracting it before the loop makes the function longer."

---

## Why It Works

1. **It gives a syntactic test for invariance.** "Does it depend on the loop variable?" is answerable from the code alone, turning a performance judgment into a dependency check the AI performs reliably.
2. **It attaches the multiplier to every line.** Framing the loop body as "multiplied by iteration count" reprices innocuous-looking calls at their actual cost.
3. **It elevates the index-build pattern by name.** The inner-linear-search case is the highest-impact instance; spelling out the dict-before-loop transformation makes it a known move rather than an insight.
4. **It includes the purity guard.** Explicitly excluding side-effecting and varying calls prevents the over-eager hoist that changes behavior, which would discredit the rule.

## Origin

An import pipeline validated each row against a JSON schema, calling the schema-compile step inside the per-row function because "that's where it was needed." At 10k-row test files, fine. A customer uploaded 3.2 million rows; the job spent 96% of its CPU time compiling the same schema 3.2 million times and was killed by its timeout after six hours. Hoisting one line above the loop took the run to eleven minutes. The profiler flame graph was a single tower with the schema compiler's name on it.
