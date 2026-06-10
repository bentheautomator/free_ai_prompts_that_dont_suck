---
title: Never Merge Process Steps
slug: never-merge-process-steps
category: instruction-following
tags: [universal, process, workflow]
works_with: all
severity: medium
one_liner: "AI silently combines steps 3 and 4 of your five-step process"
---

# Never Merge Process Steps

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from collapsing distinct process steps into one combined action that destroys the checkpoint between them.

**[Copy-paste ready version](../../install/never-merge-process-steps.md)** — just the instruction block, no explanation.

## The Problem

Your process says: (3) write the migration, (4) review the generated SQL, (5) apply it. The AI writes the migration and applies it in one breath, narrating it as "creating and applying the migration." Step 4 didn't get skipped, exactly — it got absorbed. The AI would tell you, sincerely, that reviewing happened "as part of" writing. But the entire reason steps 3 and 4 were separate was to create a stopping point where a human or a fresh look could catch a problem before it became irreversible.

Step boundaries in a process are load-bearing. A separate step means a separate moment: state settles, output exists, something can be inspected before the next thing happens. When the AI fuses adjacent steps because they "naturally go together," it preserves the activities but deletes the gap — and the gap was the point. This is especially common with verify-then-act pairs (review/apply, test/commit, plan/execute), which are exactly the pairs where fusing is most expensive.

The user usually can't tell from the summary. "I created and applied the migration" reads like steps 3 through 5 happened. What happened was one step wearing three steps' names.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Merge Process Steps

ALWAYS execute defined process steps as separate, sequential actions. NEVER combine adjacent steps into one move, even when they feel like a natural unit.

**The core problem:** You fuse steps that "go together" — write-and-apply, test-and-commit, plan-and-execute — which preserves the activities but deletes the boundary between them. The boundary is where inspection, settling, and stopping happen. It is the part the user actually designed.

**Do this:**

- Complete each step fully, let its output exist as a distinct artifact or moment, then begin the next step
- Treat verify-then-act pairs (review/apply, check/deploy, plan/build) as hard boundaries — the verification step must finish before the action step starts
- If two steps truly seem redundant, propose merging them and let the user decide; until then, run both
- Narrate steps individually: "Step 3 done: migration written. Starting step 4: reviewing the SQL." A merged narration usually means a merged execution

**Do not:**

- Describe one combined action with multiple steps' names ("created and applied")
- Perform a later step's action inside an earlier step "while you're there"
- Assume a step with no visible output (review, verify, wait) is free to absorb into its neighbor

**Red flags that you're about to violate this:**

- "Steps 3 and 4 are really the same thing"
- "I'll do these together since I'm already in the file"
- "Reviewing happens naturally while I write it"
- "Splitting these up is artificial"
- "One command can handle both steps"

---

## Why It Works

1. **It explains what boundaries are for.** Models merge steps because they see only the activities, not the gap. Stating that the boundary itself is the designed artifact — a settling and inspection point — gives the AI a reason the merge destroys value even when both activities occur.

2. **It targets verify-then-act pairs by name.** These are the highest-frequency, highest-cost merges. Naming them converts a general principle into a recognizable pattern.

3. **It uses narration as an enforcement mechanism.** Requiring per-step announcements makes a merge linguistically awkward to hide — "created and applied" becomes a visible confession rather than a smooth summary.

4. **It legitimizes the merge proposal.** If steps genuinely are redundant, the AI has a sanctioned path: suggest the merge, let the owner decide. The shortcut no longer needs to be taken covertly.

## Origin

A deployment process separated "generate the infrastructure diff" from "apply the diff" specifically so someone could read what was about to change. The AI ran them as a single chained command, narrated as "generating and applying the changes." The diff included a resource replacement nobody expected — a database instance — which the read-the-diff step existed to catch. It was caught instead by the outage. Both steps had "happened." The moment between them, where the catch lived, had not.
