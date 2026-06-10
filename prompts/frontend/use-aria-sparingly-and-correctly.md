---
title: Use ARIA Sparingly and Correctly
slug: use-aria-sparingly-and-correctly
category: frontend
tags: [universal, frontend, accessibility]
works_with: all
severity: high
one_liner: "Stops ARIA confetti — wrong roles and redundant labels that worsen a11y"
---

# Use ARIA Sparingly and Correctly

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from sprinkling ARIA attributes as an accessibility gesture — wrong roles, redundant labels, and stateless widget markup that make screen reader output worse than plain HTML.

**[Copy-paste ready version](../../install/use-aria-sparingly-and-correctly.md)** — just the instruction block, no explanation.

## The Problem

Tell an AI assistant to "make this accessible" and it starts decorating: `role="button"` on actual `<button>` elements, `aria-label="Submit button"` on a button whose visible text is "Submit," `role="navigation"` on a `<nav>`, `aria-label` on every div in sight. None of this helps — the redundant labels make screen readers announce things twice or, worse, the `aria-label` *overrides* the visible text, so a button labeled "Search" visibly gets announced as whatever stale string the attribute holds after the next copy edit.

The dangerous tier is roles as promises. `role="tablist"`/`"tab"` on styled divs promises arrow-key navigation and `aria-selected` management; `role="combobox"` promises a whole interaction contract; `aria-expanded` that's hardcoded `"true"` promises state that never updates. Screen reader users are told "tab, 1 of 3" and then find that arrow keys do nothing and selection is never announced — the ARIA made the experience *worse* than honest divs, because it raised expectations the implementation doesn't meet. A role is an API contract with assistive tech; the AI treats it as a metadata garnish.

This happens because ARIA attributes are the most visible, diffable signal of "accessibility effort," and the AI optimizes for visible effort. The first rule of ARIA — don't use it when HTML suffices — is precisely a rule about *not* producing visible tokens, which is why it loses.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Use ARIA Sparingly and Correctly

NEVER add ARIA as decoration. No ARIA beats wrong ARIA: every role is a behavioral contract, and unkept contracts make screen reader UX worse than plain markup.

- First resort is always the native element: `<button>`, `<nav>`, `<dialog>`, `<details>`, `<select>`, `<input type=...>` carry their roles, states, and keyboard behavior built-in. Adding `role="button"` to a `<button>` or `role="navigation"` to `<nav>` is noise; *reaching for ARIA when a native element exists* is the actual bug.
- Never `aria-label` an element whose visible text already names it — it's redundant at best, and it silently overrides the visible text, drifting out of sync at the first copy change. `aria-label` is for elements with no visible text (icon-only buttons).
- A role obligates you to its whole pattern. `role="tab"` means arrow-key navigation, `aria-selected` updates, and `tabindex` roving. `aria-expanded` means the value flips when the thing expands. If you add the attribute, wire the behavior and the state updates in the same change — a hardcoded `aria-expanded="true"` is a lie told specifically to people who can't see the truth.
- Don't invent attribute names (`aria-text`, `aria-description` where you meant `aria-describedby`) and don't put roles on the wrong layer (e.g., `role="list"` styling hacks on containers whose children aren't `listitem`s).
- Dynamic announcements (`aria-live`) only where content changes out from under the user (toasts, async validation) — politely (`polite`), once, not on regions that re-render constantly.
- Justify every ARIA attribute you write in one clause: what does assistive tech gain? "It seems more accessible" is not a gain.

**Red flags that you're about to violate this:**

- "I'll add roles and labels everywhere to make it accessible."
- "aria-label can't hurt even if the text is visible."
- "role='tablist' on these divs conveys the design intent."
- "I'll set aria-expanded='true' — it's usually open anyway."
- "More ARIA is more accessible."
- "The native dialog is limited; my div with role='dialog' is equivalent."

---

## Why It Works

1. **It inverts the effort signal.** The AI adds ARIA to make accessibility visible in the diff; "no ARIA beats wrong ARIA" redefines restraint as the competent move, removing the incentive to decorate.
2. **It recasts roles as contracts with deliverables.** Once `role="tab"` is understood to *owe* arrow keys and selection state, adding it stops being free and the half-implemented widget pattern stops looking like progress.
3. **It names the label-override hazard.** The AI models `aria-label` as additive; learning it replaces the visible name explains how redundant labels become actively wrong after copy edits.
4. **It demands a per-attribute justification.** One clause of "what does AT gain" filters confetti cheaply — decoration can't answer the question, real fixes answer it trivially.

## Origin

An accessibility-themed cleanup PR from an assistant added 61 ARIA attributes across a settings UI: roles on native elements, aria-labels duplicating visible text, and a `role="tablist"` div set with `aria-selected` frozen on the first tab. A blind user testing afterward reported the settings were *harder* to use than before the PR — tabs announced positions that arrow keys couldn't reach, and several buttons read out two names. The follow-up PR that actually improved things deleted 54 of the 61 attributes and wired real state into the remaining 7.
