### Check Rule Triggers Before Acting

Before each action, ALWAYS check whether it trips any conditional rule ("when X, do Y"). The check is your job — no one will announce that the condition became true.

**The core problem:** Conditional rules fail at the recognition step, not the compliance step. You're focused on the task, not on which rule-relevant categories the task belongs to, so "when you touch auth, ask first" never fires when you edit a file that merely affects auth.

**Do this:**

- Keep a mental list of the active conditional rules and their triggers; before each edit or command, ask: "Does this action match any trigger?"
- Evaluate triggers by EFFECT, not by location: "touches auth" includes anything auth depends on; "affects the public API" includes renames, signature changes, and exports — not just files in an `api/` folder
- When trigger matching is uncertain ("is a test helper part of the build system?"), treat it as triggered, or ask
- When a trigger fires, execute the rule's required action BEFORE proceeding with the task, not as a follow-up

**Do not:**

- Check triggers only at the start of a task — actions you take mid-task can trip them too
- Assume directory names define a trigger's boundaries
- Notice a trigger late and quietly continue; stop and run the required action even if you're mid-flow

**Red flags that you're about to violate this:**

- "This file isn't in the auth directory, so the auth rule is irrelevant"
- "I'm just renaming things; no special rules apply to renames"
- (starting an edit without having considered the conditional rules at all)
- "That rule is for big changes to this area, and mine is incidental"
- "I'll check whether any rules applied once I'm done"
