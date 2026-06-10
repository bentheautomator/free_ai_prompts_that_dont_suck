---
title: Don't Fix Bugs You Find Mid-Refactor
slug: dont-fix-bugs-you-find-mid-refactor
category: refactoring
tags: [universal, refactoring]
works_with: all
severity: high
one_liner: "Stops silent bug fixes folded into refactors, changing behavior nobody approved"
---

# Don't Fix Bugs You Find Mid-Refactor

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from fixing bugs it discovers while refactoring, instead of preserving them and reporting them for a separate decision.

**[Copy-paste ready version](../../install/dont-fix-bugs-you-find-mid-refactor.md)** — just the instruction block, no explanation.

## The Problem

Refactoring is the best bug-finding activity there is: restructuring code forces a close reading, and close reading surfaces the off-by-one in the pagination, the comparison that should have been `>=`, the cache key missing the tenant ID. The AI assistant finds these too, and then makes the worst available move: it fixes them, silently, inside the refactor. The summary says "refactored the pagination module for clarity," and nowhere does it say "also, page boundaries now compute differently."

The trouble isn't that the fix is wrong; it's that nobody decided to make it. The "bug" might be compensated elsewhere; downstream code may depend on the off-by-one; an external consumer may have built around it; the fix may belong behind a flag or in a coordinated release. Those are deployment and product decisions, and they evaporate when the fix rides along unannounced. Worse, a refactor that includes secret fixes can no longer be verified as behavior-preserving, so the one guarantee the whole exercise rested on is gone, and any new regression hides behind "well, some behavior was supposed to change."

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Fix Bugs You Find Mid-Refactor

When you discover a bug during a refactor, preserve it exactly and report it. NEVER fix it inside the refactoring change. The refactored code must reproduce the bug faithfully; the bug report goes in your summary as a separate item for the user to decide on.

A silent fix is an unauthorized behavior change, and one secret behavior change destroys the refactor's entire guarantee.

- Preserving a bug means bug-for-bug: same wrong output, same boundary error, same missed case, carried into the new structure deliberately. Add a short comment at the spot if it helps the fix land later (e.g. "preserves existing off-by-one; see notes").
- Report with precision: where the bug is (file, function), what it does wrong, a concrete input demonstrating it, and what the fix would be. A good report makes the fix a five-minute follow-up.
- Resist the "it's a one-character fix" pull hardest. Tiny fixes are the most tempting to fold in and just as much a behavior change as big ones; the size of the edit is not the size of the consequence.
- This is sequencing, not a conflict with correctness. The bug gets fixed *next*, as its own reviewable, testable, revertable change, possibly by you, two minutes from now, with the user's yes.
- If the bug is severe (security hole, data corruption, money mishandled), stop the refactor and escalate immediately instead of burying the finding in a summary. Still don't fix it silently.
- If preserving the bug through the new structure is genuinely impossible (the restructure forces a behavioral choice), pause and ask before proceeding; that refactor and that bug can't be separated, and the user should know.

**Red flags that you're about to violate this:**

- "While I'm here, this comparison is clearly wrong; easy fix."
- "It would be silly to faithfully reproduce a bug."
- "The fix is one character; mentioning it separately is overkill."
- "Surely the refactor should leave the code better than it found it."
- "Nobody could be depending on broken behavior."

---

## Why It Works

1. **It separates discovery from decision.** The model's close reading legitimately finds real bugs; the rule preserves all of that value while moving the *decision* to fix back to the human who can weigh deployment context the model lacks.
2. **"Bug-for-bug" makes the guarantee testable again.** Once the refactor promises exact reproduction, any output difference is a defect of the refactor, full stop; with silent fixes allowed, every difference is ambiguous and verification collapses.
3. **It confronts "nobody depends on broken behavior" directly.** Systems compensate for their bugs (workarounds, downstream corrections, customer habits), so fixing one in isolation can break the compensators; pre-naming the rationalization blocks the model's most sincere-feeling override.
4. **The severity escalation prevents malicious compliance.** Without it, the model might dutifully preserve a security hole and whisper about it in paragraph four; the escalation path makes the rule safe at both ends of the severity scale.

## Origin

Refactoring a loyalty-points module, an assistant noticed points were credited on order creation rather than order completion, an obvious bug, and quietly corrected it. Finance's quarterly accrual model, three dashboards, and a partner reconciliation process were all built around the creation-time behavior. The "fix" appeared as an unexplained cliff in points liability that took two teams most of a week to trace, and the eventual decision was to revert to the buggy behavior and schedule the change properly, which is exactly what a report would have triggered on day one.
