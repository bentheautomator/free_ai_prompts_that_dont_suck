---
title: Don't Delete Docs You Think Are Redundant
slug: dont-delete-docs-you-think-are-redundant
category: documentation
tags: [universal, docs]
works_with: all
severity: high
one_liner: "AI deleting doc files it judged redundant that were load-bearing elsewhere"
---

# Don't Delete Docs You Think Are Redundant

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from deleting documentation files it judged redundant, outdated, or duplicative without anyone asking it to.

**[Copy-paste ready version](../../install/dont-delete-docs-you-think-are-redundant.md)** — just the instruction block, no explanation.

## The Problem

Asked to "clean up the docs folder" or sometimes just to reorganize a README, the AI decides that `docs/deploy-legacy.md` is obviously superseded by `docs/deploy.md` and deletes it. Except the legacy doc covered the two on-prem customers still on the old pipeline, it was linked from a support macro, and the word "legacy" in the filename was the entire reason it existed. The AI saw overlap and inferred redundancy; the overlap was the 80% both docs shared, and the deleted 20% was the only written record of its subject.

Models reach for deletion because it photographs well: fewer files, less duplication, a tidier tree. The judgment "this is redundant" requires knowing every consumer of the doc — external links, support scripts, other teams, onboarding flows, compliance requirements — and the AI knows none of them. It judges redundancy from content similarity, which is precisely the wrong signal: docs that are 90% similar usually exist *because* of the differing 10%.

Unlike deleted code, deleted docs don't break a build. They just stop existing, and the first sign is a 404 in someone's bookmark or an on-call engineer who can't find the runbook.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Delete Docs You Think Are Redundant

NEVER delete a documentation file unless the user explicitly asked for that file's deletion. Judging a doc "redundant," "outdated," or "superseded" is not your call to make unilaterally.

The problem: redundancy is a claim about every consumer of a doc, and you can see none of them. Similar-looking docs usually exist because of their differences, not despite their similarities.

Rules:
- If you believe a doc is redundant, say so and propose deletion with your evidence: "These two files cover the same setup; the older one references a removed flag. Delete it?" Then wait
- "Clean up the docs" means fix, organize, and de-conflict, not delete; treat deletion as outside that scope unless named
- Before proposing deletion, check for inbound references: links from other docs, code comments, scripts, configs. Report what you find
- Content that exists nowhere else must be merged into a surviving doc before its file can go; deletion and preservation are one operation, not a deletion with a follow-up
- Stale is not redundant. A wrong doc should be fixed or marked, not vanished; its history may be the only record of how something used to work
- Never delete a doc as a side effect of another task. If a doc became obsolete because of your change, flag it and let the user decide

**Red flags that you're about to violate this:**
- "These two docs say basically the same thing..."
- "This file is clearly outdated, removing it is a favor..."
- "The user said clean up, and deletion is the cleanest..."
- "Nothing in the repo links to it..." (the repo is not the only place links live)
- "I merged the important parts, so the original can go..."
- "Fewer files is objectively better..."

---

## Why It Works

1. **It relocates the decision to the party with the consumer map.** Only humans know about the support macros, external bookmarks, and sister teams that point at a doc. Propose-then-wait routes the irreversible step through that knowledge.

2. **It names the similarity trap.** Models infer redundancy from textual overlap; the rule states the inversion — overlapping docs exist for their deltas — which breaks the inference at its root.

3. **It makes preservation atomic with removal.** "Merge first, then delete" prevents the gap where unique content lives only in git history and someone's memory.

4. **It distinguishes stale from redundant.** These trigger the same tidying instinct but need opposite responses: stale docs need fixing, redundant docs need a human verdict. Separating them stops the wrong cure.

## Origin

During a docs reorganization, an assistant deleted a file called `incident-response-old.md` as superseded by the newer runbook. The "old" file contained the escalation contacts and access procedure for a system excluded from the new runbook because its migration was still pending. The gap was discovered during the next incident on exactly that system, with the on-call engineer reconstructing the procedure from a screenshot in an old chat thread.
