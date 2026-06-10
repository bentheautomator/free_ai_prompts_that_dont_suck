---
title: Stop the Z-Index Arms Race
slug: stop-the-z-index-arms-race
category: frontend
tags: [universal, frontend, css]
works_with: all
severity: medium
one_liner: "Stops z-index 99999 escalation instead of fixing stacking contexts"
---

# Stop the Z-Index Arms Race

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from "fixing" overlap bugs by writing ever-larger z-index values instead of understanding the stacking context.

**[Copy-paste ready version](../../install/stop-the-z-index-arms-race.md)** — just the instruction block, no explanation.

## The Problem

Something renders behind something else — a dropdown under a sticky header, a tooltip behind a modal — and the AI's reflex is `z-index: 9999`. If that doesn't work, `z-index: 99999`. If *that* doesn't work, `position: relative; z-index: 999999` on a parent. Each escalation is a one-line change that sometimes produces the right screenshot, so the AI keeps pulling the lever. What it never does is ask why the element is behind: usually a stacking context created by a `transform`, `opacity`, `filter`, or `isolation` on an ancestor, which makes the element's z-index meaningless relative to anything outside that context no matter how large the number.

The result is a codebase where grep finds z-index values of 2, 10, 100, 999, 9999, 2147483647, and nobody can add an overlay with confidence. Worse, the escalations interact: the cookie banner at 99999 now covers the modal at 9999, which covers the toast at 999, and every new layered component triggers another round.

AI assistants escalate because the number is the only visible knob, the fix sometimes works by luck, and stacking contexts are invisible in the code being edited — the `transform` creating the trap is three components up.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Stop the Z-Index Arms Race

NEVER fix a layering bug by raising a z-index above an arbitrary big number. Diagnose the stacking context first; the number is almost never the problem.

If an element with `z-index: 9999` still renders behind something, an ancestor has created a stacking context (`transform`, `opacity < 1`, `filter`, `will-change`, `position: fixed`, `isolation`), and no value will escape it.

- Before changing any z-index, identify which stacking context each competing element lives in. If they're in different contexts, compare the contexts' roots — that's where the fix goes.
- For overlays (modals, dropdowns, toasts) trapped inside a transformed ancestor, render them at the document root instead — a portal (`createPortal` in React, `Teleport` in Vue) — rather than fighting the context.
- Use the project's z-index scale if one exists (tokens, a `$z-` map, a `zIndex` theme object). If none exists, use small, ordered values (1, 10, 20...) and add a comment naming what each layer must sit above.
- Never write `z-index` greater than the highest existing value in the project without flagging that you're doing it and why.
- Never add `position: relative; z-index: N` to a parent as a blind experiment. Each new positioned, z-indexed element creates another stacking context and tightens the knot.
- If two existing layers are already in an escalation war (999 vs 9999), flag it; don't join with 99999.

**Red flags that you're about to violate this:**

- "I'll set it to 9999 to be safe."
- "Still behind? I'll add another 9."
- "I'll give the parent a z-index too, one of these will work."
- "The header is 1000, so the dropdown gets 1001, the tooltip 1002..."
- "I don't know why it's behind, but a bigger number can't hurt."
- "Max int z-index guarantees it's always on top."

---

## Why It Works

1. **It names the invisible cause.** The AI escalates because it doesn't model stacking contexts; listing the exact properties that create them (`transform`, `opacity`, `filter`...) turns a mystery into a checkable list.
2. **It provides the actual fix for the most common trap.** Overlay-inside-transformed-ancestor is the canonical case, and "use a portal" is the answer the AI won't reach for while it's staring at a number.
3. **It makes escalation visible instead of silent.** Requiring a flag before exceeding the project's max z-index turns the arms-race move into something a human gets to veto.
4. **It bans guess-and-check parent fiddling.** Adding z-index to parents "to see if it helps" is how new stacking contexts multiply; prohibiting blind experiments forces diagnosis.

## Origin

A dropdown menu rendered behind a sticky table header, so the assistant bumped the dropdown to `z-index: 9999`. It worked on that page. The dropdown component was shared, and on a page where its container had a CSS `transform` for an entry animation, it still clipped — so a later session added `z-index: 99999` and `position: relative` to two ancestors. That broke the modal overlay, which got 999999. The eventual human fix was a four-line portal and deleting every z-index added along the way.
