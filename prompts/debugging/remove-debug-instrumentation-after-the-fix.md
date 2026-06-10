---
title: Remove Debug Instrumentation After the Fix
slug: remove-debug-instrumentation-after-the-fix
category: debugging
tags: [universal, debugging]
works_with: all
severity: medium
one_liner: "AI shipping fixes with debug prints and probes still embedded"
---

# Remove Debug Instrumentation After the Fix

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from delivering a fix with its debugging scaffolding — prints, dumps, hardcoded test values — still wired into the code.

**[Copy-paste ready version](../../install/remove-debug-instrumentation-after-the-fix.md)** — just the instruction block, no explanation.

## The Problem

The bug gets fixed, and the diff that ships contains the fix — plus `console.log("HERE 3", JSON.stringify(user))`, plus a `DEBUG=True` flipped in config, plus the loop that was shortened to 5 iterations "to test faster," plus the hardcoded test email in the recipient field. Instrumentation is supposed to be scaffolding: erected to see inside the program, torn down when the building stands. AI assistants erect it readily (good!) and then deliver the construction site (bad), because once the bug is fixed, the model's attention snaps to summarizing the victory, and the scaffolding has become invisible context it stopped tracking rounds ago.

Some leftovers are merely embarrassing — `"WHY IS THIS NULL???"` in production logs. Others are real damage: a `JSON.stringify` of a user object dumping PII into log aggregators; a debug flag that disables caching and quietly triples response times; the 5-iteration loop that now processes 5 of 80,000 records in production; the hardcoded email receiving every customer's password reset. The worst category is instrumentation that *changes behavior* — the temporary early-return above the suspect code, the commented-out validation, the probe that swallows an exception — where the "fix" being shipped is partly the leftover itself.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Remove Debug Instrumentation After the Fix

ALWAYS sweep your debugging scaffolding out of the diff before presenting a fix. Instrument freely during investigation — then tear it all down: the fix ships, the scaffolding doesn't.

- Track what you add: every print/log, debug flag, shortened loop, hardcoded value, commented-out block, early return, or extra try/catch added for visibility is a temporary structure with a removal obligation attached
- Before declaring done, audit the *entire* diff against the baseline (`git diff`) and classify every changed line: fix, or scaffolding? Scaffolding gets removed; anything you can't classify gets investigated
- Be especially careful with behavior-changing instrumentation — bypassed validation, early returns, swallowed exceptions, disabled caching, reduced iteration counts, test credentials — because removing it can change whether the bug is actually fixed: re-run the reproduction *after* the sweep, on the clean fix alone
- Watch for data leaks in leftovers: dumps of full objects, tokens, or user data into logs are a security problem, not just noise
- If a piece of instrumentation proved genuinely valuable, converting it into permanent, properly-leveled logging is allowed — as a deliberate, named decision in your summary, not as a leftover with a promotion
- The delivered diff should read as: the fix, and nothing else

**Red flags that you're about to violate this:**
- "Fixed! Let me summarize what the bug was..." (without a diff sweep)
- "I'll leave the logging in, it might be useful later..." (decide, don't drift)
- "That debug flag isn't hurting anything..."
- Forgetting what you changed three rounds ago to "see what's happening"
- A diff whose line count is far larger than the fix you're describing
- Re-running the test only with the scaffolding still in place

---

## Why It Works

1. **It attaches the removal obligation at creation time.** The leftovers survive because they stop being tracked; framing every probe as "scaffolding with a removal obligation" keeps it on the books from the moment it's added.

2. **It uses the diff as ground truth.** Memory of what was added fails over long sessions; `git diff` against baseline doesn't. Auditing the actual diff catches the probes added eight rounds ago that the AI no longer remembers.

3. **It forces a post-sweep re-verification.** Behavior-changing scaffolding can be load-bearing — the bug "fixed" only while validation is bypassed. Re-running the reproduction on the clean fix alone exposes exactly that case.

4. **It legitimizes deliberate promotion.** Some instrumentation deserves to stay; routing it through an explicit named decision separates "chose to keep" from "forgot to remove."

## Origin

A fix for a payment-matching bug shipped with its investigation intact: a log line dumping the full transaction object — card metadata included — at every match attempt. It ran for a month, writing thousands of records a day into a log platform with org-wide read access, until a routine audit flagged it. The fix itself was three lines; the cleanup was a compliance incident, a log-purge request to the vendor, and a very long meeting.
