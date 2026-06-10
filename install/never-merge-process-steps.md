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
