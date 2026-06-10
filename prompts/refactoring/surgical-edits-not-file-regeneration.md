---
title: Surgical Edits, Not File Regeneration
slug: surgical-edits-not-file-regeneration
category: refactoring
tags: [universal, refactoring]
works_with: all
severity: high
one_liner: "Stops whole-file regeneration from memory when only one function needs changing"
---

# Surgical Edits, Not File Regeneration

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from rewriting an entire file from its mental model when the refactor only touches part of it, silently mutating everything else.

**[Copy-paste ready version](../../install/surgical-edits-not-file-regeneration.md)** — just the instruction block, no explanation.

## The Problem

Asked to refactor one function in a 400-line file, an assistant will sometimes emit the whole file again: the target function restructured as requested, and the other 350 lines reproduced from its understanding of them. Reproduced, not copied. The model is reconstructing those lines the way you'd retell a story, and retellings drift. A default argument comes back subtly different, an `<=` becomes `<`, an import vanishes, a rarely-referenced constant gets "corrected" to the value the model expected it to have. None of this was part of the task, none of it is mentioned in the summary, and all of it is now in the diff, if anyone reads the diff that carefully.

The behavior comes from how generation works: producing a fluent complete file is the model's native motion, while making a minimal targeted edit requires restraint it has to be held to. Whole-file output also *feels* safer to the model, no risk of mismatched edit anchors, but it trades a visible failure (edit didn't apply) for an invisible one (untouched code mutated).

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Surgical Edits, Not File Regeneration

When refactoring part of a file, edit only that part. NEVER regenerate a whole file from memory when the change targets a subset of it. Every line you re-emit without needing to is a line you might silently mutate.

Reconstructed code drifts: operators flip, defaults shift, imports drop, constants get "corrected." The blast radius of an edit must equal the scope of the task.

- Use targeted edit operations (string replacement, patch-style edits) scoped to the lines the refactor actually changes. Touch the function being restructured; leave its neighbors byte-identical.
- If your tooling forces whole-file writes, copy the unchanged regions exactly from the file you just read. Never type unchanged code from recall.
- After editing, review your own diff. Every changed line must trace to the stated refactor. A hunk in a function you weren't asked to touch means you regenerated; revert it.
- Unrelated code that looks wrong while you're in the file gets reported, not edited. "While I was rewriting the file anyway" is the failure, not a justification.
- Large refactors within one file are still a series of targeted edits, applied and verified one at a time, not one regeneration that incorporates all of them.
- If an edit fails to apply cleanly, re-read the file and retry the targeted edit. Falling back to whole-file regeneration because edits are fiddly trades a loud failure for a silent one. Don't.

**Red flags that you're about to violate this:**

- "It's simpler to just output the whole updated file."
- "I remember what the rest of the file looks like."
- "Rewriting the file fully guarantees everything stays consistent."
- "My string replacement didn't match, so I'll regenerate instead."
- "The rest of the file will come out the same anyway."

---

## Why It Works

1. **It names the drift mechanism explicitly.** The model believes its reproduction is a copy; stating that re-emission is reconstruction, with the concrete failure modes (flipped operators, shifted defaults), breaks that false confidence.
2. **The diff-traceability check is self-auditing.** "Every hunk must trace to the stated refactor" gives the model a mechanical pass over its own output that catches regeneration after the fact, not just intent before.
3. **It blocks the failure-mode downgrade.** The retry-the-edit clause targets the exact moment models switch to regeneration, when a patch fails to anchor, and forces them to stay in the loud-failure regime where mistakes are visible.

## Origin

An assistant was asked to extract a helper from one function in a config-loading module. It returned the full file, and the diff showed 14 changed lines outside the target function. One of them changed a retry backoff from `2 ** attempt` to `2 * attempt`, presumably because linear backoff was statistically likelier in its training data. The change sailed through review inside the noise, and during the next upstream outage the service hammered a struggling dependency with near-constant retries instead of backing off.
