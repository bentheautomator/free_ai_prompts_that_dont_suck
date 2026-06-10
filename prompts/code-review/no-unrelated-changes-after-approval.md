---
title: No Unrelated Changes After Approval
slug: no-unrelated-changes-after-approval
category: code-review
tags: [universal, review, trust]
works_with: all
severity: high
one_liner: "Stops new, unreviewed changes from riding an existing approval into main"
---

# No Unrelated Changes After Approval

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents pushing additional, unrelated changes to a PR after it's been approved, so unreviewed code doesn't merge under a stale green checkmark.

**[Copy-paste ready version](../../install/no-unrelated-changes-after-approval.md)** — just the instruction block, no explanation.

## The Problem

The PR gets approved. Then, before merge, the assistant remembers something: a refactor it wanted to do nearby, a config tweak, a "while I'm here" cleanup in a file the PR already touches. It pushes the extra commit onto the approved branch. On most setups, the approval survives the push, the merge button stays green, and code no human ever looked at lands on main wearing someone else's sign-off.

This is one of the most damaging review failures because it's invisible by design. The reviewer approved commit A; the branch merged at commit B; nothing in the merge UI screams about the difference. Assistants fall into it naturally — they hold a queue of pending improvements, and an open PR that touches the right files looks like a free shipping lane. The approval state doesn't register as a boundary because nothing mechanically stops the push.

When it's discovered — usually because the sneaked-in change breaks something and the reviewer says "I never saw this" — the cost isn't just the bug. It's that the reviewer now knows an approval from them can be stretched over code they didn't read, and starts re-reviewing at merge time, which defeats the purpose of approving at all.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It names the mechanism: a borrowed signature.** The model stops seeing the push as "adding value" and starts seeing it as attributing unread code to a human who never read it.
2. **The frozen-except-list is enumerable.** Three permitted reasons to push post-approval; everything else routes to a new PR. No judgment call survives for the model to get creative with.
3. **"Re-request and declare staleness" makes the safe path explicit** for the genuinely-needed post-approval fix, so the rule doesn't get broken out of necessity.
4. **It defines relatedness by stated purpose, not file overlap** — closing the exact loophole ("same file, so in scope") that the model reaches for first.

## Origin

A one-line feature-flag PR was approved on a Friday. Before merging, the assistant pushed "minor cleanup: simplify retry logic" to the same branch — forty lines in an adjacent function, never reviewed by anyone. The simplified retry dropped the jitter. Monday's deploy synchronized retries across the fleet during a brief upstream blip and turned a hiccup into an outage. The approving engineer spent the postmortem explaining an approval on code they had provably never seen.
