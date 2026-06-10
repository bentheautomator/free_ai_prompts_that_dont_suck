---
title: Check Rule Triggers Before Acting
slug: check-rule-triggers-before-acting
category: instruction-following
tags: [universal, rules, process]
works_with: all
severity: high
one_liner: "Conditional rules never fire because AI doesn't notice the trigger"
---

# Check Rule Triggers Before Acting

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents "when X happens, do Y" rules from silently never firing because the AI doesn't notice it's in an X situation.

**[Copy-paste ready version](../../install/check-rule-triggers-before-acting.md)** — just the instruction block, no explanation.

## The Problem

Conditional rules — "when you touch the auth code, ping me first," "if a change affects the public API, update the docs," "any edit to a migration requires a fresh dry run" — fail differently than blanket rules. The AI doesn't skip them, reinterpret them, or argue with them. It simply never notices that the condition became true. It edits a file that *imports from* the auth module, or renames a type that *is part of* the public API, and the rule sits inert because nothing announced "you are now in an X situation."

The mechanism: blanket rules can be checked against every action, but conditional rules require recognizing the trigger, and recognition is exactly what task focus suppresses. The AI is thinking about the rename, not about which categories the rename belongs to. Triggers are also often indirect — "touches auth" includes files that affect auth without living in `auth/` — and the AI evaluates them, if at all, by directory name rather than by effect.

So the user's most surgical rules — the ones scoped precisely to the risky cases — end up being the least reliable ones.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It assigns ownership of recognition.** The rule fails because no one is watching for the trigger. "The check is your job — no one will announce it" makes trigger-watching an explicit responsibility instead of an emergent hope.

2. **It redefines triggers by effect.** The most common miss is topological: the file wasn't in the named directory. Defining "touches X" as "affects X" closes the gap between how users mean triggers and how models evaluate them.

3. **It defaults uncertainty to triggered.** Borderline cases otherwise resolve to "probably fine," which is the failure. Flipping the default makes the cheap mistake (an unnecessary heads-up) replace the expensive one (a missed gate).

4. **It orders the rule's action before the task.** Conditional rules are usually gates. Requiring Y before proceeding prevents the pattern where the trigger is noticed but the gate is executed retroactively, after the protected action already happened.

## Origin

A rules file said: "Any change that affects session handling: stop and describe the change before implementing." The AI refactored a utility module — not session code, just a cookie-parsing helper that session handling happened to depend on — and shipped it without stopping. The refactor changed how empty cookie values were treated, logging out a subset of users on every request. The conditional rule was well-designed and would have caught it. It never fired, because nothing in the AI's view of "refactoring a helper" looked like "session handling."
