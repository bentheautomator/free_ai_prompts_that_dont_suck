---
title: Search Before Writing Helpers
slug: search-before-writing-helpers
category: code-quality
tags: [universal, duplication]
works_with: all
severity: high
one_liner: "AI writing a new helper when the same one already exists three files away"
---

# Search Before Writing Helpers

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from duplicating utility functions that already exist elsewhere in the codebase.

**[Copy-paste ready version](../../install/search-before-writing-helpers.md)** — just the instruction block, no explanation.

## The Problem

Every codebase older than six months has a `formatCurrency`, a `slugify`, a `chunk`, a `retryWithBackoff`. And every AI assistant, asked to build a feature that needs one, will cheerfully write a fresh copy inline — because writing a helper from scratch is a pure generation task, while finding the existing one requires searching, and generation is what the model does without being told.

The new copy is never quite identical. The existing `formatCurrency` rounds half-even and handles negative zero; the AI's version doesn't. Now the cart page and the invoice page disagree by a cent, and someone files a bug that takes a day to trace because both functions look correct in isolation. Multiply this across months of AI-assisted development and you get four date formatters, three debounce implementations, and two subtly different email validators — each one a future divergence bug, each one doubling the surface area of every fix.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Search Before Writing Helpers

NEVER write a utility function without first searching the codebase for an existing one that does the job. Writing a helper is easy; that's exactly why it's the wrong default.

Every duplicate helper is a future divergence bug. The two copies start identical-ish and drift until two screens disagree about what the same value looks like.

**Before writing any general-purpose function (formatting, parsing, validation, retry, debounce, date math, string manipulation, deep clone, etc.):**
- Search for the obvious names AND their synonyms: `format`/`render`/`display`, `validate`/`check`/`is`, `retry`/`withRetry`/`backoff`
- Look in the conventional homes: `utils/`, `lib/`, `helpers/`, `common/`, `shared/`, `pkg/`, and the module you're editing
- Check whether an installed dependency already provides it before writing it from scratch
- If you find an existing helper that's close but not exact, prefer extending or wrapping it over writing a parallel one — and say what you found
- If you genuinely find nothing, put the new helper where the codebase keeps its utilities, not inline in your feature file

**Red flags that you're about to violate this:**
- "I'll just write a quick helper for this..."
- "It's only five lines, faster to write than to find..."
- "A codebase this size might have one, but inline is simpler..."
- "Their version might not handle my exact case, so I'll make my own..."
- "I'll define it locally to keep this change self-contained..."
- Writing a function whose name you haven't grepped for

---

## Why It Works

1. **It inverts the effort calculation the AI actually makes.** Generating is cheaper than searching for a model, so duplication is the path of least resistance. Making search a hard precondition removes the choice.

2. **It demands synonym search, not just name search.** The AI's grep for `formatMoney` misses the existing `renderPrice`. Listing synonym families is the difference between a real search and a ritual one.

3. **It closes the "not an exact fit" loophole.** "Their version doesn't handle my case" is the standard rationalization for a parallel copy. The instruction pre-routes that situation to extend-or-wrap.

4. **It names the real cost — divergence, not duplication.** Two copies isn't the bug; two copies *evolving separately* is. Framing it that way makes the five-line helper feel as expensive as it actually is.

## Origin

During a checkout redesign, an AI assistant wrote a tidy inline `formatPrice` for the new order summary. The codebase already had one in `lib/money.ts` that handled locale-specific separators. Three weeks later a tax-display change was made to the shared helper, the duplicate didn't get it, and customers in Europe saw two different totals on the same checkout flow. Support tickets, a hotfix, and an afternoon of grepping later, the team found four more orphaned price formatters from earlier AI sessions.
