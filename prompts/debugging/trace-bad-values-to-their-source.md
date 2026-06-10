---
title: Trace Bad Values to Their Source
slug: trace-bad-values-to-their-source
category: debugging
tags: [universal, debugging, root-cause]
works_with: all
severity: high
one_liner: "AI patching where the wrong value surfaces instead of where it's born"
---

# Trace Bad Values to Their Source

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from correcting a wrong value at the point of display instead of the point of creation.

**[Copy-paste ready version](../../install/trace-bad-values-to-their-source.md)** — just the instruction block, no explanation.

## The Problem

The invoice shows `NaN`. The AI goes to the invoice template and writes `isNaN(total) ? 0 : total`. The dashboard shows a negative age; the AI clamps it with `Math.max(0, age)` in the dashboard component. In both cases the wrong value was *born* somewhere upstream — a failed parse, a subtraction of swapped operands, a join that duplicated rows — and traveled through four functions before becoming visible. The AI patched the last stop on the journey, because that's where the symptom pointed, and left the factory producing defects at full speed.

Surface-level patching has a special property that makes it worse than doing nothing: it removes the visibility while preserving the corruption. The `NaN` was at least honest. After the patch, the invoice says `0` — a plausible lie — and the same broken value is still flowing into every *other* consumer: the tax calculation, the export, the database. One symptom got cosmetics; the disease kept all its other symptoms, now harder to notice.

Assistants default to display-site fixes because the symptom's location is handed to them ("the invoice shows NaN") and tracing dataflow backwards through assignments, transformations, and service boundaries is genuinely laborious. The fix at the surface is one line. The fix at the source requires finding the source.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Trace Bad Values to Their Source

NEVER fix a wrong value where it becomes visible. Trace it backwards to where it becomes wrong, and fix it there.

The display site is the last stop of a journey. Patching there beautifies one symptom while the corrupt value keeps flowing to every other consumer — and removes the only visible evidence that something is broken.

- Walk the dataflow upstream from the symptom: what produced this value, and what produced its inputs, until you find the first point where the data is wrong; that point is the bug
- Instrument the pipeline if reading isn't enough — print the value at each stage boundary and find the first stage whose output is bad
- Common birthplaces to check: parsing (string survived where a number was expected), arithmetic with absent operands, swapped arguments, a join or merge multiplying rows, unit or timezone mismatches at a boundary, a silent fallback returning a wrong default
- Before patching at the surface, ask: who else consumes this value? If the answer is "anyone at all," a display-site fix is leaving the bug live for all of them
- Cosmetic guards at the display layer (`?? 0`, `Math.max(0, x)`, `isNaN` checks) are acceptable only as explicitly-labeled defense in depth *after* the source is fixed — never as the fix itself
- Your explanation must name the birthplace: "the value goes wrong at <point> because <mechanism>," not "added handling for the bad value"

**Red flags that you're about to violate this:**
- "I'll add a fallback in the template so it displays cleanly..."
- "Clamping this to zero handles the negative case..."
- "Wherever it's coming from, the UI shouldn't show NaN..." (wherever?)
- "The other consumers probably aren't affected..."
- Fixing the symptom's location without being able to say where the value first went wrong
- A diff in the view layer for a bug whose wrongness is arithmetic

---

## Why It Works

1. **It defines the bug positionally.** "The first point where the data is wrong is the bug" gives an unambiguous target that the symptom's location can't satisfy, blocking the handed-to-you-by-the-report shortcut.

2. **It exposes the multi-consumer stakes.** "Who else reads this value?" makes the display-site patch visibly partial — the AI can't claim completeness once it has named other consumers still receiving corruption.

3. **It reframes the honest NaN.** A loud wrong value is evidence; a defaulted plausible value is camouflage. Stating that the patch destroys evidence flips its perceived value from tidy to harmful.

4. **It channels the guard impulse legitimately.** Defense-in-depth at the surface is real engineering — but only sequenced after the source fix and labeled as such, which keeps the cosmetic patch from masquerading as the resolution.

## Origin

A billing page intermittently showed `$NaN`, and an assistant fixed it in the formatter with `|| 0`. Clean demo, ticket closed. The NaN had been born in a currency-conversion function that returned `undefined` for one rarely-used currency pair — and that same undefined was flowing into the charge-creation path, which had been quietly creating zero-amount charges for those customers. The display patch hid the only visible symptom of a revenue bug that took another month to surface in reconciliation.
