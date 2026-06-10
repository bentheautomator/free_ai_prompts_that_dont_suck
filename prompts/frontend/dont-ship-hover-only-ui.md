---
title: Don't Ship Hover-Only UI
slug: dont-ship-hover-only-ui
category: frontend
tags: [universal, frontend]
works_with: all
severity: high
one_liner: "Stops controls and content reachable only by mouse hover"
---

# Don't Ship Hover-Only UI

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from gating actions and information behind `:hover`, which doesn't exist on touchscreens or keyboards.

**[Copy-paste ready version](../../install/dont-ship-hover-only-ui.md)** — just the instruction block, no explanation.

## The Problem

"Show the edit and delete buttons when the user hovers over the row" is a request AI assistants execute exactly as stated: `.row .actions { opacity: 0; } .row:hover .actions { opacity: 1; }`. Clean, uncluttered, looks great in the desktop demo. On a phone — where half or more of real traffic lives — there is no hover. The actions are simply gone. Touch users cannot edit, cannot delete, cannot discover the buttons exist. The same pattern hits tooltips that hold required information ("hover the icon to see why this failed"), hover-revealed nav dropdowns, and hover-to-show "copy" buttons on code blocks.

Keyboard users get a related but distinct failure: hovering isn't tabbing, so unless the reveal also triggers on `:focus-within`, tabbing into the hidden controls focuses invisible buttons — focus disappears into a blank region of the row. And `opacity: 0` keeps elements in the tab order while `display: none` removes them, so the AI's choice of hiding technique decides which way it breaks.

Assistants ship hover-only UI because hover-reveal is a beloved desktop pattern in their training data, the request usually names hover explicitly, and the AI's imagined test device has a mouse. No part of its evaluation loop owns a thumb.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Ship Hover-Only UI

NEVER make hover the only way to reach an action or read information. Hover does not exist on touchscreens or keyboards; anything gated behind it must have a touch and keyboard path too.

A hover-revealed control is an invisible control for most phone users — which is most users.

- Hover-revealed actions (row buttons, card menus, copy buttons): pair every `:hover` reveal with `:focus-within` for keyboard, and provide a touch path — either the controls stay visible on touch devices (`@media (hover: none) { .actions { opacity: 1; } }`) or an always-visible affordance (kebab menu) opens them on tap.
- Tooltips must never be the sole carrier of necessary information (error reasons, truncated values, what an icon does). Fine as enhancement; if the user *needs* it, put it on screen or behind a tap/click target. Tooltips should also appear on focus, not just hover.
- Hover-opened menus and dropdowns must also open on click/tap and Enter. Hover-to-open as the only trigger means touch users can't navigate.
- Mind the hiding technique: `opacity: 0`/`visibility` reveals keep invisible elements tabbable or not in different ways — verify that keyboard focus never lands on something the user can't see.
- Treat hover as an enhancement layer: design the interaction to work with tap and Tab first, then let hover make it slicker on devices that have it.
- When a request says "show X on hover," implement the hover *and* the non-hover path — the request is naming the desktop half of the feature, not exempting you from the other half.

**Red flags that you're about to violate this:**

- "The spec literally says on hover, so hover is the whole spec."
- "Hiding the buttons until hover keeps the table clean."
- "Mobile users can long-press or something."
- "The tooltip explains the error, that's the error handling done."
- "This is a desktop admin tool, touch doesn't matter."
- "opacity zero and display none are interchangeable here."

---

## Why It Works

1. **It reinterprets the request instead of refusing it.** "Show on hover" is treated as a description of the desktop enhancement, not the full interaction contract — the AI builds both halves without needing the user to ask twice.
2. **It gives the concrete media query.** `@media (hover: none)` is the standard escape hatch most AIs never emit; having it in hand makes the touch path a two-line addition instead of a redesign.
3. **It splits the keyboard case from the touch case.** `:focus-within` and tab-order-into-invisible-elements are separate failure mechanics that a generic "support mobile" rule misses entirely.
4. **It demotes tooltips from container to garnish.** "Necessary information never lives only in a tooltip" closes the specific hole where error details become unreachable on every phone.

## Origin

A file manager's assistant put rename, share, and delete behind a hover reveal on each row — elegant on the staging demo, reviewed entirely on laptops. After launch, mobile users (60% of sessions) filed tickets that files "couldn't be deleted from the app," and support taught workarounds involving requesting the desktop site. The fix was a kebab menu and three lines of `@media (hover: none)`; the lesson cost a quarter of mobile engagement with the feature.
