---
title: Don't Restyle Other Teams' Code in Passing
slug: dont-restyle-other-teams-code-in-passing
category: collaboration
tags: [universal, teamwork, ownership]
works_with: all
severity: medium
one_liner: "Stops drive-by style fixes in code that belongs to someone else"
---

# Don't Restyle Other Teams' Code in Passing

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from "fixing" the style of other people's code while passing through it for an unrelated task.

**[Copy-paste ready version](../../install/dont-restyle-other-teams-code-in-passing.md)** — just the instruction block, no explanation.

## The Problem

The AI needs to change three lines in a file another team maintains. While it's there, it also converts their callbacks to async/await, renames their variables to its preferred style, reorders their imports, reformats their object literals, and modernizes their loops. The actual change is three lines; the diff is three hundred. The AI calls this leaving the code better than it found it.

The owning team experiences it differently. Their `git blame` is destroyed — every restyled line now points at a drive-by commit instead of the change that explains it, which matters enormously the next time someone debugs that file at midnight. Their open branches now conflict with three hundred lines of churn. Their review burden exploded, because the three lines that matter are buried in noise, and a reviewer who skims the noise might miss a real behavior change hiding in the "pure style" edits — restyling is where accidental semantic changes love to hide (a reordered import with side effects, an async conversion that changes error timing). And their style, which may be deliberate, has been overruled by a visitor.

The AI does this because it evaluates code against its own aesthetic, and "improve what you touch" feels virtuous. It can't see that in someone else's code, unrequested improvement is a cost imposed on the owners: churn they didn't ask for, conflicts they'll pay for, history they lose.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Restyle Other Teams' Code in Passing

NEVER restyle, reformat, or "modernize" code you're passing through for an unrelated task — especially code another team or developer owns. Change the lines the task requires and leave the rest byte-for-byte alone.

Drive-by restyling buries the real change, destroys blame history, and creates merge conflicts for people with open branches — costs paid entirely by the code's owners.

- Touch only the lines your task requires. If the fix is three lines, the diff is three lines plus whatever those lines strictly force.
- Do not convert paradigms in passing: callbacks to promises, loops to comprehensions, var to const, classes to hooks. Even when the new form is better, it's a separate decision for the code's owners.
- Do not rename their variables, reorder their imports, adjust their whitespace, or re-wrap their lines outside your change.
- If your editor or formatter wants to reformat the whole file, stop it. A formatting pass mixed into a logic change makes both unreviewable.
- If the surrounding style is genuinely problematic (not just different from your taste), note it in your summary as an observation for the owners. One sentence, no diff.
- Style cleanups can be legitimate work — as their own dedicated change, requested by or agreed with whoever owns the code, never as a rider.

**Red flags that you're about to violate this:**
- "While I'm in this file, I'll clean it up properly."
- "This old-style code hurts to leave as-is."
- "Reformatting is harmless; it doesn't change behavior."
- "The owners will thank me for modernizing this."
- "My formatter touched the whole file, but that's fine."

---

## Why It Works

1. **It keeps the diff equal to the decision** — a reviewable change is one where every changed line traces to the stated task, and restyling breaks that property precisely where review matters most: other people's code.
2. **It preserves blame as a debugging tool**, which is a real asset the owners use and the visitor never sees the value of.
3. **It names where bugs hide**: "pure style" conversions (async, import order) routinely carry semantic changes, and burying them in churn maximizes the odds they ship unreviewed.
4. **It routes the improvement impulse legitimately** — observation to the owners, or a dedicated agreed change — so good taste still has an outlet that isn't unilateral.

## Origin

Fixing a one-line null check in another team's module, an assistant also converted the file from promise chains to async/await — a 280-line diff for a 1-line fix. The conversion subtly changed when one error was caught, moving it outside an existing handler. The reviewing engineer, facing 280 lines of "just style," skimmed. The error-handling change shipped, and a failure that used to be retried became a crash three weeks later. The blame for every line in that file now points to a commit titled "fix null check."
