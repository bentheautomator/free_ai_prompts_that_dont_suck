---
title: Preserve Keyboard Tab Order
slug: preserve-keyboard-tab-order
category: frontend
tags: [universal, frontend, accessibility]
works_with: all
severity: high
one_liner: "Stops positive tabindex, removed tab stops, and visual-DOM order splits"
---

# Preserve Keyboard Tab Order

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from hijacking tab order with positive tabindex, removing elements from the tab sequence, or letting CSS reorder content until keyboard focus jumps around the page.

**[Copy-paste ready version](../../install/preserve-keyboard-tab-order.md)** — just the instruction block, no explanation.

## The Problem

Tab order is invisible in a screenshot, so AI assistants break it three distinct ways without noticing. First, the brute-force fix: asked to make focus land on a particular field first, the AI writes `tabindex="3"`, `tabindex="2"`, `tabindex="1"` across the form. Positive tabindex doesn't insert those elements into the natural order — it yanks them to the front of the *entire page's* tab sequence, before the header, before the nav, and every element without a positive value now comes after all of them. One "small fix" reorders the whole document for keyboard users.

Second, removal: `tabindex="-1"` applied to a real control to stop "ugly focus" or because focus "shouldn't go there," silently deleting a tab stop that keyboard users need. Third, the CSS split: `flex-direction: row-reverse`, `order: 2`, or absolute positioning rearranges things visually while the DOM — and therefore tab order — stays put. Focus now hops right-to-left across a row that reads left-to-right, or leaps diagonally across a grid.

All three ship because the AI verifies layouts by appearance and interactions by mouse. The tab sequence is a dimension of the page it never traverses.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Preserve Keyboard Tab Order

NEVER use a positive `tabindex`, and never let visual order diverge from DOM order for interactive elements. Tab order comes from document structure; fix the structure, not the numbers.

Keyboard users experience the page as the tab sequence. Reordering or breaking it is a layout bug they can't see past.

- `tabindex` has exactly two sanctioned values: `0` (make a genuinely custom widget focusable in natural order) and `-1` (programmatic focus target, e.g. a heading to focus after route change). Positive values hijack the whole page's sequence — if focus order is wrong, reorder the elements in the markup.
- Never add `tabindex="-1"` to remove a working control from the tab order. If a control is operable by mouse, it must be reachable by Tab. (Exception: composite-widget patterns like roving tabindex inside a toolbar, where Arrow keys take over within the group.)
- When CSS reorders content (`order`, `row-reverse`, grid placement, absolute positioning), keyboard focus still follows the DOM. If the visual order matters, change the source order to match and style from there; don't paper over it with tabindex.
- Modals/drawers that overlay the page must contain Tab focus while open (and restore it on close); otherwise Tab wanders into the obscured page behind. Off-screen but rendered content (closed menus, inactive carousel slides) must not hold tab stops — hide it for real (`display: none`, `inert`, `visibility: hidden`), not just visually.
- After changing any layout or adding any interactive element, walk the change with the Tab key in your head: enumerate the focus sequence and check it matches reading order.

**Red flags that you're about to violate this:**

- "tabindex='1' on the search box puts it first, problem solved."
- "Focus shouldn't land on this button, tabindex='-1' it."
- "row-reverse gets the visual order right, ship it."
- "The menu is off-screen, so its links don't matter."
- "Tab order is an edge case for this internal tool."
- "I'll renumber all the tabindexes so the sequence works out."

---

## Why It Works

1. **It explains why positive tabindex can't do what the AI thinks.** The AI models `tabindex="3"` as "third in this form"; learning it means "before everything unnumbered on the page" makes the tool obviously wrong for the job.
2. **It reduces tabindex to a two-value vocabulary.** `0` and `-1` with stated purposes leaves no room for the renumbering spiral, while preserving the legitimate roving-tabindex pattern via explicit exception.
3. **It links CSS reordering to focus, which the AI treats as unrelated.** `order` and `row-reverse` live in the styling mental box; the rule moves them into the interaction box where their cost is visible.
4. **It adds a cheap traversal check.** Enumerating the tab sequence after a layout change is the keyboard equivalent of looking at the screenshot — almost free once demanded, never done unless demanded.

## Origin

A signup form's assistant was asked to make focus start on the email field. It assigned `tabindex` 1 through 6 down the form. Keyboard users then found that tabbing from the last form field jumped to the page header, then the cookie banner, then the footer — every unnumbered element on the page now came after the form, in an order nobody designed. The report came from an employee who relied on keyboard navigation and described the page as "shuffled." The fix was deleting six attributes and moving one `autofocus`.
