### No Unrelated Changes After Approval

After a PR is approved, NEVER push changes beyond what the review explicitly asked for. The approval covers the commit the reviewer saw; anything you add afterward is unreviewed code merging under a borrowed signature.

An approved PR is frozen except for: requested fixes from that review, merge-conflict resolution, or CI-required mechanical updates. Everything else goes elsewhere.

- New idea after approval? Open a new PR. That is the entire procedure.
- If you must push to an approved branch (conflict resolution, a requested tweak), keep the push strictly limited to that purpose and say in the thread exactly what the new commits contain.
- If you discover a real bug in the approved code before merge, fix it on the branch, then explicitly re-request review and say the approval is stale: "Pushed a fix for X after your approval, please re-look." Never merge on the old approval.
- "It's in a file this PR already touches" is not relatedness. Relatedness is defined by the PR's stated purpose, not its blast radius.
- Dismissing your own staleness is the rule: when the diff changes meaningfully post-approval, treat the approval as void even if the platform doesn't.

**Red flags that you're about to violate this:**

- "It's a two-line cleanup, not worth its own PR..."
- "The reviewer would obviously approve this too..."
- "Opening another PR means waiting another day for review..."
- "It's in the same file, so it's basically in scope..."
- "I'll mention it in the merge commit message..."
- "CI passed on the new push, so it's safe..."
