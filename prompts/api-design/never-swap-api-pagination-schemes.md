---
title: Never Swap API Pagination Schemes In Place
slug: never-swap-api-pagination-schemes
category: api-design
tags: [universal, apis, compatibility]
works_with: all
severity: high
one_liner: "Stops in-place offset-to-cursor migrations that strand every paging client"
---

# Never Swap API Pagination Schemes In Place

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from replacing an endpoint's pagination style (offset to cursor, page numbers to tokens) on the same params and fields clients already use.

**[Copy-paste ready version](../../install/never-swap-api-pagination-schemes.md)** — just the instruction block, no explanation.

## The Problem

Cursor pagination is genuinely better than offset pagination, and AI assistants know it. So when one touches a paginated endpoint — for performance, for a deep-paging bug, or just because the prompt said "improve" — it's liable to rip out `?page=3&per_page=50` and replace it with `?cursor=eyJpZCI6MTUw`, swap the response's `total_pages` for `next_cursor`, and call it an upgrade. Every consumer's paging loop is now broken in one of two ways.

Either the old params are rejected and clients get 400s, or — worse — they're ignored, and a client sending `page=3` gets page one forever. Loops that terminate on `page > total_pages` never terminate, or terminate immediately. Code that computed "jump to page 40" has no equivalent operation at all, because cursors can't random-access. The client-side contract of pagination isn't just parameter names; it's the *algorithm* the consumer wrote, and the swap deletes its foundation.

The AI does this because the superiority of cursors is in every engineering blog it trained on, while the paging loops written against the old scheme live in repositories it will never see.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Swap API Pagination Schemes In Place

NEVER replace an endpoint's existing pagination scheme (offset/limit, page/per_page, cursor, Link headers) with a different one on the same endpoint. Consumers implement paging as an algorithm — request, read the paging fields, loop — and changing the scheme breaks the loop, often into infinite repetition or silent single-page results.

- Existing pagination params must keep working with their existing semantics: `page=3` returns the third page, `offset=100` skips 100, forever. Ignoring an old param is worse than rejecting it.
- Existing paging fields in the response (`total`, `total_pages`, `has_more`, `next_url`) must keep appearing with correct values. Clients use them as loop-termination conditions; removing one creates infinite loops.
- Introduce a better scheme additively: accept `cursor` alongside `page`, return `next_cursor` alongside `total_pages`, and let new clients opt in. Or ship the new scheme on a new versioned endpoint.
- Cursor formats are also contracts once shipped: do not change their encoding or invalidate outstanding cursors, since clients persist them mid-pagination and across job runs.
- If supporting both schemes is genuinely infeasible, present that to the user as a breaking-change decision requiring a version bump and consumer migration, not something to fold into this diff.

**Red flags that you're about to violate this:**
- "Offset pagination doesn't scale; cursor-based is the correct approach here."
- "I'll map the old page param onto the new system approximately."
- "total_count was expensive to compute and the new scheme doesn't need it."
- "Clients just follow next links, so the underlying scheme is invisible to them."
- "This fixes the deep-pagination timeout, which is what the user really wants."

---

## Why It Works

1. **It reframes pagination as a client-side algorithm**, not a server detail. The AI's model is "clients fetch pages"; the truth is "clients run loops with termination conditions," and naming that makes field removal visibly dangerous.
2. **It ranks ignoring above rejecting in severity**, catching the quietest failure: old params silently no-oping into eternal page one.
3. **It extends the contract to paging metadata and cursor tokens**, which the AI treats as free to change because they look like implementation artifacts.
4. **It offers coexistence as the default path**, so the performance motivation that triggered the change has a compatible outlet.

## Origin

To fix a timeout on deep pages, an assistant converted a transactions endpoint from offset/limit to keyset cursors and removed the now-costly `total_count` field. An accounting integration paginated with `while (fetched < total_count)`; with `total_count` undefined, the comparison was always false in one code path and the sync stopped after page one — marked green. The gap was found at quarter close, when the books were short five weeks of transactions.
