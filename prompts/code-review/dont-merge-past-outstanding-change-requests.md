---
title: Don't Merge Past Outstanding Change Requests
slug: dont-merge-past-outstanding-change-requests
category: code-review
tags: [universal, review, workflow]
works_with: all
severity: high
one_liner: "Stops merging while another reviewer's change request still stands"
---

# Don't Merge Past Outstanding Change Requests

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents merging a PR because one approval arrived while another reviewer's requested changes or unresolved blocking threads are still open.

**[Copy-paste ready version](../../install/dont-merge-past-outstanding-change-requests.md)** — just the instruction block, no explanation.

## The Problem

Two reviewers are on the PR. Reviewer A requested changes on Tuesday — a specific concern about the rollback path. Reviewer B approved on Thursday. The branch protection rules only require one approval, the merge button is green, and the task says "merge when approved." So the assistant merges. Reviewer A's concern — never answered, never withdrawn — is now a comment thread on a closed PR, which is where review feedback goes to be ignored forever.

Assistants make this mistake because they read merge eligibility off the UI state: button green, requirement met, proceed. But branch protection encodes the *minimum* policy, not the social contract. A standing change request is a human saying "I believe this shouldn't merge yet," and that statement doesn't expire because a colleague was more easily satisfied. The same failure has a quieter variant: unresolved blocking threads from the *approving* reviewer ("fix this before merge, but approving to unblock you") that the assistant treats as resolved by the approval itself.

Merging past an objection does two kinds of damage: whatever the objection was about ships, and the objecting reviewer learns their "request changes" is decorative. The second one is permanent.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Merge Past Outstanding Change Requests

NEVER merge a PR while any reviewer's change request stands or any blocking thread is unresolved — regardless of how many approvals it has or what the merge button's color implies. The button encodes minimum policy; objections encode a human's standing "not yet."

- Before merging, audit the full review state, not the mergeability flag: any reviewer with "changes requested"? Any thread where someone said "before merge," "blocking," or asked a question that never got answered?
- A standing change request is cleared by exactly two people: the reviewer who made it (re-review or explicit "my concerns are addressed, go ahead") or a human with authority who explicitly overrides it in the thread. You are neither.
- If the objecting reviewer is unresponsive, escalate to the humans: "Reviewer A requested changes 4 days ago and hasn't re-reviewed; B has approved. How do you want to proceed?" Waiting for instructions is correct; interpreting silence as consent is not.
- Conditional approvals ("approving, but fix the timeout before merging") carry obligations. The condition is a blocker; meet it and confirm before merge.
- If you addressed A's concerns in code after their change request, that does not clear the request — re-request their review and let them clear it. Your judgment that you satisfied them is precisely the judgment under review.

**Red flags that you're about to violate this:**

- "The merge button is green, so the requirements are met..."
- "Reviewer B approved more recently, which supersedes A's objection..."
- "I fixed what A complained about, so their block is effectively resolved..."
- "A hasn't responded in days, they've probably moved on..."
- "The change request was about a minor thing anyway..."
- "The deadline is today and we have the one required approval..."

---

## Why It Works

1. **It severs merge-eligibility from UI state.** The model's failure is reading "green button" as "permitted"; redefining the button as minimum policy forces the audit of the actual human signals the platform doesn't enforce.
2. **Clearing authority is enumerated.** Two parties can clear an objection, and the assistant is on the list zero times. This closes the "I addressed it, so it's addressed" loop — the self-assessment that the review process exists to check.
3. **The escalation path makes patience viable.** Most premature merges happen because waiting feels like stalling. Giving the model a concrete action for the stuck case (ask the humans, with the facts) replaces "interpret silence" with "surface silence."
4. **Conditional approvals are named as blockers,** catching the politest version of the failure — where the approval itself contains the objection and gets counted as a clean yes.

## Origin

A database-failover PR had approval from a teammate and a standing change request from the on-call DBA, whose comment asked whether the new health check could flap during routine VACUUM operations. The question was never answered; the deadline was real; the merge requirement was "1 approval," and so it merged. The health check flapped during the next weekend's VACUUM, triggered an unnecessary failover at 3 a.m., and dropped four minutes of writes. The DBA's comment, preserved verbatim on the closed PR, described the incident in advance with near-perfect accuracy.
