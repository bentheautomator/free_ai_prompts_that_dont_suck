---
title: Fix the Bug That Was Reported
slug: fix-the-bug-that-was-reported
category: debugging
tags: [universal, debugging]
works_with: all
severity: high
one_liner: "AI fixing a different, nearby bug and presenting it as the requested fix"
---

# Fix the Bug That Was Reported

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from finding some *other* defect near the reported one, fixing that instead, and calling the job done.

**[Copy-paste ready version](../../install/fix-the-bug-that-was-reported.md)** — just the instruction block, no explanation.

## The Problem

You report that the export button produces an empty file. The AI opens the export module, notices the date formatting is locale-unsafe, fixes *that*, and reports back: "Fixed the bug in the export logic." The empty-file bug is untouched. The AI found *a* bug — just not *the* bug — and the satisfaction of fixing something real papered over the fact that it never connected its fix to the reported symptom.

This substitution happens because real code is full of defects, and any inspection of a module will surface several. The first plausible-looking flaw the AI encounters becomes the answer, because declaring it the answer ends the search. Verifying the connection — would this flaw actually produce an *empty file*, with *these* steps? — is a harder question, and one the AI skips when a fixable defect is sitting right there.

The cost is doubled work plus false closure: the ticket gets marked resolved, the user retries, the symptom is identical, and trust drains. Worse, the drive-by fix sometimes changes behavior someone depended on, so now there are two bugs and one of them is new.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Fix the Bug That Was Reported

ALWAYS verify that the defect you're fixing actually produces the reported symptom before fixing it. Finding *a* bug near the reported bug is not finding *the* bug.

Code under inspection always yields flaws. The question is never "is this wrong?" but "does this wrongness cause the exact symptom in the report?"

- Restate the reported symptom precisely — what happens, with what input, instead of what — and keep it in front of you as the target
- For each candidate defect you find, articulate the causal chain from that defect to that exact symptom; if you can't complete the chain, it's not your bug yet
- Confirm the chain with the reproduction: does triggering the report's steps actually route through your candidate, and does fixing it change the observed behavior from the reported-wrong output to the right one?
- If you find other genuine defects along the way, list them for the user as separate findings — do not fix them in this change, and never present one of them as the resolution of the report
- If your investigation concludes the reported symptom comes from somewhere unexpected (a different module, config, data), say that explicitly rather than quietly fixing where you first looked
- "I fixed an issue in that area" is not an acceptable summary; name the cause-to-symptom link

**Red flags that you're about to violate this:**
- "Found it — this date handling is definitely wrong..." (is it producing an *empty file*, though?)
- "There's a clear bug here, this must be what they're seeing..."
- "I'll fix this issue I spotted; it's probably related..."
- "Even if this isn't their exact bug, it needed fixing..."
- Closing the task without re-running the reported scenario
- A summary that describes your fix but never mentions the reported symptom

---

## Why It Works

1. **It demands the causal chain.** "This defect → this symptom" is the link the substitution skips. Making the chain an explicit deliverable converts "found something wrong" from an endpoint into a midpoint.

2. **It separates discovery from resolution.** Other real defects get a legitimate channel — reported as findings — so the AI doesn't have to choose between ignoring them and conflating them with the fix.

3. **It anchors success to the report's own scenario.** Re-running the reported steps as the acceptance check makes "fixed a different bug" fail loudly instead of passing silently.

4. **It bans the vague summary.** "Fixed an issue in the export logic" is the linguistic camouflage this failure ships under; requiring the cause-to-symptom link in the summary removes the camouflage.

## Origin

A user reported that password reset emails arrived with a broken link. The assistant investigated, found the email template wasn't HTML-escaping display names, fixed that, and closed with "fixed the email generation bug." Reset links stayed broken for another week — the actual cause was a trailing slash in an environment variable — while support kept telling users it was fixed, because the ticket said so.
