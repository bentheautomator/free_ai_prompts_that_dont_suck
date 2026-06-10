---
title: Verification Expires When You Edit Again
slug: verification-expires-when-you-edit-again
category: verification
tags: [universal, verification, state]
works_with: all
severity: high
one_liner: "Leaning on an old green result after making further edits it never saw"
---

# Verification Expires When You Edit Again

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the assistant from carrying a verification result forward across edits that invalidated it.

**[Copy-paste ready version](../../install/verification-expires-when-you-edit-again.md)** — just the instruction block, no explanation.

## The Problem

Mid-session, the assistant does everything right: runs the code, sees it work, reports it verified. Then the user asks for one more tweak. Then a rename for clarity. Then a quick refactor of the helper. The session ends with "all verified and working" — a claim minted three edits ago, describing a version of the code that no longer exists. Each individual edit was "too small to break anything," and the verification badge quietly migrated from the code that earned it to the code that replaced it.

This is the failure mode of diligent sessions. The assistant *did* verify — that's exactly what makes the stale claim feel honest. Verification gets stored as a property of the task ("the export feature: verified ✓") instead of a property of a snapshot ("the export feature as of the run at step 14"). Once it's task-scoped in the model's head, no amount of subsequent editing feels like it should revoke it, because the task didn't change. The code did.

The user inherits a deliverable whose last-tested version is not the shipped version, with a confidence label from the wrong commit. The bug introduced by tweak number three sails through under a flag earned by tweak number zero.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Verification Expires When You Edit Again

ALWAYS treat verification as a property of an exact snapshot of the code, not of the task. Any edit after the green run — however small — expires the result for everything that edit could affect.

The core problem: a verification earned at step 10 quietly stays attached to the feature through the edits at steps 12, 15, and 17. The final "verified" then describes code that was never run.

- Before any final claim of "verified," "working," or "done," ask one question: has anything changed since the run that proves this? If yes, the proof is expired. Rerun, or downgrade the claim.
- "Too small to break anything" is not an exemption category. Renames break callers, formatting commits touch the wrong line, one-line tweaks invert conditions. The size of the edit bounds the rerun cost, not the rule.
- Make the final check cheap by design: keep the verifying command handy (the test invocation, the curl line, the script) so re-verification after late edits is one step, not a project.
- When reporting, timestamp the evidence relative to the edits: "verified after the last change" is the claim that matters; "verified at some point during the session" is the one that bites.
- If late edits are genuinely outside the verified surface (a README typo after the test run), say that scoping out loud — claiming it implicitly is how unrelated-looking edits get smuggled past.
- Refactors and "cleanup" passes expire verification exactly like feature changes do. Behavior-preserving is the hypothesis; the rerun is the test.

**Red flags that you're about to violate this:**
- "I verified this earlier in the session, so it's verified..."
- "That last edit was cosmetic; the green run still stands..."
- "Rerunning after every tweak is busywork..."
- "The refactor didn't change behavior, by definition..."
- "I'll write the summary now — the tests passed back at step ten..."
- "It's the same feature, so it's the same verification..."

---

## Why It Works

1. **It rebinds verification from task to snapshot.** The stale claim survives because "the feature is verified" feels timelessly true. Defining the result as belonging to one exact state of the code makes every subsequent edit visibly revoke it.

2. **It installs a single final-gate question.** "Has anything changed since the proving run?" is checkable from the transcript and fires precisely at summary time — the moment the stale badge gets applied.

3. **It dismantles the smallness exemption.** Listing how tiny edits break things (renames, inverted conditions) removes the one rationalization that makes carrying the result forward feel safe.

4. **It reduces rerun friction structurally.** Keeping the verifying command ready means the honest path costs one tool call, so expiry stops feeling like a punishment.

## Origin

A session implemented a CSV importer, tested it thoroughly against three sample files — all green — and then handled four rounds of polish requests, the last of which renamed a parsing helper. The rename missed one call site behind a conditional. The closing summary said "implemented and verified against all sample files," which had been true forty minutes and four edits earlier. The importer crashed on first real use, and the diff between the verified version and the shipped version was exactly one missed rename that a single rerun would have caught.
