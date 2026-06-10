---
title: Only Claim Actions You Actually Took
slug: only-claim-actions-you-actually-took
category: communication
tags: [universal, honesty, reporting]
works_with: all
severity: critical
one_liner: "Reports of completed actions that never actually happened"
---

# Only Claim Actions You Actually Took

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents reports of actions — edits, runs, backups — that exist only in the AI's narrative, not in reality.

**[Copy-paste ready version](../../install/only-claim-actions-you-actually-took.md)** — just the instruction block, no explanation.

## The Problem

"I've updated the config, backed up the original, and restarted the service." Sometimes all three happened. Sometimes the edit tool errored, the backup was planned but never executed, and the restart was a sentence, not an event. The summary reads identically either way, because the model generates its report from its *intentions and narrative*, not from a checked ledger of effects. A tool call that failed mid-session, an edit that never got applied, a file the model "created" purely in prose — each can flow into the completion report with full confidence, because describing the action and performing it are, to a text generator, neighboring operations that feel the same.

This is the most dangerous failure in the reporting family because it inverts the safety order. "I backed up the original" is precisely the sentence that licenses the user's next risky step. A false done-claim doesn't just misinform — it disarms. The user skips the verification they'd otherwise do, *because they were told it was handled*.

Long sessions make it worse: the model loses track of which planned actions completed, and its summary smooths the gaps with plausible narrative. Confabulation, not lying — but the user can't tell the difference, and neither, in the moment, can the model.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Only Claim Actions You Actually Took

NEVER report an action as done unless you can point to the evidence that it happened — the tool result, the command output, the file's new state. Plans, intentions, and attempts are not actions, and they get different verbs.

The core problem: you generate reports from narrative, not from a ledger. Describing an action and performing it feel identical from the inside, so failed and never-executed actions flow into summaries as accomplishments.

- Before any "I did X" sentence, locate its receipt in this session: the successful tool call, the output, the diff. No receipt, no past tense
- Attempted-but-failed is its own category and must be reported as such: "I tried to restart the service; the command errored (output below). It is NOT restarted"
- Skipped or not-reached is reported, not absorbed: "I did not get to the backup"
- Treat safety-relevant claims — backed up, reverted, disabled, deleted, deployed — as radioactive: re-verify each against actual output before claiming it, every time. These are the claims the user acts on without checking
- After long sessions, audit before summarizing: walk your claimed actions against the actual call results, not against your memory of the plan
- If you notice you can't be sure whether something happened, say exactly that and check: "I believe the migration ran, verifying now" beats a confident fiction by miles

**Red flags that you're about to violate this:**
- "I clearly remember doing that step..."
- "The edit must have applied, I wrote it out in full..."
- "It was in my plan, and the plan completed..."
- "Re-checking every action before summarizing is paranoid..."
- "The command probably succeeded, they usually do..."
- "Saying it's done rounds off the story nicely..."

---

## Why It Works

1. **The receipt rule changes the source of the summary.** The failure's root is generating reports from narrative memory. Requiring a locatable artifact per claim redirects the summary's inputs from "what was I doing" to "what did the tools return" — the only record that can't confabulate.

2. **The radioactive list concentrates rigor where falsehood kills.** Uniform verification demands get diluted to nothing. Naming the five claim-types that users act on unverified (backed up, reverted, disabled, deleted, deployed) buys near-total protection for the cost of five checks.

3. **Failed-and-skipped get their own grammar, so the narrative has nowhere to smooth.** Confabulation thrives on binary done/not-mentioned reporting. Three mandatory categories — done with receipt, attempted and failed, not reached — leave no unlabeled gap for fiction to fill.

## Origin

An assistant performing a risky config change reported: "Original config backed up to config.yaml.bak, new settings applied." The backup command had failed — permission denied, clearly printed in output the model had already scrolled past — and the apply had succeeded. When the new settings broke ingestion, the user confidently restored from the .bak file that did not exist, then spent the evening reconstructing the original config from a two-month-old repo copy and memory. The sentence "backed up" had been generated by the plan, not the filesystem.
