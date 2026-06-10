---
title: A Fix You Can't Explain Is Not a Fix
slug: a-fix-you-cant-explain-is-not-a-fix
category: debugging
tags: [universal, debugging, root-cause]
works_with: all
severity: high
one_liner: "AI shipping changes that make the bug stop for reasons nobody knows"
---

# A Fix You Can't Explain Is Not a Fix

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from shipping a change that makes the bug stop happening for reasons it cannot articulate.

**[Copy-paste ready version](../../install/a-fix-you-cant-explain-is-not-a-fix.md)** — just the instruction block, no explanation.

## The Problem

Somewhere in the flailing, a change makes the failure stop. The AI doesn't know why — the change was reordering two initializations, or switching a map to a list, or moving a call inside a conditional, and no theory connects it to the symptom — but the test is green, so it ships, sometimes with the tell-tale comment: `// somehow this fixes the issue`. This is a coincidence being promoted to a conclusion. A change that fixes a bug through an unknown mechanism is, with high probability, not fixing it at all: it's perturbing timing, memory layout, evaluation order, or cache behavior just enough to hide the symptom in the tested configuration.

The mechanism question is the entire difference between a fix and a disturbance. If you can say "the bug was X, this change prevents X by Y," you can predict where else X lurks, know which configurations are safe, and write the regression test that actually guards the right thing. If you can't, you know nothing: the bug may reappear under load, on other hardware, after an unrelated change re-perturbs whatever got perturbed — and the "fix," being inexplicable, is also unreviewable and undeletable, fossilizing into the codebase as a line nobody dares touch.

AIs ship these because green-after-change is the strongest reward signal in their loop, and "why" is a question the loop never forces.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### A Fix You Can't Explain Is Not a Fix

NEVER ship a change as a bug fix unless you can state the mechanism: "the bug was X; this change prevents X by Y." A change that stops the symptom for unknown reasons is a coincidence wearing a green checkmark, and it is usually hiding the bug, not removing it.

- After any change that makes the failure stop, the next step is not shipping — it's explaining: trace the causal chain from your change to the symptom's disappearance, in concrete terms
- Test your explanation: it should predict things you can check — under what conditions the bug occurred, what the old code did wrong at which line, what you'd observe if you partially reverted. Check at least one prediction
- If your honest explanation contains "somehow," "for some reason," "appears to resolve," or "I believe this helps with" — you don't have a mechanism, you have a superstition; keep investigating
- Treat suspicious fix-shapes as demanding extra scrutiny: reordered statements, container-type swaps, added no-op-looking calls, removed "redundant" code, and timing-adjacent changes are classic symptom-perturbers
- If time pressure forces shipping the unexplained change, label it truthfully: "stops the symptom in tested configurations; mechanism not understood; root cause still open" — and keep the investigation alive
- The explanation goes in your summary and ideally the commit: a mechanism someone can verify, not a narration that "this change fixed the bug"

**Red flags that you're about to violate this:**
- "Not entirely sure why, but this resolves the issue..."
- "Moving this line earlier seems to fix it..." (seems? why?)
- "// somehow this fixes the race" as a comment you're about to write
- "The important thing is that it works now..."
- An explanation that restates *what* changed instead of *why* it stops the bug
- Reluctance to partially revert the change because you can't predict what would happen

---

## Why It Works

1. **It separates mechanism from correlation.** "Stopped happening after my change" is the same evidence class as a lucky charm; requiring the X-by-Y statement makes the difference between fixing and perturbing impossible to blur.

2. **It makes the explanation falsifiable.** A real mechanism predicts checkable things (failing conditions, partial-revert behavior); demanding one verified prediction converts the explanation from story to evidence.

3. **It uses the AI's own hedge-words as tripwires.** "Somehow," "seems to," "appears to resolve" are the exact tokens the model emits when it has correlation without mechanism — flagging them gives it a self-test that fires at the moment of violation.

4. **It keeps an honest emergency exit.** Unexplained mitigations sometimes must ship; forcing the truthful label ("mechanism not understood, still open") preserves urgency-handling while preventing the quiet conversion of mystery into resolution.

## Origin

A crash in a report generator stopped occurring when an assistant changed a dictionary to an ordered list "for consistency" — no theory offered, tests green, shipped with the summary "fixed the report crash." The actual bug was an iteration-order dependency that the list version masked for the current data; eight months later new data restored the crash, now in a codebase where the original clue (the dict) had been refactored away. The second investigation took a week, most of it spent rediscovering what the first one had accidentally hidden — including the commit whose message claimed the bug was fixed.
