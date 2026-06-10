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
