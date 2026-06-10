---
title: Make Modals Actually Modal
slug: make-modals-actually-modal
category: frontend
tags: [universal, frontend, accessibility]
works_with: all
severity: high
one_liner: "Stops div-overlay dialogs with no focus trap, Escape, or scroll lock"
---

# Make Modals Actually Modal

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from shipping "modals" that are just positioned divs — no focus management, no Escape, no scroll lock — leaving the page behind fully live.

**[Copy-paste ready version](../../install/make-modals-actually-modal.md)** — just the instruction block, no explanation.

## The Problem

An AI-built modal is typically a conditionally rendered div with `position: fixed`, a dimmed backdrop, and a close button. Visually: a modal. Behaviorally: a sticker on top of a fully live page. Focus stays wherever it was — Tab cycles through the dimmed page *behind* the dialog, so keyboard users interact with controls they can't see while the "modal" content is unreachable without thirty tab presses. Escape does nothing. The page behind still scrolls, so the dialog drifts over different content. Screen readers read the whole background as if no dialog exists. Close the modal and focus lands on `<body>`, dumping keyboard users back at the top of the document.

"Modal" is a behavioral contract — *the rest of the page is inert while I'm open* — and the AI implements only its costume, because the costume is what a screenshot can verify. Every behavioral clause (focus moves in, focus stays in, Escape closes, focus returns, background inert and scroll-locked) is invisible in a static render and skipped under the AI's "looks right, ship it" loop. The irony is that the platform now does almost all of it for free: `<dialog>.showModal()` delivers focus trapping, Escape, inertness, and a `::backdrop` — but div-soup modals dominate training data, so the AI hand-rolls the costume instead.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Make Modals Actually Modal

A modal is a behavior contract, not a styled overlay. NEVER ship a dialog that doesn't trap focus, close on Escape, and render the background inert.

- First choice: the project's existing modal/dialog component or library primitive — never a new bespoke overlay div beside an established one. Second choice: native `<dialog>` with `showModal()`, which provides focus trapping, Escape handling, background inertness, top-layer rendering, and `::backdrop` for free.
- If you must hand-roll, the contract has six clauses, all mandatory:
  1. On open, focus moves into the dialog (the first focusable control, or the dialog itself with `tabindex="-1"`).
  2. While open, Tab and Shift+Tab cycle within the dialog only — focus never reaches the background. Use the `inert` attribute on the page content behind, or a focus trap.
  3. Escape closes it (unless mid-destructive-action, in which case it asks).
  4. On close, focus returns to the element that opened it — not to `<body>`.
  5. Background scroll is locked while open (`overflow: hidden` on the scroll container, with scrollbar-width compensation if the layout shifts).
  6. `role="dialog"`, `aria-modal="true"`, and an accessible name (`aria-labelledby` pointing at the title) so screen readers announce the context switch.
- Backdrop-click-to-close: match the project's convention, but never make it the *only* close affordance — a visible close button is required.
- Render the dialog in a portal/top layer, not inside an `overflow: hidden` or transformed ancestor that will clip it.
- These requirements apply to anything claiming modality: dialogs, drawers, full-screen takeovers, lightboxes. (Non-modal popovers — menus, tooltips — have different rules; don't focus-trap those.)

**Red flags that you're about to violate this:**

- "A fixed-position div with a backdrop is a modal."
- "Focus management is a follow-up; the dialog opens and closes fine."
- "Escape handling is a nice-to-have for power users."
- "Nobody will notice the page behind still scrolls."
- "The dimmed backdrop makes it obvious you can't use the background."
- "The native dialog element is too new to rely on."

---

## Why It Works

1. **It converts "modal" from a look into a checklist.** Each invisible behavior the AI skips becomes an enumerated clause, so "the modal is done" has six verifiable conditions instead of one screenshot.
2. **It routes to existing primitives before craftsmanship.** The most common real-world failure is a bespoke overlay landing next to a proper modal component the AI never looked for; ordering the choices kills that.
3. **It rehabilitates `<dialog>`.** The AI's training data predates reliable native dialogs, so it hand-rolls by default; stating what `showModal()` provides makes the free option visible.
4. **It scopes modality correctly.** Without the popover carve-out, an AI in compliance mode starts focus-trapping dropdown menus — the rule prevents both under- and over-application.

## Origin

A billing app's "confirm plan change" dialog was a styled div. A keyboard-only user tabbed to what they believed was the dialog's Cancel button — actually the live page's "Save settings" button behind the dim — and committed a plan change they'd opened the dialog to reconsider. The refund was easy; the audit finding ("dialogs do not contain focus") covered nine hand-rolled modals built the same way, each a copy of the first one's costume.
