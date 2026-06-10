---
title: Read the File Back After You Edit It
slug: read-the-file-back-after-you-edit-it
category: verification
tags: [universal, verification, edits]
works_with: all
severity: high
one_liner: "Claiming an edit took effect without confirming what's actually on disk"
---

# Read the File Back After You Edit It

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the assistant from reporting an edit as applied when the file on disk says otherwise.

**[Copy-paste ready version](../../install/read-the-file-back-after-you-edit-it.md)** — just the instruction block, no explanation.

## The Problem

"Updated the timeout to 30 seconds." Did it, though? Edits fail in quiet ways: the tool matched a different occurrence of the search string, the patch applied to a stale copy of the file, the write hit `config.example.yaml` instead of `config.yaml`, the change landed in a generated file that the next build will overwrite, or the edit silently no-opped because the target text had already drifted. The assistant's report describes its intention, not the disk.

Assistants do this because the edit tool returned without an error, and "no error" gets rounded up to "done as described." Issuing the claim costs nothing; reading the file back costs a tool call that almost always confirms what the assistant already believes — so it feels skippable. The one time in twenty it wouldn't have confirmed it is the time that matters.

The downstream failure is maddening to debug because everyone is staring at the wrong layer. The user reruns the app, sees the old behavior, and the session pivots to "why didn't the fix work" — investigating logic that was never actually changed. Whole debugging arcs have been spent on a change that didn't exist.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Read the File Back After You Edit It

NEVER report an edit as applied until you have read the relevant region of the file back from disk and seen your change in it, in the right place, with nothing mangled around it.

The core problem: an edit tool returning without error proves a write happened, not that the file now says what you intended. Wrong occurrence, wrong file, stale buffer, and silent no-op all look identical from the tool's success message.

- After any edit you're about to describe as done, read back the changed region and confirm: the new text is present, the old text is gone, and adjacent lines are intact.
- Confirm you edited the file the system actually uses. Watch for decoy twins: `.example` files, generated output, vendored copies, build artifacts, and same-named files in other directories.
- When replacing text that appears multiple times, verify which occurrence changed — and that the others you meant to leave alone are untouched.
- After multi-file or scripted edits (codemods, sed, find-and-replace), spot-check at least one modified file per kind of change instead of trusting the summary count.
- If the read-back shows a mangled or misplaced edit, fix it before reporting anything. Never describe the edit you meant to make; describe the file as it now exists.

**Red flags that you're about to violate this:**
- "The tool said the edit succeeded, so it's in..."
- "I just wrote that text two seconds ago, no need to look at it..."
- "There's only one place that string could have matched..."
- "Reading the file back is paranoid for a one-line change..."
- "The diff in my head matches what I sent to the tool..."
- "Both files have the same name; surely I got the right one..."

---

## Why It Works

1. **It separates "the tool ran" from "the change exists."** The failure lives in the gap between those two facts; naming the gap stops the model from rounding one up to the other.

2. **It names the decoy-twin trap.** Wrong-file edits are a distinct, recurring mechanism (example configs, generated files, vendored copies). Listing them turns a surprise into a checklist item.

3. **The read-back is the same tool the claim came from.** There's no environment excuse — if you could edit it, you can read it, so the rule has no escape route that the false claim doesn't also lack.

4. **It binds the report to the disk, not the intent.** "Describe the file as it now exists" makes the honest sentence and the verified sentence the same sentence.

## Origin

An assistant reported lowering a connection-pool limit in a service's config. The session then spent forty minutes investigating why the service still exhausted connections, with increasingly exotic theories about the pool library. Eventually someone catted the config: untouched. The edit had matched the identical key in `config.defaults.yaml`, which the service reads only when the main config is absent. A three-second read-back would have caught what forty minutes of theorizing did not.
